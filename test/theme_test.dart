import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_routine/main.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeController Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Defaults to ThemeMode.dark when no preference is saved', () async {
      final controller = await ThemeController.init();
      expect(controller.value, ThemeMode.dark);
      expect(controller.isDarkMode, isTrue);
    });

    test('Restores ThemeMode.dark from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        ThemeController.themeModeKey: 'dark',
      });
      final controller = await ThemeController.init();
      expect(controller.value, ThemeMode.dark);
      expect(controller.isDarkMode, isTrue);
    });

    test('toggleTheme alternates between light and dark and persists to prefs', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = ThemeController(ThemeMode.light, prefs);

      // Toggle to dark
      controller.toggleTheme();
      expect(controller.value, ThemeMode.dark);
      expect(controller.isDarkMode, isTrue);
      expect(prefs.getString(ThemeController.themeModeKey), 'dark');

      // Toggle back to light
      controller.toggleTheme();
      expect(controller.value, ThemeMode.light);
      expect(controller.isDarkMode, isFalse);
      expect(prefs.getString(ThemeController.themeModeKey), 'light');
    });

    test('Theme persistence does not modify or overwrite other data keys', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('activities', '[{"id":"meditation"}]');
      await prefs.setString('activity_history', '[]');

      final controller = ThemeController(ThemeMode.light, prefs);
      controller.setThemeMode(ThemeMode.dark);

      // Check theme was saved
      expect(prefs.getString(ThemeController.themeModeKey), 'dark');
      // Verify other keys remain completely intact
      expect(prefs.getString('activities'), '[{"id":"meditation"}]');
      expect(prefs.getString('activity_history'), '[]');
    });

    testWidgets('ThemeScope fallback returns dark ThemeController when unnested', (
      WidgetTester tester,
    ) async {
      ThemeController? extracted;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            extracted = ThemeScope.of(context);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(extracted?.value, ThemeMode.dark);
    });
  });

  group('Theme Widget & UI Polish Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Tapping theme toggle button in AppBar switches app theme', (
      WidgetTester tester,
    ) async {
      final repo = InMemoryActivityRepository();
      final themeController = ThemeController(ThemeMode.light);

      await tester.pumpWidget(DailyRoutineApp(
        repository: repo,
        themeController: themeController,
      ));

      // Initially in Light Mode
      expect(themeController.value, ThemeMode.light);
      expect(find.byKey(const Key('settings_button')), findsOneWidget);

      // Open Settings
      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();

      // Tap Dark option in Settings
      expect(find.byKey(const Key('theme_option_dark')), findsOneWidget);
      await tester.tap(find.byKey(const Key('theme_option_dark')));
      await tester.pumpAndSettle();

      // Now in Dark Mode
      expect(themeController.value, ThemeMode.dark);

      // Tap Light option to switch back to Light Mode
      expect(find.byKey(const Key('theme_option_light')), findsOneWidget);
      await tester.tap(find.byKey(const Key('theme_option_light')));
      await tester.pumpAndSettle();

      // Back in Light Mode
      expect(themeController.value, ThemeMode.light);
    });

    testWidgets('ActivityCard renders clean text without aggressive strikethrough', (
      WidgetTester tester,
    ) async {
      final repo = InMemoryActivityRepository();
      // Complete meditation
      repo.setActivityCompletion('meditation', isCompleted: true);

      await tester.pumpWidget(DailyRoutineApp(repository: repo));

      // Find the meditation text widget
      final textWidget = tester.widget<Text>(find.text('Meditation'));
      // Verify NO lineThrough decoration is used
      expect(textWidget.style?.decoration, isNot(TextDecoration.lineThrough));
      // Verify checkmark badge is visible
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('Settings button is accessible from History and Progress tabs', (
      WidgetTester tester,
    ) async {
      final repo = InMemoryActivityRepository();
      final themeController = ThemeController(ThemeMode.light);

      await tester.pumpWidget(DailyRoutineApp(
        repository: repo,
        themeController: themeController,
      ));

      // Switch to History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings_button')), findsOneWidget);

      // Switch to Progress tab
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings_button')), findsOneWidget);

      // Open Settings from Progress tab and switch theme
      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('theme_option_dark')));
      await tester.pumpAndSettle();
      expect(themeController.value, ThemeMode.dark);
    });

    test('Serene Plum & Lavender light theme palette tokens match approved specifications', () {
      expect(AppTheme.lightBackground, const Color(0xFFF7F5F0));
      expect(AppTheme.lightCard, const Color(0xFFFFFFFF));
      expect(AppTheme.lightTextMain, const Color(0xFF2D232E));
      expect(AppTheme.lightTextSecondary, const Color(0xFF7E7381));
      expect(AppTheme.lightPrimary, const Color(0xFF9E8FC8));
      expect(AppTheme.lightSecondary, const Color(0xFF8A7AA8));
      expect(AppTheme.lightHighlight, const Color(0xFFF2EFF8));
      expect(AppTheme.lightBarBg, const Color(0xFFECE8F5));
      expect(AppTheme.lightCompleted, const Color(0xFF7E69AB));
      expect(AppTheme.lightSkipped, const Color(0xFFC48B71));
      expect(AppTheme.lightMissed, const Color(0xFFD9776E));
      expect(AppTheme.lightBorder, const Color(0xFFEFECE6));
    });

    test('Dark theme palette tokens match approved Money V2 specifications', () {
      expect(AppTheme.darkBackground, const Color(0xFF090D16));
      expect(AppTheme.darkSurface, const Color(0xFF111827));
      expect(AppTheme.darkCard, const Color(0xFF162032));
      expect(AppTheme.darkPrimaryText, const Color(0xFFF8FAFC));
      expect(AppTheme.darkSecondaryText, const Color(0xFF94A3B8));
      expect(AppTheme.darkPrimaryAccent, const Color(0xFF06B6D4));
      expect(AppTheme.darkSecondaryAccent, const Color(0xFF3B82F6));
      expect(AppTheme.darkAccentGlow, const Color(0xFF06B6D4));
      expect(AppTheme.darkIncome, const Color(0xFF22C55E));
      expect(AppTheme.darkExpense, const Color(0xFFF87171));
      expect(AppTheme.darkSavings, const Color(0xFF38BDF8));
      expect(AppTheme.darkWarning, const Color(0xFFFBBF24));
      expect(AppTheme.darkError, const Color(0xFFEF4444));
      expect(AppTheme.darkBorder, const Color(0xFF1E293B));
      expect(AppTheme.darkDivider, const Color(0xFF1A2333));
      expect(AppTheme.darkProgressTrack, const Color(0xFF1E293B));
      expect(AppTheme.darkChartColors, const [
        Color(0xFF06B6D4),
        Color(0xFF3B82F6),
        Color(0xFF22C55E),
        Color(0xFFFBBF24),
        Color(0xFF6366F1),
      ]);
    });

    test('Dark theme semantic colors use cyberNoirSurface for highlight and containers', () {
      expect(AppTheme.darkAppColors.highlight, AppTheme.cyberNoirSurface);
      expect(AppTheme.darkTheme.colorScheme.primaryContainer, AppTheme.cyberNoirSurface);
      expect(AppTheme.darkTheme.colorScheme.onPrimaryContainer, AppTheme.cyberNoirPrimary);
    });

    testWidgets('Dark Mode ActivityCard renders icon container with dark neutral surface and cyan/completed icon', (
      WidgetTester tester,
    ) async {
      final repo = InMemoryActivityRepository();
      final themeController = ThemeController(ThemeMode.dark);

      await tester.pumpWidget(DailyRoutineApp(
        repository: repo,
        themeController: themeController,
      ));
      await tester.pumpAndSettle();

      // Find icon container for Meditation (pending)
      final iconFinder = find.byIcon(Icons.self_improvement);
      expect(iconFinder, findsOneWidget);
      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.color, AppTheme.cyberNoirPrimary);

      // Find the parent Container of the icon
      final containerFinder = find.ancestor(
        of: iconFinder,
        matching: find.byType(Container),
      ).first;
      final containerWidget = tester.widget<Container>(containerFinder);
      final decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.color, AppTheme.cyberNoirSurface);
      expect(decoration.shape, BoxShape.circle);
      final border = decoration.border as Border;
      expect(border.top.color, AppTheme.cyberNoirBorder);

      // Tap the first checkbox to toggle meditation to completed
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      final completedIcon = tester.widget<Icon>(find.byIcon(Icons.self_improvement));
      expect(completedIcon.color, AppTheme.cyberNoirCompleted);
    });

    testWidgets('Dark Mode HistoryScreen renders activity rows with styled activity icon containers', (
      WidgetTester tester,
    ) async {
      final repo = InMemoryActivityRepository();
      final themeController = ThemeController(ThemeMode.dark);

      await tester.pumpWidget(DailyRoutineApp(
        repository: repo,
        themeController: themeController,
      ));
      await tester.pumpAndSettle();

      // Switch to History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Today's record should have activity icons present in History
      expect(find.byIcon(Icons.self_improvement), findsOneWidget);
      expect(find.byIcon(Icons.directions_walk), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);

      // Verify the activity icon container on History has dark neutral surface
      final meditationIcon = find.byIcon(Icons.self_improvement);
      final historyContainer = find.ancestor(
        of: meditationIcon,
        matching: find.byType(Container),
      ).first;
      final containerWidget = tester.widget<Container>(historyContainer);
      final decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.color, AppTheme.cyberNoirSurface);
      expect(decoration.shape, BoxShape.circle);
      final border = decoration.border as Border;
      expect(border.top.color, AppTheme.cyberNoirBorder);
    });

    testWidgets('Today screen renders circular progress completion ring', (
      WidgetTester tester,
    ) async {
      final repo = InMemoryActivityRepository();
      await tester.pumpWidget(DailyRoutineApp(repository: repo));

      // Verify circular progress indicator and Complete label exist in Today's Plan
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Complete'), findsOneWidget);
      expect(find.text('0%'), findsWidgets);
    });
  });
}
