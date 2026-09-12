import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/money/models/money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/repositories/in_memory_money_repository.dart';
import 'package:daily_routine/money/screens/add_edit_transaction_screen.dart';

void main() {
  group('AddEditTransactionScreen Widget Tests', () {
    late InMemoryMoneyRepository repo;

    setUp(() {
      repo = InMemoryMoneyRepository();
    });

    Widget createScreen({MoneyTransaction? initial}) {
      return MaterialApp(
        home: AddEditTransactionScreen(
          repository: repo,
          initialTransaction: initial,
        ),
      );
    }

    testWidgets('renders initial Add Transaction form with Expense selected by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Note (Optional)'), findsOneWidget);
      expect(find.text('Save Transaction'), findsOneWidget);
    });

    testWidgets('shows validation error when amount is empty or <= 0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save Transaction'));
      await tester.tap(find.text('Save Transaction'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid amount greater than 0'), findsOneWidget);
      expect((await repo.getTransactions()).length, 0);
    });

    testWidgets('successfully adds an expense transaction', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Enter amount
      await tester.enterText(find.byType(TextField).first, '120.50');

      // Select category (e.g. 'Food' is default or tap 'Food')
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // Enter note
      await tester.enterText(find.byType(TextField).last, 'Dinner at restaurant');

      // Save
      await tester.ensureVisible(find.text('Save Transaction'));
      await tester.tap(find.text('Save Transaction'));
      await tester.pumpAndSettle();

      final transactions = await repo.getTransactions();
      expect(transactions.length, 1);
      final t = transactions.first;
      expect(t.amount, 120.50);
      expect(t.type, TransactionType.expense);
      expect(t.category, 'Food');
      expect(t.note, 'Dinner at restaurant');
    });

    testWidgets('successfully adds an income transaction', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Enter amount
      await tester.enterText(find.byType(TextField).first, '3500');

      // Select Income
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      // Select category (Salary is an income category)
      await tester.tap(find.text('Salary'));
      await tester.pumpAndSettle();

      // Save
      await tester.ensureVisible(find.text('Save Transaction'));
      await tester.tap(find.text('Save Transaction'));
      await tester.pumpAndSettle();

      final transactions = await repo.getTransactions();
      expect(transactions.length, 1);
      final t = transactions.first;
      expect(t.amount, 3500.0);
      expect(t.type, TransactionType.income);
      expect(t.category, 'Salary');
    });

    testWidgets('shows only expense categories for expense and income categories for income', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // By default, Expense is selected
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Salary'), findsNothing);
      expect(find.text('Freelance'), findsNothing);

      // Switch to Income
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('Freelance'), findsOneWidget);
      expect(find.text('Food'), findsNothing);
      expect(find.text('Transport'), findsNothing);
    });

    testWidgets('pre-fills fields in Edit mode and updates without duplicating', (
      WidgetTester tester,
    ) async {
      final existing = MoneyTransaction(
        id: 'stable-edit-uuid',
        type: TransactionType.expense,
        amount: 80.0,
        category: 'Transport',
        note: 'Bus ticket',
      );
      await repo.addTransaction(existing);

      await tester.pumpWidget(createScreen(initial: existing));
      await tester.pumpAndSettle();

      expect(find.text('Edit Transaction'), findsOneWidget);
      expect(find.text('80'), findsOneWidget);
      expect(find.text('Bus ticket'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Change amount and note
      await tester.enterText(find.byType(TextField).first, '95.00');
      await tester.enterText(find.byType(TextField).last, 'Train ticket');

      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      final transactions = await repo.getTransactions();
      expect(transactions.length, 1); // No duplicate!
      expect(transactions.first.id, 'stable-edit-uuid'); // Preserved ID
      expect(transactions.first.amount, 95.00);
      expect(transactions.first.note, 'Train ticket');
    });
  });
}
