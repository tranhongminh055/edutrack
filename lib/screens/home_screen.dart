import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/nature_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/role_selector.dart';
import '../widgets/schedule_grid.dart';
import '../widgets/mail_client_view.dart';
import '../widgets/forum_board_view.dart';
import '../widgets/live_clock.dart';
import '../services/notification_service.dart';
import '../services/course_registration_service.dart';
import 'lecturer_dashboard.dart';
import 'admin_dashboard.dart';
import 'welcome_screen.dart';
import 'elearning/elearning_dashboard.dart';

class HomeScreen extends StatefulWidget {
  final UserRole role;
  final String email;
  final String studentId;
  final String fullName;

  const HomeScreen({
    super.key, 
    required this.role, 
    this.email = '',
    this.studentId = '',
    this.fullName = '',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedMenuIndex = 0;
  bool _isStudyMenuExpanded = false;
  int? _selectedStudySubIndex;
  int? _selectedFreshmanFeatureIndex;
  final NotificationService _notificationService = NotificationService();
  final CourseRegistrationService _regService = CourseRegistrationService();
  
  // Registration state
  int _regStep = 0;
  String _studentRegYear = '2025-2026';
  String _studentRegSemester = 'Học kỳ 1';

  // Lecturer state
  int _lecturerMenuIndex = 0;
  final TextEditingController _notiTitleController = TextEditingController();
  final TextEditingController _notiContentController = TextEditingController();
  bool _showSendSuccess = false;

  // Student info state
  bool _isEditingInfo = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _facultyController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();

  // Survey state
  String _selectedSurveySemester = 'Học kỳ 1';

  // Lecturer Evaluation survey state
  bool _showLecturerEvaluation = false;
  String _selectedEvalYear = '2025-2026';
  String _selectedEvalSemester = 'Học kỳ 1';
  Map<String, dynamic>? _selectedLecturerForEval;
  
  // Rating states for criteria (1 to 4)
  final Map<int, int> _evalRatings = {1: 5, 2: 5, 3: 5, 4: 5};
  final Map<String, String> _evalMultipleChoiceAnswers = {};
  final TextEditingController _evalCommentController = TextEditingController();
  bool _isSubmittingEval = false;

  // Tuition state
  bool _showTuitionSelector = true;
  String _selectedTuitionYear = '2025-2026';
  String _selectedTuitionSemester = 'Học kỳ 1';
  List<Map<String, dynamic>> _tuitionCourses = [];
  bool _isLoadingTuition = false;
  int _totalTuition = 0;
  int _baseFee = 0;
  int _studentTuitionTab = 0; // 0: Hóa đơn học phí, 1: Lịch sử nộp học phí
  bool _isSimulatingPayment = false;
  String _tuitionStatus = 'unpaid';
  String? _paymentMethod;
  DateTime? _paymentDate;
  String? _currentInvoiceDocId;

  // Detailed Grades states
  String _selectedGradesYear = '2025-2026';
  String _selectedGradesSemester = 'Học kỳ Hè';
  bool _isShowingGradesList = false;
  Map<String, dynamic>? _selectedCourseForGrades;
  String _gradeViewMode = 'personal'; // 'personal' or 'assignments'

  String? _avatarBase64;
  final ImagePicker _picker = ImagePicker();
  bool _isVerified = false;
  String? _systemNote;

  final List<String> _studentMenus = [
    'Thông tin Cá nhân',
    'Dành cho Tân Sinh viên',
    'Tin tức & Thông báo',
    'Lịch',
    'Học tập',
    'Cố vấn Học tập',
    'Đánh giá & Khảo sát',
    'Học phí',
    'Xem điểm Cụ thể',
  ];

  Stream<QuerySnapshot>? _tuitionHistoryStream;
  Stream<QuerySnapshot>? _digitalInvoicesStream;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
    _fullNameController.text = widget.fullName;
    _idController.text = widget.studentId;

    _tuitionHistoryStream = FirebaseFirestore.instance.collection('tuition_fees')
        .where('studentId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .orderBy('academicYear', descending: true)
        .orderBy('semester', descending: true)
        .snapshots();

    _digitalInvoicesStream = FirebaseFirestore.instance.collection('tuition_fees')
        .where('studentId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .where('status', isEqualTo: 'paid')
        .orderBy('academicYear', descending: true)
        .orderBy('semester', descending: true)
        .snapshots();

    _loadSavedProfile();
  }

  Future<void> _loadSavedProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _fullNameController.text = data['fullName'] ?? _fullNameController.text;
          _idController.text = data['studentId'] ?? _idController.text;
          _dobController.text = data['dob'] ?? _dobController.text;
          _genderController.text = data['gender'] ?? _genderController.text;
          _emailController.text = data['email'] ?? _emailController.text;
          _phoneController.text = data['phone'] ?? _phoneController.text;
          _facultyController.text = data['faculty'] ?? _facultyController.text;
          _majorController.text = data['major'] ?? _majorController.text;
          _classController.text = data['class'] ?? _classController.text;
          _batchController.text = data['batch'] ?? _batchController.text;
          _avatarBase64 = data['avatar'] ?? _avatarBase64;
          _isVerified = data['isVerified'] ?? false;
          _systemNote = data['systemNote'];
        });
      }
    } catch (e) {
      debugPrint('Error loading profile from Firestore: $e');
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final Map<String, dynamic> updates = <String, dynamic>{
        'fullName': _fullNameController.text,
        'studentId': _idController.text,
        'dob': _dobController.text,
        'gender': _genderController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'faculty': _facultyController.text,
        'major': _majorController.text,
        'class': _classController.text,
        'batch': _batchController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (_avatarBase64 != null) {
        updates['avatar'] = _avatarBase64!;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(updates, SetOptions(merge: true));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu thông tin cá nhân thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving profile to Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu thông tin: Tệp quá lớn hoặc có lỗi xảy ra'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70, // Nén ảnh để tránh vượt quá giới hạn 1MB của Firestore
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
  void dispose() {
    _notiTitleController.dispose();
    _notiContentController.dispose();
    _fullNameController.dispose();
    _idController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _facultyController.dispose();
    _majorController.dispose();
    _classController.dispose();
    _batchController.dispose();
    _evalCommentController.dispose();
    super.dispose();
  }



  Widget build(BuildContext context) {
    if (widget.role == UserRole.student) {
      return _buildStudentDashboard(context);
    } else if (widget.role == UserRole.lecturer) {
      return LecturerDashboard(email: widget.email);
    } else {
      return AdminDashboard(email: widget.email);
    }
  }

  // --- STUDENT DASHBOARD (MYDUYTAN CLONE) ---
  Widget _buildStudentDashboard(BuildContext context) {
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
                    Expanded(
                      child: _buildMainContentArea(),
                    ),
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
      color: Colors.black.withOpacity(0.2),
      child: Row(
        children: [
          const Icon(Icons.school, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          const Text('EduTrack', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(width: 32),
          _buildTopNavLink(Icons.home, 'Trang chủ', onTap: () => setState(() => _selectedMenuIndex = 0)),
          _buildTopNavLink(Icons.mail, 'Mail', onTap: () => setState(() => _selectedMenuIndex = 998)),
          _buildTopNavLink(Icons.check_circle, 'E-Learning', onTap: () {
            final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
            web.window.open('https://edutrack-elearning.web.app/?userId=$uid&role=student&email=${Uri.encodeComponent(widget.email)}', '_blank');
          }),
          _buildTopNavLink(Icons.forum, 'Forum', onTap: () => setState(() => _selectedMenuIndex = 997)),
          _buildTopNavLink(Icons.library_books, 'e-Lib', onTap: () => setState(() => _selectedMenuIndex = 8)),
          const Spacer(),
          const Text('Việt Nam  |  English', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTopNavLink(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: () {
        debugPrint('Clicked on $label');
        if (onTap != null) onTap();
      },
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
                Text('my', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 24, fontStyle: FontStyle.italic)),
                const Text('EDUTRACK', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ],
            ),
            
            // Center: Clock
            const LiveClock(),
            
            // Right: Quick Links
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickLink(Icons.mail, 'EduTrack Gmail', onTap: () => setState(() => _selectedMenuIndex = 998)),
                const SizedBox(height: 8),
                _buildQuickLink(Icons.language, 'HỌC TẬP TRỰC TUYẾN', onTap: () {
                  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                  web.window.open('https://edutrack-elearning.web.app/?userId=$uid&role=student&email=${Uri.encodeComponent(widget.email)}', '_blank');
                }),
                const SizedBox(height: 8),
                _buildQuickLink(Icons.group, 'DIỄN ĐÀN HỌC TẬP EDUTRACK', onTap: () => setState(() => _selectedMenuIndex = 997)),
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
          Icon(icon, color: AppColors.studentColor, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(left: 24, bottom: 24),
      child: GlassContainer(
        child: Column(
          children: [
            // User Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.studentColor.withOpacity(0.4),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.email.split('@').first, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
            ),
            // Menus
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                physics: const BouncingScrollPhysics(),
                itemCount: _studentMenus.length,
                itemBuilder: (context, index) {
                  final label = _studentMenus[index];
                  final isSelected = index == _selectedMenuIndex;
                  
                  if (index == 4) {
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMenuIndex = index;
                              _isStudyMenuExpanded = !_isStudyMenuExpanded;
                              _selectedStudySubIndex ??= 0;
                              _selectedFreshmanFeatureIndex = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
                              border: Border(
                                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                                left: isSelected ? const BorderSide(color: AppColors.studentColor, width: 4) : BorderSide.none,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(_isStudyMenuExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white54, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: isSelected ? AppColors.studentColor : Colors.white70,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_isStudyMenuExpanded)
                          ...['Đăng ký Môn học', 'Bảng điểm', 'Chương Trình học'].asMap().entries.map((e) {
                            final subIdx = e.key;
                            final subLabel = e.value;
                            final isSubSelected = _selectedStudySubIndex == subIdx;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedStudySubIndex = subIdx;
                                  _selectedMenuIndex = 4;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSubSelected ? Colors.white.withOpacity(0.05) : Colors.transparent,
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.arrow_right, color: isSubSelected ? AppColors.studentColor : Colors.white38, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      subLabel,
                                      style: TextStyle(
                                        color: isSubSelected ? AppColors.studentColor : Colors.white54,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    );
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMenuIndex = index;
                        _selectedFreshmanFeatureIndex = null;
                        if (index != 4) _isStudyMenuExpanded = false;
                        if (index == 6) {
                          _selectedLecturerForEval = null;
                        }
                      });
                      if (index == 7) {
                        _loadTuitionData();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                          left: isSelected ? const BorderSide(color: AppColors.studentColor, width: 4) : BorderSide.none,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: isSelected ? AppColors.studentColor : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
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
        ),
      ),
    );
  }

  Widget _buildMainContentArea() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      child: GlassContainer(
        child: Column(
          children: [
            // Content Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.studentColor, size: 20),
                  const SizedBox(width: 8),
                  const Text('Info webpart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  // Icons
                  const Icon(Icons.person, color: Colors.white54, size: 20),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                          (route) => false,
                        );
                      }
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.exit_to_app, color: Colors.white54, size: 20),
                        SizedBox(width: 4),
                        Text('Thoát', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content Body
            Expanded(
              child: _buildContentBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentBody() {
    switch (_selectedMenuIndex) {
      case 0: return _buildPersonalInfoContent();
      case 1: return _buildNewStudentContent();
      case 2: return _buildNewsContent();
      case 3: return _buildScheduleContent();
      case 4: return _buildStudyContent();
      case 5: return _buildAdvisorContent();
      case 6: return _buildSurveyContent();
      case 7: return _buildTuitionContent();
      case 8: return _buildDetailedGradesContent();
      case 997: return ForumBoardView(role: UserRole.student, email: widget.email);
      case 998: return MailClientView(role: UserRole.student, email: widget.email);
      case 999: return ELearningDashboard(role: UserRole.student, userId: FirebaseAuth.instance.currentUser?.uid ?? '', email: widget.email, currentSemester: _studentRegSemester, currentYear: _studentRegYear);
      default: return _buildRulesContent();
    }
  }

  // Helper for generic screen titles
  Widget _buildScreenHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.studentColor, size: 28),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.studentColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // 0: Thông tin Cá nhân
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
                _buildScreenHeader(Icons.person, 'THÔNG TIN CÁ NHÂN'),
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
                    backgroundColor: AppColors.studentColor,
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
                      color: AppColors.studentColor.withOpacity(0.2),
                      border: Border.all(color: AppColors.studentColor, width: 2),
                    ),
                    child: _avatarBase64 != null
                        ? Image.memory(base64Decode(_avatarBase64!), fit: BoxFit.cover)
                        : Icon(Icons.person, size: 60, color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.studentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Cập nhật ảnh', style: TextStyle(color: AppColors.studentColor, fontSize: 13, fontWeight: FontWeight.w600)),
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
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
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
                              Text(_systemNote!, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontStyle: FontStyle.italic)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    _buildInfoRow('Họ và tên', _fullNameController, 'Mã số SV', _idController),
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    const SizedBox(height: 16),
                    _buildInfoRow('Ngày sinh', _dobController, 'Giới tính', _genderController),
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    const SizedBox(height: 16),
                    _buildInfoRow('Email', _emailController, 'Số điện thoại', _phoneController),
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    const SizedBox(height: 16),
                    _buildInfoRow('Khoa', _facultyController, 'Ngành', _majorController),
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    const SizedBox(height: 16),
                    _buildInfoRow('Lớp', _classController, 'Khóa', _batchController),
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
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
        const SizedBox(height: 8),
        if (!_isEditingInfo || isFixed)
          Container(
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
                color: isEmpty ? Colors.black38 : Colors.black87,
                fontSize: 16,
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else if (label == 'Giới tính')
          _buildDropdownField(label, controller!, ['Nam', 'Nữ'])
        else if (label == 'Khoa')
          _buildDropdownField(label, controller!, ['Khoa CNTT', 'Khoa Kinh tế', 'Khoa Ngoại ngữ', 'Khoa Y Dược', 'Khoa Xây dựng', 'Khoa Du lịch'])
        else if (label == 'Ngành')
          _buildDropdownField(label, controller!, ['Kỹ thuật phần mềm', 'Khoa học máy tính', 'Hệ thống thông tin', 'An toàn thông tin', 'Quản trị kinh doanh', 'Ngôn ngữ Anh', 'Marketing'])
        else if (label == 'Lớp')
          _buildDropdownField(label, controller!, ['KTPM1', 'KTPM2', 'KHMT1', 'NNA1', 'QTDN1'])
        else if (label == 'Khóa')
          _buildDropdownField(label, controller!, ['K25', 'K26', 'K27', 'K28', 'K29'])
        else
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
              readOnly: label == 'Ngày sinh',
              onTap: label == 'Ngày sinh' ? () async {
                final parts = controller!.text.split('/');
                DateTime initialDate = DateTime(2005);
                if (parts.length == 3) {
                  final d = int.tryParse(parts[0]);
                  final m = int.tryParse(parts[1]);
                  final y = int.tryParse(parts[2]);
                  if (d != null && m != null && y != null) {
                    initialDate = DateTime(y, m, d);
                  }
                }
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.studentColor,
                          onPrimary: Colors.white,
                          surface: Color(0xFF2A2D2B),
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  controller!.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                }
              } : null,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              keyboardType: _getKeyboardType(label),
              inputFormatters: _getInputFormatters(label),
              validator: (value) => _validateField(label, value),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                hintText: label == 'Ngày sinh' ? 'Chọn ngày sinh' : 'Nhập $label',
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                suffixIcon: label == 'Ngày sinh' ? const Icon(Icons.calendar_today, color: Colors.black45, size: 20) : null,
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
                  borderSide: const BorderSide(color: AppColors.studentColor, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
                errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownField(String label, TextEditingController controller, List<String> items) {
    return Container(
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
      child: DropdownButtonFormField<String>(
        value: items.contains(controller.text) ? controller.text : null,
        hint: Text('Chọn $label', style: const TextStyle(color: Colors.black38, fontSize: 13)),
        dropdownColor: Colors.white,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.black45),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
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
            borderSide: const BorderSide(color: AppColors.studentColor, width: 1.5),
          ),
        ),
        items: items.map((String val) {
          return DropdownMenuItem<String>(
            value: val,
            child: Text(val),
          );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          controller.text = val;
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng chọn $label';
        }
        return null;
      },
      ),
    );
  }

  TextInputType _getKeyboardType(String label) {
    if (label == 'Email') return TextInputType.emailAddress;
    if (label == 'Số điện thoại') return TextInputType.phone;
    if (label == 'Ngày sinh') return TextInputType.datetime;
    return TextInputType.text;
  }

  List<TextInputFormatter>? _getInputFormatters(String label) {
    if (label == 'Số điện thoại') {
      return [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)];
    }
    if (label == 'Ngày sinh') {
      return [LengthLimitingTextInputFormatter(10), FilteringTextInputFormatter.allow(RegExp(r'[0-9/]'))];
    }
    return null;
  }

  String? _validateField(String label, String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $label';
    }
    if (label == 'Email') {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
        return 'Email không hợp lệ';
      }
    }
    if (label == 'Số điện thoại') {
      if (value.length < 10) return 'Phải có 10 chữ số';
      if (!value.startsWith('0')) return 'Phải bắt đầu bằng 0';
    }
    if (label == 'Ngày sinh') {
      if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) {
        return 'Định dạng dd/MM/yyyy';
      }
    }
    return null;
  }

  // 1: Tân Sinh viên
  Widget _buildNewStudentContent() {
    if (_selectedFreshmanFeatureIndex != null) {
      return _buildFreshmanFeatureDetail(_selectedFreshmanFeatureIndex!);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScreenHeader(Icons.school, 'DÀNH CHO TÂN SINH VIÊN'),
          const SizedBox(height: 24),
          _buildFreshmanFeatureCard(
            title: 'Cơ sở Vật chất & Trang thiết bị',
            subtitle: 'Giới thiệu về cơ sở vật chất, phòng lab, thực hành.',
            icon: Icons.computer,
            color: Colors.blueAccent,
            actionText: 'Xem chi tiết',
            onTap: () => setState(() => _selectedFreshmanFeatureIndex = 0),
          ),
          _buildFreshmanFeatureCard(
            title: 'Thư viện & Giáo trình',
            subtitle: 'Cách sử dụng thư viện điện tử, mượn giáo trình.',
            icon: Icons.library_books,
            color: Colors.orangeAccent,
            actionText: 'Xem chi tiết',
            onTap: () => setState(() => _selectedFreshmanFeatureIndex = 1),
          ),
          _buildFreshmanFeatureCard(
            title: 'Phương pháp Học tập, NCKH',
            subtitle: 'Hướng dẫn phương pháp học tập hiệu quả ở bậc Đại học.',
            icon: Icons.psychology,
            color: Colors.greenAccent,
            actionText: 'Xem chi tiết',
            onTap: () => setState(() => _selectedFreshmanFeatureIndex = 2),
          ),
          _buildFreshmanFeatureCard(
            title: 'Hỗ trợ Sinh viên',
            subtitle: 'Các chính sách học bổng, tư vấn tâm lý, việc làm.',
            icon: Icons.support_agent,
            color: Colors.pinkAccent,
            actionText: 'Xem chi tiết',
            onTap: () => setState(() => _selectedFreshmanFeatureIndex = 3),
          ),
          _buildFreshmanFeatureCard(
            title: 'Hoạt động Sinh viên',
            subtitle: 'Các câu lạc bộ, đoàn hội và hoạt động ngoại khóa.',
            icon: Icons.groups,
            color: Colors.purpleAccent,
            actionText: 'Xem chi tiết',
            onTap: () => setState(() => _selectedFreshmanFeatureIndex = 4),
          ),
          _buildFreshmanFeatureCard(
            title: 'Video về DTU',
            subtitle: 'Phóng sự, phim tài liệu giới thiệu về trường.',
            icon: Icons.play_circle_filled,
            color: Colors.redAccent,
            actionText: 'Xem chi tiết',
            onTap: () => setState(() => _selectedFreshmanFeatureIndex = 5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.download, color: Colors.white70),
                SizedBox(width: 12),
                Text('Tải tài liệu hướng dẫn Tân sinh viên (PDF)', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreshmanFeatureDetail(int index) {
    final List<Map<String, String>> articles = [
      {
        'title': 'Cơ sở vật chất đào tạo thực hành',
        'content': 'Ngay sau khi trở thành sinh viên, cùng với việc được tiếp thu kiến thức trên giảng đường, các bạn sẽ được thực hành trong các Phòng Thực hành - Thí nghiệm được trang bị hiện đại bậc nhất.\n\nĐặc biệt sinh viên khối ngành Công nghệ Thông tin được trang bị hệ thống máy tính cấu hình cao, kết nối internet miễn phí, hỗ trợ tối đa cho việc học tập và nghiên cứu.',
      },
      {
        'title': 'Thư viện & Giáo trình',
        'content': 'Hệ thống thư viện bao gồm hàng chục nghìn đầu sách, tài liệu tham khảo và giáo trình chuyên ngành. Sinh viên có thể truy cập hệ thống Thư viện điện tử (e-Lib) để tra cứu và mượn sách trực tuyến một cách dễ dàng và nhanh chóng.',
      },
      {
        'title': 'Phương pháp Học tập, Nghiên cứu Khoa học',
        'content': 'Học tập ở bậc đại học đòi hỏi sự chủ động cao. Sinh viên được khuyến khích tham gia các nhóm nghiên cứu khoa học, tham dự hội thảo chuyên đề và các cuộc thi học thuật để nâng cao kỹ năng thực tế và tư duy phản biện.',
      },
      {
        'title': 'Hỗ trợ Sinh viên',
        'content': 'Phòng Công tác Học sinh Sinh viên luôn sẵn sàng hỗ trợ các vấn đề về học bổng, chính sách miễn giảm học phí, tư vấn tâm lý và giới thiệu việc làm bán thời gian cho sinh viên có nhu cầu.',
      },
      {
        'title': 'Hoạt động Sinh viên',
        'content': 'Hàng chục Câu lạc bộ từ học thuật đến năng khiếu, thể thao đang chờ đón bạn. Tham gia các hoạt động ngoại khóa giúp sinh viên giải tỏa căng thẳng sau những giờ học và rèn luyện kỹ năng mềm thiết yếu.',
      },
      {
        'title': 'Video giới thiệu về trường',
        'content': 'Cùng xem lại những khoảnh khắc đáng nhớ và tìm hiểu thêm về lịch sử phát triển, các sự kiện lớn và môi trường học tập năng động qua các đoạn video phóng sự do chính sinh viên thực hiện.',
      },
    ];

    final article = articles[index];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _selectedFreshmanFeatureIndex = null),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  article['title']!.toUpperCase(),
                  style: const TextStyle(color: AppColors.studentColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article['title']!,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  article['content']!,
                  style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_outlined, color: Colors.white54, size: 64),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreshmanFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 0,
              ),
              child: Text(
                actionText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2: Tin tức & Thông báo
  Widget _buildNewsContent() {
    return StreamBuilder<List<AppNotification>>(
      stream: _notificationService.stream,
      builder: (context, snapshot) {
        final notifications = _notificationService.notifications;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScreenHeader(Icons.article, 'TIN TỨC & THÔNG BÁO'),
              const SizedBox(height: 24),
              ...notifications.map((n) => _buildNotificationItem(
                n.title, n.senderRole, n.date,
                isNew: _notificationService.isNew(n.id),
                isFromLecturer: n.isFromLecturer,
                onTap: () {
                  _notificationService.markAsSeen(n.id);
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
                        Icon(Icons.notifications_off, size: 48, color: Colors.white.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text('Chưa có thông báo nào', style: TextStyle(color: Colors.white.withOpacity(0.5))),
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
                  Icon(Icons.person_outline, size: 14, color: Colors.white.withOpacity(0.5)),
                  const SizedBox(width: 4),
                  Text(n.sender, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: Colors.white.withOpacity(0.5)),
                  const SizedBox(width: 4),
                  Text(n.date, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.white.withOpacity(0.1)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
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
                boxShadow: isNew ? [BoxShadow(color: Colors.orangeAccent.withOpacity(0.6), blurRadius: 8)] : [],
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
                        child: Text(title, style: TextStyle(color: Colors.black87, fontSize: 15, fontWeight: isNew ? FontWeight.bold : FontWeight.w600)),
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
                            color: AppColors.lecturerColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('GV', style: TextStyle(color: AppColors.lecturerColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: Colors.black38),
                      const SizedBox(width: 4),
                      Text(sender, style: const TextStyle(color: Colors.black38, fontSize: 12)),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 14, color: Colors.black38),
                      const SizedBox(width: 4),
                      Text(date, style: const TextStyle(color: Colors.black38, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }

  // 3: Lịch
  Widget _buildScheduleContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 32, top: 32, right: 32, bottom: 16),
          child: _buildScreenHeader(Icons.calendar_month, 'LỊCH HỌC TẬP & THI CỬ'),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('schedules').snapshots(),
            builder: (context, snapshot) {
              // Only show loading on initial load, not on stream updates
              if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Chưa có lịch học nào trên hệ thống.', style: TextStyle(color: Colors.white70)),
                );
              }

              final events = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ScheduleEvent(
                  title: data['courseName'] ?? '',
                  subtitle: 'Phòng ${data['room']} - GV: ${data['lecturerEmail']}',
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

  // 4: Học tập
  Widget _buildStudyContent() {
    switch (_selectedStudySubIndex) {
      case 0: return _buildCourseRegistration();
      case 1: return _buildGradesTable();
      case 2: return _buildCurriculumTree();
      default: return _buildCourseRegistration();
    }
  }

  // 4.1 Đăng ký Môn học
  Widget _buildCourseRegistration() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScreenHeader(Icons.app_registration, 'ĐĂNG KÝ MÔN HỌC'),
          const SizedBox(height: 32),
          
          // Progress Bar
          Row(
            children: [
              _buildRegStepIndicator(0, 'Chọn Học kỳ'),
              _buildRegStepLine(0),
              _buildRegStepIndicator(1, 'Chọn Môn học'),
              _buildRegStepLine(1),
              _buildRegStepIndicator(2, 'Kết quả ĐK'),
            ],
          ),
          const SizedBox(height: 48),

          // Content based on step
          if (_regStep == 0) _buildRegStep0(),
          if (_regStep == 1) _buildRegStep1(),
          if (_regStep == 2) _buildRegStep2(),
        ],
      ),
    );
  }

  Widget _buildRegStepIndicator(int stepIndex, String label) {
    final isActive = _regStep >= stepIndex;
    final isCurrent = _regStep == stepIndex;
    return Column(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppColors.studentColor : Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
            boxShadow: isActive ? [BoxShadow(color: AppColors.studentColor.withOpacity(0.4), blurRadius: 8)] : [],
          ),
          child: Center(child: Text('${stepIndex + 1}', style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontSize: 12, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildRegStepLine(int stepIndex) {
    final isActive = _regStep > stepIndex;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        color: isActive ? AppColors.studentColor : Colors.white.withOpacity(0.1),
      ),
    );
  }

  Widget _buildRegStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('BẠN PHẢI CHỌN HỌC KỲ VÀ NĂM HỌC ĐỂ ĐĂNG KÝ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepDropdown('1', 'Chọn Năm học', ['2024-2025', '2025-2026', '2026-2027'], _studentRegYear, (v) => setState(() => _studentRegYear = v!)),
              const SizedBox(width: 48),
              _buildStepDropdown('2', 'Chọn Học kỳ', ['Học kỳ 1', 'Học kỳ 2', 'Học kỳ Hè'], _studentRegSemester, (v) => setState(() => _studentRegSemester = v!)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            setState(() => _regStep = 1);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.studentColor,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text('TIẾP TỤC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildRegStep1() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Các môn mở đăng ký - $_studentRegSemester ($_studentRegYear)', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => setState(() => _regStep = 0),
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              label: const Text('Đổi Học kỳ', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        StreamBuilder<QuerySnapshot>(
          stream: _regService.getMyRegistrationsStream(userId, _studentRegSemester, _studentRegYear),
          builder: (context, myRegSnap) {
            if (!myRegSnap.hasData && myRegSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final myRegs = myRegSnap.data?.docs.map((e) => e.data() as Map<String, dynamic>).toList() ?? [];
            final totalCredits = myRegs.fold<int>(0, (sum, reg) => sum + ((reg['credits'] as num?)?.toInt() ?? 0));
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.studentColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text('Đã đăng ký: $totalCredits / 25 tín chỉ', style: const TextStyle(color: AppColors.studentColor, fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => _regStep = 2),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1), foregroundColor: Colors.white),
                      child: const Text('Xem Kết quả Đăng ký'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                StreamBuilder<QuerySnapshot>(
                  stream: _regService.getAllCoursesStream(),
                  builder: (context, availableSnap) {
                    if (!availableSnap.hasData && availableSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    // Client-side filtering
                    final allDocs = availableSnap.data?.docs ?? [];
                    final availableCourses = allDocs.where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final matchSemester = d['semester'] == _studentRegSemester;
                      final matchYear = d['academicYear'] == _studentRegYear;
                      final isOpen = d['status'] == 'open';
                      
                      final studentMajor = _majorController.text.trim().toLowerCase();
                      final courseMajor = (d['major'] ?? '').toString().trim().toLowerCase();
                      
                      // Bỏ qua filter ngành nếu sinh viên chưa có ngành hoặc ngành = "chưa cập nhật"
                      final skipMajorCheck = studentMajor.isEmpty || studentMajor == 'chưa cập nhật';
                      final matchMajor = skipMajorCheck || courseMajor == studentMajor;
                      
                      return matchSemester && matchYear && isOpen && matchMajor;
                    }).toList();
                    
                    if (availableCourses.isEmpty) {
                      return Center(child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(children: [
                          Icon(Icons.inbox, size: 48, color: Colors.white.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text('Không có môn học nào mở trong học kỳ này.', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                        ]),
                      ));
                    }
                    
                    Timestamp? latestDl;
                    for (var doc in availableCourses) {
                      final d = doc.data() as Map<String, dynamic>;
                      final dl = d['registrationDeadline'] as Timestamp?;
                      if (dl != null) {
                        if (latestDl == null || dl.toDate().isAfter(latestDl.toDate())) {
                          latestDl = dl;
                        }
                      }
                    }
                    
                    final isGloballyExpired = latestDl != null && latestDl.toDate().isBefore(DateTime.now());
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (latestDl != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Icon(Icons.timer, color: isGloballyExpired ? Colors.redAccent : Colors.orange, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Hạn đăng ký muộn nhất: ${latestDl.toDate().day}/${latestDl.toDate().month}/${latestDl.toDate().year} ${latestDl.toDate().hour.toString().padLeft(2, '0')}:${latestDl.toDate().minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(color: isGloballyExpired ? Colors.redAccent : Colors.orange, fontWeight: FontWeight.bold),
                                ),
                                if (isGloballyExpired)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text('(Đã hết hạn)', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                  )
                              ],
                            ),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.05)),
                          dataRowColor: WidgetStateProperty.all(Colors.transparent),
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text('Mã Môn', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Tên Môn', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('TC', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Nhóm', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Giảng viên', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Lịch học', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Sĩ số', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Đăng ký', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                          ],
                          rows: availableCourses.map((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            final isRegistered = _regService.isAlreadyRegistered(doc.id, myRegs);
                            
                            final courseDl = d['registrationDeadline'] as Timestamp?;
                            final isExpired = courseDl != null && courseDl.toDate().isBefore(DateTime.now());
                            
                            final dayOfWeek = d['dayOfWeek'] as int? ?? 2;
                            final startHour = (d['startHour'] as num?)?.toDouble() ?? 7.0;
                            final duration = (d['duration'] as num?)?.toDouble() ?? 2.0;
                            final isConflict = !isRegistered && _regService.checkTimeConflict(
                              dayOfWeek: dayOfWeek,
                              startHour: startHour,
                              duration: duration,
                              existingRegistrations: myRegs,
                            );
                            
                            final current = (d['currentSlots'] as num?)?.toInt() ?? 0;
                            final max = (d['maxSlots'] as num?)?.toInt() ?? 0;
                            final isFull = current >= max;
                            
                            return DataRow(
                              color: WidgetStateProperty.all(isRegistered ? AppColors.studentColor.withOpacity(0.1) : (isConflict ? Colors.red.withOpacity(0.05) : Colors.transparent)),
                              cells: [
                                DataCell(Text(d['courseId'] ?? '', style: TextStyle(color: Colors.blue.shade300, fontWeight: FontWeight.w600))),
                                DataCell(Text(d['courseName'] ?? '', style: const TextStyle(color: Colors.white))),
                                DataCell(Text('${d['credits'] ?? ''}', style: const TextStyle(color: Colors.white))),
                                DataCell(Text(d['classGroup'] ?? '', style: const TextStyle(color: Colors.white70))),
                                DataCell(Text(d['lecturerName'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13))),
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Thứ $dayOfWeek | ${_fmtHour(startHour)}-${_fmtHour(startHour + duration)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                      Text('Phòng: ${d['room']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                    ],
                                  )
                                ),
                                DataCell(Text('$current/$max', style: TextStyle(color: isFull ? Colors.red : Colors.white))),
                                DataCell(
                                  isRegistered
                                    ? const Row(children: [Icon(Icons.check_circle, color: AppColors.studentColor, size: 16), SizedBox(width: 4), Text('Đã ĐK', style: TextStyle(color: AppColors.studentColor, fontWeight: FontWeight.bold))])
                                    : (isConflict 
                                      ? const Text('Trùng lịch', style: TextStyle(color: Colors.redAccent))
                                      : ElevatedButton(
                                          onPressed: (isFull || isExpired) ? null : () => _handleRegisterCourse(doc.id, d),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.studentColor, 
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            minimumSize: const Size(0, 32),
                                          ),
                                          child: Text(isExpired ? 'Hết hạn' : (isFull ? 'Hết chỗ' : 'Đăng ký')),
                                        )
                                      ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ), // End Container
                  ], // End Column children
                ); // End Column
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRegStep2() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Kết quả Đăng ký - $_studentRegSemester ($_studentRegYear)', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => setState(() => _regStep = 1),
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              label: const Text('Quay lại Đăng ký', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        StreamBuilder<QuerySnapshot>(
          stream: _regService.getMyRegistrationsStream(userId, _studentRegSemester, _studentRegYear),
          builder: (context, snapshot) {
            if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final myRegs = snapshot.data?.docs ?? [];
            if (myRegs.isEmpty) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(children: [
                  Icon(Icons.sentiment_dissatisfied, size: 48, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('Bạn chưa đăng ký môn nào trong học kỳ này.', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _regStep = 1),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.studentColor, foregroundColor: Colors.white),
                    child: const Text('Đi đến trang Đăng ký'),
                  ),
                ]),
              ));
            }
            
            final totalCredits = myRegs.fold<int>(0, (sum, doc) => sum + (((doc.data() as Map)['credits'] as num?)?.toInt() ?? 0));
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.studentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.studentColor.withOpacity(0.3))),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.studentColor, size: 32),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Đăng ký thành công ${myRegs.length} môn học', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Tổng số tín chỉ: $totalCredits / 25', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.05)),
                      dataRowColor: WidgetStateProperty.all(Colors.transparent),
                      columns: const [
                        DataColumn(label: Text('Mã Môn', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Tên Môn', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('TC', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Nhóm', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Giảng viên', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Lịch học', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Thao tác', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                      ],
                      rows: myRegs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final startHour = (d['startHour'] as num?)?.toDouble() ?? 7.0;
                        final duration = (d['duration'] as num?)?.toDouble() ?? 2.0;
                        return DataRow(
                          cells: [
                            DataCell(Text(d['courseId'] ?? '', style: TextStyle(color: Colors.blue.shade300, fontWeight: FontWeight.w600))),
                            DataCell(Text(d['courseName'] ?? '', style: const TextStyle(color: Colors.white))),
                            DataCell(Text('${d['credits'] ?? ''}', style: const TextStyle(color: Colors.white))),
                            DataCell(Text(d['classGroup'] ?? '', style: const TextStyle(color: Colors.white70))),
                            DataCell(Text(d['lecturerName'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13))),
                            DataCell(
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Thứ ${d['dayOfWeek']} | ${_fmtHour(startHour)}-${_fmtHour(startHour + duration)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  Text('Phòng: ${d['room']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              )
                            ),
                            DataCell(
                              TextButton.icon(
                                onPressed: () => _confirmCancelRegistration(doc.id, d['courseDocId'], d['courseName']),
                                icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 16),
                                label: const Text('Hủy ĐK', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _handleRegisterCourse(String docId, Map<String, dynamic> courseData) async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final studentId = _idController.text.isNotEmpty ? _idController.text : widget.studentId;
      final studentName = _fullNameController.text.isNotEmpty ? _fullNameController.text : widget.fullName;
      final studentEmail = _emailController.text.isNotEmpty ? _emailController.text : widget.email;

      courseData['docId'] = docId;

      await _regService.registerCourse(
        userId: userId,
        studentId: studentId,
        studentName: studentName,
        studentEmail: studentEmail,
        courseData: courseData,
      );

      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đăng ký môn ${courseData['courseName']} thành công!'), backgroundColor: Colors.green));
    } catch (e) {
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
    }
  }

  void _confirmCancelRegistration(String regId, String courseDocId, String courseName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a2a1f),
        title: const Text('Xác nhận Hủy', style: TextStyle(color: Colors.white)),
        content: Text('Bạn có chắc muốn hủy đăng ký môn "$courseName"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Không', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                await _regService.cancelRegistration(regId, courseDocId);
                Navigator.pop(context); // close loading
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy đăng ký thành công!'), backgroundColor: Colors.green));
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy đăng ký', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _fmtHour(double h) {
    final hr = h.floor();
    final min = ((h - hr) * 60).round();
    return '${hr.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  Widget _buildStepDropdown(String step, String hint, List<String> items, String value, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.shade700,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Center(child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic))),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
          width: 200,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint, style: const TextStyle(color: Colors.black87)),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.black87)))).toList(),
              onChanged: onChanged,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
            ),
          ),
        ),
      ],
    );
  }

  // 4.2 Bảng điểm
  Widget _buildGradesTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('registrations')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.studentColor));
        }
        
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, size: 64, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 16),
                const Text('Chưa có dữ liệu bảng điểm.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Đăng ký môn học để bắt đầu học và cập nhật điểm số.', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ],
            ),
          );
        }

        // Group by Semester + Year
        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (var doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final semester = d['semester'] ?? '';
          final year = d['academicYear'] ?? '';
          final key = '$semester - Năm học $year';
          if (!grouped.containsKey(key)) {
            grouped[key] = [];
          }
          grouped[key]!.add(d);
        }

        // Sort semesters chronologically
        final sortedKeys = grouped.keys.toList()..sort((a, b) {
          final regYear = RegExp(r'Năm học (\d{4})-\d{4}');
          final regSem = RegExp(r'Học kỳ (\d|Hè)');
          
          final matchA_Year = regYear.firstMatch(a);
          final matchB_Year = regYear.firstMatch(b);
          
          if (matchA_Year != null && matchB_Year != null) {
            final yearA = int.parse(matchA_Year.group(1)!);
            final yearB = int.parse(matchB_Year.group(1)!);
            if (yearA != yearB) {
              return yearA.compareTo(yearB);
            }
          }
          
          final matchA_Sem = regSem.firstMatch(a);
          final matchB_Sem = regSem.firstMatch(b);
          
          if (matchA_Sem != null && matchB_Sem != null) {
            final semAStr = matchA_Sem.group(1)!;
            final semBStr = matchB_Sem.group(1)!;
            
            final semA = semAStr == 'Hè' ? 3 : int.parse(semAStr);
            final semB = semBStr == 'Hè' ? 3 : int.parse(semBStr);
            return semA.compareTo(semB);
          }
          
          return a.compareTo(b);
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScreenHeader(Icons.grade, 'BẢNG ĐIỂM SINH VIÊN'),
              const SizedBox(height: 16),
              Text(
                'Sinh viên: ${widget.fullName.isNotEmpty ? widget.fullName : _fullNameController.text} (Mã Sinh viên: ${widget.studentId.isNotEmpty ? widget.studentId : _idController.text})',
                style: const TextStyle(color: AppColors.studentColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ...sortedKeys.map((key) {
                final courses = grouped[key]!;
                return _buildSemesterGradesFromRegistrations(key, courses);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSemesterGradesFromRegistrations(String semesterName, List<Map<String, dynamic>> courses) {
    int semCredits = 0;
    double total10Sum = 0;
    double gpa4Sum = 0;
    int gradedCredits = 0;

    for (var course in courses) {
      final credit = (course['credits'] as num?)?.toInt() ?? 0;
      semCredits += credit;
      
      if (course['gradeStatus'] == 'admin_published') {
        final grade10 = (course['total10'] as num?)?.toDouble();
        final grade4 = (course['gpa4'] as num?)?.toDouble();
        if (grade10 != null && grade4 != null) {
          total10Sum += grade10 * credit;
          gpa4Sum += grade4 * credit;
          gradedCredits += credit;
        }
      }
    }

    double avg10 = gradedCredits > 0 ? total10Sum / gradedCredits : 0.0;
    double avg4 = gradedCredits > 0 ? gpa4Sum / gradedCredits : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.studentColor.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(semesterName, style: const TextStyle(color: AppColors.studentColor, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.05)),
              dataRowColor: WidgetStateProperty.all(Colors.transparent),
              dividerThickness: 0.5,
              columns: const [
                DataColumn(label: Text('Mã Môn', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Mã Lớp', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Hình Thức', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Tên Môn', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Số ĐVHT', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Điểm gốc', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Điểm chữ', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Điểm Quy đổi', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
              ],
              rows: courses.map((course) {
                final isPublished = course['gradeStatus'] == 'admin_published';
                return DataRow(cells: [
                  DataCell(Text(course['courseId'] ?? '', style: const TextStyle(color: Colors.white))),
                  DataCell(Text(course['classGroup'] ?? '', style: const TextStyle(color: Colors.white))),
                  DataCell(Text(course['type'] ?? 'LEC', style: const TextStyle(color: Colors.white))),
                  DataCell(Text(course['courseName'] ?? '', style: const TextStyle(color: Colors.white))),
                  DataCell(Text('${course['credits'] ?? ''}', style: const TextStyle(color: Colors.white))),
                  DataCell(Text(isPublished ? '${course['total10'] ?? ''}' : '-', style: const TextStyle(color: Colors.white))),
                  DataCell(Text(isPublished ? (course['letterGrade'] ?? '') : '-', style: const TextStyle(color: Colors.white))),
                  DataCell(Text(isPublished ? '${course['gpa4'] ?? ''}' : '-', style: const TextStyle(color: Colors.white))),
                ]);
              }).toList(),
            ),
          ),
          // Summary Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Tổng số ĐVHT: $semCredits', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('Trung bình Điểm gốc: ${avg10.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.studentColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Điểm Trung bình Tích lũy: ${avg4.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.studentColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4.3 Chương Trình học - Danh sách môn đã đăng ký
  Widget _buildCurriculumTree() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Vui lòng đăng nhập', style: TextStyle(color: Colors.white70)));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('registrations').where('userId', isEqualTo: user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.studentColor));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book, size: 64, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 16),
                const Text('Chưa đăng ký môn học nào', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Vui lòng vào phần "Đăng ký Môn học" để đăng ký.', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ],
            ),
          );
        }

        final registrations = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScreenHeader(Icons.book, 'DANH SÁCH MÔN HỌC ĐÃ ĐĂNG KÝ'),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: AppColors.studentColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                child: Text('Tổng số: ${registrations.length} môn học', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              const SizedBox(height: 16),
              // Header row
              Row(
                children: [
                  const Expanded(flex: 3, child: Text('Tên Môn Học', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                  const Expanded(flex: 1, child: Center(child: Text('Lớp', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)))),
                  const Expanded(flex: 1, child: Center(child: Text('Giảng Viên', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)))),
                  const Expanded(flex: 1, child: Center(child: Text('Học Kỳ', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)))),
                ],
              ),
              const Divider(color: Colors.white24, height: 32),
              ...registrations.map((reg) => _buildRegistrationItem(reg)),
            ],
          ),
        );
      }
    );
  }

  Widget _buildRegistrationItem(Map<String, dynamic> reg) {
    final courseName = reg['courseName'] ?? 'N/A';
    final classGroup = reg['classGroup'] ?? 'N/A';
    final lecturerName = reg['lecturerName'] ?? 'N/A';
    final semester = reg['semester'] ?? 'N/A';
    final academicYear = reg['academicYear'] ?? 'N/A';
    final room = reg['room'] ?? 'N/A';
    final dayOfWeek = reg['dayOfWeek'] ?? 0;
    final startHour = reg['startHour'] ?? 0;

    String getDayName(int day) {
      switch (day) {
        case 2: return 'Thứ 3';
        case 3: return 'Thứ 4';
        case 4: return 'Thứ 5';
        case 5: return 'Thứ 6';
        case 6: return 'Thứ 7';
        case 7: return 'Chủ Nhật';
        default: return 'Thứ 2';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(flex: 3, child: Text(courseName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
              Expanded(flex: 1, child: Center(child: Text(classGroup, style: const TextStyle(color: Colors.white70, fontSize: 13)))),
              Expanded(flex: 1, child: Center(child: Text(lecturerName, style: const TextStyle(color: Colors.white70, fontSize: 13)))),
              Expanded(flex: 1, child: Center(child: Text('$semester\n$academicYear', style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.white.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text('Phòng: $room', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              const SizedBox(width: 16),
              Icon(Icons.schedule, size: 14, color: Colors.white.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text('${getDayName(dayOfWeek)} - Giờ: ${startHour.toStringAsFixed(1)}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumCategory(Map<String, dynamic> category) {
    final title = category['title'] ?? '';
    final isRequired = category['isRequired'] ?? true;
    final courses = category['courses'] as List<dynamic>? ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.zero,
          title: Row(
            children: [
              const Icon(Icons.apps, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text(isRequired ? '(Bắt buộc)' : '(Tự chọn)', style: TextStyle(color: Colors.red.shade300, fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ),
          children: courses.map((c) {
            final course = c as Map<String, dynamic>;
            final status = course['status'] ?? 'Chưa học';
            Color statusColor = Colors.white54;
            if (status.contains('Đã hoàn tất')) statusColor = AppColors.studentColor;
            if (status.contains('Đang học')) statusColor = Colors.orange;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
              child: Row(
                children: [
                  const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.white38),
                  const SizedBox(width: 8),
                  Expanded(flex: 1, child: Text(course['courseId'] ?? '', style: TextStyle(color: Colors.blue.shade300, fontWeight: FontWeight.w500))),
                  Expanded(flex: 2, child: Text(course['courseName'] ?? '', style: const TextStyle(color: Colors.white))),
                  Expanded(flex: 1, child: Center(child: Text('${course['credits'] ?? ''} Tín Chỉ', style: const TextStyle(color: Colors.white70)))),
                  Expanded(flex: 1, child: Center(child: Text(status, style: TextStyle(color: statusColor, fontSize: 12), textAlign: TextAlign.center))),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 5: Cố vấn Học tập
  Widget _buildAdvisorContent() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Vui lòng đăng nhập', style: TextStyle(color: Colors.white70)));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData && userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.studentColor));
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final currentAdvisorId = userData?['advisorId'] as String?;
        final hasPendingRequest = userData?['pendingAdvisorChange'] as bool? ?? false;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'lecturer').snapshots(),
          builder: (context, advisorsSnapshot) {
            if (!advisorsSnapshot.hasData && advisorsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.studentColor));
            }

            final advisors = advisorsSnapshot.data?.docs.map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>
            }).toList() ?? [];

            final currentAdvisor = currentAdvisorId != null 
                ? advisors.cast<Map<String, dynamic>?>().firstWhere(
                    (a) => a != null && a['id'] == currentAdvisorId, 
                    orElse: () => null
                  )
                : null;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildScreenHeader(Icons.support_agent, 'CỐ VẤN HỌC TẬP'),
                  const SizedBox(height: 24),
                  
                  if (currentAdvisor != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.2),
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                          child: const Icon(Icons.person, size: 50, color: Colors.blue),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(currentAdvisor['fullName'] ?? 'N/A', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(currentAdvisor['faculty'] ?? 'Giảng viên', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                              const SizedBox(height: 16),
                              _buildQuickLink(Icons.email, currentAdvisor['email'] ?? 'N/A'),
                              const SizedBox(height: 8),
                              if (currentAdvisor['phone'] != null && currentAdvisor['phone'].toString().isNotEmpty)
                                _buildQuickLink(Icons.phone, currentAdvisor['phone'].toString()),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ] else ...[
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.person_off, size: 64, color: Colors.white24),
                          SizedBox(height: 16),
                          Text('Chưa có cố vấn học tập', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  if (hasPendingRequest) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.pending, color: Colors.orange, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('Đang chờ Admin phê duyệt yêu cầu đổi cố vấn', 
                              style: TextStyle(color: Colors.white, fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Text('Chọn Cố vấn Học tập', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  ...advisors.map((advisor) {
                    final isSelected = currentAdvisorId == advisor['id'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.studentColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.studentColor : Colors.white.withOpacity(0.1),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.withOpacity(0.2),
                            ),
                            child: const Icon(Icons.person, size: 25, color: Colors.blue),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(advisor['fullName'] ?? 'N/A', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(advisor['faculty'] ?? 'Giảng viên', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                              ],
                            ),
                          ),
                          if (isSelected) ...[
                            const Icon(Icons.check_circle, color: AppColors.studentColor, size: 24),
                          ] else if (!hasPendingRequest) ...[
                            ElevatedButton(
                              onPressed: () => _requestAdvisorChange(advisor['id'], advisor['fullName']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.studentColor,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: const Text('Đổi', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

                  if (advisors.isEmpty) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Chưa có danh sách cố vấn', style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _requestAdvisorChange(String newAdvisorId, String newAdvisorName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a2a1f),
        title: const Text('Xác nhận đổi cố vấn', style: TextStyle(color: Colors.white)),
        content: Text('Bạn có chắc muốn đổi sang cố vấn "$newAdvisorName"?\n\nYêu cầu sẽ được gửi đến Admin để phê duyệt.', 
          style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.studentColor),
            child: const Text('Gửi yêu cầu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Get current advisor ID first
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final currentAdvisorId = userDoc.data()?['advisorId'];

      // Create advisor change request
      await FirebaseFirestore.instance.collection('advisor_change_requests').add({
        'userId': user.uid,
        'userEmail': widget.email,
        'userName': widget.fullName,
        'currentAdvisorId': currentAdvisorId,
        'newAdvisorId': newAdvisorId,
        'newAdvisorName': newAdvisorName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update user document to mark pending request
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'pendingAdvisorChange': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi yêu cầu đổi cố vấn. Vui lòng chờ Admin phê duyệt.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  // 6: Đánh giá & Khảo sát
  Widget _buildSurveyContent() {
    return _buildLecturerEvaluationScreen();
  }

  Widget _buildLecturerEvaluationScreen() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Vui lòng đăng nhập', style: TextStyle(color: Colors.white70)));
    }

    if (_selectedLecturerForEval != null) {
      return _buildLecturerEvaluationForm();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('evaluation_forms')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .snapshots(),
      builder: (context, activeFormSnapshot) {
        if (activeFormSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFC00000)));
        }

        if (!activeFormSnapshot.hasData || activeFormSnapshot.data!.docs.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade400, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: const Color(0xFFC00000),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        onPressed: () => setState(() => _selectedMenuIndex = 0),
                        padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      const Text('A. GIẢNG VIÊN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ]),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Hiện tại không có đợt khảo sát ý kiến sinh viên nào hoạt động.\nVui lòng liên hệ Quản trị viên.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFC00000), fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final activeFormDoc = activeFormSnapshot.data!.docs.first;
        final activeFormData = activeFormDoc.data() as Map<String, dynamic>;
        final activeYear = activeFormData['academicYear'] ?? '';
        final activeSemester = activeFormData['semester'] ?? '';
        final activeTitle = activeFormData['title'] ?? 'KHẢO SÁT Ý KIẾN SINH VIÊN';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Panel 1 Header: A. GIẢNG VIÊN (with Back Button)
                    Container(
                      color: const Color(0xFFC00000),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                            onPressed: () {
                              setState(() {
                                _selectedMenuIndex = 0;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'A. GIẢNG VIÊN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Panel 1 Body (Instructions & Info)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeTitle.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFFC00000),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Năm học: $activeYear',
                                      style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(width: 24),
                                    const Icon(Icons.school, size: 16, color: Colors.black54),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Học kỳ: $activeSemester',
                                      style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Để hoàn thành khảo sát, bạn vui lòng thực hiện đánh giá cho từng giảng viên dưới đây:',
                                  style: TextStyle(color: Colors.black54, fontSize: 12, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Panel 2 Header: GIẢNG VIÊN
                          Container(
                            width: double.infinity,
                            color: const Color(0xFFC00000),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: const Text(
                              'GIẢNG VIÊN ĐĂNG KÝ HỌC',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),

                          // Panel 2 Body (List of Lecturers or Warning)
                          Container(
                            color: Colors.white,
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('registrations')
                                  .where('userId', isEqualTo: user.uid)
                                  .where('academicYear', isEqualTo: activeYear)
                                  .where('semester', isEqualTo: activeSemester)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator(color: Color(0xFFC00000)));
                                }

                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 24),
                                      child: Text(
                                        'Bạn không đăng ký lớp học nào trong học kỳ này để đánh giá.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFFC00000),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final registrations = snapshot.data!.docs;

                                return StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('lecturer_evaluations')
                                      .where('studentId', isEqualTo: user.uid)
                                      .where('academicYear', isEqualTo: activeYear)
                                      .where('semester', isEqualTo: activeSemester)
                                      .snapshots(),
                                  builder: (context, evalSnapshot) {
                                    final evaluatedCourseIds = <String>{};
                                    if (evalSnapshot.hasData) {
                                      for (var doc in evalSnapshot.data!.docs) {
                                        final evalData = doc.data() as Map<String, dynamic>;
                                        if (evalData['courseDocId'] != null) {
                                          evaluatedCourseIds.add(evalData['courseDocId'] as String);
                                        }
                                      }
                                    }

                                    return ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: registrations.length,
                                      separatorBuilder: (context, index) => const Divider(color: Colors.black12, height: 16),
                                      itemBuilder: (context, index) {
                                        final reg = registrations[index].data() as Map<String, dynamic>;
                                        final docId = registrations[index].id;
                                        final courseDocId = reg['courseDocId'] ?? '';
                                        final lecturerName = reg['lecturerName'] ?? 'N/A';
                                        final courseName = reg['courseName'] ?? 'N/A';
                                        final courseId = reg['courseId'] ?? 'N/A';

                                        final isEvaluated = evaluatedCourseIds.contains(courseDocId);

                                        return Card(
                                          margin: EdgeInsets.zero,
                                          color: Colors.white,
                                          elevation: 0,
                                          child: InkWell(
                                            onTap: () {
                                              if (isEvaluated) {
                                                showDialog(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text('Thông báo'),
                                                    content: const Text('Bạn đã thực hiện đánh giá cho môn học này rồi!'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(ctx),
                                                        child: const Text('Đóng'),
                                                      )
                                                    ],
                                                  ),
                                                );
                                              } else {
                                                setState(() {
                                                  _selectedLecturerForEval = {
                                                    'regDocId': docId,
                                                    'courseDocId': courseDocId,
                                                    'courseId': courseId,
                                                    'courseName': courseName,
                                                    'lecturerName': lecturerName,
                                                    'lecturerEmail': reg['lecturerEmail'] ?? '',
                                                  };
                                                  _evalMultipleChoiceAnswers.clear();
                                                  _evalCommentController.clear();
                                                });
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFC00000).withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.person, color: Color(0xFFC00000), size: 20),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          lecturerName,
                                                          style: const TextStyle(
                                                            color: Colors.black87,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          '$courseId - $courseName',
                                                          style: const TextStyle(
                                                            color: Colors.black54,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: isEvaluated 
                                                          ? Colors.green.shade50 
                                                          : const Color(0xFFC00000).withOpacity(0.05),
                                                      borderRadius: BorderRadius.circular(20),
                                                      border: Border.all(
                                                        color: isEvaluated ? Colors.green.shade400 : const Color(0xFFC00000).withOpacity(0.3),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      isEvaluated ? 'Đã đánh giá' : 'Chưa đánh giá',
                                                      style: TextStyle(
                                                        color: isEvaluated ? Colors.green.shade700 : const Color(0xFFC00000),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons.arrow_forward_ios,
                                                    color: isEvaluated ? Colors.grey : const Color(0xFFC00000),
                                                    size: 12,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLecturerEvaluationForm() {
    if (_selectedLecturerForEval == null) return const SizedBox.shrink();

    final lecturerName = _selectedLecturerForEval!['lecturerName'] ?? 'N/A';
    final courseName = _selectedLecturerForEval!['courseName'] ?? 'N/A';
    final courseId = _selectedLecturerForEval!['courseId'] ?? 'N/A';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('evaluation_forms')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFC00000)));
        }

        final docs = snapshot.data?.docs ?? [];
        List<Map<String, dynamic>> questions = [];
        String formTitle = 'ĐÁNH GIÁ GIẢNG VIÊN';
        
        if (docs.isNotEmpty) {
          final formData = docs.first.data() as Map<String, dynamic>;
          formTitle = formData['title'] ?? 'ĐÁNH GIÁ GIẢNG VIÊN';
          final rawQuestions = formData['questions'] as List<dynamic>? ?? [];
          questions = rawQuestions.map((q) => Map<String, dynamic>.from(q as Map)).toList();
        }

        if (questions.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade400, width: 1),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  color: const Color(0xFFC00000),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(children: [
                    IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20), onPressed: () => setState(() => _selectedLecturerForEval = null), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                    const SizedBox(width: 8),
                    const Text('A. CHI TIẾT ĐÁNH GIÁ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ]),
                ),
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Admin chưa tạo form đánh giá.\nVui lòng liên hệ Quản trị viên.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFC00000), fontWeight: FontWeight.w600, fontSize: 14))),
                ),
              ]),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Panel Header
                    Container(
                      color: const Color(0xFFC00000),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(children: [
                        IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20), onPressed: () => setState(() => _selectedLecturerForEval = null), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                        const SizedBox(width: 8),
                        Expanded(child: Text(formTitle.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                    
                    // Lecturer & Course info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('GIẢNG VIÊN: ${lecturerName.toUpperCase()}', style: const TextStyle(color: Color(0xFFC00000), fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Môn học: $courseId - $courseName', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 13)),
                      ]),
                    ),

                    // Multiple Choice Questions
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Vui lòng chọn một đáp án cho mỗi câu hỏi bên dưới:', style: TextStyle(color: Colors.black87, fontSize: 13, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 16),

                          ...questions.asMap().entries.map((entry) {
                            final qIdx = entry.key;
                            final q = entry.value;
                            final qText = q['text'] ?? '';
                            final options = List<String>.from(q['options'] ?? []);
                            final qKey = 'q_$qIdx';
                            final selectedAnswer = _evalMultipleChoiceAnswers[qKey];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Câu ${qIdx + 1}: $qText', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13, height: 1.4)),
                                  const SizedBox(height: 8),
                                  ...options.map((opt) {
                                    final isSelected = selectedAnswer == opt;
                                    return InkWell(
                                      onTap: () => setState(() => _evalMultipleChoiceAnswers[qKey] = opt),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(children: [
                                          Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? const Color(0xFFC00000) : Colors.grey, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(opt, style: TextStyle(color: isSelected ? const Color(0xFFC00000) : Colors.black87, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
                                        ]),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 8),
                          const Text('Ý kiến đóng góp khác (nếu có):', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _evalCommentController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Nhập ý kiến đóng góp của bạn...',
                              hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                              fillColor: Colors.white, filled: true,
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade400)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade400)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFC00000), width: 1.5)),
                            ),
                            style: const TextStyle(color: Colors.black87, fontSize: 13),
                          ),
                          const SizedBox(height: 24),

                          // Submit buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: _isSubmittingEval ? null : () => setState(() => _selectedLecturerForEval = null),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.black87, side: BorderSide(color: Colors.grey.shade400), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), backgroundColor: Colors.white),
                                child: const Text('Hủy bỏ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _isSubmittingEval ? null : _submitLecturerEvaluation,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC00000), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), elevation: 0),
                                child: _isSubmittingEval
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Gửi đánh giá', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitLecturerEvaluation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedLecturerForEval == null) return;

    setState(() {
      _isSubmittingEval = true;
    });

    try {
      final docId = _selectedLecturerForEval!['regDocId'] as String;
      final courseDocId = _selectedLecturerForEval!['courseDocId'] as String;
      final courseId = _selectedLecturerForEval!['courseId'] as String;
      final courseName = _selectedLecturerForEval!['courseName'] as String;
      final lecturerName = _selectedLecturerForEval!['lecturerName'] as String;
      final lecturerEmail = _selectedLecturerForEval!['lecturerEmail'] as String;
      
      final formSnapshot = await FirebaseFirestore.instance
          .collection('evaluation_forms')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (formSnapshot.docs.isEmpty) {
        throw Exception('Không có form đánh giá nào đang hoạt động.');
      }

      final formDoc = formSnapshot.docs.first;
      final formData = formDoc.data();
      final questions = formData['questions'] as List<dynamic>? ?? [];
      
      // Verify all questions are answered
      for (int i = 0; i < questions.length; i++) {
        final qKey = 'q_$i';
        if (!_evalMultipleChoiceAnswers.containsKey(qKey) || _evalMultipleChoiceAnswers[qKey]!.isEmpty) {
          throw Exception('Vui lòng chọn câu trả lời cho tất cả các câu hỏi.');
        }
      }

      await FirebaseFirestore.instance.collection('lecturer_evaluations').add({
        'studentId': user.uid,
        'studentName': widget.fullName,
        'studentEmail': widget.email,
        'studentIdNumber': widget.studentId,
        'registrationId': docId,
        'courseDocId': courseDocId,
        'courseId': courseId,
        'courseName': courseName,
        'lecturerName': lecturerName,
        'lecturerEmail': lecturerEmail,
        'academicYear': formData['academicYear'] ?? '',
        'semester': formData['semester'] ?? '',
        'formId': formDoc.id,
        'answers': _evalMultipleChoiceAnswers,
        'comment': _evalCommentController.text,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Thành công', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            content: const Text('Cảm ơn bạn đã gửi đánh giá! Ý kiến của bạn sẽ giúp cải thiện chất lượng giảng dạy.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedLecturerForEval = null;
                  });
                },
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Lỗi', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingEval = false;
        });
      }
    }
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  // 7: Học phí
  Widget _buildTuitionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.red.shade700, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade900],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Hóa đơn Học phí',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.red.shade700, width: 1.5)),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    _legacyTab(0, 'Hóa đơn Học phí (Mới nhất)'),
                    Container(width: 1, height: 35, color: Colors.grey.shade400),
                    _legacyTab(1, 'Lịch sử Xuất Hóa đơn Học phí'),
                    Container(width: 1, height: 35, color: Colors.grey.shade400),
                    _legacyTab(2, 'Hóa đơn số'),
                  ],
                ),
              ),
              if (_studentTuitionTab == 0)
                _buildLegacyTuitionSelector()
              else if (_studentTuitionTab == 1)
                _buildTuitionHistory()
              else
                _buildDigitalInvoices(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legacyTab(int index, String label) {
    final isSelected = _studentTuitionTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _studentTuitionTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade700 : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLegacyTuitionSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Chọn Năm học:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
              const SizedBox(width: 16),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  color: Colors.white,
                ),
                child: DropdownButton<String>(
                  value: ['2024-2025', '2025-2026', '2026-2027'].contains(_selectedTuitionYear) ? _selectedTuitionYear : 'Chọn Năm học',
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                  items: ['Chọn Năm học', '2024-2025', '2025-2026', '2026-2027'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value == 'Chọn Năm học' ? null : value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedTuitionYear = val;
                      });
                      _loadTuitionData();
                    }
                  },
                ),
              ),
              const SizedBox(width: 32),
              const Text('Chọn Học kỳ:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
              const SizedBox(width: 16),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  color: Colors.white,
                ),
                child: DropdownButton<String>(
                  value: ['Học kỳ 1', 'Học kỳ 2', 'Học kỳ Hè'].contains(_selectedTuitionSemester) ? _selectedTuitionSemester : 'Chọn Học kỳ',
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                  items: ['Chọn Học kỳ', 'Học kỳ 1', 'Học kỳ 2', 'Học kỳ Hè'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value == 'Chọn Học kỳ' ? null : value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedTuitionSemester = val;
                      });
                      _loadTuitionData();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final boxWidth = constraints.constrainWidth();
              const dashWidth = 4.0;
              const dashHeight = 1.0;
              final dashCount = (boxWidth / (2 * dashWidth)).floor();
              return Flex(
                children: List.generate(dashCount, (_) {
                  return const SizedBox(
                    width: dashWidth,
                    height: dashHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.grey),
                    ),
                  );
                }),
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                direction: Axis.horizontal,
              );
            },
          ),
          const SizedBox(height: 16),
          if (_isLoadingTuition)
            const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: Colors.red)))
          else if (_tuitionCourses.isNotEmpty)
            _buildLegacyTuitionDetail()
          else
            const Text(
              'Chưa có Hóa đơn Học phí cho Học kỳ này.',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildLegacyTuitionDetail() {
    final isPaid = _tuitionStatus == 'paid';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          border: TableBorder.all(color: Colors.grey.shade400, width: 1, borderRadius: BorderRadius.circular(2)),
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(4.5),
            3: FlexColumnWidth(1.5),
            4: FlexColumnWidth(2.5),
            5: FlexColumnWidth(2.5),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
              children: [
                _tableHeader('STT'),
                _tableHeader('Mã môn'),
                _tableHeader('Tên môn học / Học phần'),
                _tableHeader('Tín chỉ'),
                _tableHeader('Học phí'),
                _tableHeader('Trạng thái'),
              ],
            ),
            ...List.generate(_tuitionCourses.length, (idx) {
              final course = _tuitionCourses[idx];
              return TableRow(
                children: [
                  _tableCell((idx + 1).toString(), align: Alignment.center),
                  _tableCell(course['courseId'] ?? 'N/A', align: Alignment.center),
                  _tableCell(course['courseName'] ?? 'N/A'),
                  _tableCell(course['credits']?.toString() ?? '0', align: Alignment.center),
                  _tableCell(_formatCurrency(course['tuition'] ?? 0), align: Alignment.centerRight),
                  _tableCell(isPaid ? 'Đã nộp' : 'Chưa nộp', 
                    align: Alignment.center,
                    textColor: isPaid ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TỔNG CỘNG: ${_formatCurrency(_totalTuition)} VNĐ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
            if (!isPaid)
              ElevatedButton(
                onPressed: () {
                  final invoiceDocId = _currentInvoiceDocId ?? '${FirebaseAuth.instance.currentUser?.uid}_${_selectedTuitionYear}_${_selectedTuitionSemester}'.replaceAll(' ', '_');
                  _showQrPaymentDialog(context, _totalTuition, invoiceDocId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC00000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('THANH TOÁN', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTuitionHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: StreamBuilder<QuerySnapshot>(
        stream: _tuitionHistoryStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Colors.red)));
          }
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.black54))));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Chưa có lịch sử xuất hóa đơn.', style: TextStyle(color: Colors.black54))));
          }
          return Table(
            border: TableBorder.all(color: Colors.grey.shade400, width: 1),
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(3),
              4: FlexColumnWidth(2.5),
              5: FlexColumnWidth(2.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.red.shade700),
                children: [
                  _tableHeader('STT', textColor: Colors.white),
                  _tableHeader('Năm học', textColor: Colors.white),
                  _tableHeader('Học kỳ', textColor: Colors.white),
                  _tableHeader('Số tiền', textColor: Colors.white),
                  _tableHeader('Trạng thái', textColor: Colors.white),
                  _tableHeader('Ngày thanh toán', textColor: Colors.white),
                ],
              ),
              ...List.generate(docs.length, (index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final year = data['academicYear'] ?? 'N/A';
                final semester = data['semester'] ?? 'N/A';
                final amount = data['totalAmount'] ?? 0;
                final status = data['status'] ?? 'unpaid';
                final isPaid = status == 'paid';
                final paymentDate = data['paymentDate'] as Timestamp?;
                final dateStr = paymentDate != null 
                    ? DateFormat('dd/MM/yyyy HH:mm').format(paymentDate.toDate())
                    : (isPaid ? 'N/A' : '-');
                
                return TableRow(
                  decoration: BoxDecoration(color: index % 2 == 0 ? Colors.white : Colors.grey.shade50),
                  children: [
                    _tableCell((index + 1).toString(), align: Alignment.center),
                    _tableCell(year, align: Alignment.center),
                    _tableCell(semester, align: Alignment.center),
                    _tableCell('${_formatCurrency(amount)} đ', align: Alignment.centerRight, fontWeight: FontWeight.bold),
                    _tableCell(
                      isPaid ? 'Đã nộp' : (status == 'pending_verification' ? 'Đang duyệt' : 'Chưa nộp'),
                      align: Alignment.center,
                      textColor: isPaid ? Colors.green : (status == 'pending_verification' ? Colors.orange : Colors.red),
                      fontWeight: FontWeight.bold,
                    ),
                    _tableCell(dateStr, align: Alignment.center),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDigitalInvoices() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: StreamBuilder<QuerySnapshot>(
        stream: _digitalInvoicesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Colors.red)));
          }
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.black54))));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Chưa có hóa đơn số nào.', style: TextStyle(color: Colors.black54))));
          }
          return Table(
            border: TableBorder.all(color: Colors.grey.shade400, width: 1),
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(3),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2),
              4: FlexColumnWidth(3),
              5: FlexColumnWidth(2),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.red.shade700),
                children: [
                  _tableHeader('STT', textColor: Colors.white),
                  _tableHeader('Hóa đơn số', textColor: Colors.white),
                  _tableHeader('Năm học', textColor: Colors.white),
                  _tableHeader('Học kỳ', textColor: Colors.white),
                  _tableHeader('Thanh toán lúc', textColor: Colors.white),
                  _tableHeader('Thao tác', textColor: Colors.white),
                ],
              ),
              ...List.generate(docs.length, (index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final invoiceNo = doc.id.replaceAll('_', '').toUpperCase().substring(0, 10);
                final year = data['academicYear'] ?? 'N/A';
                final semester = data['semester'] ?? 'N/A';
                final paymentDate = data['paymentDate'] as Timestamp?;
                final dateStr = paymentDate != null 
                    ? DateFormat('dd/MM/yyyy HH:mm').format(paymentDate.toDate())
                    : 'N/A';
                
                return TableRow(
                  decoration: BoxDecoration(color: index % 2 == 0 ? Colors.white : Colors.grey.shade50),
                  children: [
                    _tableCell((index + 1).toString(), align: Alignment.center),
                    _tableCell('HD-$invoiceNo', align: Alignment.center, fontWeight: FontWeight.bold, textColor: Colors.blue.shade700),
                    _tableCell(year, align: Alignment.center),
                    _tableCell(semester, align: Alignment.center),
                    _tableCell(dateStr, align: Alignment.center),
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: IconButton(
                        icon: const Icon(Icons.download, color: Colors.blue),
                        iconSize: 20,
                        tooltip: 'Tải hóa đơn',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng tải hóa đơn số đang được phát triển.')));
                        },
                      ),
                    ),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTuitionSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn kỳ học phí',
              style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng chọn năm học và học kỳ để xem chi tiết học phí',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),
            
            // Year Selection Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Năm học',
                    style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildYearChip('2024-2025'),
                      _buildYearChip('2025-2026'),
                      _buildYearChip('2026-2027'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Semester Selection Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Học kỳ',
                    style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildSemesterChip('Học kỳ 1'),
                      _buildSemesterChip('Học kỳ 2'),
                      _buildSemesterChip('Học kỳ Hè'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loadTuitionData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC00000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoadingTuition
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Tiếp tục',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearChip(String year) {
    final isSelected = _selectedTuitionYear == year;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTuitionYear = year;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC00000) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFC00000) : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFC00000).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          year,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSemesterChip(String semester) {
    final isSelected = _selectedTuitionSemester == semester;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTuitionSemester = semester;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC00000) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFC00000) : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFC00000).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          semester,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTuitionDetail() {
    final invoiceDocId = _currentInvoiceDocId ?? '${FirebaseAuth.instance.currentUser?.uid}_${_selectedTuitionYear}_${_selectedTuitionSemester}'.replaceAll(' ', '_');
    final isPaid = _tuitionStatus == 'paid';
    final isPending = _tuitionStatus == 'pending_verification';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton.icon(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFC00000), size: 18),
              label: const Text('Chọn kỳ khác', style: TextStyle(color: Color(0xFFC00000), fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: () {
                setState(() {
                  _showTuitionSelector = true;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_isLoadingTuition)
          const Center(child: CircularProgressIndicator(color: Color(0xFFC00000)))
        else if (_tuitionCourses.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Không có dữ liệu học phí cho kỳ này',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFC00000), Color(0xFF900000)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_selectedTuitionSemester - Năm học $_selectedTuitionYear',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tổng học phí học kỳ',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        isPaid ? '0 VNĐ' : '${_formatCurrency(_totalTuition)} VNĐ',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BẢNG CHI TIẾT HÓA ĐƠN HỌC PHÍ',
                        style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      Table(
                        border: TableBorder.all(color: Colors.grey.shade300, width: 1, borderRadius: BorderRadius.circular(4)),
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(5),
                          3: FlexColumnWidth(2),
                          4: FlexColumnWidth(3),
                          5: FlexColumnWidth(2.5),
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
                            children: [
                              _tableHeader('STT'),
                              _tableHeader('Mã môn'),
                              _tableHeader('Tên môn học / Học phần'),
                              _tableHeader('Tín chỉ'),
                              _tableHeader('Học phí'),
                              _tableHeader('Trạng thái'),
                            ],
                          ),
                          ...List.generate(_tuitionCourses.length, (idx) {
                            final course = _tuitionCourses[idx];
                            return TableRow(
                              children: [
                                _tableCell((idx + 1).toString(), align: Alignment.center),
                                _tableCell(course['courseId'] ?? 'N/A', align: Alignment.center),
                                _tableCell(course['courseName'] ?? 'N/A'),
                                _tableCell(course['credits']?.toString() ?? '0', align: Alignment.center),
                                _tableCell(_formatCurrency(course['tuition'] ?? 0), align: Alignment.centerRight),
                                _tableCell(isPaid ? 'Đã nộp' : 'Chưa nộp', 
                                  align: Alignment.center,
                                  textColor: isPaid ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            );
                          }),
                          TableRow(
                            children: [
                              _tableCell(''),
                              _tableCell(''),
                              _tableCell('Phụ phí kỳ học (Base Fee)', fontWeight: FontWeight.bold),
                              _tableCell(''),
                              _tableCell(_formatCurrency(_baseFee), align: Alignment.centerRight, fontWeight: FontWeight.bold),
                              _tableCell(''),
                            ]
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng học phí:', style: TextStyle(color: Colors.black54, fontSize: 12)),
                          Text('${_formatCurrency(_totalTuition)} VNĐ', style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Đã thanh toán:', style: TextStyle(color: Colors.black54, fontSize: 12)),
                          Text(isPaid ? '${_formatCurrency(_totalTuition)} VNĐ' : '0 VNĐ', style: TextStyle(color: isPaid ? Colors.green : Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Còn nợ học phí:', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(isPaid ? '0 VNĐ' : '${_formatCurrency(_totalTuition)} VNĐ', style: TextStyle(color: isPaid ? Colors.green : const Color(0xFFC00000), fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      if (isPaid)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green, width: 3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ĐÃ HOÀN THÀNH NGHĨA VỤ HỌC PHÍ',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                            ),
                          ),
                        )
                      else if (isPending)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.orange, width: 3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ĐANG CHỜ XÁC NHẬN MINH CHỨNG',
                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showQrPaymentDialog(context, _totalTuition, invoiceDocId),
                                icon: const Icon(Icons.qr_code_scanner, size: 18),
                                label: const Text('Thanh toán qua QR'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC00000),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _tableHeader(String text, {Color textColor = Colors.black87}) {
    return Container(
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _tableCell(String text, {
    Alignment align = Alignment.centerLeft,
    Color textColor = Colors.black87,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      alignment: align,
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: textColor, fontWeight: fontWeight),
      ),
    );
  }

  Widget _buildPaymentHistory() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tuition_fees')
          .where('studentId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'paid')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFC00000)));
        }

        var docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Bạn chưa có lịch sử thanh toán học phí nào.', style: TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final year = data['academicYear'] ?? 'N/A';
            final semester = data['semester'] ?? 'N/A';
            final total = data['totalAmount'] ?? 0;
            final pMethod = data['paymentMethod'] ?? 'Thẻ ngân hàng';
            final pDate = (data['paymentDate'] as Timestamp?)?.toDate();
            final dateStr = pDate != null ? '${pDate.day}/${pDate.month}/${pDate.year} ${pDate.hour.toString().padLeft(2, '0')}:${pDate.minute.toString().padLeft(2, '0')}' : 'N/A';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$semester - Năm học $year', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text('Thanh toán qua: ${pMethod == 'zalopay' ? 'Ví ZaloPay' : (pMethod == 'card' ? 'Thẻ quốc tế' : 'Đóng tại quầy')}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text('Thời gian: $dateStr', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text('+${_formatCurrency(total)} VNĐ', style: const TextStyle(color: Color(0xFFC00000), fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // QR Payment & Proof Upload
  void _showQrPaymentDialog(BuildContext context, int totalAmount, String docId) {
    bool isUploading = false;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final viewId = 'qr-image-$totalAmount-$uid-${DateTime.now().millisecondsSinceEpoch}';
    
    // Register the iframe/image for Flutter Web
    if (kIsWeb) {
      ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
        final img = web.HTMLImageElement()
          ..src = 'https://img.vietqr.io/image/MB-0123456789-compact2.png?amount=$totalAmount&addInfo=MSSV%20$uid&accountName=TRUONG%20DAI%20HOC%20EDUTRACK'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain';
        return img;
      });
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Thanh toán qua mã QR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black54),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Bank Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Ngân hàng Thương mại Cổ phần Quân đội (MBBank)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          const Text('Tên tài khoản: TRUONG DAI HOC EDUTRACK', style: TextStyle(color: Colors.black87)),
                          const SizedBox(height: 4),
                          const Text('Số tài khoản: 0123456789', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                          const SizedBox(height: 4),
                          Text('Nội dung CK: MSSV - ${_formatCurrency(totalAmount)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Dynamic QR Code
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb 
                          ? HtmlElementView(viewType: viewId)
                          : Image.network(
                              'https://img.vietqr.io/image/MB-0123456789-compact2.png?amount=$totalAmount&addInfo=MSSV%20$uid&accountName=TRUONG%20DAI%20HOC%20EDUTRACK',
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.qr_code_2, size: 100, color: Colors.black54),
                                );
                              },
                            ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Text('Sau khi thanh toán thành công, vui lòng tải ảnh chụp màn hình minh chứng lên để Admin xét duyệt.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isUploading ? null : () async {
                          final result = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 60,
                            maxWidth: 1200,
                            maxHeight: 1200,
                          );
                          if (result == null) return;
                          
                          setDialogState(() {
                            isUploading = true;
                          });
                          
                          try {
                            final bytes = await result.readAsBytes();
                            final fileName = 'proof_${DateTime.now().millisecondsSinceEpoch}_${result.name}';
                            final base64String = base64Encode(bytes);
                            
                            final response = await http.post(
                              Uri.parse('https://setcors-pvqsiluuja-uc.a.run.app'),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'base64Data': base64String,
                                'mimeType': result.mimeType ?? 'image/jpeg',
                                'fileName': fileName,
                              }),
                            ).timeout(const Duration(seconds: 25), onTimeout: () {
                              throw Exception('Upload timeout. Vui lòng kiểm tra lại mạng hoặc thử lại.');
                            });
                            
                            if (response.statusCode != 200) {
                              throw Exception('Lỗi server: ${response.body}');
                            }
                            
                            final responseData = jsonDecode(response.body);
                            final downloadUrl = responseData['url'];
                            
                            await FirebaseFirestore.instance.collection('tuition_fees').doc(docId).set({
                              'studentId': uid,
                              'academicYear': _selectedTuitionYear,
                              'semester': _selectedTuitionSemester,
                              'courses': _tuitionCourses,
                              'totalAmount': totalAmount,
                              'status': 'pending_verification',
                              'proofUrl': downloadUrl,
                              'paymentMethod': 'qr_transfer',
                              'paymentDate': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));
                            
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã tải minh chứng thành công! Đang chờ Admin duyệt.'), backgroundColor: Colors.green),
                              );
                              _loadTuitionData();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi tải ảnh: $e'), backgroundColor: Colors.red),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setDialogState(() {
                                isUploading = false;
                              });
                            }
                          }
                        },
                        icon: isUploading 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.upload_file),
                        label: Text(isUploading ? 'Đang tải lên...' : 'Tải lên Minh chứng', style: const TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC00000),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  Future<void> _loadTuitionData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingTuition = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tuition_fees')
          .where('studentId', isEqualTo: user.uid)
          .where('academicYear', isEqualTo: _selectedTuitionYear)
          .where('semester', isEqualTo: _selectedTuitionSemester)
          .get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _tuitionCourses = [];
            _totalTuition = 0;
            _baseFee = 0;
            _tuitionStatus = 'unpaid';
            _paymentMethod = null;
            _paymentDate = null;
            _showTuitionSelector = false;
            _isLoadingTuition = false;
            _currentInvoiceDocId = null;
          });
        }
        return;
      }

      final doc = snapshot.docs.first;
      final tuitionData = doc.data();
      _currentInvoiceDocId = doc.id;
      final courses = tuitionData['courses'] as List<dynamic>? ?? [];
      final total = tuitionData['totalAmount'] as int? ?? 0;
      final bFee = tuitionData['baseFee'] as int? ?? 0;
      final status = tuitionData['status'] ?? 'unpaid';
      final pMethod = tuitionData['paymentMethod'] as String?;
      final pDate = (tuitionData['paymentDate'] as Timestamp?)?.toDate();

      if (mounted) {
        setState(() {
          _tuitionCourses = courses.cast<Map<String, dynamic>>();
          _totalTuition = total;
          _baseFee = bFee;
          _tuitionStatus = status;
          _paymentMethod = pMethod;
          _paymentDate = pDate;
          _showTuitionSelector = false;
          _isLoadingTuition = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTuition = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // 8: Thư viện
  Widget _buildLibraryContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScreenHeader(Icons.local_library, 'THƯ VIỆN ĐIỆN TỬ'),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Tìm kiếm tài liệu, sách, giáo trình...',
                hintStyle: TextStyle(color: Colors.black38),
                icon: Icon(Icons.search, color: Colors.black45),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Sách đang mượn', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildRuleItem('1', 'Giáo trình Cấu trúc dữ liệu và Giải thuật - Hạn trả: 25/06/2026'),
          _buildRuleItem('2', 'Design Patterns in C# - Hạn trả: 28/06/2026'),
        ],
      ),
    );
  }

  // 9: Phần mềm
  Widget _buildSoftwareContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScreenHeader(Icons.apps, 'PHẦN MỀM CHO SINH VIÊN'),
          const SizedBox(height: 24),
          _buildRuleItem('1', 'Microsoft Office 365 (Bản quyền EduTrack)'),
          _buildRuleItem('2', 'AutoCAD Education Version'),
          _buildRuleItem('3', 'JetBrains IDEs (Dành cho sinh viên CNTT)'),
          _buildRuleItem('4', 'Adobe Creative Cloud (Yêu cầu tài khoản trường)'),
        ],
      ),
    );
  }

  // 10: Sổ tay Sinh viên
  Widget _buildHandbookContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScreenHeader(Icons.book, 'SỔ TAY SINH VIÊN'),
          const SizedBox(height: 24),
          _buildRuleItem('1', 'Quy chế đào tạo tín chỉ.'),
          _buildRuleItem('2', 'Quy định về chuẩn đầu ra ngoại ngữ, tin học.'),
          _buildRuleItem('3', 'Hướng dẫn đánh giá điểm rèn luyện.'),
          _buildRuleItem('4', 'Các biểu mẫu hành chính dành cho sinh viên.'),
        ],
      ),
    );
  }

  // 11: Đăng ký Cấp Giấy xác nhận
  Widget _buildCertificateContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScreenHeader(Icons.assignment, 'ĐĂNG KÝ CẤP GIẤY XÁC NHẬN'),
          const SizedBox(height: 24),
          _buildRuleItem('1', 'Giấy xác nhận đang là Sinh viên.'),
          _buildRuleItem('2', 'Giấy xác nhận vay vốn Ngân hàng chính sách.'),
          _buildRuleItem('3', 'Bảng điểm tích lũy học tập.'),
          _buildRuleItem('4', 'Giấy xác nhận hoãn nghĩa vụ quân sự.'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.studentColor),
            child: const Text('Tạo yêu cầu mới', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Default Fallback
  Widget _buildRulesContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.public, color: AppColors.studentColor, size: 28),
              SizedBox(width: 12),
              Text(
                'NỘI QUY SỬ DỤNG HỆ THỐNG PORTAL EDUTRACK',
                style: TextStyle(
                  color: AppColors.studentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Khi sử dụng Hệ thống Portal EduTrack, mỗi Sinh viên/Học viên phải tuyệt đối tuân thủ các quy định sau:',
            style: TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          const Text(
            'Đối với SINH VIÊN/HỌC VIÊN:',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildRuleItem('1', 'Mọi Sinh viên/Học viên khi tham gia sử dụng hệ thống portal EduTrack phải chịu trách nhiệm hoàn toàn về sự xác thực và tính chính xác của mọi thông tin mình cập nhật, đăng ký, đăng tải...;'),
          _buildRuleItem('2', 'Nghiêm cấm mọi hành vi phá hoại hệ thống dưới mọi hình thức, khiến hệ thống không tiếp tục hoạt động, bằng các tiểu xảo kỹ thuật hay bằng những thông tin sai lệch;'),
          _buildRuleItem('3', 'Mỗi Sinh viên/Học viên có trách nhiệm quản lý thông tin tài khoản, mật khẩu đăng nhập và Mã số Sinh viên/Học viên của mình. Không được tiết lộ thông tin tài khoản cá nhân của mình cho bất kỳ một cá nhân hay tổ chức nào khác;'),
          _buildRuleItem('4', 'Sinh viên/Học viên chịu hoàn toàn trách nhiệm về các hành vi thực hiện thông qua tài khoản của mình nếu để lộ thông tin (đăng nhập) tài khoản cá nhân.'),
          _buildRuleItem('5', 'Nghiêm cấm hành vi dùng Email trường cấp cho các mục đích spam hay phát tán thông tin sai lệch, đồi trụy hoặc phản động;'),
          _buildRuleItem('6', 'Không được sử dụng các hình ảnh để gây hiểu nhầm, kinh dị, đồi trụy, phản động hay trái với thuần phong mỹ tục của người Việt Nam cho Avatar (hình đại diện) của tài khoản cá nhân.'),
          _buildRuleItem('7', 'Kích thước Avatar không được quá 130 x 130 pixel (hay 3.67cm x 3.67cm) và dung lượng không được lớn hơn 150 KB;'),
          _buildRuleItem('8', 'Sinh viên/Học viên ở học kỳ đầu (hay trong một số trường hợp, ở năm đầu) phải tuân thủ việc phân bổ môn học của nhà trường.'),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number. ', style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.black54, fontSize: 14, height: 1.6)),
          ),
        ],
      ),
    );
  }

  // --- DETAILED GRADES SECTION ---
  Widget _buildDetailedGradesContent() {
    if (!_isShowingGradesList) {
      return _buildGradesSelector();
    }
    if (_selectedCourseForGrades == null) {
      return _buildGradesCourseList();
    }
    if (_gradeViewMode == 'personal') {
      return _buildPersonalGrades();
    } else {
      return _buildAssignmentGrades();
    }
  }

  Widget _buildGradesSelector() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScreenHeader(Icons.calendar_month, 'XEM ĐIỂM CỤ THỂ'),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade700, width: 1),
            ),
            child: Column(
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
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      const Text('Chọn Năm học:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _selectedGradesYear,
                        items: ['2024-2025', '2025-2026', '2026-2027'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedGradesYear = val);
                        },
                      ),
                      const SizedBox(width: 48),
                      const Text('Chọn Học kỳ:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _selectedGradesSemester,
                        items: ['Học kỳ 1', 'Học kỳ 2', 'Học kỳ Hè'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedGradesSemester = val);
                        },
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                        onPressed: () {
                          setState(() {
                            _isShowingGradesList = true;
                          });
                        },
                        child: const Text('Tiếp tục'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(4),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(2),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade200),
                        children: [
                          _tableHeader('Mã Lớp'),
                          _tableHeader('Tên Môn'),
                          _tableHeader('Hình Thức'),
                          _tableHeader('Bậc Học'),
                        ],
                      ),
                      TableRow(
                        children: [
                          _tableCell(''),
                          _tableCell('Không có lớp nào', align: Alignment.center, textColor: Colors.red),
                          _tableCell(''),
                          _tableCell(''),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradesCourseList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _isShowingGradesList = false;
                  });
                },
              ),
              _buildScreenHeader(Icons.calendar_month, 'XEM ĐIỂM CỤ THỂ'),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade700, width: 1),
            ),
            child: Column(
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
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      const Text('Chọn Năm học:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Text(_selectedGradesYear, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 48),
                      const Text('Chọn Học kỳ:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Text(_selectedGradesSemester, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('registrations')
                      .where('userId', isEqualTo: user.uid)
                      .where('academicYear', isEqualTo: _selectedGradesYear)
                      .where('semester', isEqualTo: _selectedGradesSemester)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: Colors.red)));
                    }

                    final docs = snapshot.data?.docs ?? [];

                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Table(
                        border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(4),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(2),
                          4: FlexColumnWidth(3),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.shade200),
                            children: [
                              _tableHeader('Mã Lớp'),
                              _tableHeader('Tên Môn'),
                              _tableHeader('Hình Thức'),
                              _tableHeader('Bậc Học'),
                              _tableHeader(''),
                            ],
                          ),
                          if (docs.isEmpty)
                            TableRow(
                              children: [
                                _tableCell(''),
                                _tableCell('Không có lớp nào', align: Alignment.center, textColor: Colors.red),
                                _tableCell(''),
                                _tableCell(''),
                                _tableCell(''),
                              ],
                            )
                          else
                            ...docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final courseId = data['courseId'] ?? 'N/A';
                              final courseName = data['courseName'] ?? 'N/A';
                              return TableRow(
                                children: [
                                  _tableCell(courseId),
                                  _tableCell(courseName),
                                  _tableCell('LEC', align: Alignment.center),
                                  _tableCell('Đại Học, Cao Đẳng', align: Alignment.center),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedCourseForGrades = {'docId': doc.id, 'courseId': courseId, 'courseName': courseName, 'courseDocId': data['courseDocId']};
                                              _gradeViewMode = 'personal';
                                            });
                                          },
                                          child: const Text('Xem điểm Cá nhân', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 13)),
                                        ),
                                        const SizedBox(height: 8),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedCourseForGrades = {'docId': doc.id, 'courseId': courseId, 'courseName': courseName, 'courseDocId': data['courseDocId']};
                                              _gradeViewMode = 'assignments';
                                            });
                                          },
                                          child: const Text('Xem điểm Bài tập', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 13)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchPersonalGrades() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedCourseForGrades == null) return [];

    final courseDocId = _selectedCourseForGrades!['courseDocId'];
    if (courseDocId == null || courseDocId.toString().isEmpty) return [];
    
    final regSnap = await FirebaseFirestore.instance.collection('registrations')
        .where('courseDocId', isEqualTo: courseDocId)
        .where('userId', isEqualTo: user.uid).get();
        
    if (regSnap.docs.isEmpty) return [];
    
    final regData = regSnap.docs.first.data();
    final status = regData['gradeStatus'] ?? 'none';
    
    if (status != 'admin_published') {
        return [{'title': 'Bảng điểm đang chờ cập nhật hoặc chưa được công bố.', 'type': 'info', 'grade': null, 'maxGrade': null}];
    }
    
    List<Map<String, dynamic>> results = [];
    
    final att = regData['attendanceScore'];
    final mid = regData['midtermScore'];
    final fin = regData['finalScore'];
    
    if (att != null) results.add({'title': 'Chuyên cần', 'type': 'Chuyên cần', 'grade': (att as num).toDouble(), 'maxGrade': 10.0, 'weight': 10.0});
    if (mid != null) results.add({'title': 'Giữa kỳ', 'type': 'Giữa kỳ', 'grade': (mid as num).toDouble(), 'maxGrade': 10.0, 'weight': 20.0});
    if (fin != null) results.add({'title': 'Cuối kỳ', 'type': 'Cuối kỳ', 'grade': (fin as num).toDouble(), 'maxGrade': 10.0, 'weight': 70.0});
    
    final detailed = regData['detailedGrades'] as List<dynamic>? ?? [];
    for (var item in detailed) {
        if (item is Map<String, dynamic>) {
            results.add({
              'title': item['title'],
              'type': item['type'],
              'grade': (item['grade'] as num?)?.toDouble(),
              'maxGrade': (item['maxGrade'] as num?)?.toDouble() ?? 10.0,
              'weight': 0.0, // Detailed grades might not have a direct global weight in this simple display
            });
        }
    }
    
    return results;
  }

  Widget _buildPersonalGrades() {
    final courseId = _selectedCourseForGrades?['courseId'] ?? '';
    final courseName = _selectedCourseForGrades?['courseName'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _selectedCourseForGrades = null;
                  });
                },
              ),
              _buildScreenHeader(Icons.calendar_month, 'XEM ĐIỂM CỤ THỂ'),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade700, width: 1),
            ),
            child: Column(
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
                      const Text('Điểm Cá nhân', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'TÊN LỚP: $courseId - ${courseName.toUpperCase()}',
                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchPersonalGrades(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: Colors.red)));
                    }

                    final items = snapshot.data ?? [];
                    if (items.isNotEmpty && items.first['type'] == 'info') {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.lock_clock, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(items.first['title'], style: const TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        ),
                      );
                    }

                    double totalScorePercent = 0;

                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Table(
                        border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(4),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(2),
                          4: FlexColumnWidth(2),
                          5: FlexColumnWidth(2),
                          6: FlexColumnWidth(2),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.shade200),
                            children: [
                              _tableHeader(''),
                              _tableHeader('Tên Cột Điểm'),
                              _tableHeader('Điểm'),
                              _tableHeader('Loại'),
                              _tableHeader('Thang Điểm'),
                              _tableHeader('% Trọng số'),
                              _tableHeader('% Quy đổi'),
                            ],
                          ),
                          ...items.asMap().entries.map((entry) {
                            int idx = entry.key;
                            var item = entry.value;
                            double? grade = item['grade'];
                            double maxGrade = item['maxGrade'] ?? 10.0;
                            if (maxGrade == 0) maxGrade = 10.0; // Avoid division by zero
                            
                            double weight = (item['weight'] as num?)?.toDouble() ?? 0.0;
                            double percent = grade != null ? (grade / maxGrade) * weight : 0;
                            totalScorePercent += percent;

                            return TableRow(
                              children: [
                                _tableCell('${idx + 1}', align: Alignment.center),
                                _tableCell(item['title'] ?? ''),
                                _tableCell(grade?.toStringAsFixed(1) ?? '-', align: Alignment.center, fontWeight: FontWeight.bold),
                                _tableCell(item['type'] ?? '', align: Alignment.center),
                                _tableCell(maxGrade.toStringAsFixed(1), align: Alignment.center),
                                _tableCell(weight > 0 ? '${weight.toStringAsFixed(0)}%' : '-', align: Alignment.center),
                                _tableCell(weight > 0 ? percent.toStringAsFixed(1) : '-', align: Alignment.center),
                              ],
                            );
                          }),
                          TableRow(
                            children: [
                              _tableCell(''),
                              _tableCell(''),
                              _tableCell(''),
                              _tableCell(''),
                              _tableCell('TỔNG HỆ 10:', align: Alignment.centerRight, fontWeight: FontWeight.bold),
                              _tableCell('${(totalScorePercent / 10).toStringAsFixed(1)}', align: Alignment.center, fontWeight: FontWeight.bold),
                              _tableCell(''),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentGrades() {
    final courseId = _selectedCourseForGrades?['courseId'] ?? '';
    final courseName = _selectedCourseForGrades?['courseName'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _selectedCourseForGrades = null;
                  });
                },
              ),
              _buildScreenHeader(Icons.calendar_month, 'XEM ĐIỂM CỤ THỂ'),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade700, width: 1),
            ),
            child: Column(
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
                      const Text('Điểm Bài tập', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'TÊN LỚP: $courseId - ${courseName.toUpperCase()}',
                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchPersonalGrades(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: Colors.red)));
                    }

                    final allItems = snapshot.data ?? [];
                    final items = allItems.where((i) => i['type'] == 'assignment').toList();
                    double weightPerItem = allItems.isEmpty ? 0 : (100.0 / allItems.length); // Weight is based on all items

                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Table(
                        border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(4),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(2),
                          4: FlexColumnWidth(2),
                          5: FlexColumnWidth(2),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.shade200),
                            children: [
                              _tableHeader(''),
                              _tableHeader('Tên Bài Giao'),
                              _tableHeader('% Điểm'),
                              _tableHeader('Thang Điểm'),
                              _tableHeader('Ngày giao'),
                              _tableHeader('Ngày nộp'),
                            ],
                          ),
                          ...items.asMap().entries.map((entry) {
                            int idx = entry.key;
                            var item = entry.value;
                            
                            String assignedDate = 'N/A';
                            if (item['createdAt'] is Timestamp) {
                              final d = (item['createdAt'] as Timestamp).toDate();
                              assignedDate = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                            }
                            
                            String submittedDate = 'Chưa nộp';
                            if (item['submittedAt'] is Timestamp) {
                              final d = (item['submittedAt'] as Timestamp).toDate();
                              submittedDate = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                            }

                            return TableRow(
                              children: [
                                _tableCell('${idx + 1}', align: Alignment.center),
                                _tableCell(item['title'] ?? ''),
                                _tableCell('${weightPerItem.toStringAsFixed(2)}%', align: Alignment.center),
                                _tableCell(item['maxGrade']?.toString() ?? '10', align: Alignment.center),
                                _tableCell(assignedDate, align: Alignment.center),
                                _tableCell(submittedDate, align: Alignment.center),
                              ],
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MockQrCode extends StatelessWidget {
  const MockQrCode({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(14, (r) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(14, (c) {
              bool isBlack = false;
              if ((r < 4 && c < 4) || (r < 4 && c > 9) || (r > 9 && c < 4)) {
                if (r < 4 && c < 4) {
                  isBlack = r == 0 || r == 3 || c == 0 || c == 3 || (r >= 1 && r <= 2 && c >= 1 && c <= 2);
                } else if (r < 4 && c > 9) {
                  int nc = c - 10;
                  isBlack = r == 0 || r == 3 || nc == 0 || nc == 3 || (r >= 1 && r <= 2 && nc >= 1 && nc <= 2);
                } else if (r > 9 && c < 4) {
                  int nr = r - 10;
                  isBlack = nr == 0 || nr == 3 || c == 0 || c == 3 || (nr >= 1 && nr <= 2 && c >= 1 && c <= 2);
                }
              } else {
                isBlack = (r * c + r + c) % 3 == 0 || (r + c) % 5 == 0;
              }
              return Container(
                width: 8,
                height: 8,
                color: isBlack ? Colors.black : Colors.white,
              );
            }),
          );
        }),
      ),
    );
  }

}


