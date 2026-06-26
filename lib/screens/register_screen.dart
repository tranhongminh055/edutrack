import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/nature_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/gradient_button.dart';
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
    if (_selectedRole == UserRole.admin) return 'Mã quản trị viên';
    return 'Mã số (chọn vai trò trước)';
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Vui lòng chọn vai trò'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Vui lòng đồng ý điều khoản'),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _isLoading = true);
    
    try {
      // 1. Tạo tài khoản Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      // 2. Lưu thông tin thêm vào Firestore
      final roleStr = _selectedRole == UserRole.student ? 'student' : _selectedRole == UserRole.lecturer ? 'lecturer' : 'admin';
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'fullName': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'role': roleStr,
        'studentId': _idCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Đăng xuất ngay lập tức để ép người dùng đăng nhập bằng màn hình Login
      await FirebaseAuth.instance.signOut();

      setState(() => _isLoading = false);
      if (mounted) {
        _showSuccessDialog();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String errorMessage = 'Đã xảy ra lỗi, vui lòng thử lại';
      if (e.code == 'weak-password') {
        errorMessage = 'Mật khẩu quá yếu';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email này đã được đăng ký';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Email không hợp lệ';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withOpacity(0.2),
                border: Border.all(color: AppColors.primaryGreen, width: 3),
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.primaryGreen, size: 44),
            ),
            const SizedBox(height: 20),
            const Text('Đăng ký thành công!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 10),
            Text(
              'Tài khoản ${_selectedRole == UserRole.student ? "sinh viên" : _selectedRole == UserRole.lecturer ? "giảng viên" : "quản trị viên"} đã được tạo',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
            ),
            const SizedBox(height: 28),
            GradientButton(
              text: 'ĐĂNG NHẬP NGAY',
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => LoginScreen(
                    registeredName: _nameCtrl.text.trim(),
                    registeredEmail: _emailCtrl.text.trim(),
                    registeredId: _idCtrl.text.trim(),
                    registeredRole: _selectedRole,
                  )),
                );
              },
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NatureBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 24),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                  opacity: _fadeAnim,
                  child: GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitle(),
                          const SizedBox(height: 24),
                          _buildRoleLabel(),
                          const SizedBox(height: 12),
                          RoleSelector(
                            selectedRole: _selectedRole,
                            onRoleChanged: (r) => setState(() => _selectedRole = r),
                          ),
                          const SizedBox(height: 20),
                          GlassTextField(
                            hintText: 'Họ và tên',
                            prefixIcon: Icons.person_outline_rounded,
                            controller: _nameCtrl,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Vui lòng nhập họ tên';
                              if (v.trim().length < 2) return 'Họ tên quá ngắn';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          GlassTextField(
                            hintText: 'Email',
                            prefixIcon: Icons.email_outlined,
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                                return 'Email không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          GlassTextField(
                            hintText: _idHint,
                            prefixIcon: Icons.badge_outlined,
                            controller: _idCtrl,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Vui lòng nhập mã số';
                              if (!RegExp(r'^\d+$').hasMatch(v.trim())) return 'Mã số chỉ được chứa chữ số';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          GlassTextField(
                            hintText: 'Mật khẩu',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            controller: _passCtrl,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                              if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          GlassTextField(
                            hintText: 'Xác nhận mật khẩu',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            controller: _confirmPassCtrl,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                              if (v != _passCtrl.text) return 'Mật khẩu không khớp';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTermsRow(),
                          const SizedBox(height: 24),
                          _buildRegisterBtn(),
                          const SizedBox(height: 24),
                          _buildLoginLink(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
        ),
        const Spacer(),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFF81C784), Color(0xFF4CAF50)],
          ).createShader(b),
          child: const Text('EduTrack',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
        const Spacer(),
        const SizedBox(width: 44),
      ]),
    );
  }

  Widget _buildTitle() {
    return const Center(
      child: Column(children: [
        Text('Tạo Tài Khoản',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        SizedBox(height: 8),
        Text('Đăng ký để bắt đầu',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildRoleLabel() {
    return const Text('Bạn là',
      style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600));
  }

  Widget _buildTermsRow() {
    return GestureDetector(
      onTap: () => setState(() => _agreeTerms = !_agreeTerms),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 22, height: 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _agreeTerms ? AppColors.primaryGreen : Colors.white.withOpacity(0.3), width: 2),
            color: _agreeTerms ? AppColors.primaryGreen : Colors.transparent,
          ),
          child: _agreeTerms ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(text: TextSpan(
            text: 'Tôi đồng ý với ',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
            children: const [
              TextSpan(text: 'Điều khoản sử dụng',
                style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
            ],
          )),
        ),
      ]),
    );
  }

  Widget _buildRegisterBtn() {
    if (_isLoading) {
      return Center(child: Container(
        width: 56, height: 56, padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryGreen.withOpacity(0.2)),
        child: const CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 3),
      ));
    }
    return GradientButton(text: 'ĐĂNG KÝ', onPressed: _handleRegister, icon: Icons.person_add_rounded);
  }

  Widget _buildLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (c, a, s) => const LoginScreen(),
            transitionsBuilder: (c, a, s, child) => FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        ),
        child: RichText(text: TextSpan(
          text: 'Đã có tài khoản? ',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          children: const [
            TextSpan(text: 'Đăng nhập',
              style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w700)),
          ],
        )),
      ),
    );
  }
}
