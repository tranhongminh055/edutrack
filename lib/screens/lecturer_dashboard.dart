import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../theme/app_colors.dart';
import '../widgets/nature_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/schedule_grid.dart';
import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screen.dart';

class LecturerDashboard extends StatefulWidget {
  final String email;
  const LecturerDashboard({super.key, required this.email});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  int _menuIndex = 0;
  final NotificationService _notiService = NotificationService();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();
  bool _showSuccess = false;

  final List<Map<String, dynamic>> _menus = [
    {'icon': Icons.dashboard, 'label': 'Tổng quan'},
    {'icon': Icons.campaign, 'label': 'Gửi Thông báo'},
    {'icon': Icons.history, 'label': 'Thông báo đã gửi'},
    {'icon': Icons.calendar_today, 'label': 'Lịch dạy'},
    {'icon': Icons.assignment, 'label': 'Chấm bài'},
    {'icon': Icons.people, 'label': 'Quản lý SV'},
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
          const Icon(Icons.school, color: AppColors.lecturerColor, size: 24),
          const SizedBox(width: 8),
          const Text('EduTrack', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.lecturerColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Text('Giảng viên', style: TextStyle(color: AppColors.lecturerColor, fontSize: 11, fontWeight: FontWeight.bold)),
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
                color: AppColors.lecturerColor.withOpacity(0.3),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.lecturerColor.withOpacity(0.3)),
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
          0 => _buildOverview(),
          1 => _buildSendNotification(),
          2 => _buildSentNotifications(),
          3 => _buildSchedule(),
          4 => _buildGrading(),
          _ => _buildStudentMgmt(),
        },
      ),
    );
  }

  // --- 0: Tổng quan ---
  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.dashboard, color: AppColors.lecturerColor, size: 28),
          SizedBox(width: 12),
          Text('TỔNG QUAN', style: TextStyle(color: AppColors.lecturerColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: _statCard('Lớp đang dạy', '4', Icons.class_, Colors.blue)),
          const SizedBox(width: 16),
          Expanded(child: _statCard('Sinh viên', '156', Icons.people, AppColors.lecturerColor)),
          const SizedBox(width: 16),
          Expanded(child: _statCard('Thông báo đã gửi', '${_notiService.notifications.where((n) => n.isFromLecturer).length}', Icons.campaign, Colors.orange)),
        ]),
        const SizedBox(height: 32),
        const Text('Lịch dạy sắp tới', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('schedules')
              .where('lecturerEmail', isEqualTo: widget.email)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('Không có lịch dạy nào.', style: TextStyle(color: Colors.white70));
            }
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final startHour = (data['startHour'] as num?)?.toDouble() ?? 7.0;
                final duration = (data['duration'] as num?)?.toDouble() ?? 2.0;
                final endHour = startHour + duration;
                
                String formatHour(double h) {
                  final hr = h.floor();
                  final min = ((h - hr) * 60).round();
                  return '${hr.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
                }

                return _scheduleItem(
                  data['courseName'] ?? '',
                  'Phòng ${data['room']} - Lớp ${data['studentClass']}',
                  'Thứ ${data['dayOfWeek']}: ${formatHour(startHour)} - ${formatHour(endHour)}',
                  Color(data['colorValue'] ?? Colors.blue.value),
                );
              }).toList(),
            );
          },
        ),
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
          Icon(Icons.campaign, color: AppColors.lecturerColor, size: 28),
          SizedBox(width: 12),
          Text('GỬI THÔNG BÁO MỚI', style: TextStyle(color: AppColors.lecturerColor, fontSize: 18, fontWeight: FontWeight.bold)),
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
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lecturerColor, width: 2)),
            prefixIcon: const Icon(Icons.title, color: AppColors.lecturerColor),
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
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lecturerColor, width: 2)),
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
              backgroundColor: AppColors.lecturerColor,
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
      id: 'lec_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      sender: widget.email.split('@').first,
      senderRole: 'Giảng viên',
      date: dateStr,
      content: _contentCtrl.text.trim(),
      isFromLecturer: true,
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
        final sent = _notiService.notifications.where((n) => n.isFromLecturer).toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.history, color: AppColors.lecturerColor, size: 28),
              SizedBox(width: 12),
              Text('THÔNG BÁO ĐÃ GỬI', style: TextStyle(color: AppColors.lecturerColor, fontSize: 18, fontWeight: FontWeight.bold)),
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
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lecturerColor.withOpacity(0.2))),
              child: Row(children: [
                const Icon(Icons.campaign, color: AppColors.lecturerColor),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(children: [
                    Icon(Icons.calendar_today, color: AppColors.lecturerColor, size: 28),
                    SizedBox(width: 12),
                    Text('QUẢN LÝ LỊCH HỌC', style: TextStyle(color: AppColors.lecturerColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                  ElevatedButton.icon(
                    onPressed: () => _showUploadDialog(),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Tải lên Lịch học (Excel)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lecturerColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Tải lên khung lịch học cho sinh viên theo từng học kỳ.', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
              const SizedBox(height: 24),
              const Text('Lịch dạy của bạn', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('schedules')
                .where('lecturerEmail', isEqualTo: widget.email)
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

  // --- 4: Chấm bài ---
  Widget _buildGrading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.assignment, color: AppColors.lecturerColor, size: 28),
          SizedBox(width: 12),
          Text('CHẤM BÀI', style: TextStyle(color: AppColors.lecturerColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 24),
        _gradeItem('Bài tập chương 5 - Nhập môn LT', '32/40 bài đã chấm', 0.8, Colors.blue),
        _gradeItem('Kiểm tra giữa kỳ - CTDL', '0/38 bài đã chấm', 0.0, Colors.orange),
        _gradeItem('Đồ án cuối kỳ - Lập trình Web', '15/35 bài đã chấm', 0.43, Colors.green),
      ]),
    );
  }

  Widget _gradeItem(String title, String status, double progress, Color c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.white.withOpacity(0.1), valueColor: AlwaysStoppedAnimation(c)),
          )),
          const SizedBox(width: 16),
          Text(status, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
        ]),
      ]),
    );
  }

  // --- 5: Quản lý SV ---
  Widget _buildStudentMgmt() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.people, color: AppColors.lecturerColor, size: 28),
          SizedBox(width: 12),
          Text('QUẢN LÝ SINH VIÊN', style: TextStyle(color: AppColors.lecturerColor, fontSize: 18, fontWeight: FontWeight.bold)),
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
        CircleAvatar(backgroundColor: AppColors.lecturerColor.withOpacity(0.2), radius: 18, child: const Icon(Icons.person, color: AppColors.lecturerColor, size: 18)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          Text('MSSV: $id  •  Lớp: $cls', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        ])),
      ]),
    );
  }
}
