import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/money/models/money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/services/money_calculator.dart';

void main() {
  group('MoneyCalculator Tests', () {
    test('handles empty transaction list gracefully', () {
      final transactions = <MoneyTransaction>[];

      expect(MoneyCalculator.calculateTotalIncome(transactions), 0.0);
      expect(MoneyCalculator.calculateTotalExpenses(transactions), 0.0);
      expect(MoneyCalculator.calculateBalance(transactions), 0.0);
      expect(MoneyCalculator.calculateSavings(transactions), 0.0);

      final summary = MoneyCalculator.calculateSummary(transactions);
      expect(summary.totalIncome, 0.0);
      expect(summary.totalExpenses, 0.0);
      expect(summary.balance, 0.0);
      expect(summary.savings, 0.0);
      expect(summary.transactionCount, 0);
      expect(summary.expensesByCategory, isEmpty);
      expect(summary.incomeByCategory, isEmpty);
    });

    test('calculates totals accurately with mixed income and expense transactions', () {
      final transactions = [
        MoneyTransaction(
          type: TransactionType.income,
          amount: 2500.0,
          category: 'Salary',
          date: DateTime(2026, 9, 1),
        ),
        MoneyTransaction(
          type: TransactionType.income,
          amount: 500.0,
          category: 'Freelance',
          date: DateTime(2026, 9, 5),
        ),
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 150.0,
          category: 'Food',
          date: DateTime(2026, 9, 2),
        ),
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 50.0,
          category: 'Transport',
          date: DateTime(2026, 9, 3),
        ),
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 200.0,
          category: 'Food',
          date: DateTime(2026, 9, 6),
        ),
      ];

      expect(MoneyCalculator.calculateTotalIncome(transactions), 3000.0);
      expect(MoneyCalculator.calculateTotalExpenses(transactions), 400.0);
      expect(MoneyCalculator.calculateBalance(transactions), 2600.0);
      expect(MoneyCalculator.calculateSavings(transactions), 2600.0);

      final summary = MoneyCalculator.calculateSummary(transactions);
      expect(summary.totalIncome, 3000.0);
      expect(summary.totalExpenses, 400.0);
      expect(summary.balance, 2600.0);
      expect(summary.savings, 2600.0);
      expect(summary.transactionCount, 5);
      expect(summary.expensesByCategory, {
        'Food': 350.0,
        'Transport': 50.0,
      });
      expect(summary.incomeByCategory, {
        'Salary': 2500.0,
        'Freelance': 500.0,
      });
    });

    test('filters transactions by date range inclusively', () {
      final transactions = [
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 10.0,
          category: 'Food',
          date: DateTime(2026, 9, 1),
        ),
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 20.0,
          category: 'Food',
          date: DateTime(2026, 9, 5),
        ),
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 30.0,
          category: 'Food',
          date: DateTime(2026, 9, 10),
        ),
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 40.0,
          category: 'Food',
          date: DateTime(2026, 9, 15),
        ),
      ];

      final filtered = MoneyCalculator.filterByDateRange(
        transactions,
        start: DateTime(2026, 9, 5),
        end: DateTime(2026, 9, 10),
      );

      expect(filtered.length, 2);
      expect(filtered.map((t) => t.amount), [20.0, 30.0]);
    });

    test('filters transactions by specific month and year', () {
      final transactions = [
        MoneyTransaction(
          type: TransactionType.income,
          amount: 1000.0,
          category: 'Work',
          date: DateTime(2026, 8, 31),
        ),
        MoneyTransaction(
          type: TransactionType.income,
          amount: 2000.0,
          category: 'Work',
          date: DateTime(2026, 9, 1),
        ),
        MoneyTransaction(
          type: TransactionType.income,
          amount: 3000.0,
          category: 'Work',
          date: DateTime(2026, 9, 30),
        ),
        MoneyTransaction(
          type: TransactionType.income,
          amount: 4000.0,
          category: 'Work',
          date: DateTime(2026, 10, 1),
        ),
      ];

      final sep2026 = MoneyCalculator.filterByMonth(
        transactions,
        year: 2026,
        month: 9,
      );

      expect(sep2026.length, 2);
      expect(sep2026.map((t) => t.amount), [2000.0, 3000.0]);
    });

    test('filters transactions by category case-insensitively', () {
      final transactions = [
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 25.0,
          category: 'Food',
          date: DateTime(2026, 9, 1),
        ),
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 50.0,
          category: 'food',
          date: DateTime(2026, 9, 2),
        ),
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 100.0,
          category: 'Transport',
          date: DateTime(2026, 9, 3),
        ),
      ];

      final foodTransactions = MoneyCalculator.filterByCategory(transactions, 'FOOD');
      expect(foodTransactions.length, 2);
      expect(foodTransactions.map((t) => t.amount), [25.0, 50.0]);
    });

    test('filters transactions by TransactionType', () {
      final transactions = [
        MoneyTransaction(
          type: TransactionType.income,
          amount: 100.0,
          category: 'Work',
        ),
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 40.0,
          category: 'Food',
        ),
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 15.0,
          category: 'Bills',
        ),
      ];

      final incomeOnly = MoneyCalculator.filterByType(
        transactions,
        TransactionType.income,
      );
      final expenseOnly = MoneyCalculator.filterByType(
        transactions,
        TransactionType.expense,
      );

      expect(incomeOnly.length, 1);
      expect(incomeOnly.first.amount, 100.0);

      expect(expenseOnly.length, 2);
      expect(expenseOnly.map((t) => t.amount), [40.0, 15.0]);
    });
  });
}
