import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import 'role_selector.dart';

class ForumBoardView extends StatefulWidget {
  final UserRole role;
  final String email;
  const ForumBoardView({super.key, required this.role, required this.email});

  @override
  State<ForumBoardView> createState() => _ForumBoardViewState();
}

class _ForumBoardViewState extends State<ForumBoardView> {
  String _selectedTag = 'Tất cả';
  bool _showCreateForm = false;
  String? _viewingPostId;
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  String _newPostTag = 'Học tập';
  bool _posting = false;

  final List<String> _tags = ['Tất cả', 'Học tập', 'Q&A', 'Sinh hoạt', 'Thông báo'];

  Color get _accent => widget.role == UserRole.lecturer ? AppColors.lecturerColor : AppColors.studentColor;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _commentCtrl.dispose();
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
              Icon(Icons.forum, color: _accent, size: 28),
              const SizedBox(width: 12),
              Text('DIỄN ĐÀN HỌC TẬP', style: TextStyle(color: _accent, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (!_showCreateForm && _viewingPostId == null)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showCreateForm = true),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Tạo bài viết'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Tag filter
          if (!_showCreateForm && _viewingPostId == null)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _tags.map((t) {
                  final sel = _selectedTag == t;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTag = t),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? _accent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? _accent : Colors.white.withOpacity(0.1)),
                      ),
                      child: Text(t, style: TextStyle(color: sel ? _accent : Colors.white60, fontWeight: sel ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),
          // Content
          Expanded(
            child: _showCreateForm
                ? _buildCreateForm()
                : _viewingPostId != null
                    ? _buildPostDetail()
                    : _buildPostsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('forum_posts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final allDocs = snapshot.data?.docs ?? [];
        final docs = _selectedTag == 'Tất cả'
            ? allDocs
            : allDocs.where((d) => (d.data() as Map<String, dynamic>)['tag'] == _selectedTag).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.forum, size: 64, color: Colors.white.withOpacity(0.15)),
              const SizedBox(height: 16),
              Text('Chưa có bài viết nào', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
            ]),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            final likes = List<String>.from(d['likes'] ?? []);
            final isLiked = likes.contains(_uid);
            final ts = d['createdAt'] as Timestamp?;
            final date = ts != null ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}' : '';
            final commentCount = (d['commentCount'] as num?)?.toInt() ?? 0;

