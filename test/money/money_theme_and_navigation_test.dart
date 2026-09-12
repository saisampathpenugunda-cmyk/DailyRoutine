import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_routine/controllers/streak_controller.dart';
import 'package:daily_routine/controllers/user_profile_controller.dart';
import 'package:daily_routine/money/models/money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/repositories/in_memory_money_repository.dart';
import 'package:daily_routine/money/screens/budgets_screen.dart';
import 'package:daily_routine/money/screens/categories_screen.dart';
import 'package:daily_routine/money/screens/money_settings_screen.dart';
import 'package:daily_routine/money/screens/monthly_view_screen.dart';
import 'package:daily_routine/money/screens/recurring_transactions_screen.dart';
import 'package:daily_routine/money/screens/statistics_screen.dart';
import 'package:daily_routine/money/screens/transactions_screen.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/screens/settings_screen.dart';
import 'package:daily_routine/theme/app_theme.dart';
import 'package:daily_routine/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void setViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('Money Settings Refactor & Navigation Verification', () {
    late InMemoryActivityRepository activityRepo;
    late InMemoryMoneyRepository moneyRepo;
    late UserProfileController profileController;
    late StreakController streakController;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      activityRepo = InMemoryActivityRepository();
      moneyRepo = InMemoryMoneyRepository();
      profileController = UserProfileController('Sampath');
      streakController = StreakController(repository: activityRepo);
    });

    Widget createTestApp({
      ThemeController? themeController,
    }) {
      final controller = themeController ?? ThemeController(ThemeMode.dark);
      return DailyRoutineApp(
        repository: activityRepo,
        moneyRepository: moneyRepo,
        userProfileController: profileController,
        streakController: streakController,
        themeController: controller,
        showMainHome: true,
      );
    }

    // 1. Fresh installation defaults to Dark
    test('1. Fresh installation defaults to Dark (ThemeMode.dark)', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = await ThemeController.init();
      expect(controller.value, ThemeMode.dark);
      expect(controller.isDarkMode, isTrue);
    });

    // 2. Existing saved Dark preference remains Dark
    test('2. Existing saved Dark preference remains Dark', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
      final controller = await ThemeController.init();
      expect(controller.value, ThemeMode.dark);
    });

    // 3. Existing saved Light preference remains Light
    test('3. Existing saved Light preference remains Light', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'light'});
      final controller = await ThemeController.init();
      expect(controller.value, ThemeMode.light);
      expect(controller.isDarkMode, isFalse);
    });

    // 4. Existing saved System preference remains System
    test('4. Existing saved System preference remains System', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'system'});
      final controller = await ThemeController.init();
      expect(controller.value, ThemeMode.system);
    });

    // 5. Theme preference persists after restart
    test('5. Theme preference persists after restart via app_theme_mode key', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = ThemeController(ThemeMode.dark, prefs);

      controller.setThemeMode(ThemeMode.light);
      expect(prefs.getString('app_theme_mode'), 'light');

      controller.setThemeMode(ThemeMode.system);
      expect(prefs.getString('app_theme_mode'), 'system');

      controller.setThemeMode(ThemeMode.dark);
      expect(prefs.getString('app_theme_mode'), 'dark');

      final reloadedController = await ThemeController.init(prefs);
      expect(reloadedController.value, ThemeMode.dark);
    });

    // 6. Money Dashboard has exactly one top-right Settings entry
    testWidgets('6. Money Dashboard has exactly one top-right Settings entry', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Money'));
      await tester.pumpAndSettle();

      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);

      final appBar = tester.widget<AppBar>(appBarFinder);
      expect(appBar.actions?.length, 1);
      expect(find.byKey(const Key('dashboard_settings_button')), findsOneWidget);
    });

    // 7. Old multiple top-right icons are NOT restored
    testWidgets('7. Old multiple top-right icons are NOT restored', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Money'));
      await tester.pumpAndSettle();

      final appBarFinder = find.byType(AppBar);
      expect(find.descendant(of: appBarFinder, matching: find.byIcon(Icons.receipt_long)), findsNothing);
      expect(find.descendant(of: appBarFinder, matching: find.byIcon(Icons.bar_chart)), findsNothing);
      expect(find.descendant(of: appBarFinder, matching: find.byIcon(Icons.calendar_month)), findsNothing);
      expect(find.descendant(of: appBarFinder, matching: find.byIcon(Icons.account_balance_wallet)), findsNothing);
      expect(find.descendant(of: appBarFinder, matching: find.byIcon(Icons.category)), findsNothing);
      expect(find.descendant(of: appBarFinder, matching: find.byIcon(Icons.autorenew)), findsNothing);
    });

    // 7b. Money Dashboard does NOT contain Theme selector and starts directly with Current Balance
    testWidgets('7b. Money Dashboard does NOT contain Theme selector and starts with Current Balance', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Money'));
      await tester.pumpAndSettle();

      // Ensure no Theme label or Dark/Light/System selector exists on Money Dashboard
      expect(find.byKey(const Key('money_theme_option_dark')), findsNothing);
      expect(find.byKey(const Key('money_theme_option_light')), findsNothing);
      expect(find.byKey(const Key('money_theme_option_system')), findsNothing);
      expect(find.text('Theme'), findsNothing);

      // Verify Current Balance is present directly
      expect(find.text('Current Balance'), findsOneWidget);
    });

    // 8. Settings opens MoneySettingsScreen
    testWidgets('8. Settings opens MoneySettingsScreen', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Money'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dashboard_settings_button')));
      await tester.pumpAndSettle();

      expect(find.byType(MoneySettingsScreen), findsOneWidget);
      expect(find.text('Money Settings'), findsOneWidget);
    });

    // 9. Money Settings is separate from General Settings
    testWidgets('9. Money Settings is separate from General Settings', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Open Money Settings
      await tester.tap(find.text('Money'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dashboard_settings_button')));
      await tester.pumpAndSettle();

      expect(find.byType(MoneySettingsScreen), findsOneWidget);
      expect(find.byType(SettingsScreen), findsNothing);

      // Verify General Settings elements do not exist here
      expect(find.text('Manage Activities'), findsNothing);
      expect(find.text('PROFILE'), findsNothing);

      // Back to dashboard
      await tester.tap(find.byKey(const Key('money_settings_back_button')));
      await tester.pumpAndSettle();

      // Navigate to Your Day / Activities and open General Settings
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('main_home_settings_button')));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(MoneySettingsScreen), findsNothing);
    });

    // 10. All 7 Money navigation options work in MoneySettingsScreen
    testWidgets('10. Money Settings navigates to all 7 Money features', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Money'));
      await tester.pumpAndSettle();

      // 10.1 Transactions
      await tester.tap(find.byKey(const Key('dashboard_settings_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('money_settings_transactions_tile')), findsOneWidget);
      await tester.tap(find.byKey(const Key('money_settings_transactions_tile')));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionsScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('transactions_back_button')));
      await tester.pumpAndSettle();

      // 10.2 Categories
      expect(find.byKey(const Key('money_settings_categories_tile')), findsOneWidget);
      await tester.tap(find.byKey(const Key('money_settings_categories_tile')));
      await tester.pumpAndSettle();
      expect(find.byType(CategoriesScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('categories_back_button')));
      await tester.pumpAndSettle();

      // 10.3 Statistics
      expect(find.byKey(const Key('money_settings_statistics_tile')), findsOneWidget);
      await tester.tap(find.byKey(const Key('money_settings_statistics_tile')));
      await tester.pumpAndSettle();
      expect(find.byType(StatisticsScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 10.4 Monthly View
      expect(find.byKey(const Key('money_settings_monthly_view_tile')), findsOneWidget);
      await tester.tap(find.byKey(const Key('money_settings_monthly_view_tile')));
      await tester.pumpAndSettle();
      expect(find.byType(MonthlyViewScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 10.5 Budgets
      expect(find.byKey(const Key('money_settings_budgets_tile')), findsOneWidget);
      await tester.tap(find.byKey(const Key('money_settings_budgets_tile')));
      await tester.pumpAndSettle();
      expect(find.byType(BudgetsScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 10.6 Budget Insights (navigates to StatisticsScreen comparing budgets with actual spending)
      expect(find.byKey(const Key('money_settings_budget_insights_tile')), findsOneWidget);
      await tester.tap(find.byKey(const Key('money_settings_budget_insights_tile')));
      await tester.pumpAndSettle();
      expect(find.byType(StatisticsScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 10.7 Recurring Transactions
      expect(find.byKey(const Key('money_settings_recurring_tile')), findsOneWidget);
      await tester.tap(find.byKey(const Key('money_settings_recurring_tile')));
      await tester.pumpAndSettle();
      expect(find.byType(RecurringTransactionsScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    });

    // 11. Dark/Light/System options exist in Money Settings
    testWidgets('11. Dark/Light/System options exist in Money Settings', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Money'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dashboard_settings_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('money_settings_theme_option_dark')), findsOneWidget);
      expect(find.byKey(const Key('money_settings_theme_option_light')), findsOneWidget);
      expect(find.byKey(const Key('money_settings_theme_option_system')), findsOneWidget);
    });

    // 12. Money Settings uses global ThemeController and updates global theme
    testWidgets('12. Changing theme from Money Settings updates global theme', (tester) async {
      setViewport(tester);
      final themeController = ThemeController(ThemeMode.dark);
      await tester.pumpWidget(createTestApp(themeController: themeController));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Money'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dashboard_settings_button')));
      await tester.pumpAndSettle();

      // Select Light
      await tester.tap(find.byKey(const Key('money_settings_theme_option_light')));
      await tester.pumpAndSettle();

      expect(themeController.value, ThemeMode.light);
      expect(Theme.of(tester.element(find.byType(MoneySettingsScreen))).brightness, Brightness.light);

      // Select System
      await tester.tap(find.byKey(const Key('money_settings_theme_option_system')));
      await tester.pumpAndSettle();
      expect(themeController.value, ThemeMode.system);

      // Select Dark
      await tester.tap(find.byKey(const Key('money_settings_theme_option_dark')));
      await tester.pumpAndSettle();
      expect(themeController.value, ThemeMode.dark);
      expect(Theme.of(tester.element(find.byType(MoneySettingsScreen))).brightness, Brightness.dark);
    });

    // 13. Existing General Settings theme behavior still works
    testWidgets('13. Existing General Settings theme behavior still works', (tester) async {
      setViewport(tester);
      final themeController = ThemeController(ThemeMode.dark);
      await tester.pumpWidget(createTestApp(themeController: themeController));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('main_home_settings_button')));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('theme_option_light')));
      await tester.pumpAndSettle();

      expect(themeController.value, ThemeMode.light);
      expect(Theme.of(tester.element(find.byType(SettingsScreen))).brightness, Brightness.light);
    });

    // 14. Changing theme in General Settings updates Money Settings
    testWidgets('14. Changing theme in General Settings reflects in Money Settings', (tester) async {
      setViewport(tester);
      final themeController = ThemeController(ThemeMode.dark);
      await tester.pumpWidget(createTestApp(themeController: themeController));
      await tester.pumpAndSettle();

      // Set to light in General Settings
      await tester.tap(find.byKey(const Key('main_home_settings_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('theme_option_light')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_back_button')));
      await tester.pumpAndSettle();

      // Open Money Settings
      await tester.tap(find.text('Money'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dashboard_settings_button')));
      await tester.pumpAndSettle();

      expect(themeController.value, ThemeMode.light);
      expect(Theme.of(tester.element(find.byType(MoneySettingsScreen))).brightness, Brightness.light);
    });

    // 15. Money Preferences section is displayed
    testWidgets('15. Money Preferences future section is displayed', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Money'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dashboard_settings_button')));
      await tester.pumpAndSettle();

      expect(find.text('MONEY PREFERENCES'), findsOneWidget);
      expect(find.text('Money Preferences'), findsOneWidget);
      expect(find.text('Future money-specific settings'), findsOneWidget);
      expect(find.text('Coming Soon'), findsOneWidget);
    });

    // 16. Existing Money Dashboard functionality and V1 activities continue to work
    testWidgets('16. Existing Money Dashboard functionality and V1 activities continue to work', (tester) async {
      setViewport(tester);
      await moneyRepo.addTransaction(
        MoneyTransaction(
          type: TransactionType.income,
          amount: 1500.0,
          category: 'Freelance',
        ),
      );

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Check Activities
      await tester.tap(find.text('Activities'));
      await tester.pumpAndSettle();

      expect(find.text("Today's Plan"), findsOneWidget);
      expect(find.text('Meditation'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Check Money
      await tester.tap(find.text('Money'));
      await tester.pumpAndSettle();

      expect(find.text('Current Balance'), findsOneWidget);
      expect(find.text('₹1,500.00'), findsWidgets);
      expect(find.byKey(const Key('dashboard_transactions_button')), findsOneWidget);
      expect(find.byKey(const Key('dashboard_settings_button')), findsOneWidget);
    });
  });
}
