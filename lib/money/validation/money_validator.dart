import '../models/money_budget.dart';
import '../models/money_category.dart';
import '../models/money_transaction.dart';
import '../models/recurring_money_transaction.dart';
import '../models/transaction_type.dart';

/// Exception thrown when Money domain validation fails.
class MoneyValidationException implements Exception {
  final String message;

  const MoneyValidationException(this.message);

  @override
  String toString() => 'MoneyValidationException: $message';
}

/// Reusable validator for Money domain models and operations.
class MoneyValidator {
  /// Validates a [MoneyTransaction].
  ///
  /// Enforces:
  /// - ID cannot be empty
  /// - Amount must be strictly greater than 0
  /// - Category name cannot be empty or whitespace
  static void validateTransaction(MoneyTransaction transaction) {
    if (transaction.id.trim().isEmpty) {
      throw const MoneyValidationException('Transaction ID cannot be empty');
    }

    if (transaction.amount <= 0) {
      throw MoneyValidationException(
        'Transaction amount must be greater than 0, got ${transaction.amount}',
      );
    }

    if (transaction.category.trim().isEmpty) {
      throw const MoneyValidationException('Transaction category cannot be empty');
    }
  }

  /// Validates an updated [MoneyTransaction] against its [original].
  ///
  /// Enforces that the ID remains stable.
  static void validateTransactionUpdate(
    MoneyTransaction original,
    MoneyTransaction updated,
  ) {
    if (original.id != updated.id) {
      throw MoneyValidationException(
        'Transaction ID must remain stable. Cannot change ID from "${original.id}" to "${updated.id}"',
      );
    }
    validateTransaction(updated);
  }

  /// Validates a [MoneyCategory] against a list of [existingCategories].
  ///
  /// Enforces:
  /// - Category ID cannot be empty
  /// - Category name cannot be empty or whitespace
  /// - Case-insensitive uniqueness among category names
  static void validateCategory(
    MoneyCategory category,
    List<MoneyCategory> existingCategories,
  ) {
    if (category.id.trim().isEmpty) {
      throw const MoneyValidationException('Category ID cannot be empty');
    }

    final trimmedName = category.name.trim();
    if (trimmedName.isEmpty) {
      throw const MoneyValidationException('Category name cannot be empty');
    }

    final normalized = trimmedName.toLowerCase();
    final isDuplicate = existingCategories.any((c) =>
        c.id != category.id &&
        c.type == category.type &&
        c.name.trim().toLowerCase() == normalized);

    if (isDuplicate) {
      throw MoneyValidationException(
        'A category with the name "$trimmedName" already exists',
      );
    }
  }

  /// Validates updating an existing category.
  ///
  /// Enforces:
  /// - ID cannot be changed
  /// - Built-in categories cannot be renamed
  /// - Category type cannot be changed
  static void validateCategoryUpdate(
    MoneyCategory original,
    MoneyCategory updated,
    List<MoneyCategory> existingCategories,
  ) {
    if (original.id != updated.id) {
      throw const MoneyValidationException('Category ID cannot be changed');
    }
    if (original.isBuiltIn && original.name != updated.name) {
      throw MoneyValidationException(
        'Cannot rename built-in category "${original.name}"',
      );
    }
    if (original.type != updated.type) {
      throw const MoneyValidationException('Cannot change category type');
    }
    validateCategory(updated, existingCategories);
  }

  /// Validates deletion of a category by [categoryId].
  ///
  /// Enforces:
  /// - Category must exist in [existingCategories]
  /// - Built-in categories cannot be deleted
  /// - Custom category cannot be deleted if in use by [existingTransactions]
  /// - Custom category cannot be deleted if in use by [existingBudgets]
  static void validateCategoryDeletion(
    String categoryId,
    List<MoneyCategory> existingCategories, {
    List<MoneyTransaction>? existingTransactions,
    List<MoneyBudget>? existingBudgets,
  }) {
    final index = existingCategories.indexWhere((c) => c.id == categoryId);
    if (index == -1) {
      throw MoneyValidationException('Category with ID "$categoryId" not found');
    }

    final category = existingCategories[index];
    if (category.isBuiltIn) {
      throw MoneyValidationException(
        'Cannot delete built-in category "${category.name}"',
      );
    }

    if (existingTransactions != null) {
      final isUsedInTransactions = existingTransactions.any((t) =>
          t.category.trim().toLowerCase() == category.name.trim().toLowerCase() ||
          t.category.trim().toLowerCase() == category.id.trim().toLowerCase());
      if (isUsedInTransactions) {
        throw const MoneyValidationException(
          'This category is used by existing transactions and cannot be deleted.',
        );
      }
    }

    if (existingBudgets != null) {
      final isUsedInBudgets = existingBudgets.any((b) =>
          b.categoryId == category.id ||
          b.categoryId.trim().toLowerCase() == category.name.trim().toLowerCase());
      if (isUsedInBudgets) {
        throw const MoneyValidationException(
          'This category is used by an existing budget and cannot be deleted.',
        );
      }
    }
  }

