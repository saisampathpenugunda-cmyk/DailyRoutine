import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/money/models/money_budget.dart';
import 'package:daily_routine/money/models/money_category.dart';
import 'package:daily_routine/money/models/money_transaction.dart';
import 'package:daily_routine/money/models/recurring_money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/validation/money_validator.dart';

void main() {
  group('MoneyValidator Tests', () {
    group('validateTransaction', () {
      test('passes for valid transaction', () {
        final t = MoneyTransaction(
          id: 'valid-id-1',
          type: TransactionType.expense,
          amount: 15.50,
          category: 'Food',
        );

        expect(() => MoneyValidator.validateTransaction(t), returnsNormally);
      });

      test('throws for zero amount', () {
        final t = MoneyTransaction(
          id: 'zero-amount-id',
          type: TransactionType.expense,
          amount: 0.0,
          category: 'Food',
        );

        expect(
          () => MoneyValidator.validateTransaction(t),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('greater than 0'),
          )),
        );
      });

      test('throws for negative amount', () {
        final t = MoneyTransaction(
          id: 'neg-amount-id',
          type: TransactionType.income,
          amount: -50.0,
          category: 'Work',
        );

        expect(
          () => MoneyValidator.validateTransaction(t),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('greater than 0'),
          )),
        );
      });

      test('throws for empty category', () {
        final t = MoneyTransaction(
          id: 'empty-cat-id',
          type: TransactionType.expense,
          amount: 20.0,
          category: '   ',
        );

        expect(
          () => MoneyValidator.validateTransaction(t),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('category cannot be empty'),
          )),
        );
      });

      test('throws for empty ID', () {
        final t = MoneyTransaction(
          id: '   ',
          type: TransactionType.expense,
          amount: 20.0,
          category: 'Food',
        );

        expect(
          () => MoneyValidator.validateTransaction(t),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('ID cannot be empty'),
          )),
        );
      });
    });

    group('validateTransactionUpdate', () {
      test('passes when ID remains stable', () {
        final original = MoneyTransaction(
          id: 'trans-stable-id',
          type: TransactionType.expense,
          amount: 10.0,
          category: 'Food',
        );

        final updated = original.copyWith(amount: 15.0);

        expect(
          () => MoneyValidator.validateTransactionUpdate(original, updated),
          returnsNormally,
        );
      });

      test('throws when ID is modified', () {
        final original = MoneyTransaction(
          id: 'trans-orig-id',
          type: TransactionType.expense,
          amount: 10.0,
          category: 'Food',
        );

        final updated = MoneyTransaction(
          id: 'trans-new-id',
          type: TransactionType.expense,
          amount: 15.0,
          category: 'Food',
        );

        expect(
          () => MoneyValidator.validateTransactionUpdate(original, updated),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('remain stable'),
          )),
        );
      });
    });

    group('validateCategory', () {
      final existing = List<MoneyCategory>.of(MoneyCategory.defaultCategories);

      test('passes for valid new custom category', () {
        const custom = MoneyCategory(
          id: 'custom-hobbies',
          name: 'Hobbies',
        );

        expect(
          () => MoneyValidator.validateCategory(custom, existing),
          returnsNormally,
        );
      });

      test('throws for empty category name', () {
        const custom = MoneyCategory(
          id: 'custom-blank',
          name: '   ',
        );

        expect(
          () => MoneyValidator.validateCategory(custom, existing),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('name cannot be empty'),
          )),
        );
      });

      test('throws for exact duplicate category name', () {
        const duplicate = MoneyCategory(
          id: 'custom-food',
          name: 'Food',
        );

        expect(
          () => MoneyValidator.validateCategory(duplicate, existing),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('already exists'),
          )),
        );
      });

      test('throws for case-insensitive duplicate category name', () {
        const caseInsensitiveDuplicate = MoneyCategory(
          id: 'custom-food-lower',
          name: 'fOoD',
        );

        expect(
          () => MoneyValidator.validateCategory(caseInsensitiveDuplicate, existing),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('already exists'),
          )),
        );
      });

      test('allows same name across different types', () {
        const customExpense = MoneyCategory(
          id: 'custom-salary-exp',
          name: 'Salary', // Salary already exists under income
          type: TransactionType.expense,
        );

        expect(
          () => MoneyValidator.validateCategory(customExpense, existing),
          returnsNormally,
        );
      });

      test('allows updating existing category with same name', () {
        final existingFood = existing.firstWhere((c) => c.id == 'food');
        final updated = existingFood.copyWith(icon: 'new_icon');

        expect(
          () => MoneyValidator.validateCategory(updated, existing),
          returnsNormally,
        );
      });
    });

    group('validateCategoryUpdate', () {
      final existing = List<MoneyCategory>.of(MoneyCategory.defaultCategories);

      test('passes for valid custom category update', () {
        const custom = MoneyCategory(
          id: 'custom-1',
          name: 'Old Name',
          type: TransactionType.expense,
        );
        final list = [...existing, custom];
        final updated = custom.copyWith(name: 'New Name', icon: 'home');

        expect(
          () => MoneyValidator.validateCategoryUpdate(custom, updated, list),
          returnsNormally,
        );
      });

      test('throws when ID changes', () {
        const custom = MoneyCategory(
          id: 'custom-1',
          name: 'Old Name',
          type: TransactionType.expense,
        );
        final list = [...existing, custom];
        final updated = MoneyCategory(
          id: 'custom-2',
          name: 'Old Name',
          type: TransactionType.expense,
        );

        expect(
          () => MoneyValidator.validateCategoryUpdate(custom, updated, list),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('ID cannot be changed'),
          )),
        );
      });

      test('throws when attempting to rename built-in category', () {
        final food = existing.firstWhere((c) => c.id == 'food');
        final renamed = food.copyWith(name: 'Groceries & Snacks');

        expect(
          () => MoneyValidator.validateCategoryUpdate(food, renamed, existing),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('Cannot rename built-in category'),
          )),
        );
      });

      test('throws when category type is changed', () {
        const custom = MoneyCategory(
          id: 'custom-1',
          name: 'Freelancing',
          type: TransactionType.income,
        );
        final list = [...existing, custom];
        final changedType = custom.copyWith(type: TransactionType.expense);

        expect(
          () => MoneyValidator.validateCategoryUpdate(custom, changedType, list),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('Cannot change category type'),
          )),
        );
      });
    });

    group('validateCategoryDeletion', () {
      final categories = [
        ...MoneyCategory.defaultCategories,
        const MoneyCategory(id: 'custom-car', name: 'Car Maintenance', isBuiltIn: false),
      ];

      test('prevents deletion of built-in category', () {
        expect(
          () => MoneyValidator.validateCategoryDeletion('food', categories),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('Cannot delete built-in category'),
          )),
        );
      });

      test('allows deletion of custom category when not in use', () {
        expect(
          () => MoneyValidator.validateCategoryDeletion(
            'custom-car',
            categories,
            existingTransactions: [],
          ),
          returnsNormally,
        );
      });

      test('prevents deletion of custom category when used in transaction by name', () {
        final transactions = [
          MoneyTransaction(
            id: 't-1',
            type: TransactionType.expense,
            amount: 50.0,
            category: 'Car Maintenance',
          ),
        ];

        expect(
          () => MoneyValidator.validateCategoryDeletion(
            'custom-car',
            categories,
            existingTransactions: transactions,
          ),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('used by existing transactions and cannot be deleted'),
          )),
        );
      });

      test('prevents deletion of custom category when used by an existing budget', () {
        final budgets = <MoneyBudget>[
          MoneyBudget(
            id: 'b-1',
            categoryId: 'custom-car',
            year: 2026,
            month: 9,
            amount: 5000,
          ),
        ];

        expect(
          () => MoneyValidator.validateCategoryDeletion(
            'custom-car',
            categories,
            existingBudgets: budgets,
          ),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('used by an existing budget and cannot be deleted'),
          )),
        );
      });

      test('throws when category ID is not found', () {
        expect(
          () => MoneyValidator.validateCategoryDeletion('non-existent', categories),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('not found'),
          )),
        );
      });
    });

    group('validateBudget', () {
      final categories = [
        ...MoneyCategory.defaultCategories,
        const MoneyCategory(
          id: 'custom-exp',
          name: 'Gym',
          type: TransactionType.expense,
        ),
        const MoneyCategory(
          id: 'custom-inc',
          name: 'Consulting',
          type: TransactionType.income,
        ),
      ];

      test('passes for valid budget with expense category', () {
        final budget = MoneyBudget(
          id: 'b-valid-1',
          categoryId: 'food',
          year: 2026,
          month: 9,
          amount: 15000,
        );

        expect(() => MoneyValidator.validateBudget(budget, categories, <MoneyBudget>[]), returnsNormally);
      });

      test('throws for empty ID', () {
        final budget = MoneyBudget(
          id: '   ',
          categoryId: 'food',
          year: 2026,
          month: 9,
          amount: 5000,
        );

        expect(
          () => MoneyValidator.validateBudget(budget, categories, <MoneyBudget>[]),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('ID cannot be empty'),
          )),
        );
      });

      test('throws for zero or negative amount', () {
        final bZero = MoneyBudget(
          id: 'b-0',
          categoryId: 'food',
          year: 2026,
          month: 9,
          amount: 0,
        );
        final bNeg = MoneyBudget(
          id: 'b-neg',
          categoryId: 'food',
          year: 2026,
          month: 9,
          amount: -100,
        );

        expect(
          () => MoneyValidator.validateBudget(bZero, categories, <MoneyBudget>[]),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('greater than 0'),
          )),
        );
        expect(
          () => MoneyValidator.validateBudget(bNeg, categories, <MoneyBudget>[]),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('greater than 0'),
          )),
        );
      });

      test('throws for invalid month or year', () {
        final bLow = MoneyBudget(
          id: 'b-low',
          categoryId: 'food',
          year: 2026,
          month: 0,
          amount: 5000,
        );
        final bHigh = MoneyBudget(
          id: 'b-high',
          categoryId: 'food',
          year: 2026,
          month: 13,
          amount: 5000,
        );
        final bYear = MoneyBudget(
          id: 'b-yr',
          categoryId: 'food',
          year: 0,
          month: 9,
          amount: 5000,
        );

        expect(
          () => MoneyValidator.validateBudget(bLow, categories, <MoneyBudget>[]),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('Invalid budget month'),
          )),
        );
        expect(
          () => MoneyValidator.validateBudget(bHigh, categories, <MoneyBudget>[]),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('Invalid budget month'),
          )),
        );
        expect(
          () => MoneyValidator.validateBudget(bYear, categories, <MoneyBudget>[]),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('Invalid budget month'),
          )),
        );
      });

      test('throws for non-existent category', () {
        final budget = MoneyBudget(
          id: 'b-non-cat',
          categoryId: 'non-existent-cat',
          year: 2026,
          month: 9,
          amount: 5000,
        );

        expect(
          () => MoneyValidator.validateBudget(budget, categories, <MoneyBudget>[]),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('not found'),
          )),
        );
      });

      test('throws for income category', () {
        final budget = MoneyBudget(
          id: 'b-inc-cat',
          categoryId: 'salary', // built-in income category
          year: 2026,
          month: 9,
          amount: 5000,
        );

        expect(
          () => MoneyValidator.validateBudget(budget, categories, <MoneyBudget>[]),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('Expense categories'),
          )),
        );
      });

      test('throws for duplicate category budget in same month', () {
        final existing = <MoneyBudget>[
          MoneyBudget(
            id: 'b-existing-1',
            categoryId: 'food',
            year: 2026,
            month: 9,
            amount: 5000,
          ),
        ];

        final duplicate = MoneyBudget(
          id: 'b-dup',
          categoryId: 'food',
          year: 2026,
          month: 9,
          amount: 6000,
        );

        expect(
          () => MoneyValidator.validateBudget(duplicate, categories, existing),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('A budget already exists for this category this month'),
          )),
        );
      });
    });

    group('validateBudgetUpdate', () {
      final categories = List<MoneyCategory>.of(MoneyCategory.defaultCategories);

      test('passes for valid budget update', () {
        final original = MoneyBudget(
          id: 'b-1',
          categoryId: 'food',
          year: 2026,
          month: 9,
          amount: 5000,
        );
        final updated = original.copyWith(amount: 7500);

        expect(
          () => MoneyValidator.validateBudgetUpdate(original, updated, categories, [original]),
          returnsNormally,
        );
      });

      test('throws when budget ID is modified', () {
        final original = MoneyBudget(
          id: 'b-1',
          categoryId: 'food',
          year: 2026,
          month: 9,
          amount: 5000,
        );
        final updated = MoneyBudget(
          id: 'b-2',
          categoryId: 'food',
          year: 2026,
          month: 9,
          amount: 5000,
          createdAt: original.createdAt,
        );

        expect(
          () => MoneyValidator.validateBudgetUpdate(original, updated, categories, [original]),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('remain stable'),
          )),
        );
      });

      test('throws when createdAt timestamp is modified', () {
        final original = MoneyBudget(
          id: 'b-1',
          categoryId: 'food',
          year: 2026,
          month: 9,
          amount: 5000,
          createdAt: DateTime(2026, 9, 1),
        );
        final updated = original.copyWith(createdAt: DateTime(2026, 9, 2));

        expect(
          () => MoneyValidator.validateBudgetUpdate(original, updated, categories, [original]),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('createdAt cannot be changed'),
          )),
        );
      });
    });

    group('validateRecurringTransaction', () {
      final categories = MoneyCategory.defaultCategories;

      test('passes for valid recurring expense', () {
        final r = RecurringMoneyTransaction(
          id: 'rec-1',
          type: TransactionType.expense,
          amount: 1500.0,
          categoryId: 'bills',
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
        );

        expect(
          () => MoneyValidator.validateRecurringTransaction(r, categories),
          returnsNormally,
        );
      });

      test('passes for valid recurring income with end date', () {
        final r = RecurringMoneyTransaction(
          id: 'rec-2',
          type: TransactionType.income,
          amount: 50000.0,
          categoryId: 'salary',
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
          endDate: DateTime(2027, 9, 1),
        );

        expect(
          () => MoneyValidator.validateRecurringTransaction(r, categories),
          returnsNormally,
        );
      });

      test('throws if ID is empty', () {
        final r = RecurringMoneyTransaction(
          id: '   ',
          type: TransactionType.expense,
          amount: 500.0,
          categoryId: 'food',
          frequency: RecurrenceFrequency.daily,
          startDate: DateTime(2026, 9, 1),
        );

        expect(
          () => MoneyValidator.validateRecurringTransaction(r, categories),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('ID cannot be empty'),
          )),
        );
      });

      test('throws if amount is <= 0', () {
        final r = RecurringMoneyTransaction(
          id: 'rec-1',
          type: TransactionType.expense,
          amount: 0.0,
          categoryId: 'food',
          frequency: RecurrenceFrequency.daily,
          startDate: DateTime(2026, 9, 1),
        );

        expect(
          () => MoneyValidator.validateRecurringTransaction(r, categories),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('greater than 0'),
          )),
        );
      });

      test('throws if categoryId is empty', () {
        final r = RecurringMoneyTransaction(
          id: 'rec-1',
          type: TransactionType.expense,
          amount: 100.0,
          categoryId: '   ',
          frequency: RecurrenceFrequency.daily,
          startDate: DateTime(2026, 9, 1),
        );

        expect(
          () => MoneyValidator.validateRecurringTransaction(r, categories),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('category cannot be empty'),
          )),
        );
      });

      test('throws if category does not exist', () {
        final r = RecurringMoneyTransaction(
          id: 'rec-1',
          type: TransactionType.expense,
          amount: 100.0,
          categoryId: 'non_existent_category_id',
          frequency: RecurrenceFrequency.daily,
          startDate: DateTime(2026, 9, 1),
        );

        expect(
          () => MoneyValidator.validateRecurringTransaction(r, categories),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('not found'),
          )),
        );
      });

      test('throws if category type does not match transaction type', () {
        // 'salary' is an Income category, but transaction type is Expense
        final r = RecurringMoneyTransaction(
          id: 'rec-1',
          type: TransactionType.expense,
          amount: 100.0,
          categoryId: 'salary',
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
        );

        expect(
          () => MoneyValidator.validateRecurringTransaction(r, categories),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('does not match recurring transaction type'),
          )),
        );
      });

      test('throws if end date is before start date', () {
        final r = RecurringMoneyTransaction(
          id: 'rec-1',
          type: TransactionType.expense,
          amount: 100.0,
          categoryId: 'food',
          frequency: RecurrenceFrequency.daily,
          startDate: DateTime(2026, 9, 10),
          endDate: DateTime(2026, 9, 5),
        );

        expect(
          () => MoneyValidator.validateRecurringTransaction(r, categories),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('End date cannot be before start date'),
          )),
        );
      });
    });

    group('validateRecurringTransactionUpdate', () {
      final categories = MoneyCategory.defaultCategories;

      test('passes for valid update', () {
        final original = RecurringMoneyTransaction(
          id: 'rec-1',
          type: TransactionType.expense,
          amount: 1000.0,
          categoryId: 'bills',
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
        );

        final updated = original.copyWith(amount: 1200.0, note: 'Updated bill');

        expect(
          () => MoneyValidator.validateRecurringTransactionUpdate(
            original,
            updated,
            categories,
          ),
          returnsNormally,
        );
      });

      test('throws if ID changes', () {
        final original = RecurringMoneyTransaction(
          id: 'rec-1',
          type: TransactionType.expense,
          amount: 1000.0,
          categoryId: 'bills',
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
        );

        final updated = RecurringMoneyTransaction(
          id: 'rec-2',
          type: TransactionType.expense,
          amount: 1000.0,
          categoryId: 'bills',
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
          createdAt: original.createdAt,
        );

        expect(
          () => MoneyValidator.validateRecurringTransactionUpdate(
            original,
            updated,
            categories,
          ),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('remain stable'),
          )),
        );
      });

      test('throws if createdAt changes', () {
        final original = RecurringMoneyTransaction(
          id: 'rec-1',
          type: TransactionType.expense,
          amount: 1000.0,
          categoryId: 'bills',
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
          createdAt: DateTime(2026, 9, 1),
        );

        final updated = original.copyWith(createdAt: DateTime(2026, 9, 2));

        expect(
          () => MoneyValidator.validateRecurringTransactionUpdate(
            original,
            updated,
            categories,
          ),
          throwsA(isA<MoneyValidationException>().having(
            (e) => e.message,
            'message',
            contains('createdAt cannot be changed'),
          )),
        );
      });
    });
  });
}
