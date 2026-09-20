import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_routine/money/models/money_savings.dart';
import 'package:daily_routine/money/models/money_transaction.dart';
import 'package:daily_routine/money/models/recurring_money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/repositories/in_memory_money_repository.dart';
import 'package:daily_routine/money/screens/money_dashboard_screen.dart';
import 'package:daily_routine/money/screens/money_settings_screen.dart';
import 'package:daily_routine/money/screens/savings_screen.dart';
import 'package:daily_routine/money/services/money_calculator.dart';
import 'package:daily_routine/money/services/recurring_transaction_service.dart';
import 'package:daily_routine/money/services/savings_notification_helper.dart';
import 'package:daily_routine/money/storage/shared_preferences_money_repository.dart';
import 'package:daily_routine/services/notification_service.dart';
import 'package:daily_routine/theme/app_theme.dart';

void main() {
  group('Part B — V2 Money Automatic 5% Savings & Notification Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('1. ₹10,000 income -> ₹500 savings (5%)', () async {
      final repo = InMemoryMoneyRepository();
      final tx = MoneyTransaction(
        type: TransactionType.income,
        amount: 10000.0,
        category: 'Salary',
      );

      await repo.addTransaction(tx);
      final savingsList = await repo.getSavings();

      expect(savingsList.length, 1);
      final savings = savingsList.first;
      expect(savings.sourceTransactionId, tx.id);
      expect(savings.incomeAmount, 10000.0);
      expect(savings.savingsPercentage, 5.0);
      expect(savings.savingsAmount, 500.0);
    });

    test('2. ₹1,000 income -> ₹50 savings (5%)', () async {
      final repo = InMemoryMoneyRepository();
      final tx = MoneyTransaction(
        type: TransactionType.income,
        amount: 1000.0,
        category: 'Freelance',
      );

      await repo.addTransaction(tx);
      final savingsList = await repo.getSavings();

      expect(savingsList.length, 1);
      final savings = savingsList.first;
      expect(savings.savingsAmount, 50.0);
    });

    test('3. Multiple incomes cumulative', () async {
      final repo = InMemoryMoneyRepository();
      await repo.addTransaction(MoneyTransaction(
        type: TransactionType.income,
        amount: 10000.0,
        category: 'Salary',
      ));
      await repo.addTransaction(MoneyTransaction(
        type: TransactionType.income,
        amount: 5000.0,
        category: 'Bonus',
      ));

      final savingsList = await repo.getSavings();
      expect(savingsList.length, 2);

      final totalSavings = MoneyCalculator.calculateTotalSavingsAllocations(savingsList);
      expect(totalSavings, 750.0); // 500 + 250
    });

    test('4. Expense creates no savings', () async {
      final repo = InMemoryMoneyRepository();
      await repo.addTransaction(MoneyTransaction(
        type: TransactionType.expense,
        amount: 2500.0,
        category: 'Groceries',
      ));

      final savingsList = await repo.getSavings();
      expect(savingsList, isEmpty);
    });

    test('5. Income edit recalculates savings (preserving UUID)', () async {
      final repo = InMemoryMoneyRepository();
      final tx = MoneyTransaction(
        type: TransactionType.income,
        amount: 10000.0,
        category: 'Salary',
      );
      await repo.addTransaction(tx);

      final initialSavings = (await repo.getSavings()).first;
      final initialSavingsId = initialSavings.id;
      expect(initialSavings.savingsAmount, 500.0);

      // Edit amount to ₹20,000
      final updatedTx = tx.copyWith(amount: 20000.0);
      await repo.updateTransaction(updatedTx);

      final updatedSavingsList = await repo.getSavings();
      expect(updatedSavingsList.length, 1);
      final updatedSavings = updatedSavingsList.first;
      expect(updatedSavings.id, initialSavingsId); // ID preserved
      expect(updatedSavings.incomeAmount, 20000.0);
      expect(updatedSavings.savingsAmount, 1000.0); // 5% of 20,000
    });

    test('6. Income deletion removes savings', () async {
      final repo = InMemoryMoneyRepository();
      final tx = MoneyTransaction(
        type: TransactionType.income,
        amount: 10000.0,
        category: 'Salary',
      );
      await repo.addTransaction(tx);
      expect(await repo.getSavings(), hasLength(1));

      await repo.deleteTransaction(tx.id);
      expect(await repo.getSavings(), isEmpty);
    });

    test('7. Income -> Expense removes savings', () async {
      final repo = InMemoryMoneyRepository();
      final tx = MoneyTransaction(
        type: TransactionType.income,
        amount: 10000.0,
        category: 'Salary',
      );
      await repo.addTransaction(tx);
      expect(await repo.getSavings(), hasLength(1));

      final flippedTx = tx.copyWith(type: TransactionType.expense, category: 'Food');
      await repo.updateTransaction(flippedTx);

      expect(await repo.getSavings(), isEmpty);
    });

    test('8. Expense -> Income creates savings', () async {
      final repo = InMemoryMoneyRepository();
      final tx = MoneyTransaction(
        type: TransactionType.expense,
        amount: 4000.0,
        category: 'Shopping',
      );
      await repo.addTransaction(tx);
      expect(await repo.getSavings(), isEmpty);

      final flippedTx = tx.copyWith(type: TransactionType.income, category: 'Freelance');
      await repo.updateTransaction(flippedTx);

      final savingsList = await repo.getSavings();
      expect(savingsList, hasLength(1));
      expect(savingsList.first.savingsAmount, 200.0); // 5% of 4000
      expect(savingsList.first.sourceTransactionId, tx.id);
    });

    test('9. Duplicate protection', () async {
      final repo = InMemoryMoneyRepository();
      final tx = MoneyTransaction(
        type: TransactionType.income,
        amount: 10000.0,
        category: 'Salary',
      );
      await repo.addTransaction(tx);

      final existingSavings = (await repo.getSavings()).first;

      // Attempting to add duplicate savings with existing ID or sourceTransactionId throws
      expect(
        () => repo.addSavings(existingSavings),
        throwsA(isA<Exception>()),
      );

      final duplicateSourceSavings = MoneySavings(
        sourceTransactionId: tx.id,
        incomeAmount: 5000.0,
      );
      expect(
        () => repo.addSavings(duplicateSourceSavings),
        throwsA(isA<Exception>()),
      );
    });

    test('10. Recurring income creates savings without duplication', () async {
      final repo = InMemoryMoneyRepository();
      final recurringRule = RecurringMoneyTransaction(
        id: 'salary_rule',
        type: TransactionType.income,
        amount: 30000.0,
        categoryId: 'salary',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 9, 1),
        nextOccurrence: DateTime(2026, 9, 1),
      );
      await repo.addRecurring(recurringRule);

      // Evaluate due recurring transactions for Sept 1, 2026
      final generated = await RecurringTransactionService.generateDueTransactions(
        repo,
        now: DateTime(2026, 9, 1, 10, 0),
      );
      expect(generated.length, 1);

      final savingsList = await repo.getSavings();
      expect(savingsList.length, 1);
      expect(savingsList.first.savingsAmount, 1500.0); // 5% of 30,000

      // Re-running on same day should not duplicate transactions or savings
      final secondRun = await RecurringTransactionService.generateDueTransactions(
        repo,
        now: DateTime(2026, 9, 1, 12, 0),
      );
      expect(secondRun, isEmpty);
      expect(await repo.getSavings(), hasLength(1));
    });

    test('11. Persistence across restarts in SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo1 = SharedPreferencesMoneyRepository(prefs);

      final tx = MoneyTransaction(
        type: TransactionType.income,
        amount: 15000.0,
        category: 'Salary',
      );
      await repo1.addTransaction(tx);

      // Verify stored in shared preferences under money_savings_key
      final storedJson = prefs.getString(SharedPreferencesMoneyRepository.savingsKey);
      expect(storedJson, isNotNull);
      expect(storedJson, contains('"savingsAmount":750.0'));

      // Simulate app restart by constructing new repository instance
      final repo2 = SharedPreferencesMoneyRepository(prefs);
      final restoredSavings = await repo2.getSavings();
      expect(restoredSavings.length, 1);
      expect(restoredSavings.first.savingsAmount, 750.0);
      expect(restoredSavings.first.sourceTransactionId, tx.id);
    });

    test('12. Corrupted JSON safety', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        SharedPreferencesMoneyRepository.savingsKey,
        '{invalid:json:[[[',
      );

      // Construction should not crash, falls back defensively
      final repo = SharedPreferencesMoneyRepository(prefs);
      final savingsList = await repo.getSavings();
      expect(savingsList, isEmpty);
    });

    test('13. Monthly savings calculation', () {
      final list = [
        MoneySavings(
          sourceTransactionId: 'tx1',
          incomeAmount: 10000.0,
          date: DateTime(2026, 9, 5),
        ), // 500
        MoneySavings(
          sourceTransactionId: 'tx2',
          incomeAmount: 4000.0,
          date: DateTime(2026, 9, 20),
        ), // 200
        MoneySavings(
          sourceTransactionId: 'tx3',
          incomeAmount: 8000.0,
          date: DateTime(2026, 8, 10),
        ), // 400 in August
      ];

      final septSavings = MoneyCalculator.calculateMonthlySavingsAllocations(
        list,
        year: 2026,
        month: 9,
      );
      expect(septSavings, 700.0);

      final augSavings = MoneyCalculator.calculateMonthlySavingsAllocations(
        list,
        year: 2026,
        month: 8,
      );
      expect(augSavings, 400.0);
    });

    test('14. Total savings calculation', () {
      final list = [
        MoneySavings(sourceTransactionId: 'tx1', incomeAmount: 10000.0), // 500
        MoneySavings(sourceTransactionId: 'tx2', incomeAmount: 5000.0), // 250
        MoneySavings(sourceTransactionId: 'tx3', incomeAmount: 1000.0), // 50
      ];

      final total = MoneyCalculator.calculateTotalSavingsAllocations(list);
      expect(total, 800.0);
      expect(MoneyCalculator.countSavingsAllocations(list), 3);
    });

    test('15. Notification scheduling with ID 9001 and correct time', () async {
      final notifService = InMemoryNotificationService();
      await notifService.scheduleSavingsReminder(
        currentSavings: 500.0,
        hour: 21,
        minute: 0,
        testNow: DateTime(2026, 9, 20, 10, 0),
      );

      expect(notifService.scheduledNotifications.containsKey(NotificationService.savingsNotificationId), isTrue);
      final notif = notifService.scheduledNotifications[NotificationService.savingsNotificationId]!;
      expect(notif.id, 9001);
      expect(notif.activityId, 'savings');
      expect(notif.title, contains('₹500.00'));
      expect(notif.scheduledDate.hour, 21);
      expect(notif.scheduledDate.minute, 0);
    });

    test('16. Notification cancellation', () async {
      final notifService = InMemoryNotificationService();
      await notifService.scheduleSavingsReminder(
        currentSavings: 500.0,
        hour: 21,
        minute: 0,
      );
      expect(notifService.scheduledNotifications.containsKey(9001), isTrue);

      await notifService.cancelSavingsReminder();
      expect(notifService.scheduledNotifications.containsKey(9001), isFalse);
    });

    test('17. Notification time changes', () async {
      final notifService = InMemoryNotificationService();
      await notifService.scheduleSavingsReminder(
        currentSavings: 500.0,
        hour: 21,
        minute: 0,
        testNow: DateTime(2026, 9, 20, 10, 0),
      );

      // Reschedule to 8:30 PM (20:30)
      await notifService.scheduleSavingsReminder(
        currentSavings: 500.0,
        hour: 20,
        minute: 30,
        testNow: DateTime(2026, 9, 20, 10, 0),
      );

      final notif = notifService.scheduledNotifications[9001]!;
      expect(notif.scheduledDate.hour, 20);
      expect(notif.scheduledDate.minute, 30);
    });

    test('18. Disabled notification cancels scheduled alert', () async {
      final repo = InMemoryMoneyRepository();
      final notifService = InMemoryNotificationService();
      final prefs = await SharedPreferences.getInstance();

      // Schedule initially
      await notifService.scheduleSavingsReminder(
        currentSavings: 1000.0,
        hour: 21,
        minute: 0,
      );
      expect(notifService.scheduledNotifications.containsKey(9001), isTrue);

      // User disables in preferences
      await prefs.setBool(SavingsNotificationHelper.prefEnabledKey, false);
      await SavingsNotificationHelper.syncSavingsReminder(
        repository: repo,
        notificationService: notifService,
      );

      expect(notifService.scheduledNotifications.containsKey(9001), isFalse);
    });

    test('19. Current savings amount in notification title', () async {
      final repo = InMemoryMoneyRepository();
      final notifService = InMemoryNotificationService();

      await repo.addTransaction(MoneyTransaction(
        type: TransactionType.income,
        amount: 25000.0,
        category: 'Salary',
      ));
      // 5% of 25,000 = 1,250.00

      await SavingsNotificationHelper.syncSavingsReminder(
        repository: repo,
        notificationService: notifService,
      );

      final notif = notifService.scheduledNotifications[9001]!;
      expect(notif.title, 'Your current savings are ₹1,250.00');
      expect(notif.body, 'Keep building your savings.');
    });

    testWidgets('20. SavingsScreen displays total savings, monthly savings, 5% rate, and history list', (
      WidgetTester tester,
    ) async {
      final repo = InMemoryMoneyRepository();
      final incomeTx = MoneyTransaction(
        id: 'sal_01',
        type: TransactionType.income,
        amount: 10000.0,
        category: 'Salary',
        date: DateTime.now(),
      );
      await repo.addTransaction(incomeTx);

      await tester.pumpWidget(
        MaterialApp(
          home: ThemeScope(
            controller: ThemeController(ThemeMode.dark),
            child: SavingsScreen(repository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Savings'), findsOneWidget);
      expect(find.byKey(const Key('savings_total_amount')), findsOneWidget);
      expect(find.text('₹500.00'), findsWidgets);
      expect(find.byKey(const Key('savings_rate_text')), findsOneWidget);
      expect(find.text('5%'), findsWidgets);
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('+₹500.00'), findsOneWidget);
      expect(find.text('5% saved'), findsOneWidget);
    });

    testWidgets('21. SavingsScreen displays empty state when no savings', (
      WidgetTester tester,
    ) async {
      final repo = InMemoryMoneyRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: ThemeScope(
            controller: ThemeController(ThemeMode.dark),
            child: SavingsScreen(repository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('savings_empty_state')), findsOneWidget);
      expect(find.text('No automatic savings yet'), findsOneWidget);
      expect(find.text('₹0.00'), findsWidgets);
    });

    testWidgets('22. MoneyDashboardScreen displays auto-saved card and navigates to SavingsScreen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = InMemoryMoneyRepository();
      await repo.addTransaction(MoneyTransaction(
        type: TransactionType.income,
        amount: 20000.0,
        category: 'Salary',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: ThemeScope(
            controller: ThemeController(ThemeMode.dark),
            child: MoneyDashboardScreen(repository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final autoSavedCard = find.byKey(const Key('dashboard_auto_saved_card'));
      await tester.ensureVisible(autoSavedCard);
      await tester.pumpAndSettle();

      expect(autoSavedCard, findsOneWidget);
      expect(find.byKey(const Key('dashboard_auto_saved_amount')), findsOneWidget);
      expect(find.text('₹1,000.00'), findsOneWidget); // 5% of 20,000

      // Tap card to open SavingsScreen
      await tester.tap(autoSavedCard);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('savings_total_amount')), findsOneWidget);
      expect(find.byKey(const Key('savings_screen_back_button')), findsOneWidget);
    });

    testWidgets('23. MoneySettingsScreen has savings tile and daily reminder controls', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = InMemoryMoneyRepository();
      final notifService = InMemoryNotificationService();

      await tester.pumpWidget(
        MaterialApp(
          home: ThemeScope(
            controller: ThemeController(ThemeMode.dark),
            child: MoneySettingsScreen(
              repository: repo,
              notificationService: notifService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Savings tile under MONEY
      final savingsTile = find.byKey(const Key('money_settings_savings_tile'));
      await tester.ensureVisible(savingsTile);
      await tester.pumpAndSettle();
      expect(savingsTile, findsOneWidget);
      expect(find.text('5% automatic savings on income'), findsOneWidget);

      // Check Savings Notifications controls
      final toggle = find.byKey(const Key('money_settings_savings_notification_toggle'));
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      expect(find.text('SAVINGS NOTIFICATIONS'), findsOneWidget);
      expect(toggle, findsOneWidget);
      expect(find.byKey(const Key('money_settings_savings_notification_time_tile')), findsOneWidget);
      expect(find.text('9:00 PM'), findsOneWidget);

      // Tap toggle to disable
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      // When disabled, time tile hides
      expect(find.byKey(const Key('money_settings_savings_notification_time_tile')), findsNothing);

      // Tap toggle to re-enable
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('money_settings_savings_notification_time_tile')), findsOneWidget);
    });
  });
}
