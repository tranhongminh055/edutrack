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
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? registeredName;
  final String? registeredEmail;
  final String? registeredId;
  final UserRole? registeredRole;

  const LoginScreen({
    super.key,
    this.registeredName,
    this.registeredEmail,
    this.registeredId,
    this.registeredRole,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  final _passCtrl = TextEditingController();
  UserRole? _selectedRole;
  bool _isLoading = false;
  bool _rememberMe = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(
      text: widget.registeredEmail?.isNotEmpty == true 
          ? widget.registeredEmail 
          : widget.registeredId,
    );
    _selectedRole = widget.registeredRole;
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
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
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
    String input = _emailCtrl.text.trim();

    setState(() => _isLoading = true);

    try {
      String emailToLogin = input;
      
      // Nếu người dùng nhập mã số (không có @), tìm email tương ứng trong Firestore
      if (!input.contains('@')) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('studentId', isEqualTo: input)
            .limit(1)
            .get();
            
        if (querySnapshot.docs.isEmpty) {
          throw Exception('Không tìm thấy tài khoản với mã số này');
        }
        emailToLogin = querySnapshot.docs.first.data()['email'] ?? '';
      }

      // 1. Xác thực bằng Firebase Auth
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailToLogin,
        password: _passCtrl.text,
      );

      // 2. Lấy thông tin từ Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Dữ liệu người dùng không tồn tại');
      }

      final userData = userDoc.data()!;
      final dbRoleStr = userData['role'] as String?;
      final expectedRoleStr = _selectedRole == UserRole.student ? 'student' : _selectedRole == UserRole.lecturer ? 'lecturer' : 'admin';

      // 3. Kiểm tra chéo vai trò
      if (dbRoleStr != expectedRoleStr) {
        await FirebaseAuth.instance.signOut();
        final roleName = expectedRoleStr == 'student' ? 'Sinh viên' : expectedRoleStr == 'lecturer' ? 'Giảng viên' : 'Quản trị viên';
        throw Exception('Vai trò không khớp. Bạn không phải là $roleName.');
      }

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => HomeScreen(
            role: _selectedRole!, 
            email: userData['email'] ?? '',
            studentId: userData['studentId'] ?? '',
            fullName: userData['fullName'] ?? '',
          ),
        ));
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String errorMessage = 'Đăng nhập thất bại';
      if (e.code == 'user-not-found' || e.code == 'invalid-email' || e.code == 'invalid-credential') {
        errorMessage = 'Email hoặc mật khẩu không chính xác';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Sai mật khẩu';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
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
              const SizedBox(height: 30),
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
                          const SizedBox(height: 28),
                          _buildRoleLabel(),
                          const SizedBox(height: 12),
                          RoleSelector(
                            selectedRole: _selectedRole,
                            onRoleChanged: (r) => setState(() => _selectedRole = r),
                          ),
                          const SizedBox(height: 24),
                          GlassTextField(
                            hintText: 'Email hoặc mã số',
                            prefixIcon: Icons.email_outlined,
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email hoặc mã số';
                              if (v.contains('@') && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                                return 'Email không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
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
                          _buildRememberRow(),
                          const SizedBox(height: 28),
                          _buildLoginBtn(),
                          const SizedBox(height: 20),
                          _buildDivider(),
                          const SizedBox(height: 20),
                          _buildGoogleBtn(),
                          const SizedBox(height: 24),
                          _buildSignUpLink(),
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
        Text('Đăng Nhập',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        SizedBox(height: 8),
        Text('Chào mừng bạn trở lại!',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildRoleLabel() {
    return const Text('Vai trò của bạn',
      style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600));
  }

  Widget _buildRememberRow() {
    return Row(children: [
      GestureDetector(
        onTap: () => setState(() => _rememberMe = !_rememberMe),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _rememberMe ? AppColors.primaryGreen : Colors.white.withOpacity(0.3), width: 2),
              color: _rememberMe ? AppColors.primaryGreen : Colors.transparent,
            ),
            child: _rememberMe ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
          const SizedBox(width: 8),
          Text('Ghi nhớ', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
        ]),
      ),
      const Spacer(),
      GestureDetector(
        onTap: () {},
        child: const Text('Quên mật khẩu?',
          style: TextStyle(color: AppColors.primaryGreen, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    ]);
  }

  Widget _buildLoginBtn() {
    if (_isLoading) {
      return Center(child: Container(
        width: 56, height: 56, padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryGreen.withOpacity(0.2)),
        child: const CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 3),
      ));
    }
    return GradientButton(text: 'ĐĂNG NHẬP', onPressed: _handleLogin, icon: Icons.login_rounded);
  }

  Widget _buildDivider() {
    return Row(children: [
      Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.15))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('hoặc', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
      ),
      Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.15))),
    ]);
  }

  Widget _buildGoogleBtn() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          color: Colors.white.withOpacity(0.05),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Text('Đăng nhập với Google',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (c, a, s) => const RegisterScreen(),
            transitionsBuilder: (c, a, s, child) => FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        ),
        child: RichText(text: TextSpan(
          text: 'Chưa có tài khoản? ',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          children: const [
            TextSpan(text: 'Đăng ký ngay',
              style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w700)),
          ],
        )),
      ),
    );
  }
}
