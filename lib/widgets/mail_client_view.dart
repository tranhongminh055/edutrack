import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import 'role_selector.dart';

class MailClientView extends StatefulWidget {
  final UserRole role;
  final String email;
  const MailClientView({super.key, required this.role, required this.email});

  @override
  State<MailClientView> createState() => _MailClientViewState();
}

class _MailClientViewState extends State<MailClientView> {
  int _tab = 0; // 0=Inbox, 1=Sent, 2=Compose
  Map<String, dynamic>? _selectedMessage;
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _sending = false;
  List<Map<String, dynamic>> _availableUsers = [];
  bool _loadingUsers = false;

  Color get _accent => widget.role == UserRole.lecturer ? AppColors.lecturerColor : AppColors.studentColor;

  @override
  void initState() {
    super.initState();
    _loadAvailableUsers();
  }

  Future<void> _loadAvailableUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'email': data['email'] ?? '',
          'fullName': data['fullName'] ?? '',
          'role': data['role'] ?? '',
        };
      }).where((user) => user['email'] != widget.email).toList();
      setState(() => _availableUsers = users);
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      setState(() => _loadingUsers = false);
    }
  }

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.mail, color: _accent, size: 28),
              const SizedBox(width: 12),
              Text('HỆ THỐNG THƯ ĐIỆN TỬ', style: TextStyle(color: _accent, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          // Tab bar
          Row(
            children: [
              _tabButton(0, Icons.inbox, 'Hộp thư đến'),
              const SizedBox(width: 8),
              _tabButton(1, Icons.send, 'Đã gửi'),
              const SizedBox(width: 8),
              _tabButton(2, Icons.edit, 'Soạn thư'),
            ],
          ),
          const SizedBox(height: 20),
          // Content
          Expanded(
            child: _tab == 2 ? _buildCompose() : _buildMailList(),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(int idx, IconData icon, String label) {
    final sel = _tab == idx;
    return GestureDetector(
      onTap: () => setState(() {
        _tab = idx;
        _selectedMessage = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? _accent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sel ? _accent : Colors.white.withOpacity(0.1)),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: sel ? _accent : Colors.white54),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: sel ? _accent : Colors.white70, fontWeight: sel ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _buildMailList() {
    final isInbox = _tab == 0;
    final myEmail = widget.email;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mail_messages')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          if (isInbox) {
            // Inbox: emails sent TO me
            final to = d['recipientEmail'] ?? '';
            return to == myEmail;
          } else {
            // Sent: emails sent BY me
            return d['senderEmail'] == myEmail;
          }
        }).toList();

        if (_selectedMessage != null) {
          return _buildMessageDetail();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(isInbox ? Icons.inbox : Icons.send, size: 64, color: Colors.white.withOpacity(0.15)),
              const SizedBox(height: 16),
              Text(isInbox ? 'Hộp thư trống' : 'Chưa gửi thư nào', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
            ]),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            final isRead = (d['readBy'] as List<dynamic>?)?.contains(FirebaseAuth.instance.currentUser?.uid) ?? false;
            final ts = d['createdAt'] as Timestamp?;
            final date = ts != null ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year} ${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}' : '';

            return GestureDetector(
              onTap: () {
                // Mark as read
                if (isInbox && !isRead) {
                  FirebaseFirestore.instance.collection('mail_messages').doc(docId).update({
                    'readBy': FieldValue.arrayUnion([FirebaseAuth.instance.currentUser?.uid ?? ''])
                  });
                }
                setState(() {
                  _selectedMessage = {...d, '_docId': docId};
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isRead ? Colors.white.withOpacity(0.03) : _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isRead ? Colors.white.withOpacity(0.06) : _accent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: _accent.withOpacity(0.15)),
                      child: Center(child: Text(
                        (isInbox ? (d['senderName'] ?? 'U') : (d['recipientEmail'] ?? 'U')).toString().characters.first.toUpperCase(),
                        style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 16),
                      )),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          if (!isRead && isInbox) Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(shape: BoxShape.circle, color: _accent)),
                          Expanded(child: Text(
                            isInbox ? (d['senderName'] ?? d['senderEmail'] ?? '') : 'Đến: ${d['recipientEmail'] ?? ''}',
                            style: TextStyle(color: Colors.white, fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          )),
                        ]),
                        const SizedBox(height: 4),
                        Text(d['subject'] ?? '(Không có tiêu đề)', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13), overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                    Text(date, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageDetail() {
    final m = _selectedMessage!;
    final ts = m['createdAt'] as Timestamp?;
    final date = ts != null ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year} ${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}' : '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => setState(() => _selectedMessage = null),
          child: Row(children: [
            Icon(Icons.arrow_back, color: _accent, size: 18),
            const SizedBox(width: 8),
            Text('Quay lại', style: TextStyle(color: _accent, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 20),
        Text(m['subject'] ?? '(Không có tiêu đề)', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _accent.withOpacity(0.15)),
                child: Center(child: Text((m['senderName'] ?? 'U').toString().characters.first.toUpperCase(), style: TextStyle(color: _accent, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m['senderName'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(m['senderEmail'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ]),
              const Spacer(),
              Text(date, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ]),
            const SizedBox(height: 4),
            Text('Đến: ${m['recipientEmail'] ?? ''}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(m['body'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.7)),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _tab = 2;
              _selectedMessage = null;
              _toController.text = m['senderEmail'] ?? '';
              _subjectController.text = 'Re: ${m['subject'] ?? ''}';
            });
          },
          icon: const Icon(Icons.reply, size: 16),
          label: const Text('Trả lời'),
          style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        ),
      ]),
    );
  }

  Widget _buildCompose() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Soạn thư mới', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        // Recipient dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _toController.text.isEmpty ? null : _toController.text,
              hint: Row(children: [
                Icon(Icons.person, color: Colors.white38, size: 18),
                const SizedBox(width: 8),
                Text('Chọn người nhận', style: TextStyle(color: Colors.white.withOpacity(0.3))),
              ]),
              isExpanded: true,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: _loadingUsers
                  ? [
                      const DropdownMenuItem<String>(
                        value: '',
                        enabled: false,
                        child: Text('Đang tải danh sách...', style: TextStyle(color: Colors.white38)),
                      ),
                    ]
                  : _availableUsers.map((user) {
                      return DropdownMenuItem<String>(
                        value: user['email'],
                        child: Row(children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accent.withOpacity(0.15),
                            ),
                            child: Center(
                              child: Text(
                                (user['fullName'] as String).isNotEmpty
                                    ? (user['fullName'] as String)[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['fullName'] ?? 'Không tên',
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  user['email'] ?? '',
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  user['role'] == 'lecturer' ? 'Giảng viên' : 'Sinh viên',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      );
                    }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _toController.text = value);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        _composeField('Tiêu đề', _subjectController, Icons.subject),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: _bodyController,
            maxLines: 10,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Nội dung thư...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _sending ? null : _sendMail,
          icon: _sending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send, size: 16),
          label: Text(_sending ? 'Đang gửi...' : 'Gửi thư'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    );
  }

  Widget _composeField(String hint, TextEditingController ctrl, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          icon: Icon(icon, color: Colors.white38, size: 18),
        ),
      ),
    );
  }

  Future<void> _sendMail() async {
    if (_toController.text.trim().isEmpty || _subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn người nhận và nhập tiêu đề'), backgroundColor: Colors.red));
      return;
    }

    // Validate recipient email exists in system
    final recipientExists = _availableUsers.any((user) => user['email'] == _toController.text.trim());
    if (!recipientExists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Người nhận không tồn tại trong hệ thống'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
      final senderName = userDoc.data()?['fullName'] ?? widget.email.split('@').first;

      await FirebaseFirestore.instance.collection('mail_messages').add({
        'senderEmail': widget.email,
        'senderName': senderName,
        'senderUid': user?.uid ?? '',
        'senderRole': widget.role.name,
        'recipientEmail': _toController.text.trim(),
        'subject': _subjectController.text.trim(),
        'body': _bodyController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': [],
      });

      _toController.clear();
      _subjectController.clear();
      _bodyController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Đã gửi thư thành công!'), backgroundColor: Colors.green.shade600));
        setState(() { _tab = 1; _sending = false; });
      }
    } catch (e) {
      setState(() => _sending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
