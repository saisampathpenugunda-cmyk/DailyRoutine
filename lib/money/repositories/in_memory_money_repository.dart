import '../models/money_budget.dart';
import '../models/money_category.dart';
import '../models/money_transaction.dart';
import '../models/recurring_money_transaction.dart';
import '../models/transaction_type.dart';
import '../validation/money_validator.dart';
import 'money_repository.dart';

/// Hermetic in-memory implementation of [MoneyRepository], useful for unit testing.
class InMemoryMoneyRepository implements MoneyRepository {
  final List<MoneyTransaction> _transactions = [];
  final List<MoneyCategory> _categories = [];
  final List<MoneyBudget> _budgets = [];
  final List<RecurringMoneyTransaction> _recurringTransactions = [];

  InMemoryMoneyRepository({
    List<MoneyTransaction>? initialTransactions,
    List<MoneyCategory>? initialCategories,
    List<MoneyBudget>? initialBudgets,
    List<RecurringMoneyTransaction>? initialRecurringTransactions,
  }) {
    if (initialTransactions != null) {
      _transactions.addAll(initialTransactions);
    }
    if (initialCategories != null) {
      _categories.addAll(initialCategories);
    } else {
      _categories.addAll(MoneyCategory.defaultCategories);
    }
    if (initialBudgets != null) {
      _budgets.addAll(initialBudgets);
    }
    if (initialRecurringTransactions != null) {
      _recurringTransactions.addAll(initialRecurringTransactions);
    }
  }

  @override
  Future<List<MoneyTransaction>> getTransactions() async {
    return List.unmodifiable(_transactions);
  }

  @override
  Future<MoneyTransaction?> getTransactionById(String id) async {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<MoneyTransaction> addTransaction(MoneyTransaction transaction) async {
    MoneyValidator.validateTransaction(transaction);
    if (_transactions.any((t) => t.id == transaction.id)) {
      throw MoneyValidationException(
        'Transaction with ID "${transaction.id}" already exists',
      );
    }
    _transactions.add(transaction);
    return transaction;
  }

  @override
  Future<MoneyTransaction> updateTransaction(MoneyTransaction transaction) async {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index == -1) {
      throw MoneyValidationException(
        'Transaction with ID "${transaction.id}" not found',
      );
    }

    final original = _transactions[index];
    MoneyValidator.validateTransactionUpdate(original, transaction);

    _transactions[index] = transaction;
    return transaction;
  }

  @override
  Future<bool> deleteTransaction(String id) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      _transactions.removeAt(index);
      return true;
    }
    return false;
  }

  @override
  Future<List<MoneyCategory>> getCategories({TransactionType? type}) async {
    if (type == null) {
      return List.unmodifiable(_categories);
    }
    return List.unmodifiable(_categories.where((c) => c.type == type));
  }

  @override
  Future<MoneyCategory> addCategory(MoneyCategory category) async {
    MoneyValidator.validateCategory(category, _categories);
    _categories.add(category);
    return category;
  }

  @override
  Future<MoneyCategory> updateCategory(MoneyCategory category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index == -1) {
      throw MoneyValidationException('Category with ID "${category.id}" not found');
    }

    final original = _categories[index];
    MoneyValidator.validateCategoryUpdate(original, category, _categories);
    _categories[index] = category;
    return category;
  }

  @override
  Future<bool> deleteCategory(String id) async {
    MoneyValidator.validateCategoryDeletion(
      id,
      _categories,
      existingTransactions: _transactions,
      existingBudgets: _budgets,
    );
    _categories.removeWhere((c) => c.id == id);
    return true;
  }

  @override
  Future<List<MoneyBudget>> getBudgets({int? year, int? month}) async {
    return List.unmodifiable(_budgets.where((b) {
      if (year != null && b.year != year) return false;
      if (month != null && b.month != month) return false;
      return true;
    }));
  }

  @override
  Future<MoneyBudget?> getBudgetById(String id) async {
    try {
      return _budgets.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<MoneyBudget?> getBudgetByCategory({
    required String categoryId,
    required int year,
    required int month,
  }) async {
    final norm = categoryId.trim().toLowerCase();
    try {
      return _budgets.firstWhere((b) =>
          (b.categoryId == categoryId || b.categoryId.trim().toLowerCase() == norm) &&
          b.year == year &&
          b.month == month);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<MoneyBudget> addBudget(MoneyBudget budget) async {
    MoneyValidator.validateBudget(budget, _categories, _budgets);
    if (_budgets.any((b) => b.id == budget.id)) {
      throw MoneyValidationException('Budget with ID "${budget.id}" already exists');
    }
    _budgets.add(budget);
    return budget;
  }

  @override
  Future<MoneyBudget> updateBudget(MoneyBudget budget) async {
    final index = _budgets.indexWhere((b) => b.id == budget.id);
    if (index == -1) {
      throw MoneyValidationException('Budget with ID "${budget.id}" not found');
    }

    final original = _budgets[index];
    MoneyValidator.validateBudgetUpdate(original, budget, _categories, _budgets);
    _budgets[index] = budget;
    return budget;
  }

  @override
  Future<bool> deleteBudget(String id) async {
    final index = _budgets.indexWhere((b) => b.id == id);
    if (index != -1) {
      _budgets.removeAt(index);
      return true;
    }
    return false;
  }

  @override
  Future<List<RecurringMoneyTransaction>> getRecurringTransactions() async {
    return List.unmodifiable(_recurringTransactions);
  }

  @override
  Future<RecurringMoneyTransaction?> getRecurringById(String id) async {
    try {
      return _recurringTransactions.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<RecurringMoneyTransaction> addRecurring(
    RecurringMoneyTransaction recurring,
  ) async {
    MoneyValidator.validateRecurringTransaction(recurring, _categories);
    if (_recurringTransactions.any((r) => r.id == recurring.id)) {
      throw MoneyValidationException(
        'Recurring transaction with ID "${recurring.id}" already exists',
      );
    }
    _recurringTransactions.add(recurring);
    return recurring;
  }

  @override
  Future<RecurringMoneyTransaction> updateRecurring(
    RecurringMoneyTransaction recurring,
  ) async {
    final index = _recurringTransactions.indexWhere((r) => r.id == recurring.id);
    if (index == -1) {
      throw MoneyValidationException(
        'Recurring transaction with ID "${recurring.id}" not found',
      );
    }

    final original = _recurringTransactions[index];
    MoneyValidator.validateRecurringTransactionUpdate(
      original,
      recurring,
      _categories,
    );
    _recurringTransactions[index] = recurring;
    return recurring;
  }

  @override
  Future<bool> deleteRecurring(String id) async {
    final index = _recurringTransactions.indexWhere((r) => r.id == id);
    if (index != -1) {
      _recurringTransactions.removeAt(index);
      return true;
    }
    return false;
  }
}
