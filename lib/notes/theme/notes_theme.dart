import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Selectable visual theme types for the V3 Notes module.
enum NotesThemeType {
  terracotta,
  teal,
  monochrome;

  /// Stable persistence value stored in SharedPreferences.
  String get storageValue {
    switch (this) {
      case NotesThemeType.terracotta:
        return 'terracotta';
      case NotesThemeType.teal:
        return 'teal';
      case NotesThemeType.monochrome:
        return 'monochrome';
    }
  }

  /// User-facing display title.
  String get displayName {
    switch (this) {
      case NotesThemeType.terracotta:
        return 'TERRACOTTA / EARTH';
      case NotesThemeType.teal:
        return 'TEAL / DEEP GREEN';
      case NotesThemeType.monochrome:
        return 'MONOCHROME + RUST';
    }
  }

  /// User-facing title-case display name.
  String get titleCaseName {
    switch (this) {
      case NotesThemeType.terracotta:
        return 'Terracotta / Earth';
      case NotesThemeType.teal:
        return 'Teal / Deep Green';
      case NotesThemeType.monochrome:
        return 'Monochrome + Rust';
    }
  }

  /// User-facing subtitle description.
  String get subtitle {
    switch (this) {
      case NotesThemeType.terracotta:
        return 'Warm • Creative • Mature';
      case NotesThemeType.teal:
        return 'Calm • Modern • Technical';
      case NotesThemeType.monochrome:
        return 'Minimal • Premium • Editorial';
    }
  }

  /// Parses stored string key, defaulting to [NotesThemeType.terracotta].
  static NotesThemeType fromStorageValue(String? value) {
    if (value == 'teal') return NotesThemeType.teal;
    if (value == 'monochrome') return NotesThemeType.monochrome;
    return NotesThemeType.terracotta;
  }
}

/// Color tokens tailored specifically for Notes V3 screens.
/// Implements centralized V3ThemePalette with semantic roles.
class NotesColors {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color card;
  final Color textMain;
  final Color textSecondary;
  final Color border;
  final Color barBackground;
  final Color completed;
  final Color highlight;
  final Color warning;
  final Color error;

  const NotesColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.card,
    required this.textMain,
    required this.textSecondary,
    required this.border,
    required this.barBackground,
    required this.completed,
    required this.highlight,
    this.warning = const Color(0xFFD97706),
    this.error = const Color(0xFFDC2626),
  });

  // ── Centralized Semantic Role Mapping ─────────────────────────────────────
  Color get primaryText => textMain;
  Color get secondaryText => textSecondary;
  Color get accent => primary;
  Color get secondaryAccent => secondary;
  Color get pinned => primary;
  Color get selected => highlight;
  Color get divider => border;
  Color get progressTrack => barBackground;

  // ── THEME 1: TERRACOTTA / EARTH ──────────────────────────────────────────

  static const terracottaDark = NotesColors(
    primary: Color(0xFFD97757),
    secondary: Color(0xFFB85D3B),
    background: Color(0xFF191614),
    surface: Color(0xFF231F1C),
    card: Color(0xFF2C2723),
    textMain: Color(0xFFF7F3EE),
    textSecondary: Color(0xFFA39A90),
    border: Color(0xFF3B342E),
    barBackground: Color(0xFF332C26),
    completed: Color(0xFF7EA187),
    highlight: Color(0xFF2E2620),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
  );

  static const terracottaLight = NotesColors(
    primary: Color(0xFFC05A3A),
    secondary: Color(0xFFA8482A),
    background: Color(0xFFFBF9F6),
    surface: Color(0xFFF3EEE8),
    card: Color(0xFFFFFFFF),
    textMain: Color(0xFF2B2520),
    textSecondary: Color(0xFF7A7066),
    border: Color(0xFFE5DDD5),
    barBackground: Color(0xFFEFE8E0),
    completed: Color(0xFF4D7858),
    highlight: Color(0xFFF6EDE4),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
  );

  // ── THEME 2: TEAL / DEEP GREEN ──────────────────────────────────────────

  static const tealDark = NotesColors(
    primary: Color(0xFF2DD4BF),
    secondary: Color(0xFF14B8A6),
    background: Color(0xFF0F1717),
    surface: Color(0xFF142221),
    card: Color(0xFF1A2D2C),
    textMain: Color(0xFFEDF5F4),
    textSecondary: Color(0xFF86A3A0),
    border: Color(0xFF243B39),
    barBackground: Color(0xFF203332),
    completed: Color(0xFF48BB78),
    highlight: Color(0xFF162726),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
  );

  static const tealLight = NotesColors(
    primary: Color(0xFF0D9488),
    secondary: Color(0xFF115E59),
    background: Color(0xFFF5FAF9),
    surface: Color(0xFFEBF4F3),
    card: Color(0xFFFFFFFF),
    textMain: Color(0xFF132B29),
    textSecondary: Color(0xFF5B7A77),
    border: Color(0xFFD2E4E2),
    barBackground: Color(0xFFE0EFEB),
    completed: Color(0xFF277B50),
    highlight: Color(0xFFE5F2F0),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
  );

  // ── THEME 3: MONOCHROME + RUST ──────────────────────────────────────────

  static const monochromeDark = NotesColors(
    primary: Color(0xFFC84B31),
    secondary: Color(0xFFA83A22),
    background: Color(0xFF121214),
    surface: Color(0xFF1B1B1E),
    card: Color(0xFF24242A),
    textMain: Color(0xFFF5F5F7),
    textSecondary: Color(0xFF8E8E98),
    border: Color(0xFF2E2E36),
    barBackground: Color(0xFF26262E),
    completed: Color(0xFF5CA375),
    highlight: Color(0xFF222228),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
  );

  static const monochromeLight = NotesColors(
    primary: Color(0xFFB84228),
    secondary: Color(0xFF94321C),
    background: Color(0xFFFAFAFB),
    surface: Color(0xFFF0F0F3),
    card: Color(0xFFFFFFFF),
    textMain: Color(0xFF18181B),
    textSecondary: Color(0xFF71717A),
    border: Color(0xFFE4E4E7),
    barBackground: Color(0xFFEAEAEF),
    completed: Color(0xFF3F7A54),
    highlight: Color(0xFFF2F2F5),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
  );
}

/// Scoped accessor for retrieving active [NotesColors] based on user preference and brightness.
class NotesTheme {
  /// Returns the appropriate [NotesColors] for the active [NotesThemeType] and [Brightness].
  static NotesColors of(BuildContext context) {
    final themeController = ThemeScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return getPalette(themeController.notesTheme, isDark: isDark);
  }

  /// Retrieves palette directly given a [NotesThemeType] and [isDark] flag.
  static NotesColors getPalette(NotesThemeType type, {required bool isDark}) {
    switch (type) {
      case NotesThemeType.terracotta:
        return isDark ? NotesColors.terracottaDark : NotesColors.terracottaLight;
      case NotesThemeType.teal:
        return isDark ? NotesColors.tealDark : NotesColors.tealLight;
      case NotesThemeType.monochrome:
        return isDark ? NotesColors.monochromeDark : NotesColors.monochromeLight;
    }
  }

  /// 4 representative preview colors for the theme selector cards.
  static List<Color> previewColors(NotesThemeType type, {required bool isDark}) {
    final p = getPalette(type, isDark: isDark);
    return [p.primary, p.surface, p.card, p.secondary];
  }
}

/// Centralized aliases for V3 theme architecture
typedef V3ThemePalette = NotesColors;
typedef V3Theme = NotesTheme;
