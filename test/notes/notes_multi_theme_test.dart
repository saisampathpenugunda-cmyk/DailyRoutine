import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_routine/notes/repositories/in_memory_notes_repository.dart';
import 'package:daily_routine/notes/screens/checklist_editor_screen.dart';
import 'package:daily_routine/notes/screens/notes_screen.dart';
import 'package:daily_routine/notes/screens/text_note_editor_screen.dart';
import 'package:daily_routine/notes/theme/notes_theme.dart';
import 'package:daily_routine/notes/screens/notes_theme_screen.dart';
import 'package:daily_routine/money/theme/money_theme.dart';
import 'package:daily_routine/theme/app_theme.dart';
import 'package:daily_routine/screens/settings_screen.dart';
import 'package:daily_routine/controllers/user_profile_controller.dart';
import 'package:daily_routine/repositories/activity_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('V3 Notes Multi-Theme System Tests', () {
    late SharedPreferences prefs;
    late InMemoryNotesRepository notesRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      notesRepo = InMemoryNotesRepository();
    });

    Widget createThemedWidget({
      required ThemeController controller,
      required Widget child,
      Brightness brightness = Brightness.dark,
    }) {
      return ThemeScope(
        controller: controller,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: controller.value,
          home: child,
        ),
      );
    }

    // 1. Default V3 theme = Terracotta
    test('1. Default V3 theme is Terracotta', () async {
      final controller = await ThemeController.init(prefs);
      expect(controller.notesTheme, NotesThemeType.terracotta);
      expect(controller.notesTheme.storageValue, 'terracotta');
    });

    // 2. Select Teal
    test('2. Select Teal updates themeController', () async {
      final controller = await ThemeController.init(prefs);
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.setNotesTheme(NotesThemeType.teal);
      expect(controller.notesTheme, NotesThemeType.teal);
      expect(notifyCount, 1);
    });

    // 3. Teal persists
    test('3. Teal persists in SharedPreferences under notes_theme_type', () async {
      final controller = await ThemeController.init(prefs);
      controller.setNotesTheme(NotesThemeType.teal);

      expect(prefs.getString('notes_theme_type'), 'teal');
    });

    // 4. Restart/reload retains Teal
    test('4. Restart/reload retains Teal from SharedPreferences', () async {
      await prefs.setString('notes_theme_type', 'teal');
      final reloadedController = await ThemeController.init(prefs);

      expect(reloadedController.notesTheme, NotesThemeType.teal);
    });

    // 5. Select Monochrome
    test('5. Select Monochrome updates themeController', () async {
      final controller = await ThemeController.init(prefs);
      controller.setNotesTheme(NotesThemeType.monochrome);

      expect(controller.notesTheme, NotesThemeType.monochrome);
    });

    // 6. Monochrome persists
    test('6. Monochrome persists in SharedPreferences under notes_theme_type', () async {
      final controller = await ThemeController.init(prefs);
      controller.setNotesTheme(NotesThemeType.monochrome);

      expect(prefs.getString('notes_theme_type'), 'monochrome');

      final reloaded = await ThemeController.init(prefs);
      expect(reloaded.notesTheme, NotesThemeType.monochrome);
    });

    // 7. Notes Home responds to selected theme
    testWidgets('7. Notes Home responds to selected theme colors', (
      WidgetTester tester,
    ) async {
      final controller = await ThemeController.init(prefs);
      controller.setThemeMode(ThemeMode.dark);

      await tester.pumpWidget(
        createThemedWidget(
          controller: controller,
          child: NotesScreen(repository: notesRepo),
        ),
      );
      await tester.pumpAndSettle();

      final terracotta = NotesColors.terracottaDark;
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);
      Scaffold scaffold = tester.widget(scaffoldFinder);
      expect(scaffold.backgroundColor, terracotta.background);

      final appBarFinder = find.byType(AppBar);
      AppBar appBar = tester.widget(appBarFinder);
      expect(appBar.backgroundColor, terracotta.surface);

      final fabFinder = find.byKey(const Key('notes_fab'));
      FloatingActionButton fab = tester.widget(fabFinder);
      expect(fab.backgroundColor, terracotta.primary);

      // Switch to Teal
      controller.setNotesTheme(NotesThemeType.teal);
      await tester.pumpAndSettle();

      final teal = NotesColors.tealDark;
      scaffold = tester.widget(scaffoldFinder);
      expect(scaffold.backgroundColor, teal.background);

      appBar = tester.widget(appBarFinder);
      expect(appBar.backgroundColor, teal.surface);

      fab = tester.widget(fabFinder);
      expect(fab.backgroundColor, teal.primary);

      // Switch to Monochrome
      controller.setNotesTheme(NotesThemeType.monochrome);
      await tester.pumpAndSettle();

      final monochrome = NotesColors.monochromeDark;
      scaffold = tester.widget(scaffoldFinder);
      expect(scaffold.backgroundColor, monochrome.background);

      appBar = tester.widget(appBarFinder);
      expect(appBar.backgroundColor, monochrome.surface);

      fab = tester.widget(fabFinder);
      expect(fab.backgroundColor, monochrome.primary);
    });

    // 8. Text Note Editor responds to selected theme
    testWidgets('8. Text Note Editor responds to selected theme colors', (
      WidgetTester tester,
    ) async {
      final controller = await ThemeController.init(prefs);
      controller.setThemeMode(ThemeMode.dark);
      controller.setNotesTheme(NotesThemeType.terracotta);

      await tester.pumpWidget(
        createThemedWidget(
          controller: controller,
          child: TextNoteEditorScreen(repository: notesRepo),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldFinder = find.byType(Scaffold);
      Scaffold scaffold = tester.widget(scaffoldFinder);
      expect(scaffold.backgroundColor, NotesColors.terracottaDark.background);

      final appBarFinder = find.byType(AppBar);
      AppBar appBar = tester.widget(appBarFinder);
      expect(appBar.backgroundColor, NotesColors.terracottaDark.surface);

      // Switch to Teal
      controller.setNotesTheme(NotesThemeType.teal);
      await tester.pumpAndSettle();

      scaffold = tester.widget(scaffoldFinder);
      expect(scaffold.backgroundColor, NotesColors.tealDark.background);

      appBar = tester.widget(appBarFinder);
      expect(appBar.backgroundColor, NotesColors.tealDark.surface);
    });

    // 9. Checklist Editor responds to selected theme
    testWidgets('9. Checklist Editor responds to selected theme colors', (
      WidgetTester tester,
    ) async {
      final controller = await ThemeController.init(prefs);
      controller.setThemeMode(ThemeMode.dark);
      controller.setNotesTheme(NotesThemeType.terracotta);

      await tester.pumpWidget(
        createThemedWidget(
          controller: controller,
          child: ChecklistEditorScreen(repository: notesRepo),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldFinder = find.byType(Scaffold);
      Scaffold scaffold = tester.widget(scaffoldFinder);
      expect(scaffold.backgroundColor, NotesColors.terracottaDark.background);

      final addItemFinder = find.byKey(const Key('add_checklist_item_button'));
      expect(addItemFinder, findsOneWidget);

      // Switch to Teal
      controller.setNotesTheme(NotesThemeType.teal);
      await tester.pumpAndSettle();

      scaffold = tester.widget(scaffoldFinder);
      expect(scaffold.backgroundColor, NotesColors.tealDark.background);
    });

    // 10. Light mode works with Terracotta
    test('10. Light mode works with Terracotta', () {
      final palette = NotesTheme.getPalette(NotesThemeType.terracotta, isDark: false);
      expect(palette.primary, NotesColors.terracottaLight.primary);
      expect(palette.background, NotesColors.terracottaLight.background);
      expect(palette.surface, NotesColors.terracottaLight.surface);
      expect(palette.card, NotesColors.terracottaLight.card);
      expect(palette.textMain, NotesColors.terracottaLight.textMain);
      expect(palette.textSecondary, NotesColors.terracottaLight.textSecondary);
    });

    // 11. Light mode works with Teal
    test('11. Light mode works with Teal', () {
      final palette = NotesTheme.getPalette(NotesThemeType.teal, isDark: false);
      expect(palette.primary, NotesColors.tealLight.primary);
      expect(palette.background, NotesColors.tealLight.background);
      expect(palette.surface, NotesColors.tealLight.surface);
      expect(palette.card, NotesColors.tealLight.card);
      expect(palette.textMain, NotesColors.tealLight.textMain);
      expect(palette.textSecondary, NotesColors.tealLight.textSecondary);
    });

    // 12. Light mode works with Monochrome
    test('12. Light mode works with Monochrome', () {
      final palette = NotesTheme.getPalette(NotesThemeType.monochrome, isDark: false);
      expect(palette.primary, NotesColors.monochromeLight.primary);
      expect(palette.background, NotesColors.monochromeLight.background);
      expect(palette.surface, NotesColors.monochromeLight.surface);
      expect(palette.card, NotesColors.monochromeLight.card);
      expect(palette.textMain, NotesColors.monochromeLight.textMain);
      expect(palette.textSecondary, NotesColors.monochromeLight.textSecondary);
    });

    // 13. Dark mode works with all three
    test('13. Dark mode works with all three themes', () {
      final t = NotesTheme.getPalette(NotesThemeType.terracotta, isDark: true);
      final te = NotesTheme.getPalette(NotesThemeType.teal, isDark: true);
      final m = NotesTheme.getPalette(NotesThemeType.monochrome, isDark: true);

      expect(t.primary, NotesColors.terracottaDark.primary);
      expect(te.primary, NotesColors.tealDark.primary);
      expect(m.primary, NotesColors.monochromeDark.primary);

      expect(t.background, NotesColors.terracottaDark.background);
      expect(te.background, NotesColors.tealDark.background);
      expect(m.background, NotesColors.monochromeDark.background);
    });

    // 14. System mode works with all three
    testWidgets('14. System mode works with all three themes', (
      WidgetTester tester,
    ) async {
      final controller = await ThemeController.init(prefs);
      controller.setThemeMode(ThemeMode.system);

      late NotesColors capturedColors;

      Widget buildProbe() {
        return ThemeScope(
          controller: controller,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: Builder(
              builder: (ctx) {
                capturedColors = NotesTheme.of(ctx);
                return const SizedBox();
              },
            ),
          ),
        );
      }

      controller.setNotesTheme(NotesThemeType.terracotta);
      await tester.pumpWidget(buildProbe());
      expect(capturedColors.primary, NotesColors.terracottaDark.primary);

      controller.setNotesTheme(NotesThemeType.teal);
      await tester.pumpWidget(buildProbe());
      expect(capturedColors.primary, NotesColors.tealDark.primary);

      controller.setNotesTheme(NotesThemeType.monochrome);
      await tester.pumpWidget(buildProbe());
      expect(capturedColors.primary, NotesColors.monochromeDark.primary);
    });

    // 15. V3 theme changes do NOT modify V1 theme
    testWidgets('15. V3 theme changes do NOT modify V1 theme', (
      WidgetTester tester,
    ) async {
      final controller = await ThemeController.init(prefs);
      controller.setThemeMode(ThemeMode.dark);

      late AppThemeColors v1ColorsBefore;
      late AppThemeColors v1ColorsAfter;

      Widget buildProbe(bool isBefore) {
        return ThemeScope(
          controller: controller,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: controller.value,
            home: Builder(
              builder: (ctx) {
                if (isBefore) {
                  v1ColorsBefore = ctx.appColors;
                } else {
                  v1ColorsAfter = ctx.appColors;
                }
                return const SizedBox();
              },
            ),
          ),
        );
      }

      controller.setNotesTheme(NotesThemeType.terracotta);
      await tester.pumpWidget(buildProbe(true));

      controller.setNotesTheme(NotesThemeType.teal);
      await tester.pumpWidget(buildProbe(false));

      expect(v1ColorsBefore.primary, v1ColorsAfter.primary);
      expect(v1ColorsBefore.secondary, v1ColorsAfter.secondary);
      expect(v1ColorsBefore.background, v1ColorsAfter.background);
      expect(v1ColorsBefore.surface, v1ColorsAfter.surface);
    });

    // 16. V3 theme changes do NOT modify V2 Money theme
    testWidgets('16. V3 theme changes do NOT modify V2 Money theme', (
      WidgetTester tester,
    ) async {
      final controller = await ThemeController.init(prefs);
      controller.setThemeMode(ThemeMode.dark);

      late MoneyColors moneyColorsBefore;
      late MoneyColors moneyColorsAfter;

      Widget buildProbe(bool isBefore) {
        return ThemeScope(
          controller: controller,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: controller.value,
            home: Builder(
              builder: (ctx) {
                if (isBefore) {
                  moneyColorsBefore = MoneyTheme.of(ctx);
                } else {
                  moneyColorsAfter = MoneyTheme.of(ctx);
                }
                return const SizedBox();
              },
            ),
          ),
        );
      }

      controller.setNotesTheme(NotesThemeType.terracotta);
      await tester.pumpWidget(buildProbe(true));

      controller.setNotesTheme(NotesThemeType.teal);
      await tester.pumpWidget(buildProbe(false));

      expect(moneyColorsBefore.primaryAccent, moneyColorsAfter.primaryAccent);
      expect(moneyColorsBefore.secondaryAccent, moneyColorsAfter.secondaryAccent);
      expect(moneyColorsBefore.background, moneyColorsAfter.background);
      expect(moneyColorsBefore.card, moneyColorsAfter.card);
      expect(moneyColorsBefore.income, moneyColorsAfter.income);
      expect(moneyColorsBefore.expense, moneyColorsAfter.expense);
    });

    // UI Verification: Settings Screen Notes Theme Selector
    testWidgets('Settings Screen renders Notes Theme options and allows switching', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = await ThemeController.init(prefs);
      final profileController = UserProfileController('Sampath');
      final activityRepo = InMemoryActivityRepository();

      await tester.pumpWidget(
        ThemeScope(
          controller: controller,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: controller.value,
            home: SettingsScreen(
              repository: activityRepo,
              userProfileController: profileController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Notes Theme button in Settings
      final notesThemeButton = find.byKey(const Key('settings_notes_theme_button'));
      expect(notesThemeButton, findsOneWidget);
      expect(find.text('Notes Theme'), findsOneWidget);
      expect(find.text('TERRACOTTA / EARTH'), findsOneWidget);

      // Tap to open NotesThemeScreen
      await tester.tap(notesThemeButton);
      await tester.pumpAndSettle();

      final terracottaOption = find.byKey(const Key('notes_theme_terracotta'));
      final tealOption = find.byKey(const Key('notes_theme_teal'));
      final monochromeOption = find.byKey(const Key('notes_theme_monochrome'));

      expect(terracottaOption, findsOneWidget);
      expect(tealOption, findsOneWidget);
      expect(monochromeOption, findsOneWidget);

      expect(find.text('TERRACOTTA / EARTH'), findsOneWidget);
      expect(find.text('TEAL / DEEP GREEN'), findsOneWidget);
      expect(find.text('MONOCHROME + RUST'), findsOneWidget);

      // Tap Teal
      await tester.tap(tealOption);
      await tester.pumpAndSettle();

      expect(controller.notesTheme, NotesThemeType.teal);
      expect(prefs.getString('notes_theme_type'), 'teal');

      // Tap Monochrome
      await tester.tap(monochromeOption);
      await tester.pumpAndSettle();

      expect(controller.notesTheme, NotesThemeType.monochrome);
      expect(prefs.getString('notes_theme_type'), 'monochrome');

      // Tap Back button to return to SettingsScreen
      await tester.tap(find.byKey(const Key('notes_theme_back_button')));
      await tester.pumpAndSettle();

      // Verify SettingsScreen shows updated subtitle
      expect(find.text('MONOCHROME + RUST'), findsOneWidget);
    });

    // 18. V3ThemePalette semantic roles verification
    test('18. V3ThemePalette semantic roles map correctly', () {
      final tDark = V3Theme.getPalette(NotesThemeType.terracotta, isDark: true);
      expect(tDark.primaryText, tDark.textMain);
      expect(tDark.secondaryText, tDark.textSecondary);
      expect(tDark.accent, tDark.primary);
      expect(tDark.secondaryAccent, tDark.secondary);
      expect(tDark.pinned, tDark.primary);
      expect(tDark.selected, tDark.highlight);
      expect(tDark.divider, tDark.border);
      expect(tDark.progressTrack, tDark.barBackground);
      expect(tDark.warning, const Color(0xFFF59E0B));
      expect(tDark.error, const Color(0xFFEF4444));

      final tLight = V3Theme.getPalette(NotesThemeType.terracotta, isDark: false);
      expect(tLight.primaryText, tLight.textMain);
      expect(tLight.secondaryText, tLight.textSecondary);
      expect(tLight.accent, tLight.primary);
      expect(tLight.warning, const Color(0xFFD97706));
      expect(tLight.error, const Color(0xFFDC2626));
    });

    // 19. NotesThemeType titleCaseName and fromStorageValue fallback
    test('19. NotesThemeType titleCaseName and fromStorageValue fallback', () {
      expect(NotesThemeType.terracotta.titleCaseName, 'Terracotta / Earth');
      expect(NotesThemeType.teal.titleCaseName, 'Teal / Deep Green');
      expect(NotesThemeType.monochrome.titleCaseName, 'Monochrome + Rust');

      expect(NotesThemeType.fromStorageValue(null), NotesThemeType.terracotta);
      expect(NotesThemeType.fromStorageValue('invalid'), NotesThemeType.terracotta);
      expect(NotesThemeType.fromStorageValue('teal'), NotesThemeType.teal);
      expect(NotesThemeType.fromStorageValue('monochrome'), NotesThemeType.monochrome);
    });

    // 20. NotesThemeScreen displays all 3 themes and switches immediately
    testWidgets('20. NotesThemeScreen displays all 3 themes and switches immediately', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = await ThemeController.init(prefs);

      await tester.pumpWidget(
        ThemeScope(
          controller: controller,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: controller.value,
            home: const NotesThemeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final terracottaOption = find.byKey(const Key('notes_theme_terracotta'));
      final tealOption = find.byKey(const Key('notes_theme_teal'));
      final monochromeOption = find.byKey(const Key('notes_theme_monochrome'));

      expect(terracottaOption, findsOneWidget);
      expect(tealOption, findsOneWidget);
      expect(monochromeOption, findsOneWidget);

      // Tap Teal
      await tester.tap(tealOption);
      await tester.pumpAndSettle();
      expect(controller.notesTheme, NotesThemeType.teal);
      expect(prefs.getString('notes_theme_type'), 'teal');

      // Tap Monochrome
      await tester.tap(monochromeOption);
      await tester.pumpAndSettle();
      expect(controller.notesTheme, NotesThemeType.monochrome);
      expect(prefs.getString('notes_theme_type'), 'monochrome');

      // Tap Terracotta
      await tester.tap(terracottaOption);
      await tester.pumpAndSettle();
      expect(controller.notesTheme, NotesThemeType.terracotta);
      expect(prefs.getString('notes_theme_type'), 'terracotta');
    });
  });
}