            return GestureDetector(
              onTap: () => setState(() => _viewingPostId = docId),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _tagColor(d['tag'] ?? '').withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(d['tag'] ?? '', style: TextStyle(color: _tagColor(d['tag'] ?? ''), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(6)),
                      child: Text(d['authorRole'] == 'lecturer' ? 'Giảng viên' : 'Sinh viên', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                    ),
                    const Spacer(),
                    Text(date, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
                  ]),
                  const SizedBox(height: 12),
                  Text(d['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    (d['content'] ?? '').toString().length > 120 ? '${(d['content'] ?? '').toString().substring(0, 120)}...' : d['content'] ?? '',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Text(d['authorName'] ?? '', style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _toggleLike(docId, likes),
                      child: Row(children: [
                        Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 18, color: isLiked ? Colors.redAccent : Colors.white38),
                        const SizedBox(width: 4),
                        Text('${likes.length}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                      ]),
                    ),
                    const SizedBox(width: 16),
                    Row(children: [
                      Icon(Icons.comment_outlined, size: 16, color: Colors.white.withOpacity(0.35)),
                      const SizedBox(width: 4),
                      Text('$commentCount', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                    ]),
                  ]),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPostDetail() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('forum_posts').doc(_viewingPostId).snapshots(),
      builder: (context, postSnap) {
        if (!postSnap.hasData) return const Center(child: CircularProgressIndicator());
        final d = postSnap.data!.data() as Map<String, dynamic>? ?? {};
        final likes = List<String>.from(d['likes'] ?? []);
        final isLiked = likes.contains(_uid);
        final ts = d['createdAt'] as Timestamp?;
        final date = ts != null ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year} ${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}' : '';

        return Column(
          children: [
            // Back button
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => setState(() => _viewingPostId = null),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.arrow_back, color: _accent, size: 18),
                  const SizedBox(width: 8),
                  Text('Quay lại diễn đàn', style: TextStyle(color: _accent, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            // Post content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _tagColor(d['tag'] ?? '').withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(d['tag'] ?? '', style: TextStyle(color: _tagColor(d['tag'] ?? ''), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Text(date, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  ]),
                  const SizedBox(height: 14),
                  Text(d['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Icon(Icons.person, size: 16, color: _accent),
                    const SizedBox(width: 6),
                    Text(d['authorName'] ?? '', style: TextStyle(color: _accent, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 6),
                    Text('(${d['authorRole'] == 'lecturer' ? 'Giảng viên' : 'Sinh viên'})', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  ]),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(d['content'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.7)),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _toggleLike(_viewingPostId!, likes),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isLiked ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isLiked ? Colors.redAccent.withOpacity(0.3) : Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 18, color: isLiked ? Colors.redAccent : Colors.white54),
                        const SizedBox(width: 6),
                        Text('${likes.length} Thích', style: TextStyle(color: isLiked ? Colors.redAccent : Colors.white54, fontSize: 13)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.white.withOpacity(0.08)),
                  const SizedBox(height: 16),
                  const Text('Bình luận', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  // Comments list
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('forum_posts').doc(_viewingPostId)
                        .collection('comments')
                        .orderBy('createdAt', descending: false)
                        .snapshots(),
                    builder: (context, commSnap) {
                      final comments = commSnap.data?.docs ?? [];
                      if (comments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text('Chưa có bình luận nào. Hãy là người đầu tiên!', style: TextStyle(color: Colors.white.withOpacity(0.4), fontStyle: FontStyle.italic)),
                        );
                      }
                      return Column(
                        children: comments.map((c) {
                          final cd = c.data() as Map<String, dynamic>;
                          final cts = cd['createdAt'] as Timestamp?;
                          final cDate = cts != null ? '${cts.toDate().day}/${cts.toDate().month} ${cts.toDate().hour.toString().padLeft(2, '0')}:${cts.toDate().minute.toString().padLeft(2, '0')}' : '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(10),
                              border: Border(left: BorderSide(color: _accent.withOpacity(0.4), width: 3)),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Text(cd['authorName'] ?? '', style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 8),
                                Text(cd['authorRole'] == 'lecturer' ? 'GV' : 'SV', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                                const Spacer(),
                                Text(cDate, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                              ]),
                              const SizedBox(height: 8),
                              Text(cd['content'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
                            ]),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Comment input
                  Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: TextField(
                          controller: _commentCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(border: InputBorder.none, hintText: 'Viết bình luận...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _submitComment,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: _accent),
                        child: const Icon(Icons.send, size: 18, color: Colors.white),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCreateForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => setState(() => _showCreateForm = false),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.arrow_back, color: _accent, size: 18),
            const SizedBox(width: 8),
            Text('Hủy', style: TextStyle(color: _accent, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('Tạo bài viết mới', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        // Tag selector
        const Text('Chọn chủ đề:', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _tags.where((t) => t != 'Tất cả').map((t) {
            final sel = _newPostTag == t;
            return GestureDetector(
              onTap: () => setState(() => _newPostTag = t),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? _tagColor(t).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? _tagColor(t) : Colors.white.withOpacity(0.1)),
                ),
                child: Text(t, style: TextStyle(color: sel ? _tagColor(t) : Colors.white60, fontWeight: sel ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Title
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))),
          child: TextField(
            controller: _titleCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(border: InputBorder.none, hintText: 'Tiêu đề bài viết', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)), icon: Icon(Icons.title, color: Colors.white.withOpacity(0.3), size: 18)),
          ),
        ),
        const SizedBox(height: 12),
        // Content
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))),
          child: TextField(
            controller: _contentCtrl,
            maxLines: 8,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(border: InputBorder.none, hintText: 'Nội dung bài viết...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3))),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _posting ? null : _submitPost,
          icon: _posting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check, size: 16),
          label: Text(_posting ? 'Đang đăng...' : 'Đăng bài'),
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

  Color _tagColor(String tag) {
    switch (tag) {
      case 'Học tập': return Colors.blue;
      case 'Q&A': return Colors.orange;
      case 'Sinh hoạt': return Colors.green;
      case 'Thông báo': return Colors.purple;
      default: return Colors.grey;
    }
  }

  Future<void> _toggleLike(String postId, List<String> likes) async {
    final ref = FirebaseFirestore.instance.collection('forum_posts').doc(postId);
    if (likes.contains(_uid)) {
      await ref.update({'likes': FieldValue.arrayRemove([_uid])});
    } else {
      await ref.update({'likes': FieldValue.arrayUnion([_uid])});
    }
  }

  Future<void> _submitComment() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
    final authorName = userDoc.data()?['fullName'] ?? widget.email.split('@').first;

    await FirebaseFirestore.instance
        .collection('forum_posts').doc(_viewingPostId)
        .collection('comments')
        .add({
      'authorEmail': widget.email,
      'authorName': authorName,
      'authorRole': widget.role.name,
      'content': _commentCtrl.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update comment count
    await FirebaseFirestore.instance.collection('forum_posts').doc(_viewingPostId).update({
      'commentCount': FieldValue.increment(1),
    });

    _commentCtrl.clear();
  }

  Future<void> _submitPost() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tiêu đề và nội dung'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _posting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
      final authorName = userDoc.data()?['fullName'] ?? widget.email.split('@').first;

      await FirebaseFirestore.instance.collection('forum_posts').add({
        'title': _titleCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
        'tag': _newPostTag,
        'authorEmail': widget.email,
        'authorName': authorName,
        'authorRole': widget.role.name,
        'authorUid': user?.uid ?? '',
        'likes': [],
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleCtrl.clear();
      _contentCtrl.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Đăng bài thành công!'), backgroundColor: Colors.green.shade600));
        setState(() { _showCreateForm = false; _posting = false; });
      }
    } catch (e) {
      setState(() => _posting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
