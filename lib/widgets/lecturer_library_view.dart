import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';

class LecturerLibraryView extends StatefulWidget {
  final String email;
  const LecturerLibraryView({super.key, required this.email});

  @override
  State<LecturerLibraryView> createState() => _LecturerLibraryViewState();
}

class _LecturerLibraryViewState extends State<LecturerLibraryView> {
  final _searchCtrl = TextEditingController();
  bool _showAddForm = false;
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _searchQuery = '';
  bool _adding = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _categoryCtrl.dispose();
    _descCtrl.dispose();
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
              const Icon(Icons.local_library, color: AppColors.lecturerColor, size: 28),
              const SizedBox(width: 12),
              const Text('THƯ VIỆN ĐIỆN TỬ', style: TextStyle(color: AppColors.lecturerColor, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (!_showAddForm)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showAddForm = true),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm tài liệu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lecturerColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Search bar
          if (!_showAddForm)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Tìm kiếm tài liệu, sách, giáo trình...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  icon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          const SizedBox(height: 16),
          // Content
          Expanded(
            child: _showAddForm ? _buildAddForm() : _buildResourcesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('library_resources')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final allDocs = snapshot.data?.docs ?? [];
        final docs = _searchQuery.isEmpty
            ? allDocs
            : allDocs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final title = (data['title'] ?? '').toString().toLowerCase();
                final author = (data['author'] ?? '').toString().toLowerCase();
                final cat = (data['category'] ?? '').toString().toLowerCase();
                return title.contains(_searchQuery) || author.contains(_searchQuery) || cat.contains(_searchQuery);
              }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.library_books, size: 64, color: Colors.white.withOpacity(0.15)),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty ? 'Chưa có tài liệu nào. Nhấn "Thêm tài liệu" để bắt đầu.' : 'Không tìm thấy kết quả phù hợp.',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15),
              ),
            ]),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            final ts = d['createdAt'] as Timestamp?;
            final date = ts != null ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}' : '';

            final catIcon = _catIcon(d['category'] ?? '');
            final catColor = _catColor(d['category'] ?? '');

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: catColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Icon(catIcon, color: catColor, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.person_outline, size: 14, color: Colors.white.withOpacity(0.4)),
                        const SizedBox(width: 4),
                        Text(d['author'] ?? 'Không rõ tác giả', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: catColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                          child: Text(d['category'] ?? 'Khác', style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 10),
                        Text(date, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                      ]),
                      if ((d['description'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(d['description'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ]),
                  ),
                  // Delete button for the uploader
                  if (d['uploaderEmail'] == widget.email)
                    GestureDetector(
                      onTap: () => _deleteResource(docId),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.delete_outline, size: 20, color: Colors.redAccent.withOpacity(0.6)),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => setState(() => _showAddForm = false),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.arrow_back, color: AppColors.lecturerColor, size: 18),
            SizedBox(width: 8),
            Text('Hủy', style: TextStyle(color: AppColors.lecturerColor, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('Thêm tài liệu mới', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _formField('Tên tài liệu / Sách', _titleCtrl, Icons.book),
        const SizedBox(height: 12),
        _formField('Tác giả', _authorCtrl, Icons.person),
        const SizedBox(height: 12),
        _formField('Thể loại (VD: Giáo trình, Tham khảo, Slide)', _categoryCtrl, Icons.category),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: _descCtrl,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Mô tả ngắn (tùy chọn)',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _adding ? null : _addResource,
          icon: _adding ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check, size: 16),
          label: Text(_adding ? 'Đang lưu...' : 'Lưu tài liệu'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lecturerColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    );
  }

  Widget _formField(String hint, TextEditingController ctrl, IconData icon) {
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

  IconData _catIcon(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('giáo trình')) return Icons.menu_book;
    if (c.contains('slide')) return Icons.slideshow;
    if (c.contains('tham khảo')) return Icons.bookmark;
    if (c.contains('luận văn')) return Icons.description;
    return Icons.library_books;
  }

  Color _catColor(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('giáo trình')) return Colors.blue;
    if (c.contains('slide')) return Colors.orange;
    if (c.contains('tham khảo')) return Colors.green;
    if (c.contains('luận văn')) return Colors.purple;
    return Colors.teal;
  }

  Future<void> _addResource() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên tài liệu'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _adding = true);
    try {
      await FirebaseFirestore.instance.collection('library_resources').add({
        'title': _titleCtrl.text.trim(),
        'author': _authorCtrl.text.trim(),
        'category': _categoryCtrl.text.trim().isEmpty ? 'Khác' : _categoryCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'uploaderEmail': widget.email,
        'uploaderUid': FirebaseAuth.instance.currentUser?.uid ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleCtrl.clear();
      _authorCtrl.clear();
      _categoryCtrl.clear();
      _descCtrl.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Đã thêm tài liệu thành công!'), backgroundColor: Colors.green.shade600));
        setState(() { _showAddForm = false; _adding = false; });
      }
    } catch (e) {
      setState(() => _adding = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteResource(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('library_resources').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Đã xóa tài liệu'), backgroundColor: Colors.orange.shade700));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
