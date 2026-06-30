import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import '../../widgets/role_selector.dart';

class ELearningDashboard extends StatefulWidget {
  final UserRole role;
  final String userId;
  final String email;
  final String currentSemester;
  final String currentYear;

  const ELearningDashboard({
    super.key,
    required this.role,
    required this.userId,
    required this.email,
    required this.currentSemester,
    required this.currentYear,
  });

  @override
  State<ELearningDashboard> createState() => _ELearningDashboardState();
}

class _ELearningDashboardState extends State<ELearningDashboard> {
  // URL trỏ đến ứng dụng React E-Learning
  String get elearningUrl {
    final role = widget.role == UserRole.student ? 'student' : 'lecturer';
    return 'https://edutrack-elearning.web.app/?userId=${Uri.encodeComponent(widget.userId)}&role=$role&email=${Uri.encodeComponent(widget.email)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.language, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                'E-LEARNING',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Test & Quiz',
                  style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  web.window.open(elearningUrl, '_blank');
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Mở trang E-Learning'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz, size: 80, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 24),
                const Text(
                  'Hệ thống Test & Quiz',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bấm nút "Mở trang E-Learning" để truy cập hệ thống\nkiểm tra và đánh giá trực tuyến.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    web.window.open(elearningUrl, '_blank');
                  },
                  icon: const Icon(Icons.launch, size: 20),
                  label: const Text('Mở E-Learning', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
