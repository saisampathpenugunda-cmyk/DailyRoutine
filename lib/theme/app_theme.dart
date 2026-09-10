import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Semantic colors for DailyRoutine themes:
/// - Light: "Urban Zen"
/// - Dark: "Cyber Noir" (refined dark)
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color highlight;
  final Color background;
  final Color surface;
  final Color card;
  final Color textMain;
  final Color textSecondary;
  final Color completed;
  final Color skipped;
  final Color missed;
  final Color border;
  final Color barBackground;

  const AppThemeColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.highlight,
    required this.background,
    required this.surface,
    required this.card,
    required this.textMain,
    required this.textSecondary,
    required this.completed,
    required this.skipped,
    this.missed = const Color(0xFFD9776E),
    required this.border,
    required this.barBackground,
  });

  @override
  AppThemeColors copyWith({
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? highlight,
    Color? background,
    Color? surface,
    Color? card,
    Color? textMain,
    Color? textSecondary,
    Color? completed,
    Color? skipped,
    Color? missed,
    Color? border,
    Color? barBackground,
  }) {
    return AppThemeColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      highlight: highlight ?? this.highlight,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      textMain: textMain ?? this.textMain,
      textSecondary: textSecondary ?? this.textSecondary,
      completed: completed ?? this.completed,
      skipped: skipped ?? this.skipped,
      missed: missed ?? this.missed,
      border: border ?? this.border,
      barBackground: barBackground ?? this.barBackground,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      textMain: Color.lerp(textMain, other.textMain, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      completed: Color.lerp(completed, other.completed, t)!,
      skipped: Color.lerp(skipped, other.skipped, t)!,
      missed: Color.lerp(missed, other.missed, t)!,
      border: Color.lerp(border, other.border, t)!,
      barBackground: Color.lerp(barBackground, other.barBackground, t)!,
    );
  }
}

/// Helper extension on [BuildContext] to access [AppThemeColors] easily.
extension ThemeBuildContextExtension on BuildContext {
  AppThemeColors get appColors =>
      Theme.of(this).extension<AppThemeColors>() ?? AppTheme.lightAppColors;
}

class AppTheme {
  // ── Geometric Radii (18–20px Modern Rounded Aesthetic) ───────────────────
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double borderWidth = 1.0;

  // ── Light Theme Palette ("Serene Plum & Lavender") ───────────────────────
  static const Color lightBackground = Color(0xFFF7F5F0);    // Warm ivory / off-white
  static const Color lightCard = Color(0xFFFFFFFF);          // Pure white card
  static const Color lightSurface = Color(0xFFFFFFFF);       // Pure white surface
  static const Color lightTextMain = Color(0xFF2D232E);      // Deep dark plum typography
  static const Color lightTextSecondary = Color(0xFF7E7381); // Soft plum-slate typography
  static const Color lightPrimary = Color(0xFF9E8FC8);       // Soft lavender / lilac accent
  static const Color lightSecondary = Color(0xFF8A7AA8);     // Medium lilac
  static const Color lightAccent = Color(0xFF6B5887);        // Deep lilac / plum
  static const Color lightHighlight = Color(0xFFF2EFF8);     // Subtle lavender-tinted surface
  static const Color lightCompleted = Color(0xFF7E69AB);     // Subtle lavender/plum checkmark badge
  static const Color lightSkipped = Color(0xFFC48B71);       // Warm soft terracotta
  static const Color lightMissed = Color(0xFFD9776E);        // Soft pastel rose / warning
  static const Color lightBorder = Color(0xFFEFECE6);        // Soft warm border
  static const Color lightBarBg = Color(0xFFECE8F5);         // Light lavender progress track

