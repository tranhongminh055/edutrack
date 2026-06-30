import 'dart:convert';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _showSuccess = false;
  String _lecturerRegSemester = 'Học kỳ 1';
  String _lecturerRegYear = '2025-2026';
  String? _selectedGradingCourseDocId;

  final List<Map<String, dynamic>> _menus = [
    {'icon': Icons.dashboard, 'label': 'Tổng quan'},
    {'icon': Icons.article, 'label': 'Tin tức & Thông báo'},
    {'icon': Icons.calendar_today, 'label': 'Lịch dạy'},
    {'icon': Icons.how_to_reg, 'label': 'SV Đăng ký lớp'},
    {'icon': Icons.assignment, 'label': 'Chấm bài'},
    {'icon': Icons.people, 'label': 'Quản lý SV'},
    {'icon': Icons.quiz, 'label': 'E-Learning (Test & Quiz)'},
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
          GestureDetector(
            onTap: () {
              final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
              web.window.open('https://edutrack-elearning.web.app/?userId=$uid&role=lecturer&email=${Uri.encodeComponent(widget.email)}', '_blank');
            },
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white70, size: 16),
                SizedBox(width: 4),
                Text('E-Learning', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 24),
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
          1 => _buildNewsContent(),
          2 => _buildSchedule(),
          3 => _buildStudentRegistrations(),
          4 => _buildGrading(),
          5 => _buildStudentMgmt(),
          6 => ELearningDashboard(
                 role: UserRole.lecturer, 
                 userId: FirebaseAuth.instance.currentUser?.uid ?? '', 
                 email: widget.email, 
                 currentSemester: _lecturerRegSemester, 
                 currentYear: _lecturerRegYear,
               ),
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
              Text('Hiển thị lịch giảng dạy của bạn trong học kỳ này.', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
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

          final id = '${courseName}_${room}_${dayOfWeek}_${startHour}_${studentClass}'.replaceAll(' ', '_').replaceAll('/', '_');

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
                Text('QUẢN LÝ ĐIỂM SỐ', style: TextStyle(color: AppColors.lecturerColor, fontSize: 18, fontWeight: FontWeight.bold)),
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
                  Icon(Icons.inbox, size: 48, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('Bạn chưa có sinh viên/lớp nào trong $_lecturerRegSemester - $_lecturerRegYear', style: TextStyle(color: Colors.white.withOpacity(0.5))),
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
        
        int submittedCount = 0;
        int gradedCount = 0;
        for (var s in students) {
          final sd = s.data() as Map<String, dynamic>;
          final status = sd['gradeStatus'] ?? 'none';
          if (status == 'lecturer_submitted' || status == 'admin_published') {
            submittedCount++;
          }
          if (sd['attendanceScore'] != null || sd['midtermScore'] != null || sd['finalScore'] != null) {
            gradedCount++;
          }
        }
        
        final isAllSubmitted = submittedCount == students.length && students.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: isAllSubmitted ? Colors.green.withOpacity(0.2) : AppColors.lecturerColor.withOpacity(0.2),
              child: Icon(isAllSubmitted ? Icons.check_circle : Icons.edit_document, color: isAllSubmitted ? Colors.green : AppColors.lecturerColor),
            ),
            title: Text('$courseName ($classGroup)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Mã MH: $cId  |  Sĩ số: ${students.length}  |  Đã nhập điểm: $gradedCount/${students.length}', style: const TextStyle(color: Colors.white70)),
            ),
            trailing: isAllSubmitted 
                ? const Text('Đã gửi Admin', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                : ElevatedButton(
                    onPressed: () => setState(() => _selectedGradingCourseDocId = courseDocId),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.lecturerColor, foregroundColor: Colors.white),
                    child: const Text('Nhập điểm'),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildStudentListForGrading(List<QueryDocumentSnapshot> students) {
    final courseData = students.first.data() as Map<String, dynamic>;
    final courseName = courseData['courseName'] ?? '';
    final classGroup = courseData['classGroup'] ?? '';
    final courseDocId = courseData['courseDocId'] ?? '';

    // Check if any is submitted
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
                    // Mô phỏng đồng bộ điểm Sakai
                    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                    for (var s in students) {
                      final randomFinal = (50 + (DateTime.now().millisecond % 50)) / 10.0; // Random 5.0 -> 9.9
                      await _regService.updateStudentGrade(regDocId: s.id, finalScore: randomFinal, status: 'lecturer_draft');
                    }
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đồng bộ điểm Cuối kỳ từ Sakai!'), backgroundColor: Colors.green));
                    }
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Lấy điểm Sakai'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.withOpacity(0.8), foregroundColor: Colors.white),
                ),
                const SizedBox(width: 12),
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
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green)),
                  child: const Text('BẢNG ĐIỂM ĐÃ KHOÁ (Đã gửi Admin)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                )
              ]
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final studentDoc = students[index];
              final data = studentDoc.data() as Map<String, dynamic>;
              final userId = data['userId'] ?? 'Unknown';
              final att = data['attendanceScore']?.toString() ?? '';
              final mid = data['midtermScore']?.toString() ?? '';
              final fin = data['finalScore']?.toString() ?? '-';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(userId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(
                      flex: 1,
                      child: isLocked ? Text('CC: ${att.isEmpty ? '-' : att}', style: const TextStyle(color: Colors.white70)) : TextField(
                        controller: TextEditingController(text: att),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Chuyên cần (10%)', labelStyle: TextStyle(color: Colors.white54, fontSize: 12), isDense: true),
                        onSubmitted: (v) {
                          final val = double.tryParse(v);
                          if (val != null) _regService.updateStudentGrade(regDocId: studentDoc.id, attendanceScore: val, status: 'lecturer_draft');
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: isLocked ? Text('GK: ${mid.isEmpty ? '-' : mid}', style: const TextStyle(color: Colors.white70)) : TextField(
                        controller: TextEditingController(text: mid),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Giữa kỳ (20%)', labelStyle: TextStyle(color: Colors.white54, fontSize: 12), isDense: true),
                        onSubmitted: (v) {
                          final val = double.tryParse(v);
                          if (val != null) _regService.updateStudentGrade(regDocId: studentDoc.id, midtermScore: val, status: 'lecturer_draft');
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                        alignment: Alignment.center,
                        child: Text('Thi CK (70%)\n$fin', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      )
                    ),
                  ],
                ),
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
                  Icon(Icons.person_search, size: 48, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('Chưa có sinh viên nào đăng ký lớp của bạn trong $_lecturerRegSemester - $_lecturerRegYear', style: TextStyle(color: Colors.white.withOpacity(0.5))),
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
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.lecturerColor.withOpacity(0.2),
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
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.15))),
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
}
