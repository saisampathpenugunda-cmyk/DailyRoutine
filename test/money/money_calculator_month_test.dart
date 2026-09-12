import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/money/models/money_budget.dart';
import 'package:daily_routine/money/models/money_category.dart';
import 'package:daily_routine/money/models/money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/services/money_calculator.dart';

void main() {
  group('MoneyCalculator Month Analytics Tests', () {
    test('getMonthRange computes precise month boundaries', () {
      final sepRange = MoneyCalculator.getMonthRange(2026, 9);
      expect(sepRange.start, DateTime(2026, 9, 1));
      expect(sepRange.end, DateTime(2026, 9, 30));

      final febLeap = MoneyCalculator.getMonthRange(2024, 2);
      expect(febLeap.start, DateTime(2024, 2, 1));
      expect(febLeap.end, DateTime(2024, 2, 29));

      final febNonLeap = MoneyCalculator.getMonthRange(2025, 2);
      expect(febNonLeap.start, DateTime(2025, 2, 1));
      expect(febNonLeap.end, DateTime(2025, 2, 28));

      final dec = MoneyCalculator.getMonthRange(2026, 12);
      expect(dec.start, DateTime(2026, 12, 1));
      expect(dec.end, DateTime(2026, 12, 31));
    });

    final t1 = MoneyTransaction(
      id: 't1',
      amount: 4000.0,
      type: TransactionType.income,
      category: 'Salary',
      date: DateTime(2026, 9, 1),
      createdAt: DateTime(2026, 9, 1, 9, 0),
    );
    final t2 = MoneyTransaction(
      id: 't2',
      amount: 1200.0,
      type: TransactionType.expense,
      category: 'Food',
      date: DateTime(2026, 9, 5),
      createdAt: DateTime(2026, 9, 5, 12, 0),
    );
    final t3 = MoneyTransaction(
      id: 't3',
      amount: 300.0,
      type: TransactionType.expense,
      category: 'Transport',
      date: DateTime(2026, 9, 5),
      createdAt: DateTime(2026, 9, 5, 18, 0),
    );
    final t4 = MoneyTransaction(
      id: 't4',
      amount: 800.0,
      type: TransactionType.expense,
      category: 'Food',
      date: DateTime(2026, 9, 10),
      createdAt: DateTime(2026, 9, 10, 8, 0),
    );
    final t5 = MoneyTransaction(
      id: 't5',
      amount: 1500.0,
      type: TransactionType.income,
      category: 'Freelance',
      date: DateTime(2026, 9, 10),
      createdAt: DateTime(2026, 9, 10, 15, 0),
    );
    final tOct = MoneyTransaction(
      id: 'tOct',
      amount: 500.0,
      type: TransactionType.expense,
      category: 'Food',
      date: DateTime(2026, 10, 1),
      createdAt: DateTime(2026, 10, 1, 10, 0),
    );

    final transactions = [t1, t2, t3, t4, t5, tOct];

    test('transactionsForMonth filters to month and orders newest first', () {
      final sepList = MoneyCalculator.transactionsForMonth(
        transactions,
        year: 2026,
        month: 9,
      );

      expect(sepList.length, 5);
      // Sep 10 15:00 (t5), then Sep 10 08:00 (t4), then Sep 5 18:00 (t3), then Sep 5 12:00 (t2), then Sep 1 09:00 (t1)
      expect(sepList[0].id, 't5');
      expect(sepList[1].id, 't4');
      expect(sepList[2].id, 't3');
      expect(sepList[3].id, 't2');
      expect(sepList[4].id, 't1');
    });

    test('incomeForMonth, expensesForMonth, and savingsForMonth compute accurately', () {
      final income = MoneyCalculator.incomeForMonth(transactions, year: 2026, month: 9);
      final expenses = MoneyCalculator.expensesForMonth(transactions, year: 2026, month: 9);
      final savings = MoneyCalculator.savingsForMonth(transactions, year: 2026, month: 9);

      // Income: 4000 (t1) + 1500 (t5) = 5500.0
      // Expenses: 1200 (t2) + 300 (t3) + 800 (t4) = 2300.0
      // Savings: 5500 - 2300 = 3200.0
      expect(income, 5500.0);
      expect(expenses, 2300.0);
      expect(savings, 3200.0);
    });

    test('savingsForMonth returns negative savings when expenses exceed income', () {
      final octIncome = MoneyCalculator.incomeForMonth(transactions, year: 2026, month: 10);
      final octExpenses = MoneyCalculator.expensesForMonth(transactions, year: 2026, month: 10);
      final octSavings = MoneyCalculator.savingsForMonth(transactions, year: 2026, month: 10);

      expect(octIncome, 0.0);
      expect(octExpenses, 500.0);
      expect(octSavings, -500.0);
    });

    test('expensesByCategoryForMonth ranks descending and excludes zero-spending', () {
      final breakdown = MoneyCalculator.expensesByCategoryForMonth(
        transactions,
        year: 2026,
        month: 9,
      );

      // Food: 1200 + 800 = 2000.0
      // Transport: 300.0
      expect(breakdown.keys.toList(), ['Food', 'Transport']);
      expect(breakdown['Food'], 2000.0);
      expect(breakdown['Transport'], 300.0);
      expect(breakdown.containsKey('Bills'), isFalse);
    });

    test('incomeByCategoryForMonth ranks descending and excludes zero-income', () {
      final breakdown = MoneyCalculator.incomeByCategoryForMonth(
        transactions,
        year: 2026,
        month: 9,
      );

      // Salary: 4000.0, Freelance: 1500.0
      expect(breakdown.keys.toList(), ['Salary', 'Freelance']);
      expect(breakdown['Salary'], 4000.0);
      expect(breakdown['Freelance'], 1500.0);
    });

    test('incomeCountForMonth and expenseCountForMonth return accurate transaction counts', () {
      final incCount = MoneyCalculator.incomeCountForMonth(transactions, year: 2026, month: 9);
      final expCount = MoneyCalculator.expenseCountForMonth(transactions, year: 2026, month: 9);

      expect(incCount, 2); // t1, t5
      expect(expCount, 3); // t2, t3, t4

      final octInc = MoneyCalculator.incomeCountForMonth(transactions, year: 2026, month: 10);
      final octExp = MoneyCalculator.expenseCountForMonth(transactions, year: 2026, month: 10);

      expect(octInc, 0);
      expect(octExp, 1);
    });

    group('Budget Calculations', () {
      test('spentForCategoryInMonth sums category expenses matching id or name', () {
        final spentFood = MoneyCalculator.spentForCategoryInMonth(
          transactions,
          categoryId: 'food',
          categoryName: 'Food',
          year: 2026,
          month: 9,
        );
        // t2 (1200) + t4 (800) = 2000.0
        expect(spentFood, 2000.0);

        final spentTransport = MoneyCalculator.spentForCategoryInMonth(
          transactions,
          categoryId: 'transport',
          categoryName: 'Transport',
          year: 2026,
          month: 9,
        );
        // t3 = 300.0
        expect(spentTransport, 300.0);

        final spentOct = MoneyCalculator.spentForCategoryInMonth(
          transactions,
          categoryId: 'food',
          categoryName: 'Food',
          year: 2026,
          month: 10,
        );
        // tOct = 500.0
        expect(spentOct, 500.0);

        final spentNone = MoneyCalculator.spentForCategoryInMonth(
          transactions,
          categoryId: 'bills',
          categoryName: 'Bills',
          year: 2026,
          month: 9,
        );
        expect(spentNone, 0.0);
      });

      test('totalBudgetForMonth sums budget limits for target month', () {
        final budgets = [
          MoneyBudget(id: 'b1', categoryId: 'food', year: 2026, month: 9, amount: 5000),
          MoneyBudget(id: 'b2', categoryId: 'transport', year: 2026, month: 9, amount: 2000),
          MoneyBudget(id: 'b3', categoryId: 'food', year: 2026, month: 10, amount: 6000),
        ];

        expect(MoneyCalculator.totalBudgetForMonth(budgets, year: 2026, month: 9), 7000.0);
        expect(MoneyCalculator.totalBudgetForMonth(budgets, year: 2026, month: 10), 6000.0);
        expect(MoneyCalculator.totalBudgetForMonth(budgets, year: 2026, month: 11), 0.0);
      });

      test('budgetRemaining calculates limit - spent and handles overspending', () {
        expect(MoneyCalculator.budgetRemaining(limit: 5000, spent: 3000), 2000.0);
        expect(MoneyCalculator.budgetRemaining(limit: 5000, spent: 5000), 0.0);
        expect(MoneyCalculator.budgetRemaining(limit: 5000, spent: 6500), -1500.0);
      });

      test('budgetProgress calculates ratio and handles boundary cases', () {
        expect(MoneyCalculator.budgetProgress(limit: 5000, spent: 2500), 0.5);
        expect(MoneyCalculator.budgetProgress(limit: 5000, spent: 5000), 1.0);
        expect(MoneyCalculator.budgetProgress(limit: 5000, spent: 7500), 1.5);
        expect(MoneyCalculator.budgetProgress(limit: 0, spent: 100), 0.0);
      });

      test('totalSpentInBudgetedCategories sums strictly within budgeted categories and ignores unbudgeted', () {
        final budgets = [
          MoneyBudget(id: 'b1', categoryId: 'food', year: 2026, month: 9, amount: 3000),
        ];
        // transactions has Food (1200 + 800 = 2000), Transport (300), Salary (4000), Freelance (1500)
        final spentBudgeted = MoneyCalculator.totalSpentInBudgetedCategories(
          budgets: budgets,
          transactions: transactions,
          categories: MoneyCategory.defaultCategories,
          year: 2026,
          month: 9,
        );
        // ONLY Food is budgeted (2000.0). Transport (300.0) is not budgeted and must be excluded!
        expect(spentBudgeted, 2000.0);
      });

      test('calculateMonthlyBudgetSummary computes overall budget metrics accurately', () {
        final budgets = [
          MoneyBudget(id: 'b1', categoryId: 'food', year: 2026, month: 9, amount: 2500),
          MoneyBudget(id: 'b2', categoryId: 'transport', year: 2026, month: 9, amount: 500),
        ];

        final summary = MoneyCalculator.calculateMonthlyBudgetSummary(
          budgets: budgets,
          transactions: transactions,
          categories: MoneyCategory.defaultCategories,
          year: 2026,
          month: 9,
        );

        // Total budget: 2500 + 500 = 3000.0
        expect(summary.totalBudget, 3000.0);
        // Total spent: Food (2000) + Transport (300) = 2300.0
        expect(summary.totalSpent, 2300.0);
        // Remaining: 3000 - 2300 = 700.0
        expect(summary.remaining, 700.0);
        // Progress: 2300 / 3000 = 0.7666... -> clampedProgress ~ 0.7666...
        expect(summary.isOverBudget, isFalse);
        expect(summary.budgetCount, 2);
        expect(summary.clampedProgress, closeTo(0.766, 0.01));
      });

      test('calculateMonthlyBudgetSummary returns zeroes when no budgets exist', () {
        final summary = MoneyCalculator.calculateMonthlyBudgetSummary(
          budgets: [],
          transactions: transactions,
          categories: MoneyCategory.defaultCategories,
          year: 2026,
          month: 9,
        );

        expect(summary.totalBudget, 0.0);
        expect(summary.totalSpent, 0.0);
        expect(summary.remaining, 0.0);
        expect(summary.progress, 0.0);
        expect(summary.percentage, 0.0);
        expect(summary.isOverBudget, isFalse);
        expect(summary.budgetCount, 0);
      });

      test('calculateMonthlyBudgetSummary correctly flags isOverBudget and percentage > 100', () {
        final budgets = [
          MoneyBudget(id: 'b1', categoryId: 'food', year: 2026, month: 9, amount: 1500),
        ];

        final summary = MoneyCalculator.calculateMonthlyBudgetSummary(
          budgets: budgets,
          transactions: transactions,
          categories: MoneyCategory.defaultCategories,
          year: 2026,
          month: 9,
        );

        // Limit: 1500, Spent: 2000
        expect(summary.totalBudget, 1500.0);
        expect(summary.totalSpent, 2000.0);
        expect(summary.remaining, -500.0);
        expect(summary.progress, closeTo(1.333, 0.01));
        expect(summary.percentage, closeTo(133.33, 0.01));
        expect(summary.clampedProgress, 1.0);
        expect(summary.isOverBudget, isTrue);
      });

      test('budgetVsActualForMonth returns structured category comparisons with correct remaining', () {
        final budgets = [
          MoneyBudget(id: 'b1', categoryId: 'food', year: 2026, month: 9, amount: 2500),
          MoneyBudget(id: 'b2', categoryId: 'transport', year: 2026, month: 9, amount: 200),
        ];

        final comparisons = MoneyCalculator.budgetVsActualForMonth(
          budgets: budgets,
          transactions: transactions,
          categories: MoneyCategory.defaultCategories,
          year: 2026,
          month: 9,
        );

        expect(comparisons.length, 2);

        // Food
        final foodComp = comparisons.firstWhere((c) => c.categoryId == 'food');
        expect(foodComp.categoryName, 'Food');
        expect(foodComp.budgetAmount, 2500.0);
        expect(foodComp.actualSpent, 2000.0);
        expect(foodComp.remaining, 500.0);
        expect(foodComp.percentage, 80.0);
        expect(foodComp.isOverBudget, isFalse);
        expect(foodComp.clampedProgress, 0.8);

        // Transport: spent 300 vs budget 200 -> over budget
        final transComp = comparisons.firstWhere((c) => c.categoryId == 'transport');
        expect(transComp.categoryName, 'Transport');
        expect(transComp.budgetAmount, 200.0);
        expect(transComp.actualSpent, 300.0);
        expect(transComp.remaining, -100.0);
        expect(transComp.percentage, 150.0);
        expect(transComp.isOverBudget, isTrue);
        expect(transComp.clampedProgress, 1.0);
      });

      test('budgetVsActualForRange aggregates multi-month budgets across date ranges', () {
        final budgets = [
          MoneyBudget(id: 'bSep', categoryId: 'food', year: 2026, month: 9, amount: 2000),
          MoneyBudget(id: 'bOct', categoryId: 'food', year: 2026, month: 10, amount: 2000),
        ];

        final comparisons = MoneyCalculator.budgetVsActualForRange(
          budgets: budgets,
          transactions: transactions,
          categories: MoneyCategory.defaultCategories,
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 10, 31),
        );

        expect(comparisons.length, 1);
        final foodComp = comparisons.first;
        // Aggregated budget: 2000 + 2000 = 4000
        expect(foodComp.budgetAmount, 4000.0);
        // Spent: Sep (2000) + Oct (500) = 2500.0
        expect(foodComp.actualSpent, 2500.0);
        expect(foodComp.remaining, 1500.0);
        expect(foodComp.isOverBudget, isFalse);
      });
    });
  });
}
