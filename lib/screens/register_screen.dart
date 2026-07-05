import 'dart:ui';
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
  bool _obscureText = true;
  bool _obscureConfirmText = true;

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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              physics: const BouncingScrollPhysics(),
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 850;
                      final cardWidth = isDesktop ? 900.0 : 450.0;
                      
                      return Container(
                        width: cardWidth,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            )
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (isDesktop) 
                                Expanded(child: _buildLeftPanel()),
                              Expanded(child: _buildRightPanel()),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      color: AppColors.primaryBlue,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Icon(Icons.school, size: 72, color: Colors.white),
          const SizedBox(height: 24),
          const Text('EduTrack', 
            style: TextStyle(
              color: Colors.white, 
              fontSize: 32, 
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            )
          ),
          const SizedBox(height: 12),
          Text('Hệ thống quản lý giáo dục thông minh', 
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9), 
              fontSize: 16,
              fontWeight: FontWeight.w500,
            )
          ),
          const SizedBox(height: 48),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Center(
                  child: Icon(Icons.hub_rounded, size: 40, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
            ),
          ),
          const Spacer(),
          Text('Theo dõi tiến độ học tập, quản lý lớp học và kết nối cộng đồng giáo dục', 
            textAlign: TextAlign.center, 
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6), 
              fontSize: 13,
              height: 1.5,
            )
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Đăng ký',
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.w800, 
                color: AppColors.primaryBlue,
              )
            ),
            const SizedBox(height: 8),
            const Text('Tạo tài khoản mới để bắt đầu',
              style: TextStyle(
                fontSize: 14, 
                color: Colors.black54,
              )
            ),
            const SizedBox(height: 32),
            const Text('Vai trò',
              style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)
            ),
            const SizedBox(height: 10),
            RoleSelector(
              selectedRole: _selectedRole,
              onRoleChanged: (r) => setState(() => _selectedRole = r),
              isLightMode: true,
            ),
            const SizedBox(height: 24),
            _buildInputField(
              label: 'Họ và tên',
              hint: 'Nhập họ và tên đầy đủ',
              icon: Icons.person_outline,
              controller: _nameCtrl,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập họ và tên';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildInputField(
              label: 'Email',
              hint: 'Nhập email của bạn',
              icon: Icons.email_outlined,
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
            const SizedBox(height: 20),
            _buildInputField(
              label: _idHint,
              hint: 'Nhập mã số của bạn',
              icon: Icons.badge_outlined,
              controller: _idCtrl,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập mã số';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildInputField(
              label: 'Mật khẩu',
              hint: 'Nhập mật khẩu',
              icon: Icons.lock_outline,
              controller: _passCtrl,
              isPassword: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildInputField(
              label: 'Xác nhận mật khẩu',
              hint: 'Nhập lại mật khẩu',
              icon: Icons.lock_outline,
              controller: _confirmPassCtrl,
              isPassword: true,
              isConfirmPassword: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                if (v != _passCtrl.text) return 'Mật khẩu không khớp';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTermsRow(),
            const SizedBox(height: 32),
            _buildRegisterBtn(),
            const SizedBox(height: 32),
            _buildLoginLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool isConfirmPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && (isConfirmPassword ? _obscureConfirmText : _obscureText),
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
              prefixIcon: Icon(icon, color: Colors.black45, size: 20),
              suffixIcon: isPassword 
                  ? IconButton(
                      icon: Icon(
                        isConfirmPassword 
                            ? (_obscureConfirmText ? Icons.visibility_off_outlined : Icons.visibility_outlined)
                            : (_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        color: Colors.black45, 
                        size: 20
                      ),
                      onPressed: () => setState(() {
                        if (isConfirmPassword) {
                          _obscureConfirmText = !_obscureConfirmText;
                        } else {
                          _obscureText = !_obscureText;
                        }
                      }),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsRow() {
    return GestureDetector(
      onTap: () => setState(() => _agreeTerms = !_agreeTerms),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 20, height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _agreeTerms ? AppColors.primaryBlue : Colors.black26, width: 2),
            color: _agreeTerms ? AppColors.primaryBlue : Colors.white,
          ),
          child: _agreeTerms ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            children: [
              const Text('Tôi đồng ý với ', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
              GestureDetector(
                onTap: () {},
                child: const Text('Điều khoản dịch vụ', style: TextStyle(color: AppColors.primaryBlue, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const Text(' và ', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
              GestureDetector(
                onTap: () {},
                child: const Text('Chính sách bảo mật', style: TextStyle(color: AppColors.primaryBlue, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildRegisterBtn() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Text('Đăng ký', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ),
    );
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
        child: RichText(text: const TextSpan(
          text: 'Đã có tài khoản? ',
          style: TextStyle(color: Colors.black54, fontSize: 14),
          children: [
            TextSpan(text: 'Đăng nhập ngay',
              style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w700)),
          ],
        )),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng đồng ý với điều khoản dịch vụ'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng chọn vai trò'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final uid = userCred.user!.uid;
      final roleStr = _selectedRole == UserRole.student ? 'student' : 
                      _selectedRole == UserRole.lecturer ? 'lecturer' : 'admin';
      
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fullName': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'studentId': _idCtrl.text.trim(),
        'role': roleStr,
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
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Lỗi đăng ký';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Email này đã được sử dụng';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Email không hợp lệ';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Mật khẩu quá yếu';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi đăng ký: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
