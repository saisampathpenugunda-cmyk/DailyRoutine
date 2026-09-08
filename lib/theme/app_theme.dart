import 'package:flutter/material.dart';

class AppTheme {
  // ── Static Brand & Semantic Palette ──────────────────────────────────────
  static const Color cobaltBlue = Color(0xFF2563EB); // Static Primary
  static const Color deepCobalt = Color(0xFF1D4ED8);
  static const Color emeraldGreen = Color(0xFF059669); // Static Success
  static const Color brightEmerald = Color(0xFF10B981);
  static const Color amberWarning = Color(0xFFD97706); // Static In-Progress
  static const Color crimsonRed = Color(0xFFE11D48); // Static Skipped / Error

  // ── Neutral Slate Palette ────────────────────────────────────────────────
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF0B0F17);

  // ── Geometric Radii (Subtle & Sharp) ─────────────────────────────────────
  static const double radiusSmall = 6.0;
  static const double radiusMedium = 10.0;
  static const double radiusLarge = 14.0;
  static const double borderWidth = 1.2;

  // ── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: slate50,
      colorScheme: const ColorScheme.light(
        primary: cobaltBlue,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFDBEAFE),
        onPrimaryContainer: Color(0xFF1E40AF),
        secondary: slate700,
        surface: Colors.white,
        onSurface: slate900,
        surfaceContainerLow: Colors.white,
        surfaceContainerHighest: slate100,
        outline: slate500,
        outlineVariant: slate200,
        error: crimsonRed,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: slate900,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: slate900,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: slate200, width: borderWidth),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cobaltBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: slate900,
          side: const BorderSide(color: slate300, width: borderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: slate200,
        thickness: borderWidth,
        space: 1,
      ),
    );
  }
}
