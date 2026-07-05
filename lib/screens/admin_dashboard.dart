import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../theme/app_colors.dart';
import '../widgets/nature_background.dart';
import '../widgets/glass_container.dart';
import '../services/notification_service.dart';
import '../services/course_registration_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/schedule_grid.dart';
import 'welcome_screen.dart';

class AdminDashboard extends StatefulWidget {
  final String email;
  const AdminDashboard({super.key, required this.email});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _menuIndex = 0;
  final NotificationService _notiService = NotificationService();
  final CourseRegistrationService _regService = CourseRegistrationService();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();
  bool _showSuccess = false;

  // Search/Filter states
  String _adminRegYear = '2025-2026';
  String _adminRegSemester = 'Học kỳ 1';
  
  // Upload config states
  String _uploadYear = '2025-2026';
  String _uploadSemester = 'Học kỳ 1';
  String _uploadMajor = 'Kỹ thuật phần mềm';
  DateTime? _uploadDeadline;

  // Tuition Management states
  int _tuitionTab = 0; // 0: Đơn giá, 1: Tính học phí
  bool _ratesLoaded = false;
  final Map<String, TextEditingController> _creditControllers = {};
  final Map<String, TextEditingController> _courseControllers = {};
  final Map<String, TextEditingController> _baseControllers = {};
  String _calcYear = '2025-2026';
  String _calcSemester = 'Học kỳ 1';
  bool _calculating = false;
  String _tuitionSearchQuery = '';
  final TextEditingController _tuitionSearchCtrl = TextEditingController();

