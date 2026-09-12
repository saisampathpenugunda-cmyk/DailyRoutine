import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/money/models/money_category.dart';
import 'package:daily_routine/money/models/transaction_type.dart';

void main() {
  group('MoneyCategory Model Tests', () {
    test('defaultCategories contains exactly 15 built-in categories', () {
      final categories = MoneyCategory.defaultCategories;
      expect(categories.length, 15);

      final names = categories.map((c) => c.name).toList();
      expect(names, containsAll([
        'Food',
        'Transport',
        'Education',
        'Shopping',
        'Bills',
        'Entertainment',
        'Health',
        'Work',
        'Home',
        'Other',
        'Salary',
        'Freelance',
        'Business',
        'Gift',
      ]));

      for (final cat in categories) {
        expect(cat.isBuiltIn, isTrue);
        expect(cat.id, isNotEmpty);
      }
    });

    test('defaultExpenseCategories contains exactly 10 built-in expense categories', () {
      final expenseCategories = MoneyCategory.defaultExpenseCategories;
      expect(expenseCategories.length, 10);
      expect(expenseCategories.every((c) => c.type == TransactionType.expense), isTrue);
      expect(expenseCategories.every((c) => c.isBuiltIn), isTrue);
      expect(expenseCategories.map((c) => c.name), containsAll([
        'Food', 'Transport', 'Education', 'Shopping', 'Bills',
        'Entertainment', 'Health', 'Work', 'Home', 'Other',
      ]));
    });

    test('defaultIncomeCategories contains exactly 5 built-in income categories', () {
      final incomeCategories = MoneyCategory.defaultIncomeCategories;
      expect(incomeCategories.length, 5);
      expect(incomeCategories.every((c) => c.type == TransactionType.income), isTrue);
      expect(incomeCategories.every((c) => c.isBuiltIn), isTrue);
      expect(incomeCategories.map((c) => c.name), containsAll([
        'Salary', 'Freelance', 'Business', 'Gift', 'Other',
      ]));
    });

    test('creates custom category with isBuiltIn false and expense type by default', () {
      const custom = MoneyCategory(
        id: 'investments',
        name: 'Investments',
      );

      expect(custom.id, 'investments');
      expect(custom.name, 'Investments');
      expect(custom.isBuiltIn, isFalse);
      expect(custom.type, TransactionType.expense);
    });

    test('creates custom category with income type', () {
      const custom = MoneyCategory(
        id: 'rental',
        name: 'Rental Income',
        type: TransactionType.income,
      );

      expect(custom.id, 'rental');
      expect(custom.name, 'Rental Income');
      expect(custom.isBuiltIn, isFalse);
      expect(custom.type, TransactionType.income);
    });

    test('copyWith updates fields appropriately', () {
      const cat = MoneyCategory(
        id: 'gym',
        name: 'Gym',
        isBuiltIn: false,
      );

      final updated = cat.copyWith(
        name: 'Fitness',
        icon: 'fitness_center',
        type: TransactionType.income,
      );
      expect(updated.id, 'gym');
      expect(updated.name, 'Fitness');
      expect(updated.icon, 'fitness_center');
      expect(updated.isBuiltIn, isFalse);
      expect(updated.type, TransactionType.income);
    });

    test('toJson and fromJson serialize and deserialize accurately', () {
      const original = MoneyCategory(
        id: 'groceries',
        name: 'Groceries',
        isBuiltIn: false,
        icon: 'local_grocery_store',
        type: TransactionType.expense,
      );

      final json = original.toJson();
      expect(json['id'], 'groceries');
      expect(json['name'], 'Groceries');
      expect(json['isBuiltIn'], isFalse);
      expect(json['icon'], 'local_grocery_store');
      expect(json['type'], 'expense');

      final reconstructed = MoneyCategory.fromJson(json);
      expect(reconstructed, equals(original));
    });

    test('toJson and fromJson serialize income category accurately', () {
      const incomeCat = MoneyCategory(
        id: 'consulting',
        name: 'Consulting',
        isBuiltIn: false,
        icon: 'laptop',
        type: TransactionType.income,
      );

      final json = incomeCat.toJson();
      expect(json['type'], 'income');

      final reconstructed = MoneyCategory.fromJson(json);
      expect(reconstructed, equals(incomeCat));
      expect(reconstructed.type, TransactionType.income);
    });
  });
}
