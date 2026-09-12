import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/money/models/money_transaction.dart';
import 'package:daily_routine/money/models/recurring_money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/repositories/in_memory_money_repository.dart';
import 'package:daily_routine/money/screens/recurring_transactions_screen.dart';

void main() {
  group('RecurringTransactionsScreen Widget Tests', () {
    late InMemoryMoneyRepository repo;

    setUp(() {
      repo = InMemoryMoneyRepository();
    });

    Widget createScreen() {
      return MaterialApp(
        home: RecurringTransactionsScreen(repository: repo),
      );
    }

    testWidgets('renders empty state when no recurring rules exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Recurring Transactions'), findsOneWidget);
      expect(find.text('No recurring transactions'), findsOneWidget);
      expect(
        find.text('Automate regular expenses and income like rent, bills, or salary.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('empty_add_recurring_button')), findsOneWidget);
      expect(find.byKey(const Key('add_recurring_button')), findsOneWidget);
    });

    testWidgets('renders list of recurring cards with proper details', (
      WidgetTester tester,
    ) async {
      await repo.addRecurring(
        RecurringMoneyTransaction(
          id: 'rec-rent',
          type: TransactionType.expense,
          amount: 15000.0,
          categoryId: 'home',
          note: 'House rent',
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
          nextOccurrence: DateTime(2026, 10, 1),
        ),
      );
      await repo.addRecurring(
        RecurringMoneyTransaction(
          id: 'rec-salary',
          type: TransactionType.income,
          amount: 60000.0,
          categoryId: 'salary',
          note: 'Monthly job salary',
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
          nextOccurrence: DateTime(2026, 10, 1),
        ),
      );

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('House rent'), findsOneWidget);
      expect(find.text('-₹15,000.00'), findsOneWidget);

      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('Monthly job salary'), findsOneWidget);
      expect(find.text('+₹60,000.00'), findsOneWidget);

      expect(find.text('Monthly'), findsNWidgets(2));
      expect(find.text('Active'), findsNWidgets(2));
    });

    testWidgets('can open add recurring modal and create new recurring rule', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_recurring_button')));
      await tester.pumpAndSettle();

      expect(find.text('Add Recurring Transaction'), findsOneWidget);
      expect(find.byKey(const Key('recurring_amount_input')), findsOneWidget);

      // Fill in amount
      await tester.enterText(
        find.byKey(const Key('recurring_amount_input')),
        '2500',
      );

      // Fill in note
      await tester.enterText(
        find.byKey(const Key('recurring_note_input')),
        'Weekly groceries',
      );

      // Select weekly frequency
      await tester.tap(find.byKey(const Key('recurring_frequency_select')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weekly').last);
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.byKey(const Key('save_recurring_button')));
      await tester.pumpAndSettle();

      // Verify added to repository and appears in list
      final rules = await repo.getRecurringTransactions();
      expect(rules.length, 1);
      expect(rules.first.amount, 2500.0);
      expect(rules.first.frequency, RecurrenceFrequency.weekly);
      expect(rules.first.note, 'Weekly groceries');

      expect(find.text('Weekly groceries'), findsOneWidget);
      expect(find.text('-₹2,500.00'), findsOneWidget);
    });

    testWidgets('toggling pause switch pauses recurring rule and updates UI', (
      WidgetTester tester,
    ) async {
      await repo.addRecurring(
        RecurringMoneyTransaction(
          id: 'rec-toggle',
          type: TransactionType.expense,
          amount: 500.0,
          categoryId: 'bills',
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
          isActive: true,
        ),
      );

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);

      final switchFinder = find.byKey(const Key('pause_switch_rec-toggle'));
      expect(switchFinder, findsOneWidget);

      // Tap switch to pause
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final updatedRule = await repo.getRecurringById('rec-toggle');
      expect(updatedRule!.isActive, isFalse);
      expect(find.text('Paused'), findsOneWidget);
    });

    testWidgets('delete recurring rule confirms with user and keeps existing transactions untouched', (
      WidgetTester tester,
    ) async {
      await repo.addRecurring(
        RecurringMoneyTransaction(
          id: 'rec-del-test',
          type: TransactionType.expense,
          amount: 1000.0,
          categoryId: 'bills',
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
        ),
      );

      // Add already generated transaction
      await repo.addTransaction(
        MoneyTransaction(
          id: 'rec_rec-del-test_20260901',
          type: TransactionType.expense,
          amount: 1000.0,
          category: 'Bills',
          date: DateTime(2026, 9, 1),
        ),
      );

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.byKey(const Key('delete_recurring_rec-del-test')));
      await tester.pumpAndSettle();

      // Confirmation dialog must state existing transactions remain unchanged
      expect(find.text('Delete recurring transaction?'), findsOneWidget);
      expect(
        find.text('Existing transactions will remain unchanged.'),
        findsOneWidget,
      );

      // Tap Delete in dialog
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Rule is deleted
      final rules = await repo.getRecurringTransactions();
      expect(rules, isEmpty);

      // Generated transaction remains!
      final txs = await repo.getTransactions();
      expect(txs.length, 1);
      expect(txs.first.id, 'rec_rec-del-test_20260901');
    });

    testWidgets('tapping recurring card opens edit sheet and updates rule', (
      WidgetTester tester,
    ) async {
      await repo.addRecurring(
        RecurringMoneyTransaction(
          id: 'rec-edit-test',
          type: TransactionType.expense,
          amount: 1000.0,
          categoryId: 'bills',
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
        ),
      );

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Tap card to edit
      await tester.tap(find.byKey(const Key('recurring_card_rec-edit-test')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Recurring Transaction'), findsOneWidget);

      // Change amount to 1250
      await tester.enterText(
        find.byKey(const Key('recurring_amount_input')),
        '1250',
      );

      await tester.tap(find.byKey(const Key('save_recurring_button')));
      await tester.pumpAndSettle();

      final updated = await repo.getRecurringById('rec-edit-test');
      expect(updated!.amount, 1250.0);
      expect(find.text('-₹1,250.00'), findsOneWidget);
    });
  });
}
