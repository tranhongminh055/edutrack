import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    initError = e.toString();
    debugPrint('Firebase initialization error: $e');
  }

  FlutterError.onError = (details) {
    debugPrint('Flutter Error: ${details.exception}');
  };

  runZonedGuarded(() {
    runApp(EduTrackApp(initError: initError));
  }, (error, stackTrace) {
    debugPrint('Unhandled Error: $error');
  });
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class EduTrackApp extends StatelessWidget {
  final String? initError;
  const EduTrackApp({super.key, this.initError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduTrack',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: initError != null
          ? Scaffold(body: Center(child: Text('Firebase Init Error: $initError', style: const TextStyle(color: Colors.red, fontSize: 16))))
          : const AuthWrapper(),
    );
  }
}
