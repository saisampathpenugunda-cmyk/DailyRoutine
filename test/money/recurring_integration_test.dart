import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/money/models/money_budget.dart';
import 'package:daily_routine/money/models/recurring_money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/repositories/in_memory_money_repository.dart';
import 'package:daily_routine/money/services/money_calculator.dart';
import 'package:daily_routine/money/services/recurring_transaction_service.dart';

void main() {
  group('Money V2 - Recurring Transactions Cross-Module Integration Tests', () {
    late InMemoryMoneyRepository repo;

    setUp(() {
      repo = InMemoryMoneyRepository();
    });

    test('generated transactions participate naturally in MoneyCalculator and Monthly View calculations', () async {
      final sepDate = DateTime(2026, 9, 1);
      final octDate = DateTime(2026, 10, 1);

      // Recurring income ₹50,000 monthly
      await repo.addRecurring(
        RecurringMoneyTransaction(
          id: 'rec-salary',
          type: TransactionType.income,
          amount: 50000.0,
          categoryId: 'salary',
          frequency: RecurrenceFrequency.monthly,
          startDate: sepDate,
          nextOccurrence: sepDate,
        ),
      );

      // Recurring expense ₹15,000 monthly
      await repo.addRecurring(
        RecurringMoneyTransaction(
          id: 'rec-rent',
          type: TransactionType.expense,
          amount: 15000.0,
          categoryId: 'home',
          frequency: RecurrenceFrequency.monthly,
          startDate: sepDate,
          nextOccurrence: sepDate,
        ),
      );

      // Generate for September
      await RecurringTransactionService.generateDueTransactions(
        repo,
        now: sepDate,
      );

      var txs = await repo.getTransactions();
      expect(txs.length, 2);

      // Monthly View September calculations:
      final sepFiltered = MoneyCalculator.filterByMonth(txs, year: 2026, month: 9);
      var sepSummary = MoneyCalculator.calculateSummary(sepFiltered);
      expect(sepSummary.totalIncome, 50000.0);
      expect(sepSummary.totalExpenses, 15000.0);
      expect(sepSummary.balance, 35000.0);
      expect(sepSummary.savings, 35000.0);

      // October Monthly View is still 0 (future occurrence has not arrived)
      final octFiltered = MoneyCalculator.filterByMonth(txs, year: 2026, month: 10);
      var octSummary = MoneyCalculator.calculateSummary(octFiltered);
      expect(octSummary.totalIncome, 0.0);
      expect(octSummary.totalExpenses, 0.0);

      // Now time advances to October 1:
      await RecurringTransactionService.generateDueTransactions(
        repo,
        now: octDate,
      );

      txs = await repo.getTransactions();
      expect(txs.length, 4);

      // October Monthly View now reflects October occurrences:
      final octFilteredAfter = MoneyCalculator.filterByMonth(txs, year: 2026, month: 10);
      octSummary = MoneyCalculator.calculateSummary(octFilteredAfter);
      expect(octSummary.totalIncome, 50000.0);
      expect(octSummary.totalExpenses, 15000.0);
      expect(octSummary.balance, 35000.0);
    });

    test('generated expense in budgeted category automatically affects Budget actual spending', () async {
      final sepDate = DateTime(2026, 9, 1);

      // Set budget of ₹5,000 for food in September 2026
      await repo.addBudget(
        MoneyBudget(
          id: 'budget-food-sep',
          categoryId: 'food',
          year: 2026,
          month: 9,
          amount: 5000.0,
        ),
      );

      // Set recurring daily lunch of ₹200
      await repo.addRecurring(
        RecurringMoneyTransaction(
          id: 'rec-lunch',
          type: TransactionType.expense,
          amount: 200.0,
          categoryId: 'food',
          frequency: RecurrenceFrequency.daily,
          startDate: sepDate,
          nextOccurrence: sepDate,
        ),
      );

      // On Sep 1 (1 day):
      await RecurringTransactionService.generateDueTransactions(
        repo,
        now: sepDate,
      );

      var budgets = await repo.getBudgets(year: 2026, month: 9);
      var txs = await repo.getTransactions();
      var cats = await repo.getCategories();

      var summary = MoneyCalculator.calculateMonthlyBudgetSummary(
        budgets: budgets,
        transactions: txs,
        categories: cats,
        year: 2026,
        month: 9,
      );

      expect(summary.totalBudget, 5000.0);
      expect(summary.totalSpent, 200.0);
      expect(summary.remaining, 4800.0);
      expect(summary.percentage, closeTo(4.0, 0.1));

      // After 10 days (Sep 10):
      await RecurringTransactionService.generateDueTransactions(
        repo,
        now: DateTime(2026, 9, 10),
      );

      txs = await repo.getTransactions();
      expect(txs.length, 10); // 10 occurrences generated (Sep 1 to Sep 10)

      summary = MoneyCalculator.calculateMonthlyBudgetSummary(
        budgets: budgets,
        transactions: txs,
        categories: cats,
        year: 2026,
        month: 9,
      );

      // 10 days * ₹200 = ₹2,000 spent
      expect(summary.totalBudget, 5000.0);
      expect(summary.totalSpent, 2000.0);
      expect(summary.remaining, 3000.0);
      expect(summary.percentage, closeTo(40.0, 0.1));
    });

    test('recurring definitions themselves are NEVER counted as transactions or money', () async {
      // Add recurring rule with startDate in the future
      await repo.addRecurring(
        RecurringMoneyTransaction(
          id: 'future-rule',
          type: TransactionType.income,
          amount: 100000.0,
          categoryId: 'salary',
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 12, 1),
          nextOccurrence: DateTime(2026, 12, 1),
        ),
      );

      // Evaluate for September 12
      await RecurringTransactionService.generateDueTransactions(
        repo,
        now: DateTime(2026, 9, 12),
      );

      final txs = await repo.getTransactions();
      expect(txs, isEmpty);

      // Net balance is ₹0, NOT ₹100,000!
      expect(MoneyCalculator.calculateBalance(txs), 0.0);
      expect(MoneyCalculator.calculateTotalIncome(txs), 0.0);
    });
  });
}
