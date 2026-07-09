import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/role_selector.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _checking = true;
  Widget? _destination;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is logged in, fetch their profile from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final userData = doc.data()!;
          final String roleStr = (userData['role'] ?? 'student').toString();
          UserRole role = UserRole.student;
          if (roleStr == 'lecturer') {
            role = UserRole.lecturer;
          } else if (roleStr == 'admin') {
            role = UserRole.admin;
          }

          if (mounted) {
            setState(() {
              _destination = HomeScreen(
                role: role,
                email: (userData['email'] ?? user.email ?? '').toString(),
                studentId: (userData['studentId'] ?? '').toString(),
                fullName: (userData['fullName'] ?? '').toString(),
              );
              _checking = false;
            });
          }
          return;
        } else {
          // User exists in Auth but not in Firestore, sign them out
          await FirebaseAuth.instance.signOut();
        }
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
      // On any error, just show WelcomeScreen
    }

    if (mounted) {
      setState(() {
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      // Show WelcomeScreen immediately while checking auth in background
      // This prevents blank/gray screen
      return const WelcomeScreen();
    }

    return _destination ?? const WelcomeScreen();
  }
}
