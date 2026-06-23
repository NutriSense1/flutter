import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary green
  static const Color primary = Color(0xFF0F9D58);
  static const Color primaryLight = Color(0xFF43C97E);
  static const Color primaryDark = Color(0xFF007A3E);

  // Secondary (light tint of primary)
  static const Color secondary = Color(0xFFD8F3DC);

  // Accent amber
  static const Color accent = Color(0xFFF4B400);
  static const Color accentDark = Color(0xFFE0A000);

  // ── Light Mode ─────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color shadow = Color(0x1A0F1B2D);

  static const Color textPrimary = Color(0xFF0F1B2D);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFFADB5BD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Dark Mode ──────────────────────────────────────────────────────────────
  // Warm dark — not pure black. Feels premium rather than harsh.
  static const Color darkBackground = Color(0xFF111827);    // near-black indigo
  static const Color darkSurface = Color(0xFF1F2937);       // slate-800
  static const Color darkSurfaceVariant = Color(0xFF374151); // slate-700
  static const Color darkElevated = Color(0xFF293548);      // slightly lighter card
  static const Color darkDivider = Color(0xFF374151);
  static const Color darkShadow = Color(0x40000000);

  static const Color darkTextPrimary = Color(0xFFF9FAFB);    // near-white
  static const Color darkTextSecondary = Color(0xFF9CA3AF);  // slate-400
  static const Color darkTextHint = Color(0xFF6B7280);       // slate-500

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Nutrition ──────────────────────────────────────────────────────────────
  static const Color calories = Color(0xFFF97316);
  static const Color protein = Color(0xFF8B5CF6);
  static const Color carbs = Color(0xFF3B82F6);
  static const Color fat = Color(0xFFF59E0B);
  static const Color fiber = Color(0xFF10B981);
  static const Color sugar = Color(0xFFEC4899);
  static const Color water = Color(0xFF06B6D4);
  static const Color sodium = Color(0xFFEF4444);

  // ── Health Score ───────────────────────────────────────────────────────────
  static const Color scoreExcellent = Color(0xFF22C55E);
  static const Color scoreGood = Color(0xFF84CC16);
  static const Color scoreFair = Color(0xFFF59E0B);
  static const Color scorePoor = Color(0xFFEF4444);

  // ── Gradients ──────────────────────────────────────────────────────────────
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
    colors: [Color(0xFF1F2937), Color(0xFF293548)],
  );

  // ── Helper: surface colour that adapts to brightness ──────────────────────
  static Color adaptiveSurface(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurface : surface;

  static Color adaptiveSurfaceVariant(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurfaceVariant : surfaceVariant;

  static Color adaptiveDivider(Brightness brightness) =>
      brightness == Brightness.dark ? darkDivider : divider;

  static Color adaptiveTextPrimary(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextPrimary : textPrimary;

  static Color adaptiveTextSecondary(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextSecondary : textSecondary;
}
