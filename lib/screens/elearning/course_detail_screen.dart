import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../widgets/nature_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/role_selector.dart';
import '../../services/elearning_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseDocId;
  final String courseName;
  final String courseId;
  final String classGroup;
  final UserRole role;
  final String userId;
  final String email;

  const CourseDetailScreen({
    super.key,
    required this.courseDocId,
    required this.courseName,
    required this.courseId,
    required this.classGroup,
    required this.role,
    required this.userId,
    required this.email,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  int _tabIndex = 0;
  final ELearningService _elearningService = ELearningService();

  final List<Map<String, dynamic>> _tabs = [
    {'icon': Icons.home, 'label': 'Trang chủ'},
    {'icon': Icons.video_camera_front, 'label': 'Online Class'},
    {'icon': Icons.folder, 'label': 'Bài giảng'},
    {'icon': Icons.assignment, 'label': 'Bài tập'},
    {'icon': Icons.quiz, 'label': 'Kiểm tra'},
  ];

  Color get _themeColor => widget.role == UserRole.student ? AppColors.studentColor : AppColors.lecturerColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NatureBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopNav(context),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSidebar(),
                    Expanded(child: _buildMainContent()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.black.withValues(alpha: 0.3),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.school, color: Colors.white70, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.courseName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Text('${widget.courseId} - ${widget.classGroup}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _themeColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Text(widget.role == UserRole.student ? 'Sinh viên' : 'Giảng viên', style: TextStyle(color: _themeColor, fontSize: 12, fontWeight: FontWeight.bold)),
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
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: _tabs.length,
          itemBuilder: (context, index) {
            final tab = _tabs[index];
            final isSelected = _tabIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _tabIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                  border: Border(left: isSelected ? BorderSide(color: _themeColor, width: 4) : BorderSide.none),
                ),
                child: Row(
                  children: [
                    Icon(tab['icon'] as IconData, color: isSelected ? _themeColor : Colors.white54, size: 22),
                    const SizedBox(width: 16),
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        color: isSelected ? _themeColor : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 24),
      child: GlassContainer(
        child: _buildCurrentTab(),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_tabIndex) {
      case 0: return _buildOverviewTab();
      case 1: return _buildOnlineClassTab();
      case 2: return _buildMaterialsTab();
      case 3: return _buildAssignmentsTab();
      case 4: return _buildQuizzesTab();
      default: return const Center(child: Text('Unknown tab', style: TextStyle(color: Colors.white)));
    }
  }

  // ====== 0: TRANG CHỦ ======
  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.home, color: _themeColor, size: 32),
              const SizedBox(width: 12),
              Text('TRANG CHỦ MÔN HỌC', style: TextStyle(color: _themeColor, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chào mừng đến với không gian học tập trực tuyến!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _infoRow(Icons.book, 'Môn học:', widget.courseName),
                const SizedBox(height: 8),
                _infoRow(Icons.code, 'Mã môn:', widget.courseId),
                const SizedBox(height: 8),
                _infoRow(Icons.class_, 'Lớp:', widget.classGroup),
                const SizedBox(height: 16),
                Text('Tại đây bạn có thể lấy tài liệu, nộp bài tập và tham gia các bài kiểm tra được giao.', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(width: 8),
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white70))),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ====== 1: ONLINE CLASS ======
  Widget _buildOnlineClassTab() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.video_camera_front, color: _themeColor, size: 32),
              const SizedBox(width: 12),
              Text('HỌC TRỰC TUYẾN (ONLINE CLASS)', style: TextStyle(color: _themeColor, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          StreamBuilder<DocumentSnapshot>(
            stream: _elearningService.getOnlineClassLinkStream(widget.courseDocId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final link = data?['meetingLink'] ?? '';
              final password = data?['meetingPassword'] ?? '';
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.videocam, color: Colors.blueAccent, size: 24),
                            SizedBox(width: 12),
                            Text('Phòng học Trực tuyến', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (link.toString().isNotEmpty) ...[
                          const Text('Đường dẫn tham gia (Meeting Link):', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          SelectableText(link, style: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline, fontSize: 16)),
                          const SizedBox(height: 16),
                          if (password.toString().isNotEmpty) ...[
                            const Text('Mật khẩu (nếu có):', style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 4),
                            SelectableText(password, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 24),
                          ],
                          ElevatedButton.icon(
                            onPressed: () async {
                              final Uri url = Uri.parse(link);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở đường dẫn này!')));
                                }
                              }
                            },
                            icon: const Icon(Icons.launch),
                            label: const Text('Tham gia lớp học ngay'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ] else ...[
                          const Text('Giảng viên chưa cập nhật đường dẫn học trực tuyến.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        ]
                      ],
                    ),
                  ),
                  
                  if (widget.role == UserRole.lecturer) ...[
                    const SizedBox(height: 32),
                    const Text('Cập nhật đường dẫn học trực tuyến', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildUpdateLinkSection(link, password),
                  ]
                ],
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateLinkSection(String currentLink, String currentPass) {
    final linkCtrl = TextEditingController(text: currentLink);
    final passCtrl = TextEditingController(text: currentPass);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: linkCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Meeting Link (Zoom / Meet / Teams)',
              labelStyle: const TextStyle(color: Colors.white54),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _themeColor)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Mật khẩu / Passcode (Tùy chọn)',
              labelStyle: const TextStyle(color: Colors.white54),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _themeColor)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await _elearningService.updateOnlineClassLink(widget.courseDocId, linkCtrl.text.trim(), passCtrl.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật link học trực tuyến!'), backgroundColor: Colors.green));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor, foregroundColor: Colors.white),
            child: const Text('Lưu Thay Đổi'),
          ),
        ],
      ),
    );
  }

  // ====== 2: BÀI GIẢNG (MATERIALS) ======
  Widget _buildMaterialsTab() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.folder, color: _themeColor, size: 32),
                  const SizedBox(width: 12),
                  Text('BÀI GIẢNG & TÀI LIỆU', style: TextStyle(color: _themeColor, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              if (widget.role == UserRole.lecturer)
                ElevatedButton.icon(
                  onPressed: _showAddMaterialDialog,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Tải lên Tài liệu'),
                  style: ElevatedButton.styleFrom(backgroundColor: _themeColor, foregroundColor: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _elearningService.getMaterialsStream(widget.courseDocId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data?.docs ?? [];
                
                if (docs.isEmpty) {
                  return const Center(child: Text('Chưa có tài liệu nào được tải lên.', style: TextStyle(color: Colors.white54)));
                }
                
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Không tên';
                    final desc = data['description'] ?? '';
                    final url = data['fileUrl'] ?? '';
                    final isPdf = url.toString().toLowerCase().endsWith('.pdf');
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: ListTile(
                        leading: Icon(isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file, color: isPdf ? Colors.redAccent : Colors.blueAccent, size: 32),
                        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(desc, style: const TextStyle(color: Colors.white70)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.download, color: Colors.greenAccent),
                              onPressed: () => _launchURL(url),
                              tooltip: 'Tải về / Xem',
                            ),
                            if (widget.role == UserRole.lecturer)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _elearningService.deleteMaterial(docs[index].id),
                                tooltip: 'Xóa tài liệu',
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
      ),
    );
  }

  void _showAddMaterialDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a2a1f),
        title: const Text('Tải lên Tài liệu mới', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Tên tài liệu', labelStyle: TextStyle(color: Colors.white70))),
              TextField(controller: descCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Mô tả ngắn', labelStyle: TextStyle(color: Colors.white70))),
              TextField(controller: urlCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'URL (Google Drive / Link file)', labelStyle: TextStyle(color: Colors.white70))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                await _elearningService.addMaterial(widget.courseDocId, titleCtrl.text, descCtrl.text, urlCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
            child: const Text('Lưu lại', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ====== 3: BÀI TẬP (ASSIGNMENTS) ======
  Widget _buildAssignmentsTab() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.assignment, color: _themeColor, size: 32),
                  const SizedBox(width: 12),
                  Text('BÀI TẬP VỀ NHÀ', style: TextStyle(color: _themeColor, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              if (widget.role == UserRole.lecturer)
                ElevatedButton.icon(
                  onPressed: _showAddAssignmentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo Bài Tập'),
                  style: ElevatedButton.styleFrom(backgroundColor: _themeColor, foregroundColor: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _elearningService.getAssignmentsStream(widget.courseDocId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data?.docs ?? [];
                
                if (docs.isEmpty) {
                  return const Center(child: Text('Chưa có bài tập nào.', style: TextStyle(color: Colors.white54)));
                }
                
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Bài tập';
                    final desc = data['description'] ?? '';
                    final dl = data['deadline'] as Timestamp?;
                    final isExpired = dl != null && dl.toDate().isBefore(DateTime.now());
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isExpired ? Colors.red.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              if (widget.role == UserRole.lecturer)
                                IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () => _elearningService.deleteAssignment(docs[index].id))
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(desc, style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.orange, size: 16),
                              const SizedBox(width: 8),
                              Text('Hạn nộp: ${dl != null ? '${dl.toDate().day}/${dl.toDate().month} ${dl.toDate().hour}:${dl.toDate().minute}' : 'Không có hạn'}', 
                                style: TextStyle(color: isExpired ? Colors.redAccent : Colors.orange, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (widget.role == UserRole.student)
                            _buildStudentSubmissionSection(docs[index].id, isExpired)
                          else 
                            _buildLecturerSubmissionView(docs[index].id),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSubmissionSection(String assignmentId, bool isExpired) {
    return StreamBuilder<QuerySnapshot>(
      stream: _elearningService.getStudentSubmissionStream(assignmentId, widget.userId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final hasSubmitted = docs.isNotEmpty;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(hasSubmitted ? Icons.check_circle : Icons.pending, color: hasSubmitted ? Colors.green : Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Text(hasSubmitted ? 'Đã nộp bài' : 'Chưa nộp bài', style: TextStyle(color: hasSubmitted ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton(
                  onPressed: isExpired ? null : () => _showSubmitAssignmentDialog(assignmentId),
                  style: ElevatedButton.styleFrom(backgroundColor: _themeColor, foregroundColor: Colors.white),
                  child: Text(hasSubmitted ? 'Cập nhật bài nộp' : 'Nộp bài'),
                ),
              ],
            ),
            if (hasSubmitted) ...[
              const SizedBox(height: 8),
              Text('Link bài đã nộp: ${(docs.first.data() as Map)['fileUrl']}', style: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline)),
              if ((docs.first.data() as Map)['grade'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Điểm: ${(docs.first.data() as Map)['grade']}/10', style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 16)),
                )
            ]
          ],
        );
      }
    );
  }

  Widget _buildLecturerSubmissionView(String assignmentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _elearningService.getSubmissionsStream(assignmentId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: Colors.white24),
            Text('Đã có ${docs.length} bài nộp', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            if (docs.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Hiển thị popup chấm bài hoặc mở sang màn hình chấm
                },
                child: const Text('Xem danh sách & Chấm bài', style: TextStyle(color: AppColors.lecturerColor)),
              )
          ],
        );
      }
    );
  }

  void _showAddAssignmentDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1a2a1f),
          title: const Text('Tạo Bài Tập', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Tên bài tập', labelStyle: TextStyle(color: Colors.white70))),
                TextField(controller: descCtrl, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Mô tả yêu cầu', labelStyle: TextStyle(color: Colors.white70))),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(selectedDate != null ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year} ${selectedTime?.hour}:${selectedTime?.minute}' : 'Chưa chọn hạn nộp', style: const TextStyle(color: Colors.white)),
                    ElevatedButton(
                      onPressed: () async {
                        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                        if (d != null) {
                          final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (t != null) {
                            setDialogState(() {
                              selectedDate = d;
                              selectedTime = t;
                            });
                          }
                        }
                      },
                      child: const Text('Chọn thời hạn'),
                    ),
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isNotEmpty && selectedDate != null && selectedTime != null) {
                  final deadline = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, selectedTime!.hour, selectedTime!.minute);
                  await _elearningService.addAssignment(widget.courseDocId, titleCtrl.text, descCtrl.text, deadline);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
              child: const Text('Tạo', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubmitAssignmentDialog(String assignmentId) {
    final urlCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a2a1f),
        title: const Text('Nộp Bài Tập', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: urlCtrl, 
          style: const TextStyle(color: Colors.white), 
          decoration: const InputDecoration(labelText: 'URL Link bài làm (Google Drive/Github...)', labelStyle: TextStyle(color: Colors.white70))
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () async {
              if (urlCtrl.text.isNotEmpty) {
                await _elearningService.submitAssignment(assignmentId, widget.userId, urlCtrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã nộp bài thành công!'), backgroundColor: Colors.green));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
            child: const Text('Nộp bài', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ====== 4: KIỂM TRA (QUIZZES) ======
  Widget _buildQuizzesTab() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.quiz, color: _themeColor, size: 32),
                  const SizedBox(width: 12),
                  Text('BÀI KIỂM TRA (TESTS & QUIZZES)', style: TextStyle(color: _themeColor, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              if (widget.role == UserRole.lecturer)
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng tạo Quiz đang phát triển.')));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo Quiz Mới'),
                  style: ElevatedButton.styleFrom(backgroundColor: _themeColor, foregroundColor: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Center(child: Text('Chưa có bài kiểm tra nào được tạo.', style: TextStyle(color: Colors.white54))),
        ],
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở đường dẫn này!')));
      }
    }
  }
}
