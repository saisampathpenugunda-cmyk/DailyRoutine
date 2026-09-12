import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/money/models/money_budget.dart';
import 'package:daily_routine/money/models/money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/repositories/in_memory_money_repository.dart';
import 'package:daily_routine/money/screens/budgets_screen.dart';
import 'package:daily_routine/money/screens/money_dashboard_screen.dart';

void main() {
  group('BudgetsScreen Widget Tests', () {
    late InMemoryMoneyRepository repo;
    final testMonth = DateTime(2026, 9, 15);

    setUp(() {
      repo = InMemoryMoneyRepository();
    });

    Widget createScreen({DateTime? initialMonth}) {
      return MaterialApp(
        home: BudgetsScreen(
          repository: repo,
          initialMonth: initialMonth ?? testMonth,
        ),
      );
    }

    Widget createDashboardScreen() {
      return MaterialApp(
        home: MoneyDashboardScreen(repository: repo),
      );
    }

    testWidgets('renders App Bar and empty state when no budgets exist for month', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Budgets'), findsOneWidget);
      expect(find.byKey(const Key('budget_month_title')), findsOneWidget);
      expect(find.text('September 2026'), findsOneWidget);

      // Monthly overview shows ₹0.00
      expect(find.text('Monthly Overview'), findsOneWidget);
      expect(find.text('Total Budget'), findsOneWidget);
      expect(find.text('Total Spent'), findsOneWidget);
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text('₹0.00'), findsNWidgets(3));

      // Empty state
      expect(find.text('No budgets set for this month'), findsOneWidget);
      expect(
        find.text('Plan your monthly spending by setting category limits'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('empty_add_budget_button')), findsOneWidget);
      expect(find.byKey(const Key('add_budget_fab')), findsOneWidget);
    });

    testWidgets('month navigation moves backward and forward', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);

      // Previous month
      await tester.tap(find.byKey(const Key('budget_prev_month')));
      await tester.pumpAndSettle();
      expect(find.text('August 2026'), findsOneWidget);

      // Next month twice -> October 2026
      await tester.tap(find.byKey(const Key('budget_next_month')));
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);

      await tester.tap(find.byKey(const Key('budget_next_month')));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);
    });

    testWidgets('month navigation handles year boundaries smoothly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen(initialMonth: DateTime(2026, 1, 1)));
      await tester.pumpAndSettle();

      expect(find.text('January 2026'), findsOneWidget);

      // Tap prev -> December 2025
      await tester.tap(find.byKey(const Key('budget_prev_month')));
      await tester.pumpAndSettle();
      expect(find.text('December 2025'), findsOneWidget);

      // Tap next -> January 2026
      await tester.tap(find.byKey(const Key('budget_next_month')));
      await tester.pumpAndSettle();
      expect(find.text('January 2026'), findsOneWidget);
    });

    testWidgets('displays active category budget cards with accurate calculations', (
      WidgetTester tester,
    ) async {
      // Add budgets
      final b1 = MoneyBudget(
        id: 'b-food',
        categoryId: 'food',
        year: 2026,
        month: 9,
        amount: 10000,
      );
      final b2 = MoneyBudget(
        id: 'b-transport',
        categoryId: 'transport',
        year: 2026,
        month: 9,
        amount: 4000,
      );
      await repo.addBudget(b1);
      await repo.addBudget(b2);

      // Add expense transactions for September 2026
      await repo.addTransaction(MoneyTransaction(
        id: 't-1',
        amount: 3500,
        type: TransactionType.expense,
        category: 'Food',
        date: DateTime(2026, 9, 5),
      ));
      await repo.addTransaction(MoneyTransaction(
        id: 't-2',
        amount: 1500,
        type: TransactionType.expense,
        category: 'Food',
        date: DateTime(2026, 9, 12),
      ));
      await repo.addTransaction(MoneyTransaction(
        id: 't-3',
        amount: 1000,
        type: TransactionType.expense,
        category: 'Transport',
        date: DateTime(2026, 9, 8),
      ));

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Total Budget = 10,000 + 4,000 = 14,000
      // Total Spent = 5,000 (Food) + 1,000 (Transport) = 6,000
      // Total Remaining = 8,000
      expect(find.text('₹14,000.00'), findsOneWidget);
      expect(find.text('₹6,000.00'), findsOneWidget);
      expect(find.text('₹8,000.00'), findsOneWidget);
      expect(find.text('On Track'), findsOneWidget);

      // Food card: Budget: ₹10,000.00, Spent: ₹5,000.00, Remaining: ₹5,000.00, 50%
      expect(find.byKey(const Key('budget_card_b-food')), findsOneWidget);
      expect(find.text('Budget: ₹10,000.00'), findsOneWidget);
      expect(find.text('Spent: ₹5,000.00'), findsOneWidget);
      expect(find.text('Remaining: ₹5,000.00'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);

      // Transport card: Budget: ₹4,000.00, Spent: ₹1,000.00, Remaining: ₹3,000.00, 25%
      expect(find.byKey(const Key('budget_card_b-transport')), findsOneWidget);
      expect(find.text('Budget: ₹4,000.00'), findsOneWidget);
      expect(find.text('Spent: ₹1,000.00'), findsOneWidget);
      expect(find.text('Remaining: ₹3,000.00'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
    });

    testWidgets('displays over budget warning when spending exceeds category limit', (
      WidgetTester tester,
    ) async {
      await repo.addBudget(MoneyBudget(
        id: 'b-shopping',
        categoryId: 'shopping',
        year: 2026,
        month: 9,
        amount: 3000,
      ));

      await repo.addTransaction(MoneyTransaction(
        id: 't-shop',
        amount: 4500,
        type: TransactionType.expense,
        category: 'Shopping',
        date: DateTime(2026, 9, 10),
      ));

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Over Budget'), findsOneWidget);
      expect(find.text('150%'), findsOneWidget);
      expect(find.text('Over budget by: ₹1,500.00'), findsOneWidget);
      expect(find.text('-₹1,500.00'), findsOneWidget);
    });

    testWidgets('adds a new budget via the Add Budget bottom sheet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Open Add Budget sheet via FAB
      await tester.tap(find.byKey(const Key('add_budget_fab')));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(BottomSheet), matching: find.text('Add Budget')), findsOneWidget);
      expect(find.byKey(const Key('budget_amount_field')), findsOneWidget);

      // Enter amount 8500
      await tester.enterText(find.byKey(const Key('budget_amount_field')), '8500');
      await tester.pumpAndSettle();

      // Tap Save Budget
      await tester.tap(find.byKey(const Key('save_budget_button')));
      await tester.pumpAndSettle();

      // Sheet dismissed, budget card appears
      expect(find.text('Budget added successfully'), findsOneWidget);
      expect(find.text('Budget: ₹8,500.00'), findsOneWidget);

      // Verify persisted in repo
      final budgets = await repo.getBudgets(year: 2026, month: 9);
      expect(budgets.length, 1);
      expect(budgets.first.amount, 8500.0);
    });

    testWidgets('validates amount must be greater than 0 on Add Budget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('empty_add_budget_button')));
      await tester.pumpAndSettle();

      // Leave amount empty and tap save
      await tester.tap(find.byKey(const Key('save_budget_button')));
      await tester.pumpAndSettle();

      expect(find.text('Amount must be greater than 0'), findsOneWidget);

      // Enter 0
      await tester.enterText(find.byKey(const Key('budget_amount_field')), '0');
      await tester.tap(find.byKey(const Key('save_budget_button')));
      await tester.pumpAndSettle();

      expect(find.text('Amount must be greater than 0'), findsOneWidget);
    });

    testWidgets('edits an existing budget via the Edit Budget sheet', (
      WidgetTester tester,
    ) async {
      final b = MoneyBudget(
        id: 'b-edit',
        categoryId: 'bills',
        year: 2026,
        month: 9,
        amount: 5000,
      );
      await repo.addBudget(b);

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Tap category card
      await tester.tap(find.byKey(const Key('budget_card_b-edit')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Budget'), findsOneWidget);
      expect(find.text('Bills'), findsWidgets);
      expect(find.byKey(const Key('budget_amount_field')), findsOneWidget);

      // Update amount to 7000
      await tester.enterText(find.byKey(const Key('budget_amount_field')), '7000');
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.byKey(const Key('save_budget_changes_button')));
      await tester.pumpAndSettle();

      expect(find.text('Budget updated successfully'), findsOneWidget);
      expect(find.text('Budget: ₹7,000.00'), findsOneWidget);

      final updated = await repo.getBudgetById('b-edit');
      expect(updated!.amount, 7000.0);
    });

    testWidgets('deletes budget with confirmation dialog', (
      WidgetTester tester,
    ) async {
      final b = MoneyBudget(
        id: 'b-del',
        categoryId: 'entertainment',
        year: 2026,
        month: 9,
        amount: 2500,
      );
      await repo.addBudget(b);

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('budget_card_b-del')), findsOneWidget);

      // Tap card to open edit
      await tester.tap(find.byKey(const Key('budget_card_b-del')));
      await tester.pumpAndSettle();

      // Tap Delete
      await tester.tap(find.byKey(const Key('delete_budget_button')));
      await tester.pumpAndSettle();

      // Confirmation dialog shows
      expect(find.text('Delete Budget?'), findsOneWidget);

      // Confirm delete
      await tester.tap(find.byKey(const Key('confirm_delete_budget_button')));
      await tester.pumpAndSettle();

      expect(find.text('Budget deleted'), findsOneWidget);
      expect(find.byKey(const Key('budget_card_b-del')), findsNothing);
      expect(find.text('No budgets set for this month'), findsOneWidget);

      final check = await repo.getBudgetById('b-del');
      expect(check, isNull);
    });

    testWidgets('canceling delete confirmation does not delete budget', (
      WidgetTester tester,
    ) async {
      final b = MoneyBudget(
        id: 'b-keep',
        categoryId: 'health',
        year: 2026,
        month: 9,
        amount: 3500,
      );
      await repo.addBudget(b);

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('budget_card_b-keep')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('delete_budget_button')));
      await tester.pumpAndSettle();

      // Tap Cancel in dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Budget still exists
      final check = await repo.getBudgetById('b-keep');
      expect(check, isNotNull);
    });

    testWidgets('navigates from Money Dashboard to BudgetsScreen via dashboard_budgets_button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createDashboardScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dashboard_budgets_button')), findsOneWidget);

      // Tap budgets button in dashboard
      await tester.tap(find.byKey(const Key('dashboard_budgets_button')));
      await tester.pumpAndSettle();

      // Now on BudgetsScreen
      expect(find.text('Budgets'), findsOneWidget);
      expect(find.byKey(const Key('budget_month_title')), findsOneWidget);
    });
  });
}
