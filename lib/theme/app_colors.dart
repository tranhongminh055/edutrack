import 'package:flutter/material.dart';

class AppColors {
  // Primary green palette
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color accentGreen = Color(0xFF66BB6A);

  // Gradient colors
  static const Color gradientStart = Color(0xFF43A047);
  static const Color gradientEnd = Color(0xFF66BB6A);

  // Background
  static const Color darkBg = Color(0xFF0A1A0F);
  static const Color cardBg = Color(0x33FFFFFF);
  static const Color glassBg = Color(0x1AFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textHint = Color(0x80FFFFFF);

  // Role colors
  static const Color studentColor = Color(0xFF4CAF50);
  static const Color lecturerColor = Color(0xFF00BCD4);
  static const Color adminColor = Color(0xFFFF9800);

  // Input
  static const Color inputBorder = Color(0x4DFFFFFF);
  static const Color inputFill = Color(0x1AFFFFFF);

  // Gradient for buttons
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [
      Color(0x33388E3C),
      Color(0x1A66BB6A),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
