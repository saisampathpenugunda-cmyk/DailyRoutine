import 'package:flutter/material.dart';

/// Palette values for Money V2.
class MoneyColors {
  final Color background;
  final Color surface;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color income;
  final Color expense;
  final Color savings;
  final Color warning;
  final Color error;
  final Color border;
  final Color divider;
  final Color progressTrack;

  const MoneyColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.income,
    required this.expense,
    required this.savings,
    required this.warning,
    required this.error,
    required this.border,
    required this.divider,
    required this.progressTrack,
  });

  /// Chart colors palette
  static const List<Color> chartColors = [
    Color(0xFF06B6D4),
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFFFBBF24),
    Color(0xFF6366F1),
  ];

  /// Dark Theme (Primary Identity for Money V2)
  static const dark = MoneyColors(
    background: Color(0xFF090D16),
    surface: Color(0xFF111827),
    card: Color(0xFF162032),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    primaryAccent: Color(0xFF06B6D4),
    secondaryAccent: Color(0xFF3B82F6),
    income: Color(0xFF22C55E),
    expense: Color(0xFFF87171),
    savings: Color(0xFF38BDF8),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFEF4444),
    border: Color(0xFF1E293B),
    divider: Color(0xFF1A2333),
    progressTrack: Color(0xFF1E293B),
  );

  /// Light Theme for Money V2
  static const light = MoneyColors(
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFF1F5F9),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    primaryAccent: Color(0xFF0EA5E9),
    secondaryAccent: Color(0xFF2563EB),
    income: Color(0xFF16A34A),
    expense: Color(0xFFDC2626),
    savings: Color(0xFF0284C7),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    border: Color(0xFFE2E8F0),
    divider: Color(0xFFCBD5E1),
    progressTrack: Color(0xFFE2E8F0),
  );
}

/// Helper for retrieving current scoped Money theme tokens.
class MoneyTheme {
  /// Returns the appropriate [MoneyColors] based on the current theme brightness.
  static MoneyColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? MoneyColors.dark : MoneyColors.light;
  }
}
