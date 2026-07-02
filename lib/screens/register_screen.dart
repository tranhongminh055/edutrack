import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/nature_background.dart';
import '../widgets/role_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  UserRole? _selectedRole;
  bool _isLoading = false;
  bool _agreeTerms = false;
  final bool _obscureText = true;
  final bool _obscureConfirmText = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _idCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  String get _idHint {
    if (_selectedRole == UserRole.student) return 'Mã số sinh viên';
    if (_selectedRole == UserRole.lecturer) return 'Mã giảng viên';
    return 'Mã định danh';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NatureBackground(
        child: Center(
          child: SingleChildScrollView(
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                    width: 540,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Đăng ký', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(controller: _nameCtrl, decoration: InputDecoration(labelText: 'Họ và tên')),
                              const SizedBox(height: 8),
                              TextFormField(controller: _emailCtrl, decoration: InputDecoration(labelText: 'Email')),
                              const SizedBox(height: 8),
                              TextFormField(controller: _idCtrl, decoration: InputDecoration(labelText: _idHint)),
                              const SizedBox(height: 8),
                              TextFormField(controller: _passCtrl, obscureText: _obscureText, decoration: InputDecoration(labelText: 'Mật khẩu')),
                              const SizedBox(height: 8),
                              TextFormField(controller: _confirmPassCtrl, obscureText: _obscureConfirmText, decoration: InputDecoration(labelText: 'Xác nhận mật khẩu')),
                              const SizedBox(height: 12),
                              RoleSelector(
                                selectedRole: _selectedRole,
                                onRoleChanged: (role) { setState(() => _selectedRole = role); },
                                isLightMode: false,
                              ),
                              const SizedBox(height: 12),
                              Row(children: [Checkbox(value: _agreeTerms, onChanged: (v) => setState(() => _agreeTerms = v ?? false)), const Expanded(child: Text('Tôi đồng ý với các điều khoản'))]),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _isLoading ? null : _register, child: _isLoading ? CircularProgressIndicator() : Text('Đăng ký')),
                              const SizedBox(height: 8),
                              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen())), child: Text('Đã có tài khoản? Đăng nhập')),
                            ],
                          ),
                        ),
                      ],
                    ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu không khớp')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final uid = userCred.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'identifier': _idCtrl.text.trim(),
        'role': _selectedRole?.toString() ?? UserRole.student.toString(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            role: _selectedRole ?? UserRole.student,
            email: _emailCtrl.text.trim(),
            studentId: _idCtrl.text.trim(),
            fullName: _nameCtrl.text.trim(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi đăng ký: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
