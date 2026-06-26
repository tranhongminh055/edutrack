import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../widgets/nature_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/role_selector.dart';
import '../widgets/schedule_grid.dart';
import '../services/notification_service.dart';
import 'lecturer_dashboard.dart';
import 'admin_dashboard.dart';
import 'welcome_screen.dart';

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
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  final NotificationService _notificationService = NotificationService();

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
    'Thư viện',
    'Phần mềm',
    'Sổ tay Sinh viên',
    'Đăng ký Cấp Giấy xác nhận',
  ];

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
    _fullNameController.text = widget.fullName;
    _idController.text = widget.studentId;

    _loadSavedProfile();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
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
    _timer?.cancel();
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
    super.dispose();
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1: return 'Thứ hai';
      case 2: return 'Thứ ba';
      case 3: return 'Thứ tư';
      case 4: return 'Thứ năm';
      case 5: return 'Thứ sáu';
      case 6: return 'Thứ bảy';
      case 7: return 'Chủ nhật';
      default: return '';
    }
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
          _buildTopNavLink(Icons.home, 'Trang chủ'),
          _buildTopNavLink(Icons.mail, 'Mail'),
          _buildTopNavLink(Icons.check_circle, 'Learning'),
          _buildTopNavLink(Icons.forum, 'Forum'),
          _buildTopNavLink(Icons.library_books, 'e-Lib'),
          const Spacer(),
          const Text('Việt Nam  |  English', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTopNavLink(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    final hourStr = _currentTime.hour.toString().padLeft(2, '0');
    final minuteStr = _currentTime.minute.toString().padLeft(2, '0');
    final secondStr = _currentTime.second.toString().padLeft(2, '0');
    final dateStr = '${_getWeekdayName(_currentTime.weekday)}, ngày ${_currentTime.day} tháng ${_currentTime.month} năm ${_currentTime.year}';

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
            Column(
              children: [
                Row(
                  children: [
                    _buildTimeBox(hourStr[0]), _buildTimeBox(hourStr[1]), const Text(' : ', style: TextStyle(color: Colors.white, fontSize: 20)),
                    _buildTimeBox(minuteStr[0]), _buildTimeBox(minuteStr[1]), const Text(' : ', style: TextStyle(color: Colors.white, fontSize: 20)),
                    _buildTimeBox(secondStr[0]), _buildTimeBox(secondStr[1]),
                  ],
                ),
                const SizedBox(height: 8),
                Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              ],
            ),
            
            // Right: Quick Links
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickLink(Icons.mail, 'EduTrack Gmail'),
                const SizedBox(height: 8),
                _buildQuickLink(Icons.language, 'HỌC TẬP TRỰC TUYẾN'),
                const SizedBox(height: 8),
                _buildQuickLink(Icons.group, 'DIỄN ĐÀN HỌC TẬP EDUTRACK'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBox(String digit) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(digit, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildQuickLink(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.studentColor, size: 16),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
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
      case 8: return _buildLibraryContent();
      case 9: return _buildSoftwareContent();
      case 10: return _buildHandbookContent();
      case 11: return _buildCertificateContent();
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
          Text(
            isEmpty ? 'Chưa cập nhật' : displayText,
            style: TextStyle(
              color: isEmpty ? Colors.white54 : Colors.white,
              fontSize: 16,
              fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
              fontWeight: FontWeight.w500,
            ),
          )
        else if (label == 'Giới tính')
          _buildDropdownField(label, controller!, ['Nam', 'Nữ'])
        else if (label == 'Khoa')
          _buildDropdownField(label, controller!, ['Khoa CNTT', 'Khoa Kinh tế', 'Khoa Ngoại ngữ', 'Khoa Y Dược', 'Khoa Xây dựng', 'Khoa Du lịch'])
        else if (label == 'Ngành')
          _buildDropdownField(label, controller!, ['Kỹ thuật Phần mềm', 'Khoa học Máy tính', 'An toàn Thông tin', 'Quản trị Kinh doanh', 'Ngôn ngữ Anh', 'Marketing'])
        else if (label == 'Lớp')
          _buildDropdownField(label, controller!, ['KTPM1', 'KTPM2', 'KHMT1', 'NNA1', 'QTDN1'])
        else if (label == 'Khóa')
          _buildDropdownField(label, controller!, ['K25', 'K26', 'K27', 'K28', 'K29'])
        else
          TextFormField(
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
            style: const TextStyle(color: Colors.white, fontSize: 14),
            keyboardType: _getKeyboardType(label),
            inputFormatters: _getInputFormatters(label),
            validator: (value) => _validateField(label, value),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              hintText: label == 'Ngày sinh' ? 'Chọn ngày sinh' : 'Nhập $label',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
              suffixIcon: label == 'Ngày sinh' ? const Icon(Icons.calendar_today, color: Colors.white54, size: 20) : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.studentColor),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
              errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownField(String label, TextEditingController controller, List<String> items) {
    return DropdownButtonFormField<String>(
      value: items.contains(controller.text) ? controller.text : null,
      hint: Text('Chọn $label', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13)),
      dropdownColor: const Color(0xFF2A2D2B),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.studentColor),
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
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
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
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
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
          color: isNew ? Colors.white.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isNew ? Border.all(color: AppColors.studentColor.withOpacity(0.3)) : null,
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
                      Icon(Icons.person_outline, size: 14, color: Colors.white.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(sender, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 14, color: Colors.white.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(date, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3), size: 20),
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
        _buildScheduleToolbar(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('schedules')
                .where('studentClass', isEqualTo: _classController.text.trim())
                .snapshots(),
            builder: (context, snapshot) {
              // Only show loading on initial load, not on stream updates
              if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text('Chưa có lịch học nào cho lớp ${_classController.text}', style: const TextStyle(color: Colors.white70)),
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

  Widget _buildScheduleToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1)), top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
                child: const Icon(Icons.chevron_left, color: Colors.white70, size: 20),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
                child: const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: const Text('Hôm nay', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down, color: Colors.white54),
            ],
          ),
          const Spacer(),
          const Text('22/06/2026 - 28/06/2026', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          Row(
            children: [
              _buildViewBtn('Ngày', false),
              _buildViewBtn('Tuần', true),
              _buildViewBtn('Tháng', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewBtn(String text, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildScreenHeader(Icons.app_registration, 'ĐĂNG KÝ MÔN HỌC'),
          const SizedBox(height: 48),
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
                _buildStepDropdown('1', 'Chọn Năm học', ['2023-2024', '2024-2025']),
                const SizedBox(width: 48),
                _buildStepDropdown('2', 'Chọn Học kỳ', ['Học kỳ 1', 'Học kỳ 2', 'Học kỳ Hè']),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng đăng ký đang được bảo trì.')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('TIẾP TỤC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDropdown(String step, String hint, List<String> items) {
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
              hint: Text(hint, style: const TextStyle(color: Colors.black87)),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.black87)))).toList(),
              onChanged: (v) {},
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
            ),
          ),
        ),
      ],
    );
  }

  // 4.2 Bảng điểm
  Widget _buildGradesTable() {
    if (widget.studentId.isEmpty) {
      return const Center(child: Text('Không tìm thấy Mã số sinh viên.', style: TextStyle(color: Colors.white54)));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('student_grades').doc(widget.studentId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.studentColor));
        
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, size: 64, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 16),
                const Text('Chưa có dữ liệu bảng điểm.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Dữ liệu sẽ được Quản trị viên cập nhật sau.', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ],
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final semesters = data['semesters'] as List<dynamic>? ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScreenHeader(Icons.grade, 'BẢNG ĐIỂM SINH VIÊN'),
              const SizedBox(height: 16),
              Text('Sinh viên: ${widget.fullName} (Mã Sinh viên: ${widget.studentId})', style: const TextStyle(color: AppColors.studentColor, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 24),
              ...semesters.map((s) => _buildSemesterGrades(s as Map<String, dynamic>)),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSemesterGrades(Map<String, dynamic> semesterData) {
    final title = semesterData['semesterName'] ?? 'Học kỳ';
    final courses = semesterData['courses'] as List<dynamic>? ?? [];

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
            child: Text(title, style: const TextStyle(color: AppColors.studentColor, fontWeight: FontWeight.bold, fontSize: 15)),
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
              rows: courses.map((c) {
                final course = c as Map<String, dynamic>;
                return DataRow(cells: [
                  DataCell(Text(course['courseId'] ?? '', style: const TextStyle(color: Colors.white))),
                  DataCell(Text(course['classId'] ?? '', style: const TextStyle(color: Colors.white))),
                  DataCell(Text(course['type'] ?? '', style: const TextStyle(color: Colors.white))),
                  DataCell(Text(course['courseName'] ?? '', style: const TextStyle(color: Colors.white))),
                  DataCell(Text('${course['credits'] ?? ''}', style: const TextStyle(color: Colors.white))),
                  DataCell(Text('${course['grade10'] ?? ''}', style: const TextStyle(color: Colors.white))),
                  DataCell(Text(course['gradeChar'] ?? '', style: const TextStyle(color: Colors.white))),
                  DataCell(Text('${course['grade4'] ?? ''}', style: const TextStyle(color: Colors.white))),
                ]);
              }).toList(),
            ),
          ),
          // Summary Footer
          if (semesterData['summary'] != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Tổng số ĐVHT: ${semesterData['summary']['totalCredits'] ?? 0}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('Trung bình Điểm gốc: ${semesterData['summary']['avg10'] ?? 0.0}', style: const TextStyle(color: AppColors.studentColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Điểm Trung bình Tích lũy: ${semesterData['summary']['avg4'] ?? 0.0}', style: const TextStyle(color: AppColors.studentColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 4.3 Chương Trình học
  Widget _buildCurriculumTree() {
    if (_majorController.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber, size: 64, color: Colors.orange.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('Chưa cập nhật chuyên ngành!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Vui lòng vào phần "Thông tin Cá nhân" để điền chuyên ngành của bạn.', style: TextStyle(color: Colors.white.withOpacity(0.7))),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('curriculums').where('major', isEqualTo: _majorController.text.trim()).limit(1).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.studentColor));
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_tree, size: 64, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text('Chưa có chương trình học cho ngành "${_majorController.text}".', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Dữ liệu sẽ được Quản trị viên cập nhật sau.', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ],
            ),
          );
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final categories = data['categories'] as List<dynamic>? ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScreenHeader(Icons.account_tree, 'CHƯƠNG TRÌNH HỌC'),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.red.shade800, borderRadius: BorderRadius.circular(4)),
                child: Text('Hệ thống Đào tạo Ngành ${_majorController.text}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              const SizedBox(height: 16),
              // Header row
              Row(
                children: [
                  const Expanded(flex: 3, child: Text('Mã Môn / Tên Môn', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Center(child: Text('Tín Chỉ', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)))),
                  Expanded(flex: 1, child: Center(child: Text('Trạng Thái', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)))),
                ],
              ),
              const Divider(color: Colors.white24, height: 32),
              ...categories.map((cat) => _buildCurriculumCategory(cat as Map<String, dynamic>)),
            ],
          ),
        );
      }
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScreenHeader(Icons.support_agent, 'CỐ VẤN HỌC TẬP'),
          const SizedBox(height: 24),
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
                    const Text('PGS. TS. Lê Văn B', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Giảng viên Khoa Công nghệ thông tin', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                    const SizedBox(height: 16),
                    _buildQuickLink(Icons.email, 'levanb@edutrack.edu.vn'),
                    const SizedBox(height: 8),
                    _buildQuickLink(Icons.phone, '0987 654 321'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Gửi tin nhắn cho Cố vấn', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit, color: Colors.white54, size: 16),
                SizedBox(width: 8),
                Text('Soạn tin nhắn...', style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.studentColor),
            child: const Text('Gửi tin nhắn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 6: Đánh giá & Khảo sát
  Widget _buildSurveyContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScreenHeader(Icons.poll, 'ĐÁNH GIÁ & KHẢO SÁT'),
          const SizedBox(height: 24),
          _buildSurveyItem('Khảo sát chất lượng giảng dạy học kỳ 1 (2026)', 'Mở đến 30/06/2026', true),
          _buildSurveyItem('Đánh giá cơ sở vật chất năm học mới', 'Mở đến 15/07/2026', true),
          _buildSurveyItem('Khảo sát mức độ hài lòng về căn tin', 'Đã đóng', false),
        ],
      ),
    );
  }

  Widget _buildSurveyItem(String title, String status, bool isOpen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment, color: isOpen ? AppColors.studentColor : Colors.grey, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(status, style: TextStyle(color: isOpen ? AppColors.studentColor : Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          if (isOpen)
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.studentColor),
              child: const Text('Tham gia', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
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
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  // 7: Học phí
  Widget _buildTuitionContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScreenHeader(Icons.monetization_on, 'THÔNG TIN HỌC PHÍ'),
          const SizedBox(height: 24),
          _buildStatBox('Tổng học phí học kỳ này', '12,500,000 VNĐ', Icons.account_balance_wallet, Colors.green),
          const SizedBox(height: 24),
          const Text('Chi tiết môn học', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTuitionItem('Công nghệ phần mềm', '3', '2,500,000 VNĐ'),
          _buildTuitionItem('Trí tuệ nhân tạo', '3', '2,500,000 VNĐ'),
          _buildTuitionItem('Kiến trúc máy tính', '3', '2,500,000 VNĐ'),
          _buildTuitionItem('Cơ sở dữ liệu', '3', '2,500,000 VNĐ'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Thanh toán học phí trực tuyến', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTuitionItem(String subject, String credits, String price) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(subject, style: const TextStyle(color: Colors.white, fontSize: 14)),
          Row(
            children: [
              Text('$credits Tín chỉ', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
              const SizedBox(width: 24),
              Text(price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Tìm kiếm tài liệu, sách, giáo trình...',
                hintStyle: TextStyle(color: Colors.white54),
                icon: Icon(Icons.search, color: Colors.white54),
              ),
              style: TextStyle(color: Colors.white),
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
          Text('$number. ', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
          ),
        ],
      ),
    );
  }

}
