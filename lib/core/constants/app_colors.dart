import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Aqua Theme
  static const Color primary = Color(0xFF0284C7); // Sky 600
  static const Color primaryLight = Color(0xFF38BDF8); // Sky 400
  static const Color primaryDark = Color(0xFF0369A1); // Sky 700

  static const Color secondary = Color(0xFF0D9488); // Teal 600
  static const Color secondaryLight = Color(0xFF2DD4BF); // Teal 400
  static const Color accent = Color(0xFF06B6D4); // Cyan 500

  // Dark & Surface Colors
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFF1F5F9); // Slate 100
  static const Color border = Color(0xFFE2E8F0); // Slate 200

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Role Badge & Status Colors
  static const Color customerBadge = Color(0xFF0284C7);
  static const Color dealerBadge = Color(0xFFD97706); // Amber 600
  static const Color adminBadge = Color(0xFF7C3AED); // Violet 600

  static const Color success = Color(0xFF16A34A); // Emerald 600
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFDC2626); // Red 600
  static const Color info = Color(0xFF2563EB); // Blue 600

  // Gradients
  static const LinearGradient aquaGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dealerGradient = LinearGradient(
    colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
