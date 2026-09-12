import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/money/models/money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/repositories/in_memory_money_repository.dart';
import 'package:daily_routine/money/screens/money_dashboard_screen.dart';
import 'package:daily_routine/money/screens/monthly_view_screen.dart';

void main() {
  group('MonthlyViewScreen Widget Tests', () {
    late InMemoryMoneyRepository repo;
    final testMonth = DateTime(2026, 9, 15);

    setUp(() {
      repo = InMemoryMoneyRepository();
    });

    Widget createScreen({DateTime? initialMonth, Key? key}) {
      return MaterialApp(
        home: MonthlyViewScreen(
          key: key,
          repository: repo,
          initialMonth: initialMonth ?? testMonth,
        ),
      );
    }

    testWidgets('Monthly View loads with initial current month and empty state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Monthly View'), findsOneWidget);
      expect(find.text('September 2026'), findsOneWidget);

      // Summary shows zeros
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Savings'), findsOneWidget);
      expect(find.text('₹0.00'), findsNWidgets(3));

      // Empty month state
      expect(find.text('No transactions this month'), findsOneWidget);
      expect(
        find.text('Add a transaction to start tracking your money.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('monthly_empty_add_transaction_button')), findsOneWidget);
    });

    testWidgets('Month navigation moves backward and forward by exactly one month', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);

      // Tap previous month
      await tester.tap(find.byKey(const Key('monthly_prev_month_button')));
      await tester.pumpAndSettle();
      expect(find.text('August 2026'), findsOneWidget);

      // Tap next month twice
      await tester.tap(find.byKey(const Key('monthly_next_month_button')));
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);

      await tester.tap(find.byKey(const Key('monthly_next_month_button')));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);
    });

    testWidgets('January to previous December and December to next January navigation', (
      WidgetTester tester,
    ) async {
      // Start in January 2026
      await tester.pumpWidget(createScreen(initialMonth: DateTime(2026, 1, 10)));
      await tester.pumpAndSettle();

      expect(find.text('January 2026'), findsOneWidget);

      // Tap previous month -> December 2025
      await tester.tap(find.byKey(const Key('monthly_prev_month_button')));
      await tester.pumpAndSettle();
      expect(find.text('December 2025'), findsOneWidget);

      // Tap next month -> January 2026
      await tester.tap(find.byKey(const Key('monthly_next_month_button')));
      await tester.pumpAndSettle();
      expect(find.text('January 2026'), findsOneWidget);

      // Navigate to December 2026
      await tester.pumpWidget(createScreen(
        key: const ValueKey('dec_screen'),
        initialMonth: DateTime(2026, 12, 5),
      ));
      await tester.pumpAndSettle();
      expect(find.text('December 2026'), findsOneWidget);

      // Tap next month -> January 2027
      await tester.tap(find.byKey(const Key('monthly_next_month_button')));
      await tester.pumpAndSettle();
      expect(find.text('January 2027'), findsOneWidget);
    });

    testWidgets('Displays month summary, overview with counts, category rankings, and newest-first transactions', (
      WidgetTester tester,
    ) async {
      final t1 = MoneyTransaction(
        id: 't1',
        amount: 8000.0,
        type: TransactionType.income,
        category: 'Salary',
        note: 'Monthly stipend',
        date: DateTime(2026, 9, 2),
        createdAt: DateTime(2026, 9, 2, 10, 0),
      );
      final t2 = MoneyTransaction(
        id: 't2',
        amount: 2500.0,
        type: TransactionType.expense,
        category: 'Food',
        note: 'Groceries',
        date: DateTime(2026, 9, 5),
        createdAt: DateTime(2026, 9, 5, 12, 0),
      );
      final t3 = MoneyTransaction(
        id: 't3',
        amount: 500.0,
        type: TransactionType.expense,
        category: 'Transport',
        note: 'Metro pass',
        date: DateTime(2026, 9, 10),
        createdAt: DateTime(2026, 9, 10, 15, 0),
      );
      final t4 = MoneyTransaction(
        id: 't4',
        amount: 1500.0,
        type: TransactionType.income,
        category: 'Freelance',
        note: 'Consulting',
        date: DateTime(2026, 9, 10),
        createdAt: DateTime(2026, 9, 10, 18, 0),
      );
      // August transaction (outside September)
      final tAug = MoneyTransaction(
        id: 'tAug',
        amount: 9999.0,
        type: TransactionType.income,
        category: 'Salary',
        date: DateTime(2026, 8, 20),
      );

      await repo.addTransaction(t1);
      await repo.addTransaction(t2);
      await repo.addTransaction(t3);
      await repo.addTransaction(t4);
      await repo.addTransaction(tAug);

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Month summary
      // Income: 8000 + 1500 = 9500
      // Expenses: 2500 + 500 = 3000
      // Savings: 9500 - 3000 = 6500
      expect(find.text('₹9,500.00'), findsWidgets);
      expect(find.text('₹3,000.00'), findsWidgets);
      expect(find.text('₹6,500.00'), findsWidgets);

      // Monthly Overview counts
      expect(find.text('Monthly Overview'), findsOneWidget);
      expect(find.text('Income transactions'), findsOneWidget);
      expect(find.text('Expense transactions'), findsOneWidget);
      expect(find.text('2'), findsNWidgets(2)); // 2 income transactions, 2 expense transactions

      // Spending by Category
      expect(find.text('Spending by Category'), findsOneWidget);
      expect(find.text('Food'), findsWidgets);
      expect(find.text('Transport'), findsWidgets);
      expect(find.text('₹2,500.00'), findsWidgets);
      expect(find.text('₹500.00'), findsWidgets);

      // Income by Category
      expect(find.text('Income by Category'), findsOneWidget);
      expect(find.text('Salary'), findsWidgets);
      expect(find.text('Freelance'), findsWidgets);
      expect(find.text('₹8,000.00'), findsWidgets);
      expect(find.text('₹1,500.00'), findsWidgets);

      // Transaction items & ordering: t4 was on Sep 10 18:00, t3 Sep 10 15:00
      expect(find.byKey(const Key('monthly_transaction_t4')), findsOneWidget);
      expect(find.byKey(const Key('monthly_transaction_t3')), findsOneWidget);
      expect(find.byKey(const Key('monthly_transaction_t2')), findsOneWidget);
      expect(find.byKey(const Key('monthly_transaction_t1')), findsOneWidget);
      expect(find.byKey(const Key('monthly_transaction_tAug')), findsNothing);

      expect(find.text('+₹1,500.00'), findsOneWidget);
      expect(find.text('-₹500.00'), findsOneWidget);
    });

    testWidgets('Negative savings displayed correctly with minus sign', (
      WidgetTester tester,
    ) async {
      final t1 = MoneyTransaction(
        id: 't1',
        amount: 1000.0,
        type: TransactionType.income,
        category: 'Freelance',
        date: DateTime(2026, 9, 5),
      );
      final t2 = MoneyTransaction(
        id: 't2',
        amount: 2500.0,
        type: TransactionType.expense,
        category: 'Shopping',
        date: DateTime(2026, 9, 8),
      );
      await repo.addTransaction(t1);
      await repo.addTransaction(t2);

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Net savings: 1000 - 2500 = -1500
      expect(find.text('-₹1,500.00'), findsWidgets);
    });

    testWidgets('Excludes zero-value categories from spending and income sections', (
      WidgetTester tester,
    ) async {
      final t1 = MoneyTransaction(
        id: 't1',
        amount: 1200.0,
        type: TransactionType.expense,
        category: 'Bills',
        date: DateTime(2026, 9, 3),
      );
      await repo.addTransaction(t1);

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Bills'), findsWidgets);
      // Income section should show empty indication
      expect(find.text('No income this month'), findsOneWidget);
    });

    testWidgets('Empty month add transaction button navigates to AddEditTransactionScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('monthly_empty_add_transaction_button')));
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction'), findsOneWidget);
    });

    testWidgets('Tapping transaction tile navigates to Edit screen and updates totals', (
      WidgetTester tester,
    ) async {
      final t1 = MoneyTransaction(
        id: 't-edit',
        amount: 500.0,
        type: TransactionType.expense,
        category: 'Food',
        date: DateTime(2026, 9, 4),
      );
      await repo.addTransaction(t1);

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('₹500.00'), findsWidgets);

      // Scroll to transaction tile and tap
      final tileFinder = find.byKey(const Key('monthly_transaction_t-edit'));
      await tester.ensureVisible(tileFinder);
      await tester.pumpAndSettle();
      await tester.tap(tileFinder);
      await tester.pumpAndSettle();

      expect(find.text('Edit Transaction'), findsOneWidget);

      // Change amount to 900
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '900');
      await tester.pumpAndSettle();

      // Save
      final saveBtn = find.text('Save Changes');
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Back in Monthly View, totals updated
      expect(find.text('₹900.00'), findsWidgets);
      expect(find.text('₹500.00'), findsNothing);
    });

    testWidgets('Deleting transaction via repository updates monthly totals upon refresh', (
      WidgetTester tester,
    ) async {
      final t1 = MoneyTransaction(
        id: 't-del',
        amount: 800.0,
        type: TransactionType.expense,
        category: 'Food',
        date: DateTime(2026, 9, 6),
      );
      await repo.addTransaction(t1);

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('₹800.00'), findsWidgets);

      await repo.deleteTransaction('t-del');
      // Trigger pull-to-refresh
      await tester.fling(find.text('Monthly Overview'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(find.text('No transactions this month'), findsOneWidget);
    });

    testWidgets('Dashboard navigates to MonthlyViewScreen via AppBar button and Monthly Summary card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MoneyDashboardScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Via AppBar button
      final monthlyBtn = find.byKey(const Key('dashboard_monthly_view_button'));
      expect(monthlyBtn, findsOneWidget);

      await tester.tap(monthlyBtn);
      await tester.pumpAndSettle();

      expect(find.text('Monthly View'), findsOneWidget);

      // Pop back
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Money'), findsOneWidget);

      // 2. Via Monthly Summary card
      final summaryCard = find.byKey(const Key('dashboard_monthly_summary_card'));
      expect(summaryCard, findsOneWidget);

      await tester.tap(summaryCard);
      await tester.pumpAndSettle();

      expect(find.text('Monthly View'), findsOneWidget);
    });

    testWidgets('Pull to refresh and theme support', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: MonthlyViewScreen(
            repository: repo,
            initialMonth: testMonth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No transactions this month'), findsOneWidget);

      // Background transaction added
      await repo.addTransaction(
        MoneyTransaction(
          id: 't-bg',
          amount: 600.0,
          type: TransactionType.expense,
          category: 'Shopping',
          date: DateTime(2026, 9, 8),
        ),
      );

      // Pull to refresh
      await tester.fling(find.text('No transactions this month'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(find.text('No transactions this month'), findsNothing);
      expect(find.text('Shopping'), findsWidgets);
      expect(find.text('₹600.00'), findsWidgets);
    });

    testWidgets('Monthly View displays recurring indicator badge for generated recurring transactions', (
      WidgetTester tester,
    ) async {
      await repo.addTransaction(
        MoneyTransaction(
          id: 'rec_rule123_20260905',
          amount: 450.0,
          type: TransactionType.expense,
          category: 'Food',
          note: 'Automated weekly meal',
          date: DateTime(2026, 9, 5),
        ),
      );

      await tester.pumpWidget(createScreen(initialMonth: DateTime(2026, 9, 1)));
      await tester.pumpAndSettle();

      expect(find.text('Automated weekly meal'), findsOneWidget);
      expect(find.text('₹450.00'), findsWidgets);
      expect(find.byIcon(Icons.repeat_rounded), findsWidgets);
    });
  });
}
