import 'dart:async';
import 'dart:convert';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../theme/app_colors.dart';
import '../widgets/nature_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/schedule_grid.dart';
import '../services/notification_service.dart';
import '../services/course_registration_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screen.dart';
import '../widgets/role_selector.dart';
import '../widgets/mail_client_view.dart';
import '../widgets/forum_board_view.dart';
import '../widgets/lecturer_library_view.dart';
import '../widgets/live_clock.dart';
import 'elearning/elearning_dashboard.dart';

class LecturerDashboard extends StatefulWidget {
  final String email;
  const LecturerDashboard({super.key, required this.email});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  int _menuIndex = 0;
  final NotificationService _notiService = NotificationService();
  final CourseRegistrationService _regService = CourseRegistrationService();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();
  final bool _showSuccess = false;
  String _lecturerRegSemester = 'Học kỳ 1';
  String _lecturerRegYear = '2025-2026';
  String? _selectedGradingCourseDocId;
  Future<Map<String, dynamic>>? _detailedGradeFuture;
  Map<String, dynamic>? _selectedEvaluation;

  bool _isEditingInfo = false;
  bool _isVerified = false;
  String? _systemNote;
  String? _avatarBase64;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _facultyController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _fullNameController.text = data['fullName'] ?? '';
          _idController.text = data['idNumber'] ?? '';
          _dobController.text = data['dob'] ?? '';
          _genderController.text = data['gender'] ?? '';
          _emailController.text = data['email'] ?? widget.email;
          _phoneController.text = data['phone'] ?? '';
          _facultyController.text = data['faculty'] ?? '';
          _majorController.text = data['major'] ?? '';
          _avatarBase64 = data['avatarBase64'];
          _isVerified = data['isVerified'] ?? false;
          _systemNote = data['systemNote'];
        });
      }
    }
  }

  final List<Map<String, dynamic>> _menus = [
    {'icon': Icons.person, 'label': 'Thông tin Cá nhân'},
    {'icon': Icons.article, 'label': 'Tin tức & Thông báo'},
    {'icon': Icons.calendar_today, 'label': 'Lịch dạy'},
    {'icon': Icons.how_to_reg, 'label': 'SV Đăng ký lớp'},
    {'icon': Icons.assignment, 'label': 'Bảng điểm Cụ thể'},
    {'icon': Icons.rate_review, 'label': 'Đánh giá Giảng viên'},
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _fullNameController.dispose();
    _idController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _facultyController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final updates = {
      'fullName': _fullNameController.text.trim(),
      'idNumber': _idController.text.trim(),
      'dob': _dobController.text.trim(),
      'gender': _genderController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'faculty': _facultyController.text.trim(),
      'major': _majorController.text.trim(),
      if (_avatarBase64 != null) 'avatarBase64': _avatarBase64,
    };

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(updates, SetOptions(merge: true));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thông tin thành công')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _avatarBase64 = base64Encode(bytes);
        });
        if (!_isEditingInfo) {
          _saveProfile();
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NatureBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopNav(),
              _buildBanner(),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSidebar(),
                    Expanded(child: _buildContent()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: Colors.black.withValues(alpha: 0.2),
      child: Row(
        children: [
          const Icon(Icons.school, color: AppColors.lecturerColor, size: 24),
          const SizedBox(width: 8),
          const Text('EduTrack', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(width: 32),
          _buildTopNavLink(Icons.home, 'Trang chủ', onTap: () => setState(() => _menuIndex = 0)),
          _buildTopNavLink(Icons.mail, 'Mail', onTap: () => setState(() => _menuIndex = 998)),
          _buildTopNavLink(Icons.check_circle, 'E-Learning', onTap: () {
            final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
            web.window.open('https://edutrack-elearning.web.app/?userId=$uid&role=lecturer&email=${Uri.encodeComponent(widget.email)}', '_blank');
          }),
          _buildTopNavLink(Icons.forum, 'Forum', onTap: () => setState(() => _menuIndex = 997)),
          _buildTopNavLink(Icons.library_books, 'e-Lib', onTap: () => setState(() => _menuIndex = 996)),
          const Spacer(),
          Text(widget.email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()), (r) => false,
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
              child: const Row(children: [
                Icon(Icons.logout, color: Colors.redAccent, size: 14),
                SizedBox(width: 4),
                Text('Đăng xuất', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavLink(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Logo text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('my', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 24, fontStyle: FontStyle.italic)),
                const Text('EDUTRACK', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ],
            ),
            
            // Center: Clock
            const LiveClock(),
            
            // Right: Quick Links
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickLink(Icons.mail, 'EduTrack Gmail', onTap: () => setState(() => _menuIndex = 998)),
                const SizedBox(height: 8),
                _buildQuickLink(Icons.language, 'HỌC TẬP TRỰC TUYẾN', onTap: () {
                  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                  web.window.open('https://edutrack-elearning.web.app/?userId=$uid&role=lecturer&email=${Uri.encodeComponent(widget.email)}', '_blank');
                }),
                const SizedBox(height: 8),
                _buildQuickLink(Icons.group, 'DIỄN ĐÀN HỌC TẬP EDUTRACK', onTap: () => setState(() => _menuIndex = 997)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLink(IconData icon, String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.lecturerColor, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(left: 24, top: 16, bottom: 24),
      child: GlassContainer(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lecturerColor.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.lecturerColor.withValues(alpha: 0.3)),
                  child: const Icon(Icons.person, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.email.split('@').first, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _menus.length,
                itemBuilder: (_, i) {
                  final m = _menus[i];
                  final sel = i == _menuIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _menuIndex = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                        border: Border(left: sel ? const BorderSide(color: AppColors.lecturerColor, width: 4) : BorderSide.none),
                      ),
                      child: Row(children: [
                        Icon(m['icon'] as IconData, color: sel ? AppColors.lecturerColor : Colors.white54, size: 20),
                        const SizedBox(width: 12),
                        Text(m['label'] as String, style: TextStyle(color: sel ? AppColors.lecturerColor : Colors.white70, fontWeight: sel ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 24),
      child: GlassContainer(
        child: switch (_menuIndex) {
          0 => _buildPersonalInfoContent(),
          1 => _buildNewsContent(),
          2 => _buildSchedule(),
          3 => _buildStudentRegistrations(),
          4 => _buildGrading(),
          5 => _buildLecturerEvaluations(),
          996 => LecturerLibraryView(email: widget.email),
          997 => ForumBoardView(role: UserRole.lecturer, email: widget.email),
          998 => MailClientView(role: UserRole.lecturer, email: widget.email),
          999 => ELearningDashboard(
                 role: UserRole.lecturer, 
                 userId: '', 
                 email: widget.email, 
                 currentSemester: _lecturerRegSemester, 
                 currentYear: _lecturerRegYear,
               ),
          _ => const SizedBox(),
        },
      ),
    );
  }

  Widget _tableHeader(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(text, style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
    );
  }

  Widget _tableCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Center(child: child),
    );
  }

  // --- 0: Tổng quan ---
  Widget _buildPersonalInfoContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person, color: AppColors.lecturerColor, size: 28),
                    SizedBox(width: 12),
                    Text('THÔNG TIN CÁ NHÂN', style: TextStyle(color: AppColors.lecturerColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_isEditingInfo) {
                      if (_formKey.currentState!.validate()) {
                        _saveProfile();
                        setState(() {
                          _isEditingInfo = false;
                        });
                      }
                    } else {
                      setState(() {
                        _isEditingInfo = true;
                      });
                    }
                  },
                  icon: Icon(_isEditingInfo ? Icons.save : Icons.edit, size: 16),
                  label: Text(_isEditingInfo ? 'Lưu thông tin' : 'Cập nhật thông tin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lecturerColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar section
                Column(
                  children: [
                    Container(
                      width: 120, height: 120,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.lecturerColor.withValues(alpha: 0.2),
                        border: Border.all(color: AppColors.lecturerColor, width: 2),
                      ),
                      child: _avatarBase64 != null
                          ? Image.memory(base64Decode(_avatarBase64!), fit: BoxFit.cover)
                          : Icon(Icons.person, size: 60, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.lecturerColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Cập nhật ảnh', style: TextStyle(color: AppColors.lecturerColor, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 40),
                // Info details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isVerified) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(children: [
                                Icon(Icons.verified, color: Colors.green, size: 18),
                                SizedBox(width: 8),
                                Text('Tài khoản đã được hệ thống xác thực', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                              ]),
                              if (_systemNote != null) ...[
                                const SizedBox(height: 6),
                                Text(_systemNote!, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontStyle: FontStyle.italic)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      _buildInfoRow('Họ và tên', _fullNameController, 'Mã số GV/ID', _idController),
                      const SizedBox(height: 16),
                      Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                      const SizedBox(height: 16),
                      _buildInfoRow('Ngày sinh', _dobController, 'Giới tính', _genderController),
                      const SizedBox(height: 16),
                      Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                      const SizedBox(height: 16),
                      _buildInfoRow('Email', _emailController, 'Số điện thoại', _phoneController),
                      const SizedBox(height: 16),
                      Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                      const SizedBox(height: 16),
                      _buildInfoRow('Khoa', _facultyController, 'Ngành/Bộ môn', _majorController),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label1, dynamic val1, String label2, dynamic val2, {bool isFirstFixed = false, bool isSecondFixed = false}) {
    return Row(
      children: [
        Expanded(child: _buildInfoField(label1, val1, isFixed: isFirstFixed)),
        const SizedBox(width: 24),
        Expanded(child: _buildInfoField(label2, val2, isFixed: isSecondFixed)),
      ],
    );
  }

  Widget _buildInfoField(String label, dynamic val, {bool isFixed = false}) {
    bool isString = val is String;
    TextEditingController? controller = isString ? null : val as TextEditingController;
    
    String displayText = isString ? val : controller!.text;
    bool isEmpty = displayText.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
        const SizedBox(height: 8),
        if (!_isEditingInfo || isFixed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Text(
              isEmpty ? 'Chưa cập nhật' : displayText,
              style: TextStyle(
                color: isEmpty ? Colors.grey.shade400 : Colors.black87,
                fontSize: 14,
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          )
        else
          TextFormField(
            controller: controller,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Nhập $label',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.lecturerColor),
              ),
            ),
          ),
      ],
    );
  }

  // --- 1: Tin tức & Thông báo ---
  Widget _buildNewsContent() {
    return StreamBuilder<List<AppNotification>>(
      stream: _notiService.stream,
      builder: (context, snapshot) {
        final notifications = _notiService.notifications;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.article, color: AppColors.lecturerColor, size: 28),
                SizedBox(width: 12),
                Text('TIN TỨC & THÔNG BÁO', style: TextStyle(color: AppColors.lecturerColor, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 24),
              ...notifications.map((n) => _buildNotificationItem(
                n.title, n.senderRole, n.date,
                isNew: _notiService.isNew(n.id),
                isFromLecturer: n.isFromLecturer,
                onTap: () {
                  _notiService.markAsSeen(n.id);
                  setState(() {});
                  _showNotificationDetail(n);
                },
              )),
              if (notifications.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Icon(Icons.notifications_off, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('Chưa có thông báo nào', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationDetail(AppNotification n) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1a2a1f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.campaign, color: n.isFromLecturer ? AppColors.lecturerColor : AppColors.studentColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(n.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(n.sender, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(n.date, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              Text(n.content ?? 'Không có nội dung chi tiết.', style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.7)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String title, String sender, String date, {bool isNew = false, bool isFromLecturer = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isNew ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isNew ? Border.all(color: AppColors.studentColor.withValues(alpha: 0.3)) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: isNew ? Colors.orangeAccent : AppColors.studentColor,
                shape: BoxShape.circle,
                boxShadow: isNew ? [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.6), blurRadius: 8)] : [],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: isNew ? FontWeight.bold : FontWeight.w600)),
                      ),
                      if (isNew)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.orangeAccent, Colors.deepOrange]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Mới', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      if (isFromLecturer)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.lecturerColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('GV', style: TextStyle(color: AppColors.lecturerColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(sender, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(date, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3), size: 20),
          ],
        ),
      ),
    );
  }

  // --- 3: Lịch dạy ---
  Widget _buildSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.calendar_today, color: AppColors.lecturerColor, size: 28),
                SizedBox(width: 12),
                Text('LỊCH DẠY CỦA BẠN', style: TextStyle(color: AppColors.lecturerColor, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 8),
              Text('Hiển thị lịch giảng dạy của bạn trong học kỳ này.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('schedules')
                .snapshots(),
            builder: (context, snapshot) {
              // Only show loading on initial load, not on stream updates
              if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Chưa có lịch dạy nào.', style: TextStyle(color: Colors.white70)),
                );
              }

              final events = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ScheduleEvent(
                  title: data['courseName'] ?? '',
                  subtitle: 'Phòng ${data['room']} - Lớp ${data['studentClass']}',
                  dayOfWeek: data['dayOfWeek'] ?? 2,
                  startHour: (data['startHour'] as num?)?.toDouble() ?? 7.0,
                  duration: (data['duration'] as num?)?.toDouble() ?? 2.0,
                  color: Color(data['colorValue'] ?? Colors.blue.value),
                );
              }).toList();

              return ScheduleGrid(events: events);
            },
          ),
        ),
      ],
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1a2a1f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_upload, size: 64, color: AppColors.lecturerColor),
              const SizedBox(height: 16),
              const Text('Tải lên Khung lịch học', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YÊU CẦU ĐỊNH DẠNG FILE CSV:', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                    SizedBox(height: 8),
                    Text('File phải có 7 cột theo thứ tự sau (bỏ qua dòng tiêu đề):\n1. Tên Môn Học (VD: Lập trình Web)\n2. Phòng Học (VD: A101)\n3. Thứ (Từ 2 đến 8)\n4. Giờ Bắt Đầu (VD: 7.0 hoặc 13.5)\n5. Số Giờ Học (VD: 2.0)\n6. Email Giảng Viên (VD: gv@dtu.edu.vn)\n7. Mã Lớp (VD: KTPM1)', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  await _handleFileUpload(ctx);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.description, color: Colors.white54, size: 24),
                      SizedBox(height: 8),
                      Text('Nhấn để chọn file', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleFileUpload(BuildContext ctx) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        final csvString = utf8.decode(bytes, allowMalformed: true);
        var rows = const CsvDecoder().convert(csvString);

        if (rows.isNotEmpty && rows.first.length < 7) {
          rows = const CsvDecoder(fieldDelimiter: ';').convert(csvString);
        }

        if (rows.isEmpty || rows.length <= 1) {
          throw Exception('File rỗng hoặc không có dữ liệu (có thể sai định dạng cột)');
        }

        final dataRows = rows.skip(1);
        final firestore = FirebaseFirestore.instance;
        
        showDialog(context: ctx, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

        // Xóa sạch lịch dạy cũ của giảng viên này trước khi tải lịch mới lên
        final oldSchedules = await firestore.collection('schedules').where('lecturerEmail', isEqualTo: widget.email).get();
        final deleteBatch = firestore.batch();
        for (var doc in oldSchedules.docs) {
          deleteBatch.delete(doc.reference);
        }
        await deleteBatch.commit();

        for (var row in dataRows) {
          if (row.length < 7) continue;
          
          final courseName = row[0].toString().trim();
          final room = row[1].toString().trim();
          final dayOfWeek = int.tryParse(row[2].toString().trim()) ?? 2;
          final startHour = double.tryParse(row[3].toString().trim()) ?? 7.0;
          final duration = double.tryParse(row[4].toString().trim()) ?? 2.0;
          final lecturerEmail = row[5].toString().trim();
          final studentClass = row[6].toString().trim();

          final id = '${courseName}_${room}_${dayOfWeek}_${startHour}_$studentClass'.replaceAll(' ', '_').replaceAll('/', '_');

          await firestore.collection('schedules').doc(id).set({
            'courseName': courseName,
            'room': room,
            'dayOfWeek': dayOfWeek,
            'startHour': startHour,
            'duration': duration,
            'lecturerEmail': lecturerEmail,
            'studentClass': studentClass,
            'colorValue': Colors.primaries[dayOfWeek % Colors.primaries.length].value,
          });
        }
        
        Navigator.pop(ctx); // close loading
        Navigator.pop(ctx); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật khung lịch học thành công!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      Navigator.pop(ctx); // close dialog/loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải file: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- 4: Chấm bài ---
  Widget _buildGrading() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.assignment, color: AppColors.lecturerColor, size: 28),
                SizedBox(width: 12),
                Text('BẢNG ĐIỂM CỤ THỂ', style: TextStyle(color: AppColors.lecturerColor, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              Row(children: [
                _filterDropdown('Năm học', _lecturerRegYear, ['2024-2025', '2025-2026', '2026-2027'], (v) {
                  setState(() { _lecturerRegYear = v!; _selectedGradingCourseDocId = null; });
                }),
                const SizedBox(width: 12),
                _filterDropdown('Học kỳ', _lecturerRegSemester, ['Học kỳ 1', 'Học kỳ 2', 'Học kỳ Hè'], (v) {
                  setState(() { _lecturerRegSemester = v!; _selectedGradingCourseDocId = null; });
                }),
              ]),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _regService.getRegistrationsByLecturer(widget.email, semester: _lecturerRegSemester, academicYear: _lecturerRegYear),
            builder: (context, snapshot) {
              if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.inbox, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('Bạn chưa có sinh viên/lớp nào trong $_lecturerRegSemester - $_lecturerRegYear', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                ]));
              }

              // Group by courseDocId
              final Map<String, List<QueryDocumentSnapshot>> courseMap = {};
              for (var doc in docs) {
                final d = doc.data() as Map<String, dynamic>;
                final cId = d['courseDocId'] ?? '';
                if (!courseMap.containsKey(cId)) courseMap[cId] = [];
                courseMap[cId]!.add(doc);
              }

              if (_selectedGradingCourseDocId == null || !courseMap.containsKey(_selectedGradingCourseDocId)) {
                return _buildCourseListForGrading(courseMap);
              } else {
                return _buildStudentListForGrading(courseMap[_selectedGradingCourseDocId]!);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCourseListForGrading(Map<String, List<QueryDocumentSnapshot>> courseMap) {
    if (courseMap.isEmpty) {
      return const Center(child: Text('Không có lớp nào', style: TextStyle(color: Colors.white70)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Table(
          border: TableBorder.symmetric(inside: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          columnWidths: const {
            0: FlexColumnWidth(1.5),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1.5),
            4: FlexColumnWidth(1.5),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: AppColors.lecturerColor.withValues(alpha: 0.2), borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))),
              children: [
                _tableHeader('Mã MH'),
                _tableHeader('Tên Môn (Lớp)'),
                _tableHeader('Sĩ số'),
                _tableHeader('Tiến độ'),
                _tableHeader('Thao tác'),
              ],
            ),
            ...courseMap.entries.map((entry) {
              final courseDocId = entry.key;
              final students = entry.value;
              final courseData = students.first.data() as Map<String, dynamic>;
              
              final courseName = courseData['courseName'] ?? 'Unknown';
              final classGroup = courseData['classGroup'] ?? '';
              final cId = courseData['courseId'] ?? '';
              
              int submittedCount = 0;
              int gradedCount = 0;
              for (var s in students) {
                final sd = s.data() as Map<String, dynamic>;
                final status = sd['gradeStatus'] ?? 'none';
                if (status == 'lecturer_submitted' || status == 'admin_published') {
                  submittedCount++;
                }
                if (sd['attendanceScore'] != null || sd['midtermScore'] != null || sd['finalScore'] != null || (sd['detailedGrades'] as List?)?.isNotEmpty == true) {
                  gradedCount++;
                }
              }
              
              final isAllSubmitted = submittedCount == students.length && students.isNotEmpty;
              
              return TableRow(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
                children: [
                  _tableCell(Text(cId, style: const TextStyle(color: Colors.white))),
                  _tableCell(Text('$courseName ($classGroup)', style: const TextStyle(color: Colors.white))),
                  _tableCell(Text('${students.length}', style: const TextStyle(color: Colors.white))),
                  _tableCell(Text('$gradedCount/${students.length}', style: const TextStyle(color: Colors.white70))),
                  _tableCell(
                    isAllSubmitted 
                      ? const Text('Đã gửi Admin', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13))
                      : InkWell(
                          onTap: () => setState(() {
                            _selectedGradingCourseDocId = courseDocId;
                            _detailedGradeFuture = _fetchDetailedGradeData(courseDocId);
                          }),
                          child: const Text('Nhập điểm', style: TextStyle(color: AppColors.lecturerColor, decoration: TextDecoration.underline, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentListForGrading(List<QueryDocumentSnapshot> students) {
    final courseData = students.first.data() as Map<String, dynamic>;
    final courseName = courseData['courseName'] ?? '';
    final classGroup = courseData['classGroup'] ?? '';
    final courseDocId = courseData['courseDocId'] ?? '';

    bool isLocked = false;
    for (var s in students) {
      final sd = s.data() as Map<String, dynamic>;
      final status = sd['gradeStatus'] ?? 'none';
      if (status == 'lecturer_submitted' || status == 'admin_published') {
        isLocked = true;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _selectedGradingCourseDocId = null),
              ),
              Text('Lớp: $courseName ($classGroup)', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (!isLocked) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                    await _regService.submitCourseGradesToAdmin(courseDocId);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi bảng điểm cho Admin phê duyệt!'), backgroundColor: Colors.green));
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Gửi Admin Duyệt'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green)),
                  child: const Text('BẢNG ĐIỂM ĐÃ KHOÁ (Đã gửi Admin)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                )
              ]
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _detailedGradeFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.lecturerColor));
              }

              final data = snapshot.data ?? {};
              final assignments = data['assignments'] as List<QueryDocumentSnapshot>? ?? [];
              final quizzes = data['quizzes'] as List<QueryDocumentSnapshot>? ?? [];
              final assignmentGrades = data['assignmentGrades'] as Map<String, Map<String, double>>? ?? {};
              final quizGrades = data['quizGrades'] as Map<String, Map<String, double>>? ?? {};

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade700, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(11), topRight: Radius.circular(11)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            const Text('Bảng điểm Cụ thể', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'TÊN LỚP: ${courseData['courseId'] ?? ''} - ${courseData['courseName']?.toString().toUpperCase() ?? ''}',
                            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Container(
                                  constraints: BoxConstraints(minWidth: constraints.maxWidth - 32),
                                  child: Table(
                                    border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                                    defaultColumnWidth: const IntrinsicColumnWidth(),
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(color: Colors.grey.shade200),
                                  children: [
                            _tableHeader('MSSV', color: Colors.black87),
                            _tableHeader('Họ Tên', color: Colors.black87),
                            _tableHeader('Chuyên cần\n(10%)', color: Colors.black87),
                            _tableHeader('Giữa kỳ\n(20%)', color: Colors.black87),
                            _tableHeader('Cuối kỳ\n(70%)', color: Colors.black87),
                            ...assignments.map((a) => _tableHeader('${a['title']}\n(Bài tập)', color: Colors.black87)),
                            ...quizzes.map((q) => _tableHeader('${q['title']}\n(Kiểm tra)', color: Colors.black87)),
                            _tableHeader('Tổng\n(Hệ 10)', color: Colors.black87),
                            _tableHeader('Điểm\nChữ', color: Colors.black87),
                            _tableHeader('Hệ 4', color: Colors.black87),
                          ],
                        ),
                        ...students.map((sDoc) {
                          final sData = sDoc.data() as Map<String, dynamic>;
                          final studentUserId = sData['userId'] ?? '';
                          final studentIdStr = sData['studentId'] ?? studentUserId;
                          final studentNameStr = sData['studentName'] ?? 'Unknown';
                          final savedDetailed = sData['detailedGrades'] as List<dynamic>? ?? [];

                          // Build map of saved detailed grades to prioritize them if they exist
                          final Map<String, double> savedMap = {};
                          for (var item in savedDetailed) {
                            if (item is Map<String, dynamic> && item['title'] != null && item['grade'] != null) {
                              savedMap[item['title']] = (item['grade'] as num).toDouble();
                            }
                          }

                          return TableRow(
                            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade300))),
                            children: [
                              _tableCell(Text(studentIdStr, style: const TextStyle(color: Colors.black87))),
                              _tableCell(Text(studentNameStr, style: const TextStyle(color: Colors.black87))),
                              _tableCell(_buildInputCell(sDoc, 'attendanceScore', isLocked)),
                              _tableCell(_buildInputCell(sDoc, 'midtermScore', isLocked)),
                              _tableCell(_buildInputCell(sDoc, 'finalScore', isLocked)),
                              ...assignments.map((a) {
                                final title = a['title'] as String;
                                final maxGrade = (a['maxGrade'] as num?)?.toDouble() ?? 10.0;
                                // If saved in registrations, use it. Else fetch from elearning_submissions
                                double initialGrade = savedMap[title] ?? (assignmentGrades[a.id]?[studentUserId] ?? 0.0);
                                
                                return _tableCell(
                                  isLocked 
                                    ? Text(initialGrade.toStringAsFixed(1), style: const TextStyle(color: Colors.orangeAccent))
                                    : GradeInputCell(
                                        initialValue: initialGrade > 0 ? initialGrade.toStringAsFixed(1) : '',
                                        onSaved: (val) {
                                          final parsed = double.tryParse(val);
                                          if (parsed != null) {
                                            _updateDetailedGrade(sDoc, savedDetailed, title, 'assignment', parsed, maxGrade);
                                          }
                                        },
                                      )
                                );
                              }),
                              ...quizzes.map((q) {
                                final title = q['title'] as String;
                                // Auto sync quiz grades
                                double grade = savedMap[title] ?? (quizGrades[q.id]?[studentUserId] ?? 0.0);

                                return _tableCell(
                                  Text(grade > 0 ? grade.toStringAsFixed(1) : '-', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                                );
                              }),
                              _tableCell(
                                Text(
                                  sData['attendanceScore'] != null || sData['midtermScore'] != null || sData['finalScore'] != null 
                                    ? (((double.tryParse(sData['attendanceScore']?.toString() ?? '0') ?? 0.0) * 0.1) + ((double.tryParse(sData['midtermScore']?.toString() ?? '0') ?? 0.0) * 0.2) + ((double.tryParse(sData['finalScore']?.toString() ?? '0') ?? 0.0) * 0.7)).toStringAsFixed(1)
                                    : '-',
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)
                                )
                              ),
                              _tableCell(
                                Text(
                                  sData['attendanceScore'] != null || sData['midtermScore'] != null || sData['finalScore'] != null 
                                    ? _getLetterGrade((((double.tryParse(sData['attendanceScore']?.toString() ?? '0') ?? 0.0) * 0.1) + ((double.tryParse(sData['midtermScore']?.toString() ?? '0') ?? 0.0) * 0.2) + ((double.tryParse(sData['finalScore']?.toString() ?? '0') ?? 0.0) * 0.7)))
                                    : '-',
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)
                                )
                              ),
                              _tableCell(
                                Text(
                                  sData['attendanceScore'] != null || sData['midtermScore'] != null || sData['finalScore'] != null 
                                    ? _getGpa4((((double.tryParse(sData['attendanceScore']?.toString() ?? '0') ?? 0.0) * 0.1) + ((double.tryParse(sData['midtermScore']?.toString() ?? '0') ?? 0.0) * 0.2) + ((double.tryParse(sData['finalScore']?.toString() ?? '0') ?? 0.0) * 0.7))).toStringAsFixed(1)
                                    : '-',
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)
                                )
                              ),
                            ],
                          );
                        }).toList(),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _fetchDetailedGradeData(String courseDocId) async {
    final assignments = await FirebaseFirestore.instance.collection('elearning_assignments').where('courseDocId', isEqualTo: courseDocId).get();
    final quizzes = await FirebaseFirestore.instance.collection('elearning_quizzes').where('courseDocId', isEqualTo: courseDocId).get();
    
    final Map<String, Map<String, double>> assignmentGrades = {}; 
    for (var a in assignments.docs) {
        assignmentGrades[a.id] = {};
        final subs = await FirebaseFirestore.instance.collection('elearning_submissions').where('assignmentId', isEqualTo: a.id).get();
        for (var sub in subs.docs) {
            final data = sub.data();
            assignmentGrades[a.id]![data['studentId']] = (data['grade'] as num?)?.toDouble() ?? 0.0;
        }
    }
    
    final Map<String, Map<String, double>> quizGrades = {};
    for (var q in quizzes.docs) {
        quizGrades[q.id] = {};
        final attempts = await FirebaseFirestore.instance.collection('elearning_quiz_attempts').where('quizId', isEqualTo: q.id).get();
        for (var att in attempts.docs) {
            final data = att.data();
            quizGrades[q.id]![data['studentId']] = (data['score'] as num?)?.toDouble() ?? 0.0;
        }
    }

    return {
        'assignments': assignments.docs,
        'quizzes': quizzes.docs,
        'assignmentGrades': assignmentGrades,
        'quizGrades': quizGrades,
    };
  }

  Widget _buildInputCell(QueryDocumentSnapshot sDoc, String field, bool isLocked) {
    final data = sDoc.data() as Map<String, dynamic>;
    final val = data[field]?.toString() ?? '';
    if (isLocked) return Text(val.isEmpty ? '-' : val, style: const TextStyle(color: Colors.black87));
    return GradeInputCell(
      initialValue: val,
      onSaved: (v) {
        final parsed = double.tryParse(v);
        if (parsed != null) {
          final updateData = <String, double?>{};
          if (field == 'attendanceScore') updateData['attendanceScore'] = parsed;
          if (field == 'midtermScore') updateData['midtermScore'] = parsed;
          if (field == 'finalScore') updateData['finalScore'] = parsed;
          _regService.updateStudentGrade(
            regDocId: sDoc.id,
            attendanceScore: updateData['attendanceScore'],
            midtermScore: updateData['midtermScore'],
            finalScore: updateData['finalScore'],
            status: 'lecturer_draft',
          );
        }
      },
    );
  }

  void _updateDetailedGrade(QueryDocumentSnapshot sDoc, List<dynamic> currentDetailed, String title, String type, double grade, double maxGrade) {
    final List<Map<String, dynamic>> updatedList = currentDetailed.map((e) => e as Map<String, dynamic>).toList();
    final idx = updatedList.indexWhere((e) => e['title'] == title);
    if (idx >= 0) {
      updatedList[idx]['grade'] = grade;
      updatedList[idx]['maxGrade'] = maxGrade;
    } else {
      updatedList.add({
        'title': title,
        'type': type,
        'grade': grade,
        'maxGrade': maxGrade,
        'submittedAt': Timestamp.now(),
      });
    }
    _regService.updateStudentGrade(
      regDocId: sDoc.id,
      detailedGrades: updatedList,
      status: 'lecturer_draft',
    );
  }

  // --- 5: Quản lý SV ---
  Widget _buildLecturerEvaluations() {
    if (_selectedEvaluation != null) {
      return _buildEvaluationDetail(_selectedEvaluation!);
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(Icons.rate_review, color: AppColors.lecturerColor, size: 28),
              SizedBox(width: 12),
              Text('QUẢN LÝ ĐÁNH GIÁ GIẢNG VIÊN', style: TextStyle(color: AppColors.lecturerColor, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('lecturer_evaluations')
                .where('lecturerEmail', isEqualTo: widget.email)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.lecturerColor));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speaker_notes_off, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text('Chưa có đánh giá nào từ sinh viên.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
                    ],
                  ),
                );
              }

              final docs = snapshot.data!.docs.toList();
              // Sort locally
              docs.sort((a, b) {
                final tsA = (a.data() as Map<String, dynamic>)['submittedAt'] as Timestamp?;
                final tsB = (b.data() as Map<String, dynamic>)['submittedAt'] as Timestamp?;
                if (tsA == null && tsB == null) return 0;
                if (tsA == null) return 1;
                if (tsB == null) return -1;
                return tsB.compareTo(tsA); // descending
              });

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final courseName = data['courseName'] ?? 'Không rõ môn học';
                  final academicYear = data['academicYear'] ?? '';
                  final semester = data['semester'] ?? '';
                  final comment = data['comment'] ?? '';
                  final ts = data['submittedAt'] as Timestamp?;
                  final dateStr = ts != null ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}' : '';
                  final answers = data['answers'] as Map<String, dynamic>? ?? {};
                  
                  // Calculate average score if answers exist (assuming 1-5 scale)
                  double avgScore = 0;
                  int validAnswers = 0;
                  answers.forEach((key, value) {
                    if (value is num) {
                      avgScore += value;
                      validAnswers++;
                    } else if (value is String && num.tryParse(value) != null) {
                      avgScore += num.parse(value);
                      validAnswers++;
                    }
                  });
                  if (validAnswers > 0) avgScore /= validAnswers;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedEvaluation = data;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.lecturerColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.lecturerColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(courseName, style: const TextStyle(color: AppColors.lecturerColor, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              const Spacer(),
                              Text(dateStr, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: Colors.white.withValues(alpha: 0.4)),
                              const SizedBox(width: 6),
                              Text('$semester - Năm học $academicYear', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                              const Spacer(),
                              if (validAnswers > 0)
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(avgScore.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                            ],
                          ),
                          if (comment.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(8),
                                border: Border(left: BorderSide(color: AppColors.lecturerColor.withValues(alpha: 0.5), width: 3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Ý kiến đóng góp:', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontStyle: FontStyle.italic)),
                                  const SizedBox(height: 4),
                                  Text(comment, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                                ],
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEvaluationDetail(Map<String, dynamic> evalData) {
    final formId = evalData['formId'] as String?;
    final courseName = evalData['courseName'] ?? 'Không rõ môn học';
    final academicYear = evalData['academicYear'] ?? '';
    final semester = evalData['semester'] ?? '';
    final comment = evalData['comment'] ?? '';
    final ts = evalData['submittedAt'] as Timestamp?;
    final dateStr = ts != null ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}' : '';
    final answers = evalData['answers'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedEvaluation = null),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, color: AppColors.lecturerColor, size: 24),
                    SizedBox(width: 8),
                    Text('Quay lại', style: TextStyle(color: AppColors.lecturerColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              const Expanded(
                child: Text('CHI TIẾT ĐÁNH GIÁ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lecturerColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lecturerColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(courseName, style: const TextStyle(color: AppColors.lecturerColor, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      const Spacer(),
                      Text('Ngày gửi: $dateStr', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.white.withValues(alpha: 0.4)),
                      const SizedBox(width: 6),
                      Text('$semester - Năm học $academicYear', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  
                  if (formId == null)
                    const Text('Không tìm thấy thông tin biểu mẫu.', style: TextStyle(color: Colors.white70))
                  else
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('evaluation_forms').doc(formId).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Text('Biểu mẫu đã bị xóa hoặc không tồn tại.', style: TextStyle(color: Colors.white70));
                        }
                        final formData = snapshot.data!.data() as Map<String, dynamic>;
                        final formTitle = formData['title'] ?? 'PHIẾU KHẢO SÁT';
                        final rawQuestions = formData['questions'] as List<dynamic>? ?? [];
                        final questions = rawQuestions.map((q) => Map<String, dynamic>.from(q as Map)).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formTitle, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            ...questions.asMap().entries.map((entry) {
                              final qIndex = entry.key;
                              final qData = entry.value;
                              final qText = qData['text'] ?? '';
                              final ansVal = answers['q_$qIndex'];
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Câu ${qIndex + 1}: $qText', style: const TextStyle(color: Colors.white, fontSize: 14)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.arrow_right, color: AppColors.lecturerColor, size: 16),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            ansVal != null ? 'Đánh giá: $ansVal' : 'Không có đánh giá',
                                            style: TextStyle(color: ansVal != null ? Colors.amber : Colors.white54, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  
                  if (comment.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Ý KIẾN ĐÓNG GÓP', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(left: BorderSide(color: AppColors.lecturerColor.withValues(alpha: 0.5), width: 4)),
                      ),
                      child: Text(comment, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 4: SV Đăng ký lớp ---
  Widget _buildStudentRegistrations() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.how_to_reg, color: AppColors.lecturerColor, size: 28),
                SizedBox(width: 12),
                Text('SINH VIÊN ĐĂNG KÝ LỚP', style: TextStyle(color: AppColors.lecturerColor, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              Row(children: [
                _filterDropdown('Năm học', _lecturerRegYear, ['2024-2025', '2025-2026', '2026-2027'], (v) => setState(() => _lecturerRegYear = v!)),
                const SizedBox(width: 12),
                _filterDropdown('Học kỳ', _lecturerRegSemester, ['Học kỳ 1', 'Học kỳ 2', 'Học kỳ Hè'], (v) => setState(() => _lecturerRegSemester = v!)),
              ]),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _regService.getRegistrationsByLecturer(widget.email, semester: _lecturerRegSemester, academicYear: _lecturerRegYear),
            builder: (context, snapshot) {
              if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.person_search, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('Chưa có sinh viên nào đăng ký lớp của bạn trong $_lecturerRegSemester - $_lecturerRegYear', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                ]));
              }
              
              // Group registrations by course
              Map<String, List<Map<String, dynamic>>> courseGroups = {};
              for (var doc in docs) {
                final d = doc.data() as Map<String, dynamic>;
                final courseKey = '${d['courseId']} - ${d['courseName']} (${d['classGroup']})';
                if (!courseGroups.containsKey(courseKey)) courseGroups[courseKey] = [];
                courseGroups[courseKey]!.add(d);
              }
              
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: courseGroups.entries.map((entry) {
                    final courseName = entry.key;
                    final students = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.lecturerColor.withValues(alpha: 0.2),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(courseName, style: const TextStyle(color: AppColors.lecturerColor, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Sĩ số: ${students.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.transparent),
                              dataRowColor: WidgetStateProperty.all(Colors.transparent),
                              columns: const [
                                DataColumn(label: Text('STT', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('MSSV', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Họ và Tên', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Ngày ĐK', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Trạng thái', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                              ],
                              rows: students.asMap().entries.map((e) {
                                final idx = e.key;
                                final d = e.value;
                                final date = (d['registeredAt'] as Timestamp?)?.toDate();
                                final dateStr = date != null ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}' : '';
                                return DataRow(cells: [
                                  DataCell(Text('${idx + 1}', style: const TextStyle(color: Colors.white70))),
                                  DataCell(Text(d['studentId'] ?? '', style: const TextStyle(color: Colors.white))),
                                  DataCell(Text(d['studentName'] ?? '', style: const TextStyle(color: Colors.white))),
                                  DataCell(Text(dateStr, style: const TextStyle(color: Colors.white70))),
                                  DataCell(Text(d['status'] == 'registered' ? 'Đã ĐK' : d['status'] ?? '', style: const TextStyle(color: Colors.green))),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, dropdownColor: const Color(0xFF1a2a1f),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
  String _getLetterGrade(double total10) {
    if (total10 >= 8.5) return 'A';
    if (total10 >= 7.0) return 'B';
    if (total10 >= 5.5) return 'C';
    if (total10 >= 4.0) return 'D';
    return 'F';
  }

  double _getGpa4(double total10) {
    if (total10 >= 8.5) return 4.0;
    if (total10 >= 7.0) return 3.0;
    if (total10 >= 5.5) return 2.0;
    if (total10 >= 4.0) return 1.0;
    return 0.0;
  }
}

class GradeInputCell extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onSaved;

  const GradeInputCell({Key? key, required this.initialValue, required this.onSaved}) : super(key: key);

  @override
  State<GradeInputCell> createState() => _GradeInputCellState();
}

class _GradeInputCellState extends State<GradeInputCell> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        if (_controller.text != widget.initialValue) {
          widget.onSaved(_controller.text);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant GradeInputCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && !_focusNode.hasFocus) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: const TextStyle(color: Colors.black87, fontSize: 13),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          isDense: true, 
          contentPadding: const EdgeInsets.all(8),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade700)),
        ),
        onSubmitted: (v) {
          if (v != widget.initialValue) {
            widget.onSaved(v);
          }
        },
      ),
    );
  }
}