  /// Validates a [MoneyBudget].
  ///
  /// Enforces:
  /// - Budget ID cannot be empty
  /// - Budget amount must be strictly greater than 0
  /// - Budget month must be between 1 and 12, year > 0
  /// - Category must exist and must be an Expense category
  /// - One budget per category per calendar month
  static void validateBudget(
    MoneyBudget budget,
    List<MoneyCategory> existingCategories,
    List<MoneyBudget> existingBudgets,
  ) {
    if (budget.id.trim().isEmpty) {
      throw const MoneyValidationException('Budget ID cannot be empty');
    }

    if (budget.amount <= 0) {
      throw MoneyValidationException(
        'Budget amount must be greater than 0, got ${budget.amount}',
      );
    }

    if (budget.year <= 0 || budget.month < 1 || budget.month > 12) {
      throw MoneyValidationException(
        'Invalid budget month: ${budget.month}/${budget.year}',
      );
    }

    final category = existingCategories.firstWhere(
      (c) =>
          c.id == budget.categoryId ||
          c.name.trim().toLowerCase() == budget.categoryId.trim().toLowerCase(),
      orElse: () => throw MoneyValidationException(
        'Category with ID "${budget.categoryId}" not found',
      ),
    );

    if (category.type != TransactionType.expense) {
      throw const MoneyValidationException(
        'Budgets can only be created for Expense categories',
      );
    }

    final isDuplicate = existingBudgets.any((b) =>
        b.id != budget.id &&
        (b.categoryId == category.id ||
            b.categoryId.trim().toLowerCase() == category.name.trim().toLowerCase()) &&
        b.year == budget.year &&
        b.month == budget.month);

    if (isDuplicate) {
      throw const MoneyValidationException(
        'A budget already exists for this category this month.',
      );
    }
  }

  /// Validates an updated [MoneyBudget] against its [original].
  ///
  /// Enforces that the ID and createdAt remain stable.
  static void validateBudgetUpdate(
    MoneyBudget original,
    MoneyBudget updated,
    List<MoneyCategory> existingCategories,
    List<MoneyBudget> existingBudgets,
  ) {
    if (original.id != updated.id) {
      throw MoneyValidationException(
        'Budget ID must remain stable. Cannot change ID from "${original.id}" to "${updated.id}"',
      );
    }
    if (original.createdAt != updated.createdAt) {
      throw const MoneyValidationException('Budget createdAt cannot be changed');
    }
    validateBudget(updated, existingCategories, existingBudgets);
  }

  /// Validates a [RecurringMoneyTransaction].
  ///
  /// Enforces:
  /// - ID cannot be empty
  /// - Amount must be strictly greater than 0
  /// - Category ID cannot be empty
  /// - Category must exist in [existingCategories]
  /// - Category type must match recurring transaction type (income vs expense)
  /// - If [endDate] is specified, it must not be before [startDate]
  static void validateRecurringTransaction(
    RecurringMoneyTransaction recurring,
    List<MoneyCategory> existingCategories,
  ) {
    if (recurring.id.trim().isEmpty) {
      throw const MoneyValidationException('Recurring transaction ID cannot be empty');
    }

    if (recurring.amount <= 0) {
      throw MoneyValidationException(
        'Recurring transaction amount must be greater than 0, got ${recurring.amount}',
      );
    }

    if (recurring.categoryId.trim().isEmpty) {
      throw const MoneyValidationException('Recurring transaction category cannot be empty');
    }

    final category = existingCategories.firstWhere(
      (c) =>
          c.id == recurring.categoryId ||
          c.name.trim().toLowerCase() == recurring.categoryId.trim().toLowerCase(),
      orElse: () => throw MoneyValidationException(
        'Category with ID "${recurring.categoryId}" not found',
      ),
    );

    if (category.type != recurring.type) {
      throw MoneyValidationException(
        'Category "${category.name}" type (${category.type.name}) does not match recurring transaction type (${recurring.type.name})',
      );
    }

    if (recurring.endDate != null &&
        recurring.endDate!.isBefore(recurring.startDate)) {
      throw const MoneyValidationException('End date cannot be before start date');
    }
  }

  /// Validates an updated [RecurringMoneyTransaction] against its [original].
  ///
  /// Enforces that the ID and createdAt remain stable.
  static void validateRecurringTransactionUpdate(
    RecurringMoneyTransaction original,
    RecurringMoneyTransaction updated,
    List<MoneyCategory> existingCategories,
  ) {
    if (original.id != updated.id) {
      throw MoneyValidationException(
        'Recurring transaction ID must remain stable. Cannot change ID from "${original.id}" to "${updated.id}"',
      );
    }
    if (original.createdAt != updated.createdAt) {
      throw const MoneyValidationException(
        'Recurring transaction createdAt cannot be changed',
      );
    }
    validateRecurringTransaction(updated, existingCategories);
  }
}
