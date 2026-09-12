import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/money_budget.dart';
import '../models/money_category.dart';
import '../models/money_transaction.dart';
import '../models/recurring_money_transaction.dart';
import '../models/transaction_type.dart';
import '../repositories/money_repository.dart';
import '../validation/money_validator.dart';

/// SharedPreferences-backed implementation of [MoneyRepository].
///
/// Ensures strict separation from routine/activity storage by utilizing
/// isolated preference keys [transactionsKey], [categoriesKey], [budgetsKey],
/// and [recurringKey].
class SharedPreferencesMoneyRepository implements MoneyRepository {
  static const String transactionsKey = 'money_transactions_key';
  static const String categoriesKey = 'money_categories_key';
  static const String budgetsKey = 'money_budgets_key';
  static const String recurringKey = 'money_recurring_transactions_key';

  final SharedPreferences _prefs;
  final List<MoneyTransaction> _transactions = [];
  final List<MoneyCategory> _categories = [];
  final List<MoneyBudget> _budgets = [];
  final List<RecurringMoneyTransaction> _recurring = [];

  SharedPreferencesMoneyRepository(this._prefs) {
    _loadFromPrefs();
  }

  /// Factory helper to initialize repository asynchronously with SharedPreferences.
  static Future<SharedPreferencesMoneyRepository> create({
    SharedPreferences? prefs,
  }) async {
    final preferences = prefs ?? await SharedPreferences.getInstance();
    return SharedPreferencesMoneyRepository(preferences);
  }

  void _loadFromPrefs() {
    _loadCategories();
    _loadTransactions();
    _loadBudgets();
    _loadRecurring();
  }

  void _loadCategories() {
    _categories.clear();
    final raw = _prefs.getString(categoriesKey);
    if (raw == null || raw.trim().isEmpty) {
      _categories.addAll(MoneyCategory.defaultCategories);
      _saveCategories();
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            try {
              final category =
                  MoneyCategory.fromJson(Map<String, dynamic>.from(item));
              if (category.id.isNotEmpty && category.name.isNotEmpty) {
                _categories.add(category);
              }
            } catch (_) {
              // Ignore individual malformed category entries
            }
          }
        }
      }
    } catch (_) {
      // Corrupted JSON storage fallback
      _categories.clear();
      _categories.addAll(MoneyCategory.defaultCategories);
      _saveCategories();
      return;
    }

    // Ensure built-in categories are always present
    for (final defaultCat in MoneyCategory.defaultCategories) {
      if (!_categories.any((c) => c.id == defaultCat.id)) {
        _categories.add(defaultCat);
      }
    }
  }

  void _loadTransactions() {
    _transactions.clear();
    final raw = _prefs.getString(transactionsKey);
    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            try {
              final transaction =
                  MoneyTransaction.fromJson(Map<String, dynamic>.from(item));
              MoneyValidator.validateTransaction(transaction);
              _transactions.add(transaction);
            } catch (_) {
              // Ignore individual malformed transactions defensively
            }
          }
        }
      }
    } catch (_) {
      // Corrupted JSON string, defensive reset without crash
      _transactions.clear();
    }
  }

  Future<void> _saveTransactions() async {
    final encoded = jsonEncode(_transactions.map((t) => t.toJson()).toList());
    await _prefs.setString(transactionsKey, encoded);
  }

  Future<void> _saveCategories() async {
    final encoded = jsonEncode(_categories.map((c) => c.toJson()).toList());
    await _prefs.setString(categoriesKey, encoded);
  }

  void _loadBudgets() {
    _budgets.clear();
    final raw = _prefs.getString(budgetsKey);
    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            try {
              final budget =
                  MoneyBudget.fromJson(Map<String, dynamic>.from(item));
              if (budget.id.isNotEmpty &&
                  budget.amount > 0 &&
                  budget.month >= 1 &&
                  budget.month <= 12 &&
                  budget.year > 0 &&
                  !_budgets.any((b) => b.id == budget.id)) {
                _budgets.add(budget);
              }
            } catch (_) {
              // Ignore individual malformed budgets defensively
            }
          }
        }
      }
    } catch (_) {
      // Corrupted JSON string, defensive reset without crash
      _budgets.clear();
    }
  }

  Future<void> _saveBudgets() async {
    final encoded = jsonEncode(_budgets.map((b) => b.toJson()).toList());
    await _prefs.setString(budgetsKey, encoded);
  }

  void _loadRecurring() {
    _recurring.clear();
    final raw = _prefs.getString(recurringKey);
    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            try {
              final r = RecurringMoneyTransaction.fromJson(
                Map<String, dynamic>.from(item),
              );
              if (r.id.isNotEmpty &&
                  r.amount > 0 &&
                  r.categoryId.isNotEmpty &&
                  !_recurring.any((existing) => existing.id == r.id)) {
                _recurring.add(r);
              }
            } catch (_) {
              // Ignore individual malformed recurring records defensively
            }
          }
        }
      }
    } catch (_) {
      // Corrupted JSON string, defensive reset without crash
      _recurring.clear();
    }
  }

  Future<void> _saveRecurring() async {
    final encoded = jsonEncode(_recurring.map((r) => r.toJson()).toList());
    await _prefs.setString(recurringKey, encoded);
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
    await _saveTransactions();
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
    await _saveTransactions();
    return transaction;
  }

  @override
  Future<bool> deleteTransaction(String id) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      _transactions.removeAt(index);
      await _saveTransactions();
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
    await _saveCategories();
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
    await _saveCategories();
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
    await _saveCategories();
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
    await _saveBudgets();
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
    await _saveBudgets();
    return budget;
  }

  @override
  Future<bool> deleteBudget(String id) async {
    final index = _budgets.indexWhere((b) => b.id == id);
    if (index != -1) {
      _budgets.removeAt(index);
      await _saveBudgets();
      return true;
    }
    return false;
  }

  @override
  Future<List<RecurringMoneyTransaction>> getRecurringTransactions() async {
    return List.unmodifiable(_recurring);
  }

  @override
  Future<RecurringMoneyTransaction?> getRecurringById(String id) async {
    try {
      return _recurring.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<RecurringMoneyTransaction> addRecurring(
    RecurringMoneyTransaction recurring,
  ) async {
    MoneyValidator.validateRecurringTransaction(recurring, _categories);
    if (_recurring.any((r) => r.id == recurring.id)) {
      throw MoneyValidationException(
        'Recurring transaction with ID "${recurring.id}" already exists',
      );
    }
    _recurring.add(recurring);
    await _saveRecurring();
    return recurring;
  }

  @override
  Future<RecurringMoneyTransaction> updateRecurring(
    RecurringMoneyTransaction recurring,
  ) async {
    final index = _recurring.indexWhere((r) => r.id == recurring.id);
    if (index == -1) {
      throw MoneyValidationException(
        'Recurring transaction with ID "${recurring.id}" not found',
      );
    }

    final original = _recurring[index];
    MoneyValidator.validateRecurringTransactionUpdate(
      original,
      recurring,
      _categories,
    );
    _recurring[index] = recurring;
    await _saveRecurring();
    return recurring;
  }

  @override
  Future<bool> deleteRecurring(String id) async {
    final index = _recurring.indexWhere((r) => r.id == id);
    if (index != -1) {
      _recurring.removeAt(index);
      await _saveRecurring();
      return true;
    }
    return false;
  }
}
