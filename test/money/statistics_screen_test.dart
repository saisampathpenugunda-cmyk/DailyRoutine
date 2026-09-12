import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/money/models/money_budget.dart';
import 'package:daily_routine/money/models/money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/repositories/in_memory_money_repository.dart';
import 'package:daily_routine/money/screens/money_dashboard_screen.dart';
import 'package:daily_routine/money/screens/statistics_screen.dart';

void main() {
  group('StatisticsScreen Widget Tests', () {
    late InMemoryMoneyRepository repo;
    final testDate = DateTime(2026, 9, 15);

    setUp(() {
      repo = InMemoryMoneyRepository();
    });

    Widget createScreen({DateTime? now}) {
      return MaterialApp(
        home: StatisticsScreen(
          repository: repo,
          now: now ?? testDate,
        ),
      );
    }

    testWidgets('shows Statistics title, period selector, and empty state when no transactions exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('1 Sep – 30 Sep 2026'), findsOneWidget);

      // Financial summary cards show zero
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Savings'), findsOneWidget);
      expect(find.text('₹0.00'), findsNWidgets(3));

      // Empty state
      expect(find.text('Nothing to analyze yet'), findsOneWidget);
      expect(
        find.text('Add some transactions to see your statistics.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('statistics_add_transaction_button')), findsOneWidget);
    });

    testWidgets('empty state Add Transaction button navigates to AddEditTransactionScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('statistics_add_transaction_button')));
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction'), findsOneWidget);
    });

    testWidgets('renders financial summary, comparison chart, category breakdown, and trends with data', (
      WidgetTester tester,
    ) async {
      final t1 = MoneyTransaction(
        id: 't1',
        amount: 5000.0,
        type: TransactionType.income,
        category: 'Salary',
        date: DateTime(2026, 9, 2),
      );
      final t2 = MoneyTransaction(
        id: 't2',
        amount: 1500.0,
        type: TransactionType.expense,
        category: 'Food',
        date: DateTime(2026, 9, 5),
      );
      final t3 = MoneyTransaction(
        id: 't3',
        amount: 500.0,
        type: TransactionType.expense,
        category: 'Transport',
        date: DateTime(2026, 9, 8),
      );
      await repo.addTransaction(t1);
      await repo.addTransaction(t2);
      await repo.addTransaction(t3);

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Summary
      expect(find.text('₹5,000.00'), findsWidgets); // Income
      expect(find.text('₹2,000.00'), findsWidgets); // Expenses (1500 + 500)
      expect(find.text('₹3,000.00'), findsWidgets); // Savings (5000 - 2000)

      // Comparison chart
      expect(find.text('Income vs Expenses'), findsOneWidget);

      // Spending by Category
      expect(find.text('Spending by Category'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('₹1,500.00'), findsOneWidget);

      // Income by Category
      expect(find.text('Income by Category'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);

      // Trends
      expect(find.text('Spending Trend'), findsOneWidget);
      expect(find.text('Savings Trend'), findsOneWidget);
    });

    testWidgets('correctly displays negative savings when expenses exceed income', (
      WidgetTester tester,
    ) async {
      final t1 = MoneyTransaction(
        id: 't1',
        amount: 1000.0,
        type: TransactionType.income,
        category: 'Freelance',
        date: DateTime(2026, 9, 2),
      );
      final t2 = MoneyTransaction(
        id: 't2',
        amount: 2500.0,
        type: TransactionType.expense,
        category: 'Shopping',
        date: DateTime(2026, 9, 4),
      );
      await repo.addTransaction(t1);
      await repo.addTransaction(t2);

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Net savings: 1000 - 2500 = -1500
      expect(find.text('-₹1,500.00'), findsOneWidget);
    });

    testWidgets('excludes zero-spending and zero-income categories from breakdown lists', (
      WidgetTester tester,
    ) async {
      // Only expense
      final t1 = MoneyTransaction(
        id: 't1',
        amount: 800.0,
        type: TransactionType.expense,
        category: 'Bills',
        date: DateTime(2026, 9, 3),
      );
      await repo.addTransaction(t1);

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Bills'), findsOneWidget);
      // Empty income message
      expect(find.text('No income in this period'), findsOneWidget);
    });

    testWidgets('switching period to Last Month updates data filter and displays appropriate range', (
      WidgetTester tester,
    ) async {
      // Sep transaction
      final tSep = MoneyTransaction(
        id: 'tSep',
        amount: 3000.0,
        type: TransactionType.income,
        category: 'Salary',
        date: DateTime(2026, 9, 10),
      );
      // Aug transaction (Last Month)
      final tAug = MoneyTransaction(
        id: 'tAug',
        amount: 1200.0,
        type: TransactionType.expense,
        category: 'Education',
        date: DateTime(2026, 8, 15),
      );
      await repo.addTransaction(tSep);
      await repo.addTransaction(tAug);

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Initially on This Month (Sep)
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('₹3,000.00'), findsWidgets);
      expect(find.text('Education'), findsNothing);

      // Tap period selector dropdown
      await tester.tap(find.byKey(const Key('statistics_period_selector')));
      await tester.pumpAndSettle();

      // Select "Last Month"
      await tester.tap(find.text('Last Month'));
      await tester.pumpAndSettle();

      // Range updated to August
      expect(find.text('Last Month'), findsOneWidget);
      expect(find.text('1 Aug – 31 Aug 2026'), findsOneWidget);
      expect(find.text('Education'), findsOneWidget);
      expect(find.text('₹1,200.00'), findsWidgets);
    });

    testWidgets('Dashboard statistics button navigates to StatisticsScreen and back', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MoneyDashboardScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Verify dashboard statistics button exists
      final statsBtn = find.byKey(const Key('dashboard_statistics_button'));
      expect(statsBtn, findsOneWidget);

      // Tap statistics button
      await tester.tap(statsBtn);
      await tester.pumpAndSettle();

      // In StatisticsScreen
      expect(find.text('Statistics'), findsOneWidget);
      expect(find.byKey(const Key('statistics_period_selector')), findsOneWidget);

      // Pop back to Dashboard
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Money'), findsOneWidget);
      expect(find.byKey(const Key('dashboard_statistics_button')), findsOneWidget);
    });

    testWidgets('renders flat baseline when all days in period have zero expenses', (
      WidgetTester tester,
    ) async {
      // Income only transaction
      final t1 = MoneyTransaction(
        id: 't-inc-only',
        amount: 2500.0,
        type: TransactionType.income,
        category: 'Freelance',
        date: DateTime(2026, 9, 10),
      );
      await repo.addTransaction(t1);

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Spending Trend'), findsOneWidget);
      expect(find.text('Total: ₹0.00'), findsOneWidget); // spending trend total
      expect(find.text('Savings Trend'), findsOneWidget);
      expect(find.text('Net Daily Savings'), findsOneWidget);
    });

    testWidgets('pull to refresh reloads transactions from repository', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Nothing to analyze yet'), findsOneWidget);

      // Add a transaction to the repo in the background
      await repo.addTransaction(
        MoneyTransaction(
          id: 't-background',
          amount: 750.0,
          type: TransactionType.expense,
          category: 'Food',
          date: DateTime(2026, 9, 12),
        ),
      );

      // Trigger pull to refresh
      await tester.fling(find.text('Nothing to analyze yet'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Nothing to analyze yet'), findsNothing);
      expect(find.text('Spending by Category'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('₹750.00'), findsWidgets);
    });

    testWidgets('renders correctly in both light and dark themes', (
      WidgetTester tester,
    ) async {
      await repo.addTransaction(
        MoneyTransaction(
          id: 't-dark',
          amount: 500.0,
          type: TransactionType.expense,
          category: 'Shopping',
          date: DateTime(2026, 9, 14),
        ),
      );

      // Dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: StatisticsScreen(
            repository: repo,
            now: testDate,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('Shopping'), findsOneWidget);

      // Light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: StatisticsScreen(
            repository: repo,
            now: testDate,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('Shopping'), findsOneWidget);
    });

    testWidgets('renders Budget vs Actual section with category cards when budgets and transactions exist', (
      WidgetTester tester,
    ) async {
      await repo.addBudget(
        MoneyBudget(
          categoryId: 'food',
          year: 2026,
          month: 9,
          amount: 2500.0,
        ),
      );
      await repo.addBudget(
        MoneyBudget(
          categoryId: 'transport',
          year: 2026,
          month: 9,
          amount: 1000.0,
        ),
      );

      await repo.addTransaction(
        MoneyTransaction(
          id: 't-food',
          amount: 1500.0,
          type: TransactionType.expense,
          category: 'Food',
          date: DateTime(2026, 9, 5),
        ),
      );
      await repo.addTransaction(
        MoneyTransaction(
          id: 't-trans',
          amount: 500.0,
          type: TransactionType.expense,
          category: 'Transport',
          date: DateTime(2026, 9, 6),
        ),
      );

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      final sectionFinder = find.byKey(const Key('statistics_budget_vs_actual_section'));
      expect(sectionFinder, findsOneWidget);
      expect(find.text('Budget vs Actual'), findsOneWidget);

      // Verify category items within section
      expect(find.descendant(of: sectionFinder, matching: find.text('Food')), findsOneWidget);
      expect(find.descendant(of: sectionFinder, matching: find.text('Transport')), findsOneWidget);
      expect(find.descendant(of: sectionFinder, matching: find.text('On Track')), findsNWidgets(2));

      // Food metrics: Budget 2500, Actual 1500, Remaining 1000, 60%
      expect(find.descendant(of: sectionFinder, matching: find.text('₹2,500.00')), findsOneWidget);
      expect(find.descendant(of: sectionFinder, matching: find.text('₹1,500.00')), findsOneWidget);
      expect(find.descendant(of: sectionFinder, matching: find.text('₹1,000.00')), findsWidgets);
      expect(find.descendant(of: sectionFinder, matching: find.text('60%')), findsOneWidget);

      // Transport metrics: Budget 1000, Actual 500, Remaining 500, 50%
      expect(find.descendant(of: sectionFinder, matching: find.text('50%')), findsOneWidget);
    });

    testWidgets('displays Over Budget status badge and allows percentages exceeding 100% in Budget vs Actual', (
      WidgetTester tester,
    ) async {
      await repo.addBudget(
        MoneyBudget(
          categoryId: 'food',
          year: 2026,
          month: 9,
          amount: 1000.0,
        ),
      );

      await repo.addTransaction(
        MoneyTransaction(
          id: 't-over',
          amount: 1400.0,
          type: TransactionType.expense,
          category: 'Food',
          date: DateTime(2026, 9, 8),
        ),
      );

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      final sectionFinder = find.byKey(const Key('statistics_budget_vs_actual_section'));
      expect(sectionFinder, findsOneWidget);
      expect(find.descendant(of: sectionFinder, matching: find.text('Over Budget')), findsOneWidget);
      expect(find.descendant(of: sectionFinder, matching: find.text('-₹400.00')), findsOneWidget); // Remaining
      expect(find.descendant(of: sectionFinder, matching: find.text('140%')), findsOneWidget); // Uncapped percentage
    });

    testWidgets('switching period updates Budget vs Actual section for selected month', (
      WidgetTester tester,
    ) async {
      // Sep budget and transaction
      await repo.addBudget(
        MoneyBudget(
          categoryId: 'food',
          year: 2026,
          month: 9,
          amount: 2000.0,
        ),
      );
      await repo.addTransaction(
        MoneyTransaction(
          id: 't-sep',
          amount: 800.0,
          type: TransactionType.expense,
          category: 'Food',
          date: DateTime(2026, 9, 10),
        ),
      );

      // Aug budget and transaction
      await repo.addBudget(
        MoneyBudget(
          categoryId: 'education',
          year: 2026,
          month: 8,
          amount: 1500.0,
        ),
      );
      await repo.addTransaction(
        MoneyTransaction(
          id: 't-aug',
          amount: 600.0,
          type: TransactionType.expense,
          category: 'Education',
          date: DateTime(2026, 8, 12),
        ),
      );

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      final sectionFinder = find.byKey(const Key('statistics_budget_vs_actual_section'));
      // Initially This Month (Sep)
      expect(find.descendant(of: sectionFinder, matching: find.text('Food')), findsOneWidget);
      expect(find.descendant(of: sectionFinder, matching: find.text('Education')), findsNothing);

      // Switch to Last Month (Aug)
      await tester.tap(find.byKey(const Key('statistics_period_selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last Month'));
      await tester.pumpAndSettle();

      expect(find.descendant(of: sectionFinder, matching: find.text('Education')), findsOneWidget);
      expect(find.descendant(of: sectionFinder, matching: find.text('Food')), findsNothing);
    });

    testWidgets('shows informative message when no budgets exist for current period', (
      WidgetTester tester,
    ) async {
      await repo.addTransaction(
        MoneyTransaction(
          id: 't-nobudget',
          amount: 500.0,
          type: TransactionType.expense,
          category: 'Shopping',
          date: DateTime(2026, 9, 5),
        ),
      );

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      final sectionFinder = find.byKey(const Key('statistics_budget_vs_actual_section'));
      expect(sectionFinder, findsOneWidget);
      expect(
        find.descendant(of: sectionFinder, matching: find.text('No budgets set for this period')),
        findsOneWidget,
      );
    });

    testWidgets('tapping Manage button in Budget vs Actual header opens BudgetsScreen', (
      WidgetTester tester,
    ) async {
      await repo.addBudget(
        MoneyBudget(
          categoryId: 'food',
          year: 2026,
          month: 9,
          amount: 1500.0,
        ),
      );
      await repo.addTransaction(
        MoneyTransaction(
          id: 't-manage',
          amount: 300.0,
          type: TransactionType.expense,
          category: 'Food',
          date: DateTime(2026, 9, 2),
        ),
      );

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      final manageBtn = find.byKey(const Key('statistics_manage_budgets_button'));
      expect(manageBtn, findsOneWidget);

      await tester.ensureVisible(manageBtn);
      await tester.pumpAndSettle();

      await tester.tap(manageBtn);
      await tester.pumpAndSettle();

      expect(find.text('Budgets'), findsOneWidget);
    });
  });
}
