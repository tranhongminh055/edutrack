import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  final List<Map<String, dynamic>> _menus = [
    {'icon': Icons.dashboard, 'label': 'Tổng quan'},
    {'icon': Icons.campaign, 'label': 'Gửi Thông báo'},
    {'icon': Icons.history, 'label': 'Thông báo đã gửi'},
    {'icon': Icons.calendar_today, 'label': 'Quản lý lịch học'},
    {'icon': Icons.verified, 'label': 'Phê duyệt Bảng điểm'},
    {'icon': Icons.people, 'label': 'Quản lý SV'},
    {'icon': Icons.app_registration, 'label': 'Quản lý môn ĐK'},
    {'icon': Icons.analytics, 'label': 'Theo dõi ĐK'},
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
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
      color: Colors.black.withOpacity(0.2),
      child: Row(
        children: [
          const Icon(Icons.school, color: AppColors.adminColor, size: 24),
          const SizedBox(width: 8),
          const Text('EduTrack', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.adminColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
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
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withOpacity(0.3))),
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
                color: AppColors.adminColor.withOpacity(0.3),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.adminColor.withOpacity(0.3)),
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
                        color: sel ? Colors.white.withOpacity(0.1) : Colors.transparent,
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
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
      ]),
    );
  }

  Widget _scheduleItem(String subj, String room, String time, Color c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), border: Border(left: BorderSide(color: c, width: 4)), borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8))),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(subj, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(room, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: c.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
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
        Text('Thông báo sẽ được hiển thị trên trang Sinh viên trong mục "Tin tức & Thông báo"', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
        const SizedBox(height: 28),

        // Title
        const Text('Tiêu đề thông báo *', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _titleCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'VD: Thông báo lịch kiểm tra giữa kỳ',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true, fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
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
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true, fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
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
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Gửi thông báo thành công!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Thông báo đã xuất hiện trên trang Sinh viên.', style: TextStyle(color: Colors.green.withOpacity(0.7), fontSize: 12)),
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
                Icon(Icons.inbox, size: 48, color: Colors.white.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text('Chưa gửi thông báo nào', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ]))),
            ...sent.map((n) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.adminColor.withOpacity(0.2))),
              child: Row(children: [
                const Icon(Icons.campaign, color: AppColors.adminColor),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(n.date, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
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
              Text('Tải lên khung lịch học cho toàn trường. Dữ liệu sẽ đồng bộ cho giảng viên và sinh viên.', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
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
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.withOpacity(0.3))),
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
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                  Icon(Icons.inbox, size: 48, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('Chưa có bảng điểm nào được Giảng viên gửi lên', style: TextStyle(color: Colors.white.withOpacity(0.5))),
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
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: isPublished ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
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

  // --- 5: Quản lý SV ---
  Widget _buildStudentMgmt() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.people, color: AppColors.adminColor, size: 28),
          SizedBox(width: 12),
          Text('QUẢN LÝ SINH VIÊN', style: TextStyle(color: AppColors.adminColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 24),
        _studentRow('Nguyễn Văn A', '29210247142', 'KTPM2022'),
        _studentRow('Trần Thị B', '29210247143', 'KTPM2022'),
        _studentRow('Lê Văn C', '29210247144', 'KTPM2022'),
        _studentRow('Phạm Thị D', '29210247145', 'CNTT2023'),
      ]),
    );
  }

  Widget _studentRow(String name, String id, String cls) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        CircleAvatar(backgroundColor: AppColors.adminColor.withOpacity(0.2), radius: 18, child: const Icon(Icons.person, color: AppColors.adminColor, size: 18)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          Text('MSSV: $id  •  Lớp: $cls', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        ])),
      ]),
    );
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
                  Icon(Icons.inbox, size: 48, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('Chưa có môn nào cho $_adminRegSemester - $_adminRegYear', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  const SizedBox(height: 16),
                  const Text('Nhấn "Tải lên DS Môn ĐK (CSV)" để tải dữ liệu lên.', style: TextStyle(color: Colors.white38, fontSize: 13)),
                ]));
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.05)),
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
                          SizedBox(width: 50, child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: Colors.white.withOpacity(0.1), valueColor: AlwaysStoppedAnimation(pct >= 1.0 ? Colors.red : AppColors.adminColor)))),
                        ])),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: d['status'] == 'open' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
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
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.15))),
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
                return Center(child: Text('Chưa có lượt đăng ký nào trong $_adminRegSemester - $_adminRegYear', style: TextStyle(color: Colors.white.withOpacity(0.5))));
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.05)),
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
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
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
                      color: AppColors.adminColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.adminColor.withOpacity(0.5)),
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
}