  // Soft low-contrast shadow for light cards
  static const List<BoxShadow> lightCardShadow = [
    BoxShadow(
      color: Color(0x08000000), // very soft 3% shadow
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  // ── Backward-compatible Light Aliases ────────────────────────────────────
  static const Color urbanZenPrimary = lightPrimary;
  static const Color urbanZenSecondary = lightSecondary;
  static const Color urbanZenAccent = lightAccent;
  static const Color urbanZenHighlight = lightHighlight;
  static const Color urbanZenBackground = lightBackground;
  static const Color urbanZenCard = lightCard;
  static const Color urbanZenTextMain = lightTextMain;
  static const Color urbanZenTextSecondary = lightTextSecondary;
  static const Color urbanZenCompleted = lightCompleted;
  static const Color urbanZenSkipped = lightSkipped;
  static const Color urbanZenBorder = lightBorder;
  static const Color urbanZenBarBg = lightBarBg;

  // ── Cyber Noir (Dark Theme Palette - Strictly Preserved) ──────────────────
  static const Color cyberNoirBackground = Color(0xFF101416);   // Background
  static const Color cyberNoirSurface = Color(0xFF181E21);      // Surface
  static const Color cyberNoirCard = Color(0xFF20282C);         // Card
  static const Color cyberNoirPrimary = Color(0xFF8BCFD1);      // Primary
  static const Color cyberNoirSecondary = Color(0xFF6F818B);    // Secondary
  static const Color cyberNoirAccent = Color(0xFF00C7D4);       // Accent
  static const Color cyberNoirTextMain = Color(0xFFF1F5F6);     // Main text
  static const Color cyberNoirTextSecondary = Color(0xFFA5B2B8);// Secondary text
  static const Color cyberNoirCompleted = Color(0xFF31C49A);    // Completed
  static const Color cyberNoirSkipped = Color(0xFFE27D5F);      // Skipped/warning
  static const Color cyberNoirBorder = Color(0xFF2B363C);       // Card/container border
  static const Color cyberNoirBarBg = Color(0xFF1A2226);        // Track background

  // ── Switch Styling Constants (Polished Outlined Switch) ──────────────────
  // Light theme:
  static const Color lightSwitchTrackOutlineOn = Color(0xFF7E69AB);  // Strong primary purple outline (2.0px)
  static const Color lightSwitchThumbOn = Color(0xFF7E69AB);         // Prominent purple thumb (24px diameter)
  static const Color lightSwitchTrackOutlineOff = Color(0xFFB5A8C8); // Clearly visible muted purple outline (1.4px)
  static const Color lightSwitchThumbOff = Color(0xFFA699BC);        // Muted purple/grey circular thumb (16px diameter)

  // Dark theme (Cyber Noir):
  static const Color cyberNoirSwitchTrackOutlineOn = Color(0xFF8BCFD1);  // Electric cyan outline (2.0px)
  static const Color cyberNoirSwitchThumbOn = Color(0xFF8BCFD1);         // Vibrant cyan thumb (24px diameter)
  static const Color cyberNoirSwitchTrackOutlineOff = Color(0xFF556873); // Muted slate outline visible on dark card (1.4px)
  static const Color cyberNoirSwitchThumbOff = Color(0xFF6F818B);        // Muted slate thumb (16px diameter)

  // ── Semantic Color Objects ───────────────────────────────────────────────
  static const AppThemeColors lightAppColors = AppThemeColors(
    primary: lightPrimary,
    secondary: lightSecondary,
    accent: lightAccent,
    highlight: lightHighlight,
    background: lightBackground,
    surface: lightSurface,
    card: lightCard,
    textMain: lightTextMain,
    textSecondary: lightTextSecondary,
    completed: lightCompleted,
    skipped: lightSkipped,
    missed: lightMissed,
    border: lightBorder,
    barBackground: lightBarBg,
  );

  static const AppThemeColors darkAppColors = AppThemeColors(
    primary: cyberNoirPrimary,
    secondary: cyberNoirSecondary,
    accent: cyberNoirAccent,
    highlight: cyberNoirSurface,
    background: cyberNoirBackground,
    surface: cyberNoirSurface,
    card: cyberNoirCard,
    textMain: cyberNoirTextMain,
    textSecondary: cyberNoirTextSecondary,
    completed: cyberNoirCompleted,
    skipped: cyberNoirSkipped,
    missed: cyberNoirSkipped,
    border: cyberNoirBorder,
    barBackground: cyberNoirBarBg,
  );

  // ── Backward-compatible Aliases for Smooth Transition ────────────────────
  static const Color cobaltBlue = lightPrimary;
  static const Color emeraldGreen = lightCompleted;
  static const Color amberWarning = lightSkipped;
  static const Color crimsonRed = lightSkipped;
  static const Color slate50 = lightBackground;
  static const Color slate100 = lightBarBg;
  static const Color slate200 = lightBorder;
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = lightSecondary;
  static const Color slate500 = lightTextSecondary;
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = lightAccent;
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = lightTextMain;

  static AppThemeColors colorsOf(BuildContext context) => context.appColors;

  // ── Light ThemeData (Serene Plum & Lavender) ─────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        onPrimary: Colors.white,
        primaryContainer: lightHighlight,
        onPrimaryContainer: lightAccent,
        secondary: lightSecondary,
        onSecondary: Colors.white,
        tertiary: lightAccent,
        surface: lightCard,
        onSurface: lightTextMain,
        surfaceContainerLow: lightCard,
        surfaceContainerHighest: lightBarBg,
        outline: lightSecondary,
        outlineVariant: lightBorder,
        error: lightSkipped,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightTextMain,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightTextMain,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: lightBorder, width: borderWidth),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightCard,
        selectedItemColor: lightPrimary,
        unselectedItemColor: lightSecondary,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightTextMain,
          side: const BorderSide(color: lightBorder, width: borderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return lightSwitchThumbOn;
          return lightSwitchThumbOff;
        }),
        trackColor: const WidgetStatePropertyAll(Colors.transparent),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return lightSwitchTrackOutlineOn;
          return lightSwitchTrackOutlineOff;
        }),
        trackOutlineWidth: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return 2.0;
          return 1.4;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: borderWidth,
        space: 1,
      ),
      extensions: const [lightAppColors],
    );
  }

  // ── Cyber Noir (Dark ThemeData) ──────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: cyberNoirBackground,
      colorScheme: const ColorScheme.dark(
        primary: cyberNoirPrimary,
        onPrimary: cyberNoirBackground,
        primaryContainer: cyberNoirSurface,
        onPrimaryContainer: cyberNoirPrimary,
        secondary: cyberNoirSecondary,
        onSecondary: Colors.white,
        tertiary: cyberNoirAccent,
        surface: cyberNoirSurface,
        onSurface: cyberNoirTextMain,
        surfaceContainerLow: cyberNoirCard,
        surfaceContainerHighest: cyberNoirBarBg,
        outline: cyberNoirSecondary,
        outlineVariant: cyberNoirBorder,
        error: cyberNoirSkipped,
        onError: cyberNoirBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cyberNoirBackground,
        foregroundColor: cyberNoirTextMain,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: cyberNoirTextMain,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: cyberNoirCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: cyberNoirBorder, width: borderWidth),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cyberNoirSurface,
        selectedItemColor: cyberNoirPrimary,
        unselectedItemColor: cyberNoirSecondary,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cyberNoirPrimary,
          foregroundColor: cyberNoirBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cyberNoirTextMain,
          side: const BorderSide(color: cyberNoirBorder, width: borderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cyberNoirSwitchThumbOn;
          return cyberNoirSwitchThumbOff;
        }),
        trackColor: const WidgetStatePropertyAll(Colors.transparent),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cyberNoirSwitchTrackOutlineOn;
          return cyberNoirSwitchTrackOutlineOff;
        }),
        trackOutlineWidth: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return 2.0;
          return 1.4;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: cyberNoirBorder,
        thickness: borderWidth,
        space: 1,
      ),
      extensions: const [darkAppColors],
    );
  }
}

/// Manages active [ThemeMode] and persists user selection to SharedPreferences.
class ThemeController extends ValueNotifier<ThemeMode> {
  final SharedPreferences? _prefs;
  static const String themeModeKey = 'app_theme_mode';

  ThemeController(super.value, [this._prefs]);

  bool get isDarkMode => value == ThemeMode.dark;

  void toggleTheme() {
    final next = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }

  void setThemeMode(ThemeMode mode) {
    if (value == mode) return;
    value = mode;
    _prefs?.setString(themeModeKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  static Future<ThemeController> init([SharedPreferences? prefs]) async {
    final effectivePrefs = prefs ?? await SharedPreferences.getInstance();
    final saved = effectivePrefs.getString(themeModeKey);
    final mode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    return ThemeController(mode, effectivePrefs);
  }
}

/// Inherited scope to access [ThemeController] reactively from anywhere in the tree.
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    if (scope == null || scope.notifier == null) {
      return ThemeController(ThemeMode.light);
    }
    return scope.notifier!;
  }
}