  final List<Map<String, dynamic>> _menus = [
    {'icon': Icons.dashboard, 'label': 'Tổng quan'},
    {'icon': Icons.campaign, 'label': 'Gửi Thông báo'},
    {'icon': Icons.history, 'label': 'Thông báo đã gửi'},
    {'icon': Icons.calendar_today, 'label': 'Quản lý lịch học'},
    {'icon': Icons.verified, 'label': 'Phê duyệt Bảng điểm'},
    {'icon': Icons.login, 'label': 'Quản lý đăng nhập'},
    {'icon': Icons.app_registration, 'label': 'Quản lý môn ĐK'},
    {'icon': Icons.analytics, 'label': 'Theo dõi ĐK'},
    {'icon': Icons.support_agent, 'label': 'Phê duyệt đổi Cố vấn'},
    {'icon': Icons.poll, 'label': 'Form Đánh giá GV'},
    {'icon': Icons.payment, 'label': 'Quản lý Học phí'},
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tuitionSearchCtrl.dispose();
    for (var ctrl in _creditControllers.values) {
      ctrl.dispose();
    }
    for (var ctrl in _courseControllers.values) {
      ctrl.dispose();
    }
    for (var ctrl in _baseControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NatureBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopNav(),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: Colors.black.withValues(alpha: 0.2),
      child: Row(
        children: [
          const Icon(Icons.school, color: AppColors.adminColor, size: 24),
          const SizedBox(width: 8),
          const Text('EduTrack', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.adminColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: const Text('Quản trị viên', style: TextStyle(color: AppColors.adminColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
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
                color: AppColors.adminColor.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.adminColor.withValues(alpha: 0.3)),
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
                        border: Border(left: sel ? const BorderSide(color: AppColors.adminColor, width: 4) : BorderSide.none),
                      ),
                      child: Row(children: [
                        Icon(m['icon'] as IconData, color: sel ? AppColors.adminColor : Colors.white54, size: 20),
                        const SizedBox(width: 12),
                        Text(m['label'] as String, style: TextStyle(color: sel ? AppColors.adminColor : Colors.white70, fontWeight: sel ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
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
          0 => _buildOverview(),
          1 => _buildSendNotification(),
          2 => _buildSentNotifications(),
          3 => _buildSchedule(),
          4 => _buildGrading(),
          5 => _buildStudentMgmt(),
          6 => _buildCourseManagement(),
          7 => _buildRegistrationTracking(),
          8 => _buildAdvisorChangeApproval(),
          9 => _buildEvaluationFormManager(),
          10 => _buildTuitionManager(),
          _ => const Center(child: Text('Chức năng đang phát triển', style: TextStyle(color: Colors.white))),
        },
      ),
    );
  }

  // --- 0: Tổng quan ---
  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(children: [
              Icon(Icons.dashboard, color: AppColors.adminColor, size: 28),
              SizedBox(width: 12),
              Text('TỔNG QUAN', style: TextStyle(color: AppColors.adminColor, fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: _statCard('Lớp đang dạy', '4', Icons.class_, Colors.blue)),
          const SizedBox(width: 16),
          Expanded(child: _statCard('Sinh viên', '156', Icons.people, AppColors.adminColor)),
          const SizedBox(width: 16),
          Expanded(child: _statCard('Thông báo đã gửi', '${_notiService.notifications.where((n) => !n.isFromLecturer).length}', Icons.campaign, Colors.orange)),
        ]),
        const SizedBox(height: 32),
        const Text('Lịch trình hệ thống', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text('Dữ liệu lịch học đang được đồng bộ cho tất cả các tài khoản.', style: TextStyle(color: Colors.white70)),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
      ]),
    );
  }

  Widget _scheduleItem(String subj, String room, String time, Color c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), border: Border(left: BorderSide(color: c, width: 4)), borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8))),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(subj, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(room, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: c.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
          child: Text(time, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ]),
    );
  }

  // --- 1: Gửi Thông báo ---
  Widget _buildSendNotification() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.campaign, color: AppColors.adminColor, size: 28),
          SizedBox(width: 12),
          Text('GỬI THÔNG BÁO MỚI', style: TextStyle(color: AppColors.adminColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Text('Thông báo sẽ được hiển thị trên trang Sinh viên trong mục "Tin tức & Thông báo"', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
        const SizedBox(height: 28),

        // Title
        const Text('Tiêu đề thông báo *', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _titleCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'VD: Thông báo lịch kiểm tra giữa kỳ',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true, fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.adminColor, width: 2)),
            prefixIcon: const Icon(Icons.title, color: AppColors.adminColor),
          ),
        ),
        const SizedBox(height: 20),

        // Content
        const Text('Nội dung thông báo *', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _contentCtrl,
          style: const TextStyle(color: Colors.white),
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Nhập nội dung chi tiết thông báo...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true, fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.adminColor, width: 2)),
          ),
        ),
        const SizedBox(height: 28),

        // Send button
        Row(children: [
          ElevatedButton.icon(
            onPressed: _sendNotification,
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Gửi thông báo', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () { _titleCtrl.clear(); _contentCtrl.clear(); },
            child: const Text('Xóa nội dung', style: TextStyle(color: Colors.white54)),
          ),
        ]),

        if (_showSuccess) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Gửi thông báo thành công!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Thông báo đã xuất hiện trên trang Sinh viên.', style: TextStyle(color: Colors.green.withValues(alpha: 0.7), fontSize: 12)),
              ])),
            ]),
          ),
        ],
      ]),
    );
  }

  void _sendNotification() {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ tiêu đề và nội dung!'), backgroundColor: Colors.red),
      );
      return;
    }
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    _notiService.addNotification(AppNotification(
      id: 'admin_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      sender: widget.email.split('@').first,
      senderRole: 'Phòng Đào tạo',
      date: dateStr,
      content: _contentCtrl.text.trim(),
      isFromLecturer: false,
    ));
    _titleCtrl.clear();
    _contentCtrl.clear();
    setState(() => _showSuccess = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSuccess = false);
    });
  }

  // --- 2: Thông báo đã gửi ---
  Widget _buildSentNotifications() {
    return StreamBuilder<List<AppNotification>>(
      stream: _notiService.stream,
      builder: (context, snapshot) {
        final sent = _notiService.notifications.where((n) => !n.isFromLecturer).toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.history, color: AppColors.adminColor, size: 28),
              SizedBox(width: 12),
              Text('THÔNG BÁO ĐÃ GỬI', style: TextStyle(color: AppColors.adminColor, fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 24),
            if (sent.isEmpty)
              Center(child: Padding(padding: const EdgeInsets.all(48), child: Column(children: [
                Icon(Icons.inbox, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('Chưa gửi thông báo nào', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
              ]))),
            ...sent.map((n) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.adminColor.withValues(alpha: 0.2))),
              child: Row(children: [
                const Icon(Icons.campaign, color: AppColors.adminColor),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(n.date, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                ])),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () {
                    _notiService.removeNotification(n.id);
                  },
                ),
              ]),
            )),
          ]),
        );
      },
    );
  }

  // --- 3: Quản lý Lịch học ---
  Widget _buildSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(children: [
                    Icon(Icons.calendar_today, color: AppColors.adminColor, size: 28),
                    SizedBox(width: 12),
                    Text('QUẢN LÝ LỊCH HỌC', style: TextStyle(color: AppColors.adminColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                  ElevatedButton.icon(
                    onPressed: () => _showUploadDialog(),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Tải lên Lịch học (CSV)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Tải lên khung lịch học cho toàn trường. Dữ liệu sẽ đồng bộ cho giảng viên và sinh viên.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('schedules').snapshots(),
            builder: (context, snapshot) {
              // Only show loading spinner on very first load, not on stream updates
              if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Chưa có dữ liệu lịch học trên hệ thống.', style: TextStyle(color: Colors.white70)),
                );
              }

              final events = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ScheduleEvent(
                  title: data['courseName'] ?? '',
                  subtitle: 'Phòng ${data['room']} - Lớp ${data['studentClass']}\nGV: ${data['lecturerEmail']}',
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
              const Icon(Icons.cloud_upload, size: 64, color: AppColors.adminColor),
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
                      Text('Nhấn để chọn file CSV', style: TextStyle(color: Colors.white54)),
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

        for (var row in dataRows) {
          if (row.length < 7) continue;
          
          final courseName = row[0].toString();
          final room = row[1].toString();
          final dayOfWeek = int.tryParse(row[2].toString()) ?? 2;
          final startHour = double.tryParse(row[3].toString()) ?? 7.0;
          final duration = double.tryParse(row[4].toString()) ?? 2.0;
          final lecturerEmail = row[5].toString();
          final studentClass = row[6].toString();

          final id = '${courseName}_${room}_${dayOfWeek}_$startHour'.replaceAll(' ', '_');

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

  // --- 4: Phê duyệt Bảng điểm ---
  Widget _buildGrading() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.verified, color: AppColors.adminColor, size: 28),
                SizedBox(width: 12),
                Text('PHÊ DUYỆT BẢNG ĐIỂM', style: TextStyle(color: AppColors.adminColor, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              Row(children: [
                _filterDropdown('Năm học', _adminRegYear, ['2024-2025', '2025-2026', '2026-2027'], (v) {
                  setState(() { _adminRegYear = v!; });
                }),
                const SizedBox(width: 12),
                _filterDropdown('Học kỳ', _adminRegSemester, ['Học kỳ 1', 'Học kỳ 2', 'Học kỳ Hè'], (v) {
                  setState(() { _adminRegSemester = v!; });
                }),
              ]),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('registrations')
                .where('semester', isEqualTo: _adminRegSemester)
                .where('academicYear', isEqualTo: _adminRegYear)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              
              // Lọc các lớp có status >= lecturer_submitted
              final Map<String, List<QueryDocumentSnapshot>> courseMap = {};
              for (var doc in docs) {
                final d = doc.data() as Map<String, dynamic>;
                final status = d['gradeStatus'] ?? 'none';
                if (status == 'lecturer_submitted' || status == 'admin_published') {
                  final cId = d['courseDocId'] ?? '';
                  if (!courseMap.containsKey(cId)) courseMap[cId] = [];
                  courseMap[cId]!.add(doc);
                }
              }

              if (courseMap.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.inbox, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('Chưa có bảng điểm nào được Giảng viên gửi lên', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                ]));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: courseMap.length,
                itemBuilder: (context, index) {
                  final courseDocId = courseMap.keys.elementAt(index);
                  final students = courseMap[courseDocId]!;
                  final courseData = students.first.data() as Map<String, dynamic>;
                  
                  final courseName = courseData['courseName'] ?? 'Unknown';
                  final classGroup = courseData['classGroup'] ?? '';
                  final cId = courseData['courseId'] ?? '';
                  final lecturer = courseData['lecturerEmail'] ?? '';
                  
                  bool isPublished = students.every((s) => (s.data() as Map<String,dynamic>)['gradeStatus'] == 'admin_published');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: isPublished ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                          child: Icon(isPublished ? Icons.check_circle : Icons.pending_actions, color: isPublished ? Colors.green : Colors.orange),
                        ),
                        title: Text('$courseName ($classGroup)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('Mã MH: $cId  |  Sĩ số: ${students.length}  |  GV: $lecturer', style: const TextStyle(color: Colors.white70)),
                        ),
                        children: [
                          Container(
                            color: Colors.black12,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Chi tiết điểm:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    if (!isPublished) ElevatedButton.icon(
                                      onPressed: () async {
                                        showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                                        await _regService.calculateAndPublishCourseGrades(courseDocId);
                                        if (mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tính tổng điểm và công bố cho Sinh viên!'), backgroundColor: Colors.green));
                                        }
                                      },
                                      icon: const Icon(Icons.calculate),
                                      label: const Text('Tính Tổng & Công Bố'),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor, foregroundColor: Colors.white),
                                    ) else const Text('Đã Công Bố Cho SV', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...students.map((doc) {
                                  final d = doc.data() as Map<String, dynamic>;
                                  final uid = d['userId'] ?? '';
                                  final att = d['attendanceScore']?.toString() ?? '-';
                                  final mid = d['midtermScore']?.toString() ?? '-';
                                  final fin = d['finalScore']?.toString() ?? '-';
                                  final tot = d['total10']?.toString() ?? '-';
                                  final let = d['letterGrade'] ?? '-';
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 2, child: Text(uid, style: const TextStyle(color: Colors.white))),
                                        Expanded(child: Text('CC: $att', style: const TextStyle(color: Colors.white70))),
                                        Expanded(child: Text('GK: $mid', style: const TextStyle(color: Colors.white70))),
                                        Expanded(child: Text('CK: $fin', style: const TextStyle(color: Colors.white70))),
                                        Expanded(child: Text('Tổng: $tot', style: TextStyle(color: isPublished ? Colors.greenAccent : Colors.white54, fontWeight: FontWeight.bold))),
                                        Expanded(child: Text('Đ: $let', style: TextStyle(color: isPublished ? Colors.yellow : Colors.white54, fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          )
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

  // --- 5: Quản lý Đăng nhập ---
  Widget _buildStudentMgmt() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('users').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.adminColor));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.white70)));
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('Không có dữ liệu', style: TextStyle(color: Colors.white70)));
        }

        final allUsers = snapshot.data!.docs.map((doc) => {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>
        }).toList();

        final students = allUsers.where((u) => u['role'] == 'student').toList();
        final lecturers = allUsers.where((u) => u['role'] == 'lecturer').toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.login, color: AppColors.adminColor, size: 28),
              SizedBox(width: 12),
              Text('QUẢN LÝ ĐĂNG NHẬP', style: TextStyle(color: AppColors.adminColor, fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 24),

            // Students Table
            _buildUserTable('Danh sách Sinh viên', students, Icons.school),
            const SizedBox(height: 32),

            // Lecturers Table
            _buildUserTable('Danh sách Giảng viên', lecturers, Icons.person),
          ]),
        );
      },
    );
  }

  Widget _buildUserTable(String title, List<Map<String, dynamic>> users, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: AppColors.adminColor, size: 24),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.adminColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${users.length}', style: const TextStyle(color: AppColors.adminColor, fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: users.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Không có dữ liệu', style: TextStyle(color: Colors.white70))),
                )
              : Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.adminColor.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 2, child: Text('Họ tên', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Email', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('Vai trò', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Đăng nhập cuối', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    // Rows
                    ...users.map((user) => _buildUserRow(user)),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user) {
    final fullName = user['fullName'] ?? 'N/A';
    final email = user['email'] ?? 'N/A';
    final role = user['role'] ?? 'N/A';
    final userId = user['id'] as String?;

    return FutureBuilder<DatabaseEvent>(
      future: FirebaseDatabase.instance.ref('users/$userId/lastLogin').once(),
      builder: (context, snapshot) {
        String lastLoginText = 'Chưa đăng nhập';
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final timestamp = snapshot.data!.snapshot.value as int?;
          if (timestamp != null) {
            final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
            lastLoginText = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          ),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text(fullName, style: const TextStyle(color: Colors.white))),
              Expanded(flex: 2, child: Text(email, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13))),
              Expanded(flex: 1, child: Text(role, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12))),
              Expanded(flex: 2, child: Text(lastLoginText, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12))),
              if (role == 'student' && userId != null) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showCancelCreditsDialog(userId, fullName),
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('Hủy tín chỉ', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCancelCreditsDialog(String userId, String studentName) async {
    // Get student's registered courses
    final snapshot = await FirebaseFirestore.instance
        .collection('registrations')
        .where('userId', isEqualTo: userId)
        .get();

    if (snapshot.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sinh viên chưa đăng ký môn học nào'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final registrations = snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>
    }).toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a2a1f),
        title: Text('Hủy tín chỉ - $studentName', style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chọn môn học để hủy:', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ...registrations.map((reg) => ListTile(
                title: Text(reg['courseName'] ?? 'N/A', style: const TextStyle(color: Colors.white)),
                subtitle: Text('${reg['classGroup'] ?? 'N/A'} - ${reg['semester'] ?? 'N/A'}', 
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmCancelCredit(reg['id'], reg['courseName']);
                  },
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancelCredit(String registrationId, String courseName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a2a1f),
        title: const Text('Xác nhận hủy tín chỉ', style: TextStyle(color: Colors.white)),
        content: Text('Bạn có chắc muốn hủy môn "$courseName"?\n\nHành động này không thể hoàn tác.', 
          style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xác nhận hủy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('registrations').doc(registrationId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã hủy môn $courseName'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- 6: Quản lý Môn Đăng Ký ---
  Widget _buildCourseManagement() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.app_registration, color: AppColors.adminColor, size: 28),
                SizedBox(width: 12),
                Text('QUẢN LÝ MÔN ĐĂNG KÝ', style: TextStyle(color: AppColors.adminColor, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              Row(children: [
                _filterDropdown('Năm học', _adminRegYear, ['2024-2025', '2025-2026', '2026-2027'], (v) => setState(() => _adminRegYear = v!)),
                const SizedBox(width: 12),
                _filterDropdown('Học kỳ', _adminRegSemester, ['Học kỳ 1', 'Học kỳ 2', 'Học kỳ Hè'], (v) => setState(() => _adminRegSemester = v!)),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showCourseUploadDialog(),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Tải lên DS Môn ĐK (CSV)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ]),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _regService.getAllCoursesStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final allDocs = snapshot.data?.docs ?? [];
              
              // Client-side filtering cho Admin
              final docs = allDocs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return d['semester'] == _adminRegSemester && d['academicYear'] == _adminRegYear;
              }).toList();
              
              if (docs.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.inbox, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('Chưa có môn nào cho $_adminRegSemester - $_adminRegYear', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                  const SizedBox(height: 16),
                  const Text('Nhấn "Tải lên DS Môn ĐK (CSV)" để tải dữ liệu lên.', style: TextStyle(color: Colors.white38, fontSize: 13)),
                ]));
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.05)),
                    dataRowColor: WidgetStateProperty.all(Colors.transparent),
                    columns: const [
                      DataColumn(label: Text('Mã Môn', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Tên Môn', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('TC', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Giảng viên', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Thời gian', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Phòng', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Slot', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Trạng thái', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Thao tác', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                    ],
                    rows: docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final current = (d['currentSlots'] as num?)?.toInt() ?? 0;
                      final max = (d['maxSlots'] as num?)?.toInt() ?? 0;
                      final pct = max > 0 ? current / max : 0.0;
                      return DataRow(cells: [
                        DataCell(Text(d['courseId'] ?? '', style: TextStyle(color: Colors.blue.shade300, fontWeight: FontWeight.w600))),
                        DataCell(Text(d['courseName'] ?? '', style: const TextStyle(color: Colors.white))),
                        DataCell(Text('${d['credits'] ?? ''}', style: const TextStyle(color: Colors.white))),
                        DataCell(Text(d['lecturerName'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13))),
                        DataCell(Text('Thứ ${d['dayOfWeek']} | ${_fmtHour((d['startHour'] as num?)?.toDouble() ?? 7)}-${_fmtHour(((d['startHour'] as num?)?.toDouble() ?? 7) + ((d['duration'] as num?)?.toDouble() ?? 2))}', style: const TextStyle(color: Colors.white70, fontSize: 13))),
                        DataCell(Text(d['room'] ?? '', style: const TextStyle(color: Colors.white70))),
                        DataCell(Row(children: [
                          Text('$current/$max', style: TextStyle(color: pct >= 1.0 ? Colors.red : Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          SizedBox(width: 50, child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: Colors.white.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation(pct >= 1.0 ? Colors.red : AppColors.adminColor)))),
                        ])),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: d['status'] == 'open' ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                          child: Text(d['status'] == 'open' ? 'Mở' : 'Đóng', style: TextStyle(color: d['status'] == 'open' ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                        )),
                        DataCell(Row(children: [
                          IconButton(icon: Icon(d['status'] == 'open' ? Icons.lock : Icons.lock_open, color: Colors.orange, size: 18), onPressed: () => _regService.toggleCourseStatus(doc.id, d['status'] == 'open' ? 'closed' : 'open'), tooltip: d['status'] == 'open' ? 'Đóng ĐK' : 'Mở ĐK'),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () => _confirmDeleteCourse(doc.id, d['courseName'] ?? ''), tooltip: 'Xóa'),
                        ])),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDeleteCourse(String docId, String name) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1a2a1f),
      title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
      content: Text('Bạn có chắc muốn xóa môn "$name"?\nTất cả đăng ký liên quan sẽ bị xóa.', style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.white54))),
        ElevatedButton(onPressed: () async { Navigator.pop(ctx); await _regService.deleteCourse(docId); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Xóa', style: TextStyle(color: Colors.white))),
      ],
    ));
  }

  Widget _filterDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF1a2a1f),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _fmtHour(double h) {
    final hr = h.floor();
    final min = ((h - hr) * 60).round();
    return '${hr.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  // --- 7: Theo dõi Đăng ký ---
  Widget _buildRegistrationTracking() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.analytics, color: AppColors.adminColor, size: 28),
                SizedBox(width: 12),
                Text('THEO DÕI ĐĂNG KÝ', style: TextStyle(color: AppColors.adminColor, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              Row(children: [
                _filterDropdown('Năm học', _adminRegYear, ['2024-2025', '2025-2026', '2026-2027'], (v) => setState(() => _adminRegYear = v!)),
                const SizedBox(width: 12),
                _filterDropdown('Học kỳ', _adminRegSemester, ['Học kỳ 1', 'Học kỳ 2', 'Học kỳ Hè'], (v) => setState(() => _adminRegSemester = v!)),
              ]),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _regService.getAllRegistrationsStream(semester: _adminRegSemester, academicYear: _adminRegYear),
            builder: (context, snapshot) {
              if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(child: Text('Chưa có lượt đăng ký nào trong $_adminRegSemester - $_adminRegYear', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))));
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.05)),
                    dataRowColor: WidgetStateProperty.all(Colors.transparent),
                    columns: const [
                      DataColumn(label: Text('Thời gian ĐK', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Mã SV', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Tên SV', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Mã Môn', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Tên Môn', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                    ],
                    rows: docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final ts = d['registeredAt'] as Timestamp?;
                      final dt = ts?.toDate() ?? DateTime.now();
                      return DataRow(cells: [
                        DataCell(Text('${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2,'0')}', style: const TextStyle(color: Colors.white70))),
                        DataCell(Text(d['studentId'] ?? '', style: TextStyle(color: Colors.blue.shade300))),
                        DataCell(Text(d['studentName'] ?? '', style: const TextStyle(color: Colors.white))),
                        DataCell(Text(d['courseId'] ?? '', style: const TextStyle(color: Colors.white70))),
                        DataCell(Text(d['courseName'] ?? '', style: const TextStyle(color: Colors.white))),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ====== UPLOAD COURSES ======
  void _showCourseUploadDialog() {
    _uploadYear = _adminRegYear;
    _uploadSemester = _adminRegSemester;
    _uploadMajor = 'Kỹ thuật phần mềm';
    _uploadDeadline = DateTime.now().add(const Duration(days: 7)); // Default +7 days
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1a2a1f),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.cloud_upload, size: 48, color: AppColors.adminColor),
                      SizedBox(height: 16),
                      Text('Tải lên Danh sách Môn học (CSV)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Form fields
                _buildUploadField('Năm học', DropdownButton<String>(
                  value: _uploadYear,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1a2a1f),
                  style: const TextStyle(color: Colors.white),
                  items: ['2024-2025', '2025-2026', '2026-2027'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setDialogState(() => _uploadYear = v!),
                )),
                const SizedBox(height: 12),
                _buildUploadField('Học kỳ', DropdownButton<String>(
                  value: _uploadSemester,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1a2a1f),
                  style: const TextStyle(color: Colors.white),
                  items: ['Học kỳ 1', 'Học kỳ 2', 'Học kỳ Hè'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setDialogState(() => _uploadSemester = v!),
                )),
                const SizedBox(height: 12),
                _buildUploadField('Ngành học', DropdownButton<String>(
                  value: _uploadMajor,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1a2a1f),
                  style: const TextStyle(color: Colors.white),
                  items: ['Kỹ thuật phần mềm', 'Hệ thống thông tin', 'Khoa học máy tính', 'An toàn thông tin'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setDialogState(() => _uploadMajor = v!),
                )),
                const SizedBox(height: 12),
                _buildUploadField('Hạn đăng ký', GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _uploadDeadline ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_uploadDeadline ?? DateTime.now()),
                      );
                      if (time != null) {
                        setDialogState(() {
                          _uploadDeadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        });
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
                    child: Text(_uploadDeadline != null ? '${_uploadDeadline!.day}/${_uploadDeadline!.month}/${_uploadDeadline!.year} ${_uploadDeadline!.hour.toString().padLeft(2,'0')}:${_uploadDeadline!.minute.toString().padLeft(2,'0')}' : 'Chọn thời hạn', style: const TextStyle(color: Colors.white)),
                  ),
                )),
                const SizedBox(height: 24),
                
                GestureDetector(
                  onTap: () async {
                    await _handleCourseFileUpload(ctx);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.adminColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.adminColor.withValues(alpha: 0.5)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.file_upload, color: AppColors.adminColor, size: 24),
                        SizedBox(height: 8),
                        Text('Nhấn để chọn file CSV', style: TextStyle(color: AppColors.adminColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadField(String label, Widget child) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
        Expanded(child: child),
      ],
    );
  }

  Future<void> _handleCourseFileUpload(BuildContext ctx) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có file nào được chọn'), backgroundColor: Colors.orange),
        );
        return;
      }

      final file = result.files.single;
      final fileName = file.name.toLowerCase();

      if (!fileName.endsWith('.csv')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn file .csv'), backgroundColor: Colors.red),
        );
        return;
      }

      if (file.bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không đọc được nội dung file'), backgroundColor: Colors.red),
        );
        return;
      }

      final bytes = file.bytes!;
      final csvString = utf8.decode(bytes, allowMalformed: true);
      var rows = const CsvDecoder().convert(csvString);
      
      // Thử delimiter ';' nếu ',' không đúng
      if (rows.isNotEmpty && rows.first.length < 11) {
        rows = const CsvDecoder(fieldDelimiter: ';').convert(csvString);
      }

      if (rows.isEmpty || rows.length <= 1) {
        throw Exception('File rỗng hoặc không có dữ liệu (cần ít nhất 1 header + 1 data row)');
      }

      final dataRows = rows.skip(1).toList(); // Bỏ dòng header
      final firestore = FirebaseFirestore.instance;
      
      // Hiện loading
      showDialog(context: ctx, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

      int uploadedCount = 0;
      int skippedCount = 0;

      for (var row in dataRows) {
        if (row.length < 11) {
          skippedCount++;
          continue;
        }
        
        final courseId = row[0].toString().trim();
        final courseName = row[1].toString().trim();
        final credits = int.tryParse(row[2].toString().trim()) ?? 3;
        final classGroup = row[3].toString().trim();
        final lecturerName = row[4].toString().trim();
        final lecturerEmail = row[5].toString().trim();
        final maxSlots = int.tryParse(row[6].toString().trim()) ?? 40;
        final dayOfWeek = int.tryParse(row[7].toString().trim()) ?? 2;
        final startHour = double.tryParse(row[8].toString().trim()) ?? 7.0;
        final duration = double.tryParse(row[9].toString().trim()) ?? 3.0;
        final room = row[10].toString().trim();

        if (courseId.isEmpty || courseName.isEmpty) {
          skippedCount++;
          continue;
        }

        await firestore.collection('available_courses').add({
          'courseId': courseId,
          'courseName': courseName,
          'credits': credits,
          'classGroup': classGroup,
          'lecturerName': lecturerName,
          'lecturerEmail': lecturerEmail,
          'maxSlots': maxSlots,
          'currentSlots': 0,
          'dayOfWeek': dayOfWeek,
          'startHour': startHour,
          'duration': duration,
          'room': room,
          'semester': _uploadSemester,
          'academicYear': _uploadYear,
          'major': _uploadMajor,
          'status': 'open',
          'registrationDeadline': _uploadDeadline != null ? Timestamp.fromDate(_uploadDeadline!) : null,
        });
        uploadedCount++;
      }
      
      if (ctx.mounted) Navigator.pop(ctx); // close loading
      if (ctx.mounted) Navigator.pop(ctx); // close dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tải lên thành công $uploadedCount môn học (bỏ qua $skippedCount dòng lỗi) vào $_uploadSemester $_uploadYear ngành $_uploadMajor'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      // Cố gắng pop loading nếu đang hiện
      try { if (ctx.mounted) Navigator.pop(ctx); } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải file: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 8)),
      );
    }
  }

  // --- 8: Phê duyệt đổi Cố vấn ---
  Widget _buildAdvisorChangeApproval() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('advisor_change_requests')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.adminColor));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.white70)));
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('Không có dữ liệu', style: TextStyle(color: Colors.white70)));
        }

        final allRequests = snapshot.data!.docs.map((doc) => {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>
        }).toList();

        // Filter and sort on client side
        final requests = allRequests
            .where((req) => req['status'] == 'pending')
            .toList()
          ..sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

        if (requests.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('Không có yêu cầu nào đang chờ phê duyệt', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.support_agent, color: AppColors.adminColor, size: 28),
                SizedBox(width: 12),
                Text('PHÊ DUYỆT ĐỔI CỐ VẤN', style: TextStyle(color: AppColors.adminColor, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 16),
              Text('Danh sách yêu cầu đổi cố vấn đang chờ phê duyệt', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
              const SizedBox(height: 24),
              
              if (requests.isEmpty) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.white24),
                        SizedBox(height: 16),
                        Text('Không có yêu cầu nào đang chờ phê duyệt', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ...requests.map((req) => _buildAdvisorRequestItem(req)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdvisorRequestItem(Map<String, dynamic> req) {
    final userName = req['userName'] ?? 'N/A';
    final userEmail = req['userEmail'] ?? 'N/A';
    final newAdvisorName = req['newAdvisorName'] ?? 'N/A';
    final createdAt = req['createdAt'] as Timestamp?;
    final dateStr = createdAt != null 
        ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year} ${createdAt.toDate().hour}:${createdAt.toDate().minute.toString().padLeft(2, '0')}'
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.adminColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person, color: AppColors.adminColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(userEmail, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Đang chờ', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.arrow_forward, size: 16, color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Text('Muốn đổi sang: ', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
              Text(newAdvisorName, style: const TextStyle(color: AppColors.adminColor, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Ngày gửi: $dateStr', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _rejectAdvisorChange(req['id'], req['userId']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Từ chối', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _approveAdvisorChange(req['id'], req['userId'], req['newAdvisorId']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Phê duyệt', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approveAdvisorChange(String requestId, String userId, String newAdvisorId) async {
    try {
      // Update request status
      await FirebaseFirestore.instance.collection('advisor_change_requests').doc(requestId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Update user's advisor
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'advisorId': newAdvisorId,
        'pendingAdvisorChange': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã phê duyệt yêu cầu đổi cố vấn'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectAdvisorChange(String requestId, String userId) async {
    try {
      // Update request status
      await FirebaseFirestore.instance.collection('advisor_change_requests').doc(requestId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      // Remove pending flag from user
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'pendingAdvisorChange': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã từ chối yêu cầu đổi cố vấn'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- 9: Form Đánh giá GV ---
  Widget _buildEvaluationFormManager() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.poll, color: AppColors.adminColor, size: 28),
                SizedBox(width: 12),
                Text('QUẢN LÝ FORM ĐÁNH GIÁ GIẢNG VIÊN', style: TextStyle(color: AppColors.adminColor, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              ElevatedButton.icon(
                onPressed: () => _showCreateEvalFormDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tạo Form mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('Tạo và quản lý các bộ câu hỏi đánh giá giảng viên. Sinh viên sẽ trả lời dưới dạng trắc nghiệm.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('evaluation_forms').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.adminColor));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.inbox, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('Chưa có form đánh giá nào. Nhấn "Tạo Form mới" để bắt đầu.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                ]));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['title'] ?? 'Không có tiêu đề';
                  final year = data['academicYear'] ?? '';
                  final sem = data['semester'] ?? '';
                  final questions = (data['questions'] as List<dynamic>?) ?? [];
                  final isActive = data['isActive'] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isActive ? AppColors.adminColor.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive ? AppColors.adminColor.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                          child: Icon(Icons.poll, color: isActive ? AppColors.adminColor : Colors.grey),
                        ),
                        title: Row(children: [
                          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                              child: const Text('Đang kích hoạt', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                        ]),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('$year | $sem | ${questions.length} câu hỏi', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ),
                        children: [
                          Container(
                            color: Colors.black12,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...questions.asMap().entries.map((entry) {
                                  final q = entry.value as Map<String, dynamic>;
                                  final qText = q['text'] ?? '';
                                  final options = (q['options'] as List<dynamic>?) ?? [];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Câu ${entry.key + 1}: $qText', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      ...options.map((opt) => Padding(
                                        padding: const EdgeInsets.only(left: 16, top: 2),
                                        child: Row(children: [
                                          Icon(Icons.radio_button_unchecked, color: Colors.white38, size: 14),
                                          const SizedBox(width: 6),
                                          Text(opt.toString(), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                        ]),
                                      )),
                                    ]),
                                  );
                                }),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (!isActive)
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          // Deactivate all other forms first
                                          final allForms = await FirebaseFirestore.instance.collection('evaluation_forms').get();
                                          for (var f in allForms.docs) {
                                            await f.reference.update({'isActive': false});
                                          }
                                          await doc.reference.update({'isActive': true});
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Đã kích hoạt form đánh giá!'), backgroundColor: Colors.green),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.check_circle, size: 16),
                                        label: const Text('Kích hoạt'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                                      ),
                                    if (isActive)
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          await doc.reference.update({'isActive': false});
                                        },
                                        icon: const Icon(Icons.pause_circle, size: 16),
                                        label: const Text('Tắt'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                                      ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: const Color(0xFF1a2a1f),
                                            title: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
                                            content: const Text('Xóa form đánh giá này?', style: TextStyle(color: Colors.white70)),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: Colors.white54))),
                                              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Xóa', style: TextStyle(color: Colors.white))),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await doc.reference.delete();
                                        }
                                      },
                                      icon: const Icon(Icons.delete, size: 16),
                                      label: const Text('Xóa'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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

  void _showCreateEvalFormDialog() {
    final titleCtrl = TextEditingController();
    String year = '2026-2027';
    String semester = 'Học kỳ 1';
    final List<Map<String, dynamic>> questions = [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: const Color(0xFF1a2a1f),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 650,
              constraints: const BoxConstraints(maxHeight: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.adminColor.withValues(alpha: 0.15),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.poll, color: AppColors.adminColor, size: 24),
                      const SizedBox(width: 12),
                      const Text('TẠO FORM ĐÁNH GIÁ GIẢNG VIÊN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                    ]),
                  ),
                  // Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          const Text('Tiêu đề form *', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: titleCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'VD: Khảo sát chất lượng giảng dạy HK1 2025-2026',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                              filled: true, fillColor: Colors.white.withValues(alpha: 0.08),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Year & Semester
                          Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Năm học', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: year,
                                dropdownColor: const Color(0xFF1a2a1f),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(filled: true, fillColor: Colors.white.withValues(alpha: 0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                                items: ['2024-2025', '2025-2026', '2026-2027', '2027-2028'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                                onChanged: (v) => setDialogState(() => year = v!),
                              ),
                            ])),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Học kỳ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: semester,
                                dropdownColor: const Color(0xFF1a2a1f),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(filled: true, fillColor: Colors.white.withValues(alpha: 0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                                items: ['Học kỳ 1', 'Học kỳ 2', 'Học kỳ Hè'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                                onChanged: (v) => setDialogState(() => semester = v!),
                              ),
                            ])),
                          ]),
                          const SizedBox(height: 20),
                          // Questions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Danh sách câu hỏi (${questions.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              TextButton.icon(
                                onPressed: () {
                                  setDialogState(() {
                                    questions.add({
                                      'text': '',
                                      'options': ['Hoàn toàn đồng ý', 'Đồng ý', 'Bình thường', 'Không đồng ý', 'Hoàn toàn không đồng ý'],
                                    });
                                  });
                                },
                                icon: const Icon(Icons.add_circle, color: AppColors.adminColor, size: 18),
                                label: const Text('Thêm câu hỏi', style: TextStyle(color: AppColors.adminColor)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (questions.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                              child: const Center(child: Text('Chưa có câu hỏi nào. Nhấn "Thêm câu hỏi" ở trên.', style: TextStyle(color: Colors.white38))),
                            ),
                          ...questions.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final q = entry.value;
                            final textCtrl = TextEditingController(text: q['text'] ?? '');
                            final opts = List<String>.from(q['options'] ?? []);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    CircleAvatar(radius: 12, backgroundColor: AppColors.adminColor.withValues(alpha: 0.3), child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                                    const SizedBox(width: 8),
                                    const Text('Nội dung câu hỏi:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                      onPressed: () => setDialogState(() => questions.removeAt(idx)),
                                      padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                                    ),
                                  ]),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: textCtrl,
                                    onChanged: (val) => questions[idx]['text'] = val,
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: 'VD: Giảng viên truyền đạt kiến thức rõ ràng, dễ hiểu',
                                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 12),
                                      filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Các lựa chọn (mỗi dòng 1 đáp án):', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  ...opts.asMap().entries.map((oEntry) {
                                    final oIdx = oEntry.key;
                                    final oCtrl = TextEditingController(text: oEntry.value);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(children: [
                                        const Icon(Icons.radio_button_unchecked, color: Colors.white30, size: 14),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: TextField(
                                            controller: oCtrl,
                                            onChanged: (val) {
                                              (questions[idx]['options'] as List)[oIdx] = val;
                                            },
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              filled: true, fillColor: Colors.white.withValues(alpha: 0.03),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 16),
                                          onPressed: () => setDialogState(() => (questions[idx]['options'] as List).removeAt(oIdx)),
                                          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                                        ),
                                      ]),
                                    );
                                  }),
                                  TextButton.icon(
                                    onPressed: () => setDialogState(() => (questions[idx]['options'] as List).add('Đáp án mới')),
                                    icon: const Icon(Icons.add, size: 14, color: Colors.white54),
                                    label: const Text('Thêm đáp án', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 24)),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.white54))),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (titleCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tiêu đề'), backgroundColor: Colors.red));
                              return;
                            }
                            if (questions.isEmpty || questions.any((q) => (q['text'] ?? '').toString().trim().isEmpty)) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập nội dung cho tất cả câu hỏi'), backgroundColor: Colors.red));
                              return;
                            }

                            await FirebaseFirestore.instance.collection('evaluation_forms').add({
                              'title': titleCtrl.text.trim(),
                              'academicYear': year,
                              'semester': semester,
                              'questions': questions.map((q) => {
                                'text': q['text'],
                                'options': List<String>.from(q['options'] ?? []),
                              }).toList(),
                              'isActive': false,
                              'createdAt': FieldValue.serverTimestamp(),
                              'createdBy': widget.email,
                            });

                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã tạo form đánh giá thành công!'), backgroundColor: Colors.green),
                              );
                            }
                          },
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Lưu Form'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.adminColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ====== TUITION MANAGEMENT METHODS ======
  Future<void> _loadRates() async {
    if (_ratesLoaded) return;
    final snapshot = await FirebaseFirestore.instance.collection('tuition_rates').get();
    final majors = ['Kỹ thuật phần mềm', 'Hệ thống thông tin', 'Khoa học máy tính', 'An toàn thông tin', 'Mặc định'];
    
    final defaultRates = {
      'Kỹ thuật phần mềm': {'credit': 480000, 'course': 150000, 'base': 1200000},
      'Hệ thống thông tin': {'credit': 450000, 'course': 150000, 'base': 1200000},
      'Khoa học máy tính': {'credit': 460000, 'course': 150000, 'base': 1200000},
      'An toàn thông tin': {'credit': 470000, 'course': 150000, 'base': 1200000},
      'Mặc định': {'credit': 450000, 'course': 150000, 'base': 1000000},
    };

    for (var major in majors) {
      int cVal = defaultRates[major]?['credit'] ?? 450000;
      int coVal = defaultRates[major]?['course'] ?? 150000;
      int bVal = defaultRates[major]?['base'] ?? 1000000;

      final match = snapshot.docs.where((d) => d.id == major).toList();
      if (match.isNotEmpty) {
        final data = match.first.data();
        cVal = data['creditRate'] ?? cVal;
        coVal = data['courseRate'] ?? coVal;
        bVal = data['baseFee'] ?? bVal;
      }

      _creditControllers[major] = TextEditingController(text: cVal.toString());
      _courseControllers[major] = TextEditingController(text: coVal.toString());
      _baseControllers[major] = TextEditingController(text: bVal.toString());
    }

    if (mounted) {
      setState(() {
        _ratesLoaded = true;
      });
    }
  }

  Future<void> _saveRates() async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var major in _creditControllers.keys) {
        final cRef = FirebaseFirestore.instance.collection('tuition_rates').doc(major);
        batch.set(cRef, {
          'major': major,
          'creditRate': int.tryParse(_creditControllers[major]!.text.trim()) ?? 0,
          'courseRate': int.tryParse(_courseControllers[major]!.text.trim()) ?? 0,
          'baseFee': int.tryParse(_baseControllers[major]!.text.trim()) ?? 0,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu đơn giá học phí thành công!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu đơn giá: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _calculateAllStudentsTuition() async {
    setState(() => _calculating = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final ratesSnapshot = await FirebaseFirestore.instance.collection('tuition_rates').get();
      final rates = <String, Map<String, int>>{};
      for (var doc in ratesSnapshot.docs) {
        final data = doc.data();
        rates[doc.id] = {
          'creditRate': data['creditRate'] ?? 450000,
          'courseRate': data['courseRate'] ?? 150000,
          'baseFee': data['baseFee'] ?? 1000000,
        };
      }

      Map<String, int> getRatesForMajor(String? major) {
        final m = major ?? 'Mặc định';
        if (rates.containsKey(m)) return rates[m]!;
        if (rates.containsKey('Mặc định')) return rates['Mặc định']!;
        return {'creditRate': 450000, 'courseRate': 150000, 'baseFee': 1000000};
      }

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      final regsSnapshot = await FirebaseFirestore.instance
          .collection('registrations')
          .where('academicYear', isEqualTo: _calcYear)
          .where('semester', isEqualTo: _calcSemester)
          .get();

      final regsByUser = <String, List<QueryDocumentSnapshot>>{};
      for (var doc in regsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final uid = data['userId'] ?? '';
        if (uid.isNotEmpty) {
          if (!regsByUser.containsKey(uid)) regsByUser[uid] = [];
          regsByUser[uid]!.add(doc);
        }
      }

      final existingSnapshot = await FirebaseFirestore.instance
          .collection('tuition_fees')
          .where('academicYear', isEqualTo: _calcYear)
          .where('semester', isEqualTo: _calcSemester)
          .get();
      
      final existingStatus = <String, String>{};
      for (var doc in existingSnapshot.docs) {
        existingStatus[doc.id] = doc.data()['status'] ?? 'unpaid';
      }

      final batch = FirebaseFirestore.instance.batch();
      int successCount = 0;

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final uid = userDoc.id;
        final studentName = userData['fullName'] ?? 'N/A';
        final studentEmail = userData['email'] ?? 'N/A';
        final studentCardId = userData['studentId'] ?? 'N/A';
        final studentMajor = userData['major'] ?? 'Mặc định';

        final userRegs = regsByUser[uid] ?? [];
        if (userRegs.isEmpty) {
          continue;
        }

        int totalCredits = 0;
        final coursesList = <Map<String, dynamic>>[];
        final studentRates = getRatesForMajor(studentMajor);
        final cRate = studentRates['creditRate']!;
        final coRate = studentRates['courseRate']!;
        final bFee = studentRates['baseFee']!;

        for (var regDoc in userRegs) {
          final regData = regDoc.data() as Map<String, dynamic>;
          final cCredits = (regData['credits'] as num?)?.toInt() ?? 3;
          final courseName = regData['courseName'] ?? 'N/A';
          final courseId = regData['courseId'] ?? 'N/A';
          totalCredits += cCredits;

          final courseTuition = (cCredits * cRate) + coRate;
          coursesList.add({
            'courseId': courseId,
            'courseName': courseName,
            'credits': cCredits,
            'tuition': courseTuition,
          });
        }

        final int totalTuition = (totalCredits * cRate) + (userRegs.length * coRate) + bFee;
        final invoiceDocId = '${uid}_${_calcYear}_${_calcSemester}'.replaceAll(' ', '_');
        final currentStatus = existingStatus[invoiceDocId] ?? 'unpaid';
        final invoiceRef = FirebaseFirestore.instance.collection('tuition_fees').doc(invoiceDocId);
        
        batch.set(invoiceRef, {
          'studentId': uid,
          'studentName': studentName,
          'studentEmail': studentEmail,
          'studentCardId': studentCardId,
          'major': studentMajor,
          'academicYear': _calcYear,
          'semester': _calcSemester,
          'creditsCount': totalCredits,
          'coursesCount': userRegs.length,
          'baseFee': bFee,
          'courses': coursesList,
          'totalAmount': totalTuition,
          'status': currentStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        successCount++;
      }

      await batch.commit();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tính học phí cho $successCount sinh viên thành công!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tính học phí: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _calculating = false);
      }
    }
  }

  Widget _buildTuitionManager() {
    _loadRates();
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.payment, color: AppColors.adminColor, size: 28),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('QUẢN LÝ HỌC PHÍ', style: TextStyle(color: AppColors.adminColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Thiết lập định mức học phí & tính hóa đơn sinh viên', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _tabButton(0, 'Định mức & Đơn giá', Icons.settings),
                    _tabButton(1, 'Hóa đơn học phí', Icons.receipt_long),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: !_ratesLoaded
              ? const Center(child: CircularProgressIndicator(color: AppColors.adminColor))
              : _tuitionTab == 0
                  ? _buildRatesTab()
                  : _buildBillingTab(),
        ),
      ],
    );
  }

  Widget _tabButton(int index, String label, IconData icon) {
    final sel = _tuitionTab == index;
    return GestureDetector(
      onTap: () => setState(() => _tuitionTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.adminColor.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sel ? AppColors.adminColor.withValues(alpha: 0.5) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: sel ? AppColors.adminColor : Colors.white60, size: 16),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: sel ? Colors.white : Colors.white60, fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildRatesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          _buildRateCard('Kỹ thuật phần mềm', Icons.computer, Colors.blue),
          const SizedBox(height: 16),
          _buildRateCard('Hệ thống thông tin', Icons.dns, Colors.green),
          const SizedBox(height: 16),
          _buildRateCard('Khoa học máy tính', Icons.code, Colors.purple),
          const SizedBox(height: 16),
          _buildRateCard('An toàn thông tin', Icons.security, Colors.orange),
          const SizedBox(height: 16),
          _buildRateCard('Mặc định', Icons.tune, Colors.grey),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _saveRates,
            icon: const Icon(Icons.save),
            label: const Text('Lưu Tất Cả Cấu Hình', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRateCard(String major, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Text(major, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _rateTextField(
                  label: 'Đơn giá tín chỉ',
                  controller: _creditControllers[major]!,
                  hint: 'VD: 480000',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _rateTextField(
                  label: 'Đơn giá môn học',
                  controller: _courseControllers[major]!,
                  hint: 'VD: 150000',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _rateTextField(
                  label: 'Học phí cơ bản kỳ',
                  controller: _baseControllers[major]!,
                  hint: 'VD: 1200000',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rateTextField({required String label, required TextEditingController controller, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 13),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            suffixText: 'đ',
            suffixStyle: const TextStyle(color: Colors.white30, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildBillingTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _filterDropdown('Năm học', _calcYear, ['2024-2025', '2025-2026', '2026-2027'], (v) {
                        setState(() { _calcYear = v!; });
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _filterDropdown('Học kỳ', _calcSemester, ['Học kỳ 1', 'Học kỳ 2', 'Học kỳ Hè'], (v) {
                        setState(() { _calcSemester = v!; });
                      }),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _calculating ? null : _calculateAllStudentsTuition,
                      icon: _calculating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.calculate, size: 18),
                      label: const Text('Tính học phí tự động', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.adminColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _tuitionSearchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (val) {
                    setState(() {
                      _tuitionSearchQuery = val.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên sinh viên hoặc mã sinh viên...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                    suffixIcon: _tuitionSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                            onPressed: () {
                              _tuitionSearchCtrl.clear();
                              setState(() {
                                _tuitionSearchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tuition_fees')
                .where('academicYear', isEqualTo: _calcYear)
                .where('semester', isEqualTo: _calcSemester)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.adminColor));
              }
              
              var docs = snapshot.data?.docs ?? [];
              
              if (_tuitionSearchQuery.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['studentName'] ?? '').toString().toLowerCase();
                  final cardId = (data['studentCardId'] ?? '').toString().toLowerCase();
                  return name.contains(_tuitionSearchQuery) || cardId.contains(_tuitionSearchQuery);
                }).toList();
              }
              
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      const Text('Chưa có hóa đơn học phí nào được tạo cho kỳ này', style: TextStyle(color: Colors.white38, fontSize: 13)),
                      const SizedBox(height: 8),
                      const Text('Hãy nhấn "Tính học phí tự động" ở trên', style: TextStyle(color: Colors.white24, fontSize: 11)),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  return _buildBillingItem(docs[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBillingItem(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['studentName'] ?? 'N/A';
    final cardId = data['studentCardId'] ?? 'N/A';
    final major = data['major'] ?? 'Mặc định';
    final credits = data['creditsCount'] ?? 0;
    final courses = data['coursesCount'] ?? 0;
    final total = data['totalAmount'] ?? 0;
    final status = data['status'] ?? 'unpaid';
    final coursesList = (data['courses'] as List<dynamic>?) ?? [];
    final isPaid = status == 'paid';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.white70,
          collapsedIconColor: Colors.white30,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPaid ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPaid ? Icons.check_circle_outline : Icons.pending_outlined,
              color: isPaid ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(cardId, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.adminColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(major, style: const TextStyle(color: AppColors.adminColor, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${_formatCurrency(total)} đ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('$credits TC | $courses môn', style: const TextStyle(color: Colors.white30, fontSize: 11)),
                ],
              ),
            ],
          ),
          children: [
            Container(
              color: Colors.black12,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CHI TIẾT MÔN ĐĂNG KÝ:', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 8),
                  ...coursesList.map((c) {
                    final cData = c as Map<String, dynamic>;
                    final cId = cData['courseId'] ?? 'N/A';
                    final cName = cData['courseName'] ?? 'N/A';
                    final cCredits = cData['credits'] ?? 3;
                    final cTuition = cData['tuition'] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '$cId - $cName ($cCredits TC)',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('${_formatCurrency(cTuition)} đ', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    );
                  }),
                  const Divider(color: Colors.white12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Phụ phí kỳ học (Base Fee):', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      Text('${_formatCurrency(data['baseFee'] ?? 0)} đ', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          await doc.reference.update({
                            'status': isPaid ? 'unpaid' : 'paid',
                            'paymentMethod': isPaid ? null : 'admin_manual',
                            'paymentDate': isPaid ? null : FieldValue.serverTimestamp(),
                          });
                        },
                        icon: Icon(isPaid ? Icons.undo : Icons.check, size: 14),
                        label: Text(isPaid ? 'Đánh dấu Chưa nộp' : 'Đánh dấu Đã nộp', style: const TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPaid ? Colors.orange.withValues(alpha: 0.8) : Colors.green.withValues(alpha: 0.8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF1a2a1f),
                              title: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
                              content: Text('Xóa hóa đơn học phí của $name?', style: const TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: Colors.white54))),
                                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Xóa', style: TextStyle(color: Colors.white))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await doc.reference.delete();
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 14),
                        label: const Text('Xóa', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          elevation: 0,
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
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
