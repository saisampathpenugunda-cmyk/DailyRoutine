import '../models/money_budget.dart';
import '../models/money_category.dart';
import '../models/money_transaction.dart';
import '../models/transaction_type.dart';

/// Aggregated financial summary of a set of transactions.
class MoneySummary {
  final double totalIncome;
  final double totalExpenses;
  final double balance;
  final double savings;
  final int transactionCount;
  final Map<String, double> expensesByCategory;
  final Map<String, double> incomeByCategory;

  const MoneySummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
    required this.savings,
    required this.transactionCount,
    required this.expensesByCategory,
    required this.incomeByCategory,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoneySummary &&
          runtimeType == other.runtimeType &&
          (totalIncome - other.totalIncome).abs() < 0.000001 &&
          (totalExpenses - other.totalExpenses).abs() < 0.000001 &&
          (balance - other.balance).abs() < 0.000001 &&
          (savings - other.savings).abs() < 0.000001 &&
          transactionCount == other.transactionCount;

  @override
  int get hashCode => Object.hash(
        totalIncome,
        totalExpenses,
        balance,
        savings,
        transactionCount,
      );

  @override
  String toString() =>
      'MoneySummary(income: $totalIncome, expenses: $totalExpenses, balance: $balance, savings: $savings, count: $transactionCount)';
}

/// Detailed comparison between budget limit and actual spending for a specific category.
class CategoryBudgetComparison {
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final double budgetAmount;
  final double actualSpent;
  final double remaining;
  final double progress;
  final double percentage;
  final bool isOverBudget;

  const CategoryBudgetComparison({
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    required this.budgetAmount,
    required this.actualSpent,
    required this.remaining,
    required this.progress,
    required this.percentage,
    required this.isOverBudget,
  });

  /// Clamped progress fraction (0.0 to 1.0) for visual progress bars.
  double get clampedProgress => progress.clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryBudgetComparison &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          (budgetAmount - other.budgetAmount).abs() < 0.000001 &&
          (actualSpent - other.actualSpent).abs() < 0.000001 &&
          (remaining - other.remaining).abs() < 0.000001;

  @override
  int get hashCode => Object.hash(categoryId, budgetAmount, actualSpent, remaining);

  @override
  String toString() =>
      'CategoryBudgetComparison($categoryName: spent $actualSpent / $budgetAmount, remaining $remaining)';
}

/// Aggregated monthly budget overview metrics.
class MonthlyBudgetSummary {
  final double totalBudget;
  final double totalSpent;
  final double remaining;
  final double progress;
  final double percentage;
  final bool isOverBudget;
  final int budgetCount;

  const MonthlyBudgetSummary({
    required this.totalBudget,
    required this.totalSpent,
    required this.remaining,
    required this.progress,
    required this.percentage,
    required this.isOverBudget,
    required this.budgetCount,
  });

  /// Clamped progress fraction (0.0 to 1.0) for visual progress bars.
  double get clampedProgress => progress.clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyBudgetSummary &&
          runtimeType == other.runtimeType &&
          (totalBudget - other.totalBudget).abs() < 0.000001 &&
          (totalSpent - other.totalSpent).abs() < 0.000001 &&
          (remaining - other.remaining).abs() < 0.000001 &&
          budgetCount == other.budgetCount;

  @override
  int get hashCode => Object.hash(totalBudget, totalSpent, remaining, budgetCount);

  @override
  String toString() =>
      'MonthlyBudgetSummary(budget: $totalBudget, spent: $totalSpent, remaining: $remaining, count: $budgetCount)';
}

