import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/money/models/money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/repositories/in_memory_money_repository.dart';
import 'package:daily_routine/money/screens/money_dashboard_screen.dart';
import 'package:daily_routine/money/screens/transactions_screen.dart';

void main() {
  group('TransactionsScreen Widget Tests', () {
    late InMemoryMoneyRepository repo;

    setUp(() {
      repo = InMemoryMoneyRepository();
    });

    Widget createScreen() {
      return MaterialApp(
        home: TransactionsScreen(repository: repo),
      );
    }

    testWidgets('shows empty state with wallet icon and Add Transaction button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Transactions'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
      expect(find.text('No transactions yet'), findsOneWidget);
      expect(
        find.text('Add your first income or expense\nfrom the Add Transaction button.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('empty_add_transaction_button')), findsOneWidget);

      // Tap Add Transaction from empty state
      await tester.tap(find.byKey(const Key('empty_add_transaction_button')));
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction'), findsOneWidget);
    });

    testWidgets('displays transaction list with category, note, date, and ₹ amounts', (
      WidgetTester tester,
    ) async {
      final t1 = MoneyTransaction(
        id: 't-food-1',
        type: TransactionType.expense,
        amount: 250.0,
        category: 'Food',
        note: 'Lunch',
        date: MoneyTransaction.localToday(),
      );
      final t2 = MoneyTransaction(
        id: 't-work-1',
        type: TransactionType.income,
        amount: 2000.0,
        category: 'Work',
        note: 'Freelance',
        date: DateTime(2026, 9, 11),
      );

      await repo.addTransaction(t1);
      await repo.addTransaction(t2);

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Header count
      expect(find.text('2'), findsOneWidget);

      // Category and note
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Freelance'), findsOneWidget);

      // Dates
      expect(find.text('Today'), findsOneWidget);

      // Amounts formatted with ₹
      expect(find.text('-₹250.00'), findsOneWidget);
      expect(find.text('+₹2,000.00'), findsOneWidget);
    });

    testWidgets('defaults to newest-first ordering', (
      WidgetTester tester,
    ) async {
      final tOld = MoneyTransaction(
        id: 't-old',
        type: TransactionType.expense,
        amount: 100.0,
        category: 'Transport',
        date: DateTime(2026, 9, 1),
      );
      final tNew = MoneyTransaction(
        id: 't-new',
        type: TransactionType.income,
        amount: 500.0,
        category: 'Work',
        date: DateTime(2026, 9, 10),
      );

      await repo.addTransaction(tOld);
      await repo.addTransaction(tNew);

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // First item rendered should be tNew (Work), second tOld (Transport)
      final workIndex = tester.getTopLeft(find.text('Work')).dy;
      final transportIndex = tester.getTopLeft(find.text('Transport')).dy;
      expect(workIndex < transportIndex, isTrue);
    });

    testWidgets('sorts by oldest first, highest amount, and lowest amount', (
      WidgetTester tester,
    ) async {
      final tSmallOld = MoneyTransaction(
        id: 't-small-old',
        type: TransactionType.expense,
        amount: 50.0,
        category: 'Bills',
        date: DateTime(2026, 9, 1),
      );
      final tBigNew = MoneyTransaction(
        id: 't-big-new',
        type: TransactionType.income,
        amount: 3000.0,
        category: 'Work',
        date: DateTime(2026, 9, 10),
      );

      await repo.addTransaction(tSmallOld);
      await repo.addTransaction(tBigNew);

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // 1. Sort by Oldest First
      await tester.tap(find.byKey(const Key('open_sort_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sort_option_oldestFirst')));
      await tester.pumpAndSettle();

      var billsTop = tester.getTopLeft(find.text('Bills')).dy;
      var workTop = tester.getTopLeft(find.text('Work')).dy;
      expect(billsTop < workTop, isTrue); // Oldest first: Bills is above Work

      // 2. Sort by Highest Amount
      await tester.tap(find.byKey(const Key('open_sort_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sort_option_highestAmount')));
      await tester.pumpAndSettle();

      billsTop = tester.getTopLeft(find.text('Bills')).dy;
      workTop = tester.getTopLeft(find.text('Work')).dy;
      expect(workTop < billsTop, isTrue); // Highest amount: Work (3000) is above Bills (50)

      // 3. Sort by Lowest Amount
      await tester.tap(find.byKey(const Key('open_sort_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sort_option_lowestAmount')));
      await tester.pumpAndSettle();

      billsTop = tester.getTopLeft(find.text('Bills')).dy;
      workTop = tester.getTopLeft(find.text('Work')).dy;
      expect(billsTop < workTop, isTrue); // Lowest amount: Bills (50) is above Work (3000)
    });

    testWidgets('live search filters by category and note with empty search message', (
      WidgetTester tester,
    ) async {
      await repo.addTransaction(
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 150.0,
          category: 'Food',
          note: 'Pizza party',
        ),
      );
      await repo.addTransaction(
        MoneyTransaction(
          type: TransactionType.income,
          amount: 4000.0,
          category: 'Work',
          note: 'Project milestone',
        ),
      );

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);

      // Search by note substring: "party"
      await tester.enterText(
        find.byKey(const Key('transactions_search_field')),
        'party',
      );
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Work'), findsNothing);

      // Search by category substring: "wor"
      await tester.enterText(
        find.byKey(const Key('transactions_search_field')),
        'wor',
      );
      await tester.pumpAndSettle();

      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Food'), findsNothing);

      // Search with no matching results
      await tester.enterText(
        find.byKey(const Key('transactions_search_field')),
        'nonexistent query',
      );
      await tester.pumpAndSettle();

      expect(find.text('No transactions found'), findsOneWidget);
      expect(find.text('Try a different search.'), findsOneWidget);

      // Clear search
      await tester.tap(find.byKey(const Key('transactions_search_clear')));
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('filters by transaction type: All, Income, Expense', (
      WidgetTester tester,
    ) async {
      await repo.addTransaction(
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 80.0,
          category: 'Transport',
        ),
      );
      await repo.addTransaction(
        MoneyTransaction(
          type: TransactionType.income,
          amount: 1200.0,
          category: 'Work',
        ),
      );

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);

      // Filter by Expense
      await tester.tap(find.byKey(const Key('type_filter_expense')));
      await tester.pumpAndSettle();

      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Work'), findsNothing);

      // Filter by Income
      await tester.tap(find.byKey(const Key('type_filter_income')));
      await tester.pumpAndSettle();

      expect(find.text('Transport'), findsNothing);
      expect(find.text('Work'), findsOneWidget);

      // Filter by All
      await tester.tap(find.byKey(const Key('type_filter_all')));
      await tester.pumpAndSettle();

      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('filters by category and date combining multi-criteria', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      // Matching: Expense + Food + This Month
      await repo.addTransaction(
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 250.0,
          category: 'Food',
          date: DateTime(now.year, now.month, 10),
        ),
      );
      // Diff Category: Expense + Transport + This Month
      await repo.addTransaction(
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 70.0,
          category: 'Transport',
          date: DateTime(now.year, now.month, 10),
        ),
      );
      // Diff Month: Expense + Food + Last Year
      await repo.addTransaction(
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 300.0,
          category: 'Food',
          date: DateTime(now.year - 1, now.month, 10),
        ),
      );
      // Diff Type: Income + Food + This Month
      await repo.addTransaction(
        MoneyTransaction(
          type: TransactionType.income,
          amount: 1000.0,
          category: 'Food',
          date: DateTime(now.year, now.month, 10),
        ),
      );

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Initially all 4 exist
      expect(find.text('4'), findsOneWidget);

      // 1. Select Expense type
      await tester.tap(find.byKey(const Key('type_filter_expense')));
      await tester.pumpAndSettle();

      // 2. Open Filter modal and select Category: Food, Date: This month
      await tester.tap(find.byKey(const Key('open_filter_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('category_filter_Food')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('date_filter_thisMonth')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('apply_filters_button')));
      await tester.pumpAndSettle();

      // Only the 1 matching transaction (Expense + Food + This Month: ₹250.00) remains!
      expect(find.text('1'), findsOneWidget);
      expect(find.text('-₹250.00'), findsOneWidget);
      expect(find.text('-₹70.00'), findsNothing);
      expect(find.text('-₹300.00'), findsNothing);
      expect(find.text('+₹1,000.00'), findsNothing);
    });

    testWidgets('tapping transaction opens Edit mode preserving UUID without duplicate', (
      WidgetTester tester,
    ) async {
      final t = MoneyTransaction(
        id: 'stable-transaction-uuid',
        type: TransactionType.expense,
        amount: 180.0,
        category: 'Food',
        note: 'Burger and fries',
      );
      await repo.addTransaction(t);

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Burger and fries'), findsOneWidget);

      // Tap to edit
      await tester.tap(find.byKey(Key('transaction_item_${t.id}')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Transaction'), findsOneWidget);
      expect(find.text('180'), findsOneWidget);

      // Update note
      await tester.enterText(find.byType(TextField).last, 'Gourmet dinner');
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Back on TransactionsScreen
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Gourmet dinner'), findsOneWidget);

      // Confirm repository holds exactly 1 transaction with same UUID
      final all = await repo.getTransactions();
      expect(all.length, 1);
      expect(all.first.id, 'stable-transaction-uuid');
      expect(all.first.note, 'Gourmet dinner');
    });

    testWidgets('deleting transaction shows confirmation dialog and removes it', (
      WidgetTester tester,
    ) async {
      final t = MoneyTransaction(
        id: 'delete-me-uuid',
        type: TransactionType.expense,
        amount: 90.0,
        category: 'Entertainment',
        note: 'Movie ticket',
      );
      await repo.addTransaction(t);

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Movie ticket'), findsOneWidget);

      // Tap delete icon
      await tester.tap(find.byKey(Key('delete_transaction_${t.id}')));
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('Delete transaction?'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete this transaction?'),
        findsOneWidget,
      );

      // 1. Test Cancel
      await tester.tap(find.byKey(const Key('cancel_delete_transaction_button')));
      await tester.pumpAndSettle();

      expect(find.text('Movie ticket'), findsOneWidget);
      expect((await repo.getTransactions()).length, 1);

      // 2. Test Confirm Delete
      await tester.tap(find.byKey(Key('delete_transaction_${t.id}')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_delete_transaction_button')));
      await tester.pumpAndSettle();

      // Verify empty state now appears
      expect(find.text('No transactions yet'), findsOneWidget);
      expect((await repo.getTransactions()).isEmpty, isTrue);
    });

    testWidgets('FAB Add Transaction creates new transaction and displays it in list', (
      WidgetTester tester,
    ) async {
      await repo.addTransaction(
        MoneyTransaction(
          type: TransactionType.income,
          amount: 5000.0,
          category: 'Work',
        ),
      );

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);

      // Tap FAB
      await tester.tap(find.byKey(const Key('transactions_fab_add')));
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction'), findsOneWidget);

      // Fill in details
      await tester.enterText(find.byType(TextField).first, '350');
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'Snacks');
      await tester.ensureVisible(find.text('Save Transaction'));
      await tester.tap(find.text('Save Transaction'));
      await tester.pumpAndSettle();

      // Back on TransactionsScreen with updated count 2
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Snacks'), findsOneWidget);
      expect(find.text('-₹350.00'), findsOneWidget);
    });

    testWidgets('MoneyDashboard updates balance and summary after transaction is deleted in TransactionsScreen', (
      WidgetTester tester,
    ) async {
      final t1 = MoneyTransaction(
        id: 't-1',
        type: TransactionType.income,
        amount: 2000.0,
        category: 'Work',
      );
      final t2 = MoneyTransaction(
        id: 't-2',
        type: TransactionType.expense,
        amount: 500.0,
        category: 'Shopping',
      );
      await repo.addTransaction(t1);
      await repo.addTransaction(t2);

      await tester.pumpWidget(
        MaterialApp(
          home: MoneyDashboardScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Initial balance: 2000 - 500 = 1500 -> ₹1,500.00
      expect(find.text('₹1,500.00'), findsWidgets);

      // Open TransactionsScreen via View All
      await tester.ensureVisible(find.byKey(const Key('dashboard_view_all_button')));
      await tester.tap(find.byKey(const Key('dashboard_view_all_button')));
      await tester.pumpAndSettle();

      expect(find.text('Transactions'), findsOneWidget);

      // Delete the expense transaction t2
      await tester.tap(find.byKey(Key('delete_transaction_${t2.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_delete_transaction_button')));
      await tester.pumpAndSettle();

      // Go back to MoneyDashboardScreen
      await tester.tap(find.byKey(const Key('transactions_back_button')));
      await tester.pumpAndSettle();

      // Updated balance: 2000 - 0 = 2000 -> ₹2,000.00
      expect(find.text('₹2,000.00'), findsWidgets);
      expect(find.text('Shopping'), findsNothing);
    });
  });
}
