import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/money/models/money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/services/money_calculator.dart';

void main() {
  group('MoneyCalculator Statistics Range & Analytics Tests', () {
    final t1 = MoneyTransaction(
      id: 't1',
      amount: 1500.0,
      type: TransactionType.income,
      category: 'Salary',
      date: DateTime(2026, 9, 2),
      createdAt: DateTime(2026, 9, 2, 10, 0),
    );
    final t2 = MoneyTransaction(
      id: 't2',
      amount: 300.0,
      type: TransactionType.expense,
      category: 'Food',
      date: DateTime(2026, 9, 5),
      createdAt: DateTime(2026, 9, 5, 12, 0),
    );
    final t3 = MoneyTransaction(
      id: 't3',
      amount: 200.0,
      type: TransactionType.expense,
      category: 'Transport',
      date: DateTime(2026, 9, 5),
      createdAt: DateTime(2026, 9, 5, 18, 0),
    );
    final t4 = MoneyTransaction(
      id: 't4',
      amount: 500.0,
      type: TransactionType.income,
      category: 'Freelance',
      date: DateTime(2026, 9, 8),
      createdAt: DateTime(2026, 9, 8, 9, 0),
    );
    final t5 = MoneyTransaction(
      id: 't5',
      amount: 1200.0,
      type: TransactionType.expense,
      category: 'Food',
      date: DateTime(2026, 9, 10),
      createdAt: DateTime(2026, 9, 10, 20, 0),
    );
    // Outside range (August transaction)
    final tOld = MoneyTransaction(
      id: 'tOld',
      amount: 999.0,
      type: TransactionType.income,
      category: 'Salary',
      date: DateTime(2026, 8, 25),
      createdAt: DateTime(2026, 8, 25, 10, 0),
    );

    final transactions = [t1, t2, t3, t4, t5, tOld];

    test('getDaysInRange returns all calendar days inclusively', () {
      final days = MoneyCalculator.getDaysInRange(
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 5),
      );
      expect(days.length, 5);
      expect(days.first, DateTime(2026, 9, 1));
      expect(days.last, DateTime(2026, 9, 5));

      final invalidDays = MoneyCalculator.getDaysInRange(
        DateTime(2026, 9, 5),
        DateTime(2026, 9, 1),
      );
      expect(invalidDays, isEmpty);
    });

    test('getThisMonthRange computes correct boundaries', () {
      final ref = DateTime(2026, 9, 15);
      final range = MoneyCalculator.getThisMonthRange(ref);
      expect(range.start, DateTime(2026, 9, 1));
      expect(range.end, DateTime(2026, 9, 30));
    });

    test('getLastMonthRange computes correct boundaries including year rollover', () {
      final sep = DateTime(2026, 9, 15);
      final sepRange = MoneyCalculator.getLastMonthRange(sep);
      expect(sepRange.start, DateTime(2026, 8, 1));
      expect(sepRange.end, DateTime(2026, 8, 31));

      final jan = DateTime(2026, 1, 10);
      final janRange = MoneyCalculator.getLastMonthRange(jan);
      expect(janRange.start, DateTime(2025, 12, 1));
      expect(janRange.end, DateTime(2025, 12, 31));
    });

    test('incomeForRange, expensesForRange, and savingsForRange compute accurately', () {
      final start = DateTime(2026, 9, 1);
      final end = DateTime(2026, 9, 10);

      // In range:
      // Income: t1 (1500) + t4 (500) = 2000.0
      // Expenses: t2 (300) + t3 (200) + t5 (1200) = 1700.0
      // Savings: 2000 - 1700 = 300.0
      expect(MoneyCalculator.incomeForRange(transactions, start: start, end: end), 2000.0);
      expect(MoneyCalculator.expensesForRange(transactions, start: start, end: end), 1700.0);
      expect(MoneyCalculator.savingsForRange(transactions, start: start, end: end), 300.0);
    });

    test('savingsForRange computes negative savings when expenses exceed income', () {
      final start = DateTime(2026, 9, 10);
      final end = DateTime(2026, 9, 10);

      // Only t5 on Sep 10: Income = 0, Expenses = 1200.0 -> Savings = -1200.0
      expect(MoneyCalculator.incomeForRange(transactions, start: start, end: end), 0.0);
      expect(MoneyCalculator.expensesForRange(transactions, start: start, end: end), 1200.0);
      expect(MoneyCalculator.savingsForRange(transactions, start: start, end: end), -1200.0);
    });

    test('expensesByCategoryForRange sorts descending and excludes zero-spending categories', () {
      final start = DateTime(2026, 9, 1);
      final end = DateTime(2026, 9, 10);

      final breakdown = MoneyCalculator.expensesByCategoryForRange(
        transactions,
        start: start,
        end: end,
      );

      // Food: 300 + 1200 = 1500.0
      // Transport: 200.0
      expect(breakdown.keys.toList(), ['Food', 'Transport']);
      expect(breakdown['Food'], 1500.0);
      expect(breakdown['Transport'], 200.0);
      expect(breakdown.containsKey('Bills'), isFalse);
    });

    test('incomeByCategoryForRange sorts descending and excludes zero-income categories', () {
      final start = DateTime(2026, 9, 1);
      final end = DateTime(2026, 9, 10);

      final breakdown = MoneyCalculator.incomeByCategoryForRange(
        transactions,
        start: start,
        end: end,
      );

      // Salary: 1500.0, Freelance: 500.0
      expect(breakdown.keys.toList(), ['Salary', 'Freelance']);
      expect(breakdown['Salary'], 1500.0);
      expect(breakdown['Freelance'], 500.0);
    });

    test('dailyExpensesForRange includes every single calendar day in range with 0.0 for empty days', () {
      final start = DateTime(2026, 9, 1);
      final end = DateTime(2026, 9, 6);

      final daily = MoneyCalculator.dailyExpensesForRange(
        transactions,
        start: start,
        end: end,
      );

      expect(daily.length, 6);
      expect(daily[DateTime(2026, 9, 1)], 0.0);
      expect(daily[DateTime(2026, 9, 2)], 0.0);
      expect(daily[DateTime(2026, 9, 3)], 0.0);
      expect(daily[DateTime(2026, 9, 4)], 0.0);
      expect(daily[DateTime(2026, 9, 5)], 500.0); // 300 + 200
      expect(daily[DateTime(2026, 9, 6)], 0.0);
    });

    test('dailySavingsForRange computes positive, zero, and negative net values per day', () {
      final start = DateTime(2026, 9, 1);
      final end = DateTime(2026, 9, 10);

      final daily = MoneyCalculator.dailySavingsForRange(
        transactions,
        start: start,
        end: end,
      );

      expect(daily[DateTime(2026, 9, 1)], 0.0);
      expect(daily[DateTime(2026, 9, 2)], 1500.0); // salary income
      expect(daily[DateTime(2026, 9, 5)], -500.0); // food + transport expense
      expect(daily[DateTime(2026, 9, 8)], 500.0); // freelance income
      expect(daily[DateTime(2026, 9, 10)], -1200.0); // food expense
    });
  });
}