/// Central calculation and financial formula service for DailyRoutine Money.
class MoneyCalculator {
  /// Sums all income transactions.
  static double calculateTotalIncome(Iterable<MoneyTransaction> transactions) {
    double total = 0.0;
    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        total += t.amount;
      }
    }
    return _round(total);
  }

  /// Sums all expense transactions.
  static double calculateTotalExpenses(Iterable<MoneyTransaction> transactions) {
    double total = 0.0;
    for (final t in transactions) {
      if (t.type == TransactionType.expense) {
        total += t.amount;
      }
    }
    return _round(total);
  }

  /// Net balance: `totalIncome - totalExpenses`.
  static double calculateBalance(Iterable<MoneyTransaction> transactions) {
    return _round(calculateTotalIncome(transactions) - calculateTotalExpenses(transactions));
  }

  /// Net savings: `totalIncome - totalExpenses`.
  static double calculateSavings(Iterable<MoneyTransaction> transactions) {
    return calculateBalance(transactions);
  }

  /// Computes a comprehensive [MoneySummary] for the given [transactions].
  static MoneySummary calculateSummary(Iterable<MoneyTransaction> transactions) {
    final income = calculateTotalIncome(transactions);
    final expenses = calculateTotalExpenses(transactions);
    final balance = _round(income - expenses);

    return MoneySummary(
      totalIncome: income,
      totalExpenses: expenses,
      balance: balance,
      savings: balance,
      transactionCount: transactions.length,
      expensesByCategory: calculateExpensesByCategory(transactions),
      incomeByCategory: calculateIncomeByCategory(transactions),
    );
  }

  /// Aggregates expenses by category name.
  static Map<String, double> calculateExpensesByCategory(
    Iterable<MoneyTransaction> transactions,
  ) {
    final Map<String, double> result = {};
    for (final t in transactions) {
      if (t.type == TransactionType.expense) {
        result[t.category] = _round((result[t.category] ?? 0.0) + t.amount);
      }
    }
    return Map.unmodifiable(result);
  }

  /// Aggregates income by category name.
  static Map<String, double> calculateIncomeByCategory(
    Iterable<MoneyTransaction> transactions,
  ) {
    final Map<String, double> result = {};
    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        result[t.category] = _round((result[t.category] ?? 0.0) + t.amount);
      }
    }
    return Map.unmodifiable(result);
  }

  /// Filters transactions by an inclusive date range.
  static List<MoneyTransaction> filterByDateRange(
    Iterable<MoneyTransaction> transactions, {
    DateTime? start,
    DateTime? end,
  }) {
    final startDate = start != null ? DateTime(start.year, start.month, start.day) : null;
    final endDate = end != null ? DateTime(end.year, end.month, end.day) : null;

    return transactions.where((t) {
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      if (startDate != null && tDate.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && tDate.isAfter(endDate)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Filters transactions to a specific [year] and [month].
  static List<MoneyTransaction> filterByMonth(
    Iterable<MoneyTransaction> transactions, {
    required int year,
    required int month,
  }) {
    return transactions.where((t) => t.date.year == year && t.date.month == month).toList();
  }

  /// Filters transactions by category name (case-insensitive).
  static List<MoneyTransaction> filterByCategory(
    Iterable<MoneyTransaction> transactions,
    String category,
  ) {
    final normalized = category.trim().toLowerCase();
    return transactions
        .where((t) => t.category.trim().toLowerCase() == normalized)
        .toList();
  }

  /// Filters transactions by [TransactionType].
  static List<MoneyTransaction> filterByType(
    Iterable<MoneyTransaction> transactions,
    TransactionType type,
  ) {
    return transactions.where((t) => t.type == type).toList();
  }

  /// Returns all calendar days from [start] to [end] inclusive.
  static List<DateTime> getDaysInRange(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    if (s.isAfter(e)) return [];

    final days = <DateTime>[];
    var current = s;
    while (!current.isAfter(e)) {
      days.add(current);
      current = DateTime(current.year, current.month, current.day + 1);
    }
    return List.unmodifiable(days);
  }

  /// Calculates start and end of current calendar month.
  static ({DateTime start, DateTime end}) getThisMonthRange([DateTime? now]) {
    final current = now ?? DateTime.now();
    final start = DateTime(current.year, current.month, 1);
    final end = DateTime(current.year, current.month + 1, 0);
    return (start: start, end: end);
  }

  /// Calculates start and end of previous calendar month.
  static ({DateTime start, DateTime end}) getLastMonthRange([DateTime? now]) {
    final current = now ?? DateTime.now();
    final start = DateTime(current.year, current.month - 1, 1);
    final end = DateTime(current.year, current.month, 0);
    return (start: start, end: end);
  }

  /// Calculates total income for [start]..[end] inclusive.
  static double incomeForRange(
    Iterable<MoneyTransaction> transactions, {
    required DateTime start,
    required DateTime end,
  }) {
    final inRange = filterByDateRange(transactions, start: start, end: end);
    return calculateTotalIncome(inRange);
  }

  /// Calculates total expenses for [start]..[end] inclusive.
  static double expensesForRange(
    Iterable<MoneyTransaction> transactions, {
    required DateTime start,
    required DateTime end,
  }) {
    final inRange = filterByDateRange(transactions, start: start, end: end);
    return calculateTotalExpenses(inRange);
  }

  /// Calculates net savings (income - expenses) for [start]..[end] inclusive.
  static double savingsForRange(
    Iterable<MoneyTransaction> transactions, {
    required DateTime start,
    required DateTime end,
  }) {
    final inc = incomeForRange(transactions, start: start, end: end);
    final exp = expensesForRange(transactions, start: start, end: end);
    return _round(inc - exp);
  }

  /// Aggregates expenses by category within [start]..[end], ranked descending.
  /// Categories with ₹0 spending are excluded.
  static Map<String, double> expensesByCategoryForRange(
    Iterable<MoneyTransaction> transactions, {
    required DateTime start,
    required DateTime end,
  }) {
    final inRange = filterByDateRange(transactions, start: start, end: end);
    final raw = calculateExpensesByCategory(inRange);
    final sorted = raw.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.unmodifiable(Map.fromEntries(sorted));
  }

  /// Aggregates income by category within [start]..[end], ranked descending.
  /// Categories with ₹0 income are excluded.
  static Map<String, double> incomeByCategoryForRange(
    Iterable<MoneyTransaction> transactions, {
    required DateTime start,
    required DateTime end,
  }) {
    final inRange = filterByDateRange(transactions, start: start, end: end);
    final raw = calculateIncomeByCategory(inRange);
    final sorted = raw.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.unmodifiable(Map.fromEntries(sorted));
  }

  /// Generates a map of daily expense totals for every calendar day in [start]..[end].
  /// Days with no expenses have value 0.0.
  static Map<DateTime, double> dailyExpensesForRange(
    Iterable<MoneyTransaction> transactions, {
    required DateTime start,
    required DateTime end,
  }) {
    final days = getDaysInRange(start, end);
    final inRange = filterByDateRange(transactions, start: start, end: end);
    final Map<DateTime, double> result = {for (final d in days) d: 0.0};

    for (final t in inRange) {
      if (t.type == TransactionType.expense) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        if (result.containsKey(d)) {
          result[d] = _round(result[d]! + t.amount);
        }
      }
    }
    return Map.unmodifiable(result);
  }

  /// Generates a map of daily income totals for every calendar day in [start]..[end].
  /// Days with no income have value 0.0.
  static Map<DateTime, double> dailyIncomeForRange(
    Iterable<MoneyTransaction> transactions, {
    required DateTime start,
    required DateTime end,
  }) {
    final days = getDaysInRange(start, end);
    final inRange = filterByDateRange(transactions, start: start, end: end);
    final Map<DateTime, double> result = {for (final d in days) d: 0.0};

    for (final t in inRange) {
      if (t.type == TransactionType.income) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        if (result.containsKey(d)) {
          result[d] = _round(result[d]! + t.amount);
        }
      }
    }
    return Map.unmodifiable(result);
  }

  /// Generates a map of daily net savings (income - expense) for every calendar day in [start]..[end].
  /// Days with no transactions have value 0.0.
  static Map<DateTime, double> dailySavingsForRange(
    Iterable<MoneyTransaction> transactions, {
    required DateTime start,
    required DateTime end,
  }) {
    final dailyInc = dailyIncomeForRange(transactions, start: start, end: end);
    final dailyExp = dailyExpensesForRange(transactions, start: start, end: end);
    final Map<DateTime, double> result = {};

    for (final d in dailyInc.keys) {
      final inc = dailyInc[d] ?? 0.0;
      final exp = dailyExp[d] ?? 0.0;
      result[d] = _round(inc - exp);
    }
    return Map.unmodifiable(result);
  }

  /// Calculates start and end of a specific calendar month.
  static ({DateTime start, DateTime end}) getMonthRange(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    return (start: start, end: end);
  }

  /// Returns all transactions for [year] and [month], sorted newest first.
  static List<MoneyTransaction> transactionsForMonth(
    Iterable<MoneyTransaction> transactions, {
    required int year,
    required int month,
  }) {
    final filtered = filterByMonth(transactions, year: year, month: month);
    return filtered..sort((a, b) {
      final dateCmp = b.date.compareTo(a.date);
      if (dateCmp != 0) return dateCmp;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  /// Calculates total income for [year] and [month].
  static double incomeForMonth(
    Iterable<MoneyTransaction> transactions, {
    required int year,
    required int month,
  }) {
    final range = getMonthRange(year, month);
    return incomeForRange(transactions, start: range.start, end: range.end);
  }

  /// Calculates total expenses for [year] and [month].
  static double expensesForMonth(
    Iterable<MoneyTransaction> transactions, {
    required int year,
    required int month,
  }) {
    final range = getMonthRange(year, month);
    return expensesForRange(transactions, start: range.start, end: range.end);
  }

  /// Calculates net savings (income - expenses) for [year] and [month].
  static double savingsForMonth(
    Iterable<MoneyTransaction> transactions, {
    required int year,
    required int month,
  }) {
    final range = getMonthRange(year, month);
    return savingsForRange(transactions, start: range.start, end: range.end);
  }

  /// Aggregates expenses by category within [year] and [month], ranked descending.
  /// Categories with ₹0 spending are excluded.
  static Map<String, double> expensesByCategoryForMonth(
    Iterable<MoneyTransaction> transactions, {
    required int year,
    required int month,
  }) {
    final range = getMonthRange(year, month);
    return expensesByCategoryForRange(transactions, start: range.start, end: range.end);
  }

  /// Aggregates income by category within [year] and [month], ranked descending.
  /// Categories with ₹0 income are excluded.
  static Map<String, double> incomeByCategoryForMonth(
    Iterable<MoneyTransaction> transactions, {
    required int year,
    required int month,
  }) {
    final range = getMonthRange(year, month);
    return incomeByCategoryForRange(transactions, start: range.start, end: range.end);
  }

  /// Counts the number of income transactions in [year] and [month].
  static int incomeCountForMonth(
    Iterable<MoneyTransaction> transactions, {
    required int year,
    required int month,
  }) {
    return filterByMonth(transactions, year: year, month: month)
        .where((t) => t.type == TransactionType.income)
        .length;
  }

  /// Counts the number of expense transactions in [year] and [month].
  static int expenseCountForMonth(
    Iterable<MoneyTransaction> transactions, {
    required int year,
    required int month,
  }) {
    return filterByMonth(transactions, year: year, month: month)
        .where((t) => t.type == TransactionType.expense)
        .length;
  }

  /// Calculates total expense spent for a specific category in [year] and [month].
  /// Matches transactions where `t.category` matches either [categoryId] or [categoryName] (case-insensitive).
  static double spentForCategoryInMonth(
    Iterable<MoneyTransaction> transactions, {
    required String categoryId,
    String? categoryName,
    required int year,
    required int month,
  }) {
    final normId = categoryId.trim().toLowerCase();
    final normName = categoryName?.trim().toLowerCase();

    double total = 0.0;
    for (final t in transactions) {
      if (t.type == TransactionType.expense &&
          t.date.year == year &&
          t.date.month == month) {
        final tCat = t.category.trim().toLowerCase();
        if (tCat == normId || (normName != null && tCat == normName)) {
          total += t.amount;
        }
      }
    }
    return _round(total);
  }

  /// Computes the sum of all budget limits for [year] and [month].
  static double totalBudgetForMonth(
    Iterable<MoneyBudget> budgets, {
    required int year,
    required int month,
  }) {
    double total = 0.0;
    for (final b in budgets) {
      if (b.year == year && b.month == month) {
        total += b.amount;
      }
    }
    return _round(total);
  }

  /// Computes the remaining budget for a category: `limit - spent`.
  /// Can be negative if overspent.
  static double budgetRemaining({
    required double limit,
    required double spent,
  }) {
    return _round(limit - spent);
  }

  /// Computes the progress fraction: `spent / limit`.
  /// If limit <= 0, returns 0.0.
  /// Can exceed 1.0 if overspent.
  static double budgetProgress({
    required double limit,
    required double spent,
  }) {
    if (limit <= 0) return 0.0;
    return spent / limit;
  }

  /// Calculates the total expense spent strictly within categories that have an active budget for [year] and [month].
  /// Expenses in unbudgeted categories are NOT included.
  static double totalSpentInBudgetedCategories({
    required Iterable<MoneyBudget> budgets,
    required Iterable<MoneyTransaction> transactions,
    required Iterable<MoneyCategory> categories,
    required int year,
    required int month,
  }) {
    final activeBudgets = budgets.where((b) => b.year == year && b.month == month).toList();
    if (activeBudgets.isEmpty) return 0.0;

    double total = 0.0;
    for (final budget in activeBudgets) {
      final cat = _findCategory(categories, budget.categoryId);
      final spent = spentForCategoryInMonth(
        transactions,
        categoryId: budget.categoryId,
        categoryName: cat?.name,
        year: year,
        month: month,
      );
      total += spent;
    }
    return _round(total);
  }

  /// Computes a comprehensive [MonthlyBudgetSummary] for [year] and [month].
  static MonthlyBudgetSummary calculateMonthlyBudgetSummary({
    required Iterable<MoneyBudget> budgets,
    required Iterable<MoneyTransaction> transactions,
    required Iterable<MoneyCategory> categories,
    required int year,
    required int month,
  }) {
    final activeBudgets = budgets.where((b) => b.year == year && b.month == month).toList();
    if (activeBudgets.isEmpty) {
      return const MonthlyBudgetSummary(
        totalBudget: 0.0,
        totalSpent: 0.0,
        remaining: 0.0,
        progress: 0.0,
        percentage: 0.0,
        isOverBudget: false,
        budgetCount: 0,
      );
    }

    final totalBudget = totalBudgetForMonth(activeBudgets, year: year, month: month);
    final totalSpent = totalSpentInBudgetedCategories(
      budgets: activeBudgets,
      transactions: transactions,
      categories: categories,
      year: year,
      month: month,
    );

    final remaining = budgetRemaining(limit: totalBudget, spent: totalSpent);
    final progress = budgetProgress(limit: totalBudget, spent: totalSpent);
    final percentage = _round(progress * 100);
    final isOverBudget = totalBudget > 0 && totalSpent > totalBudget;

    return MonthlyBudgetSummary(
      totalBudget: totalBudget,
      totalSpent: totalSpent,
      remaining: remaining,
      progress: progress,
      percentage: percentage,
      isOverBudget: isOverBudget,
      budgetCount: activeBudgets.length,
    );
  }

  /// Computes a list of [CategoryBudgetComparison] for all budgeted categories in [year] and [month].
  static List<CategoryBudgetComparison> budgetVsActualForMonth({
    required Iterable<MoneyBudget> budgets,
    required Iterable<MoneyTransaction> transactions,
    required Iterable<MoneyCategory> categories,
    required int year,
    required int month,
  }) {
    final activeBudgets = budgets.where((b) => b.year == year && b.month == month).toList();
    final List<CategoryBudgetComparison> result = [];

    for (final b in activeBudgets) {
      final cat = _findCategory(categories, b.categoryId);
      final categoryName = cat?.name ?? b.categoryId;
      final categoryIcon = cat?.icon;
      final spent = spentForCategoryInMonth(
        transactions,
        categoryId: b.categoryId,
        categoryName: cat?.name,
        year: year,
        month: month,
      );
      final remaining = budgetRemaining(limit: b.amount, spent: spent);
      final progress = budgetProgress(limit: b.amount, spent: spent);
      final percentage = _round(progress * 100);
      final isOver = b.amount > 0 && spent > b.amount;

      result.add(
        CategoryBudgetComparison(
          categoryId: b.categoryId,
          categoryName: categoryName,
          categoryIcon: categoryIcon,
          budgetAmount: b.amount,
          actualSpent: spent,
          remaining: remaining,
          progress: progress,
          percentage: percentage,
          isOverBudget: isOver,
        ),
      );
    }
    return List.unmodifiable(result);
  }

  /// Computes a list of [CategoryBudgetComparison] for all budgeted categories across a date range [start]..[end].
  /// Aggregates budgets for all calendar months covered in the range.
  static List<CategoryBudgetComparison> budgetVsActualForRange({
    required Iterable<MoneyBudget> budgets,
    required Iterable<MoneyTransaction> transactions,
    required Iterable<MoneyCategory> categories,
    required DateTime start,
    required DateTime end,
  }) {
    final Set<({int year, int month})> coveredMonths = {};
    var cursor = DateTime(start.year, start.month, 1);
    final limit = DateTime(end.year, end.month, 1);
    while (!cursor.isAfter(limit)) {
      coveredMonths.add((year: cursor.year, month: cursor.month));
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    final rangeBudgets = budgets.where((b) => coveredMonths.any((m) => m.year == b.year && m.month == b.month)).toList();
    if (rangeBudgets.isEmpty) return const [];

    final Map<String, double> categoryBudgetTotals = {};
    for (final b in rangeBudgets) {
      final key = b.categoryId.trim().toLowerCase();
      categoryBudgetTotals[key] = _round((categoryBudgetTotals[key] ?? 0.0) + b.amount);
    }

    final inRange = filterByDateRange(transactions, start: start, end: end);
    final List<CategoryBudgetComparison> result = [];
    final seen = <String>{};

    for (final b in rangeBudgets) {
      final key = b.categoryId.trim().toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);

      final cat = _findCategory(categories, b.categoryId);
      final categoryName = cat?.name ?? b.categoryId;
      final categoryIcon = cat?.icon;
      final normName = cat?.name.trim().toLowerCase();

      double spent = 0.0;
      for (final t in inRange) {
        if (t.type == TransactionType.expense) {
          final tCat = t.category.trim().toLowerCase();
          if (tCat == key || (normName != null && tCat == normName)) {
            spent += t.amount;
          }
        }
      }
      spent = _round(spent);
      final totalBudget = categoryBudgetTotals[key] ?? b.amount;
      final remaining = budgetRemaining(limit: totalBudget, spent: spent);
      final progress = budgetProgress(limit: totalBudget, spent: spent);
      final percentage = _round(progress * 100);
      final isOver = totalBudget > 0 && spent > totalBudget;

      result.add(
        CategoryBudgetComparison(
          categoryId: b.categoryId,
          categoryName: categoryName,
          categoryIcon: categoryIcon,
          budgetAmount: totalBudget,
          actualSpent: spent,
          remaining: remaining,
          progress: progress,
          percentage: percentage,
          isOverBudget: isOver,
        ),
      );
    }

    return List.unmodifiable(result);
  }

  static MoneyCategory? _findCategory(Iterable<MoneyCategory> categories, String categoryId) {
    final norm = categoryId.trim().toLowerCase();
    for (final c in categories) {
      if (c.id == categoryId || c.name.trim().toLowerCase() == norm) {
        return c;
      }
    }
    return null;
  }

  static double _round(double val) {
    return double.parse(val.toStringAsFixed(2));
  }
}
