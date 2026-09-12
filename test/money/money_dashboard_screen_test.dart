import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/money/models/money_budget.dart';
import 'package:daily_routine/money/models/money_transaction.dart';
import 'package:daily_routine/money/models/recurring_money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/repositories/in_memory_money_repository.dart';
import 'package:daily_routine/money/screens/money_dashboard_screen.dart';

void main() {
  group('MoneyDashboardScreen Widget Tests', () {
    late InMemoryMoneyRepository repo;

    setUp(() {
      repo = InMemoryMoneyRepository();
    });

    Widget createScreen() {
      return MaterialApp(
        home: MoneyDashboardScreen(repository: repo),
      );
    }

    testWidgets('shows clean empty state when no transactions exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Money'), findsOneWidget);
      expect(find.text('Current Balance'), findsOneWidget);
      expect(find.text('₹0.00'), findsWidgets);
      expect(find.text('No transactions yet'), findsOneWidget);
      expect(find.text('Tap + Add Transaction to record your first income or expense.'), findsOneWidget);
    });

    testWidgets('displays correct balance, summary, and recent transactions', (
      WidgetTester tester,
    ) async {
      await repo.addTransaction(
        MoneyTransaction(
          type: TransactionType.income,
          amount: 5000.0,
          category: 'Work',
          note: 'Monthly salary',
          date: DateTime.now(),
        ),
      );
      await repo.addTransaction(
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 150.0,
          category: 'Food',
          note: 'Groceries',
          date: DateTime.now(),
        ),
      );

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Current balance = 5000 - 150 = 4850 -> ₹4,850.00
      expect(find.text('₹4,850.00'), findsWidgets);

      // Total Income & Expenses in summary
      expect(find.text('₹5,000.00'), findsWidgets);
      expect(find.text('₹150.00'), findsWidgets);

      // Recent transactions
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Monthly salary'), findsOneWidget);
      expect(find.text('+₹5,000.00'), findsOneWidget);

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('-₹150.00'), findsOneWidget);
    });

    testWidgets('tapping Add Transaction opens AddEditTransactionScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Transaction'));
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction'), findsOneWidget);
      expect(find.text('Save Transaction'), findsOneWidget);
    });

    testWidgets('tapping Categories action icon in AppBar navigates to CategoriesScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      final categoriesButton = find.byKey(const Key('dashboard_categories_button'));
      expect(categoriesButton, findsOneWidget);

      await tester.tap(categoriesButton);
      await tester.pumpAndSettle();

      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Your Categories'), findsOneWidget);
    });

    testWidgets('shows Budget Status empty card when no budgets exist for current month, and Set Budget button opens BudgetsScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dashboard_budget_empty_card')), findsOneWidget);
      expect(find.text('Budget Status'), findsOneWidget);
      expect(find.text('No budgets set for this month'), findsOneWidget);

      final setBudgetBtn = find.byKey(const Key('dashboard_set_budget_button'));
      expect(setBudgetBtn, findsOneWidget);

      await tester.ensureVisible(setBudgetBtn);
      await tester.pumpAndSettle();

      await tester.tap(setBudgetBtn);
      await tester.pumpAndSettle();

      expect(find.text('Budgets'), findsOneWidget);
    });

    testWidgets('displays populated budget summary card when budgets exist, reflecting only budgeted spending', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      await repo.addBudget(
        MoneyBudget(
          categoryId: 'food',
          year: now.year,
          month: now.month,
          amount: 3000.0,
        ),
      );

      // Add expense for Food (budgeted)
      await repo.addTransaction(
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 1200.0,
          category: 'Food',
          date: now,
        ),
      );

      // Add expense for Transport (unbudgeted)
      await repo.addTransaction(
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 500.0,
          category: 'Transport',
          date: now,
        ),
      );

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Card is populated
      final cardFinder = find.byKey(const Key('dashboard_budget_summary_card'));
      expect(cardFinder, findsOneWidget);
      expect(find.text('On Track'), findsOneWidget);

      // Total Budget: ₹3,000.00
      expect(find.descendant(of: cardFinder, matching: find.text('₹3,000.00')), findsOneWidget);

      // Total Spent in budgeted categories: ONLY ₹1,200.00, NOT ₹1,700.00!
      expect(find.descendant(of: cardFinder, matching: find.text('₹1,200.00')), findsOneWidget);

      // Remaining: 3000 - 1200 = ₹1,800.00
      expect(find.descendant(of: cardFinder, matching: find.text('₹1,800.00')), findsOneWidget);

      // 40% used
      expect(find.text('40% used'), findsOneWidget);
      expect(find.text('1 category budgeted'), findsOneWidget);
    });

    testWidgets('shows Over Budget status badge and negative remaining when spending exceeds budget', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      await repo.addBudget(
        MoneyBudget(
          categoryId: 'food',
          year: now.year,
          month: now.month,
          amount: 1000.0,
        ),
      );

      await repo.addTransaction(
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 1500.0,
          category: 'Food',
          date: now,
        ),
      );

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      final cardFinder = find.byKey(const Key('dashboard_budget_summary_card'));
      expect(cardFinder, findsOneWidget);

      expect(find.text('Over Budget'), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('₹1,000.00')), findsOneWidget); // Budget
      expect(find.descendant(of: cardFinder, matching: find.text('₹1,500.00')), findsOneWidget); // Spent
      expect(find.descendant(of: cardFinder, matching: find.text('-₹500.00')), findsOneWidget); // Remaining
      expect(find.text('150% used'), findsOneWidget); // Uncapped percentage
    });

    testWidgets('tapping populated budget summary card navigates to BudgetsScreen', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      await repo.addBudget(
        MoneyBudget(
          categoryId: 'food',
          year: now.year,
          month: now.month,
          amount: 2000.0,
        ),
      );

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      final budgetCard = find.byKey(const Key('dashboard_budget_summary_card'));
      expect(budgetCard, findsOneWidget);

      await tester.ensureVisible(budgetCard);
      await tester.pumpAndSettle();

      await tester.tap(budgetCard);
      await tester.pumpAndSettle();

      expect(find.text('Budgets'), findsOneWidget);
    });

    testWidgets('tapping recurring action icon in AppBar navigates to RecurringTransactionsScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      final recurringButton = find.byKey(const Key('dashboard_recurring_button'));
      expect(recurringButton, findsOneWidget);

      await tester.tap(recurringButton);
      await tester.pumpAndSettle();

      expect(find.text('Recurring Transactions'), findsOneWidget);
    });

    testWidgets('tapping recurring entry button beside Add Transaction navigates to RecurringTransactionsScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      final recurringEntry = find.byKey(const Key('dashboard_recurring_entry'));
      expect(recurringEntry, findsOneWidget);

      await tester.tap(recurringEntry);
      await tester.pumpAndSettle();

      expect(find.text('Recurring Transactions'), findsOneWidget);
    });

    testWidgets('startup generates due recurring transactions and displays them in balance and recent list', (
      WidgetTester tester,
    ) async {
      final today = MoneyTransaction.localToday();
      await repo.addRecurring(
        RecurringMoneyTransaction(
          id: 'rec-startup-test',
          type: TransactionType.expense,
          amount: 350.0,
          categoryId: 'food',
          note: 'Automated daily lunch',
          frequency: RecurrenceFrequency.daily,
          startDate: today,
          nextOccurrence: today,
        ),
      );

      // Verify no transactions in repo before dashboard loads
      expect(await repo.getTransactions(), isEmpty);

      // Launch MoneyDashboardScreen (which calls _loadData)
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Verify transaction was generated on startup
      final txs = await repo.getTransactions();
      expect(txs.length, 1);
      expect(txs.first.id, 'rec_rec-startup-test_${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}');

      // Verify balance and recent transaction display on dashboard
      expect(find.text('-₹350.00'), findsWidgets);
      expect(find.text('Automated daily lunch'), findsOneWidget);
      expect(find.byIcon(Icons.repeat_rounded), findsWidgets);
    });
  });
}
