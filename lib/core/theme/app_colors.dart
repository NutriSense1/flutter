import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF0F9D58);
  static const Color primaryLight = Color(0xFF43C97E);
  static const Color primaryDark = Color(0xFF007A3E);

  // Secondary
  static const Color secondary = Color(0xFFD8F3DC);

  // Accent
  static const Color accent = Color(0xFFF4B400);
  static const Color accentDark = Color(0xFFE0A000);

  // Background
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Dark Mode
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF1A2332);
  static const Color darkSurfaceVariant = Color(0xFF243044);

  // Text
  static const Color textPrimary = Color(0xFF0F1B2D);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFFADB5BD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Dark Text
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Nutrition
  static const Color calories = Color(0xFFF97316);
  static const Color protein = Color(0xFF8B5CF6);
  static const Color carbs = Color(0xFF3B82F6);
  static const Color fat = Color(0xFFF59E0B);
  static const Color fiber = Color(0xFF10B981);
  static const Color sugar = Color(0xFFEC4899);
  static const Color water = Color(0xFF06B6D4);
  static const Color sodium = Color(0xFFEF4444);

  // Health Score
  static const Color scoreExcellent = Color(0xFF22C55E);
  static const Color scoreGood = Color(0xFF84CC16);
  static const Color scoreFair = Color(0xFFF59E0B);
  static const Color scorePoor = Color(0xFFEF4444);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F9D58), Color(0xFF007A3E)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF4B400), Color(0xFFE0A000)],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A2332), Color(0xFF243044)],
  );

  // Divider
  static const Color divider = Color(0xFFE2E8F0);
  static const Color darkDivider = Color(0xFF334155);

  // Shadow
  static const Color shadow = Color(0x1A0F1B2D);
}
