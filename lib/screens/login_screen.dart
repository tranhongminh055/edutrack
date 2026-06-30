import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/nature_background.dart';
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
  bool _obscureText = true;

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
                              color: Colors.black.withOpacity(0.2),
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
              color: Colors.white.withOpacity(0.9), 
              fontSize: 16,
              fontWeight: FontWeight.w500,
            )
          ),
          const SizedBox(height: 48),
          // Decorative elements (representing tech/education connection)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                ),
                child: Center(
                  child: Icon(Icons.hub_rounded, size: 40, color: Colors.white.withOpacity(0.7)),
                ),
              ),
            ),
          ),
          const Spacer(),
          Text('Theo dõi tiến độ học tập, quản lý lớp học và kết nối cộng đồng giáo dục', 
            textAlign: TextAlign.center, 
            style: TextStyle(
              color: Colors.white.withOpacity(0.6), 
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
            const Text('Đăng nhập',
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.w800, 
                color: AppColors.primaryBlue,
              )
            ),
            const SizedBox(height: 8),
            const Text('Vui lòng nhập thông tin tài khoản của bạn',
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
              label: 'Email hoặc Mã số',
              hint: 'Nhập email hoặc mã số sinh viên',
              icon: Icons.person_outline,
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
            const SizedBox(height: 16),
            _buildRememberRow(),
            const SizedBox(height: 32),
            _buildLoginBtn(),
            const SizedBox(height: 24),
            _buildDivider(),
            const SizedBox(height: 24),
            _buildGoogleBtn(),
            const SizedBox(height: 32),
            _buildSignUpLink(),
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
        TextFormField(
          controller: controller,
          obscureText: isPassword && _obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.black45, size: 20),
            suffixIcon: isPassword 
                ? IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black45, size: 20),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black12, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black12, width: 1.5),
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
      ],
    );
  }

  Widget _buildRememberRow() {
    return Row(children: [
      GestureDetector(
        onTap: () => setState(() => _rememberMe = !_rememberMe),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20, height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _rememberMe ? AppColors.primaryBlue : Colors.black26, width: 2),
              color: _rememberMe ? AppColors.primaryBlue : Colors.white,
            ),
            child: _rememberMe ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
          const SizedBox(width: 10),
          const Text('Ghi nhớ đăng nhập', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
      const Spacer(),
      GestureDetector(
        onTap: () {},
        child: const Text('Quên mật khẩu?',
          style: TextStyle(color: AppColors.primaryBlue, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    ]);
  }

  Widget _buildLoginBtn() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
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
            : const Text('Đăng nhập', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(children: [
      Expanded(child: Container(height: 1, color: Colors.black12)),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('hoặc', style: TextStyle(color: Colors.black38, fontSize: 13)),
      ),
      Expanded(child: Container(height: 1, color: Colors.black12)),
    ]);
  }

  Widget _buildGoogleBtn() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.g_mobiledata_rounded, color: Colors.black87, size: 28),
        label: const Text('Đăng nhập với Google',
          style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.black12, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
        child: RichText(text: const TextSpan(
          text: 'Chưa có tài khoản? ',
          style: TextStyle(color: Colors.black54, fontSize: 14),
          children: [
            TextSpan(text: 'Đăng ký ngay',
              style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w700)),
          ],
        )),
      ),
    );
  }
}
