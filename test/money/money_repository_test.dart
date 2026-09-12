import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_routine/money/models/money_budget.dart';
import 'package:daily_routine/money/models/money_category.dart';
import 'package:daily_routine/money/models/money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/repositories/in_memory_money_repository.dart';
import 'package:daily_routine/money/storage/shared_preferences_money_repository.dart';
import 'package:daily_routine/money/validation/money_validator.dart';

void main() {
  group('InMemoryMoneyRepository Tests', () {
    late InMemoryMoneyRepository repo;

    setUp(() {
      repo = InMemoryMoneyRepository();
    });

    test('initializes with default categories (10 expense + 5 income = 15 total)', () async {
      final categories = await repo.getCategories();
      expect(categories.length, 15);
      expect(categories.every((c) => c.isBuiltIn), isTrue);

      final expenses = await repo.getCategories(type: TransactionType.expense);
      expect(expenses.length, 10);
      expect(expenses.every((c) => c.type == TransactionType.expense), isTrue);

      final incomes = await repo.getCategories(type: TransactionType.income);
      expect(incomes.length, 5);
      expect(incomes.every((c) => c.type == TransactionType.income), isTrue);
    });

    test('add and getTransactionById retrieves transaction', () async {
      final t = MoneyTransaction(
        id: 't-100',
        type: TransactionType.expense,
        amount: 85.0,
        category: 'Food',
      );

      await repo.addTransaction(t);
      final retrieved = await repo.getTransactionById('t-100');
      expect(retrieved, isNotNull);
      expect(retrieved!.amount, 85.0);
      expect(retrieved.category, 'Food');
    });

    test('updateTransaction modifies transaction and preserves ID', () async {
      final t = MoneyTransaction(
        id: 't-200',
        type: TransactionType.expense,
        amount: 50.0,
        category: 'Transport',
      );

      await repo.addTransaction(t);
      final updated = t.copyWith(amount: 65.0, note: 'Taxi fare surge');

      await repo.updateTransaction(updated);
      final retrieved = await repo.getTransactionById('t-200');
      expect(retrieved!.id, 't-200');
      expect(retrieved.amount, 65.0);
      expect(retrieved.note, 'Taxi fare surge');
    });

    test('deleteTransaction removes transaction permanently', () async {
      final t = MoneyTransaction(
        id: 't-300',
        type: TransactionType.income,
        amount: 500.0,
        category: 'Work',
      );

      await repo.addTransaction(t);
      expect(await repo.deleteTransaction('t-300'), isTrue);
      expect(await repo.getTransactionById('t-300'), isNull);
      expect(await repo.deleteTransaction('t-300'), isFalse);
    });

    test('addCategory prevents duplicate category names within same type', () async {
      const custom = MoneyCategory(
        id: 'c-crypto',
        name: 'Crypto',
        type: TransactionType.expense,
      );
      await repo.addCategory(custom);

      const duplicate = MoneyCategory(
        id: 'c-crypto-2',
        name: 'cRyPtO',
        type: TransactionType.expense,
      );
      expect(
        () => repo.addCategory(duplicate),
        throwsA(isA<MoneyValidationException>()),
      );
    });

    test('addCategory allows same category name across different types', () async {
      const expenseCustom = MoneyCategory(
        id: 'c-dividends-exp',
        name: 'Dividends',
        type: TransactionType.expense,
      );
      await repo.addCategory(expenseCustom);

      const incomeCustom = MoneyCategory(
        id: 'c-dividends-inc',
        name: 'Dividends',
        type: TransactionType.income,
      );
      final added = await repo.addCategory(incomeCustom);
      expect(added.id, 'c-dividends-inc');

      final expenses = await repo.getCategories(type: TransactionType.expense);
      final incomes = await repo.getCategories(type: TransactionType.income);
      expect(expenses.any((c) => c.name == 'Dividends'), isTrue);
      expect(incomes.any((c) => c.name == 'Dividends'), isTrue);
    });

    test('updateCategory modifies custom category', () async {
      const custom = MoneyCategory(
        id: 'c-fitness',
        name: 'Gym',
        type: TransactionType.expense,
      );
      await repo.addCategory(custom);

      final updated = custom.copyWith(name: 'Fitness Center', icon: 'fitness_center');
      await repo.updateCategory(updated);

      final categories = await repo.getCategories();
      final found = categories.firstWhere((c) => c.id == 'c-fitness');
      expect(found.name, 'Fitness Center');
      expect(found.icon, 'fitness_center');
    });

    test('updateCategory rejects changing category type', () async {
      const custom = MoneyCategory(
        id: 'c-type-change',
        name: 'Tutoring',
        type: TransactionType.income,
      );
      await repo.addCategory(custom);

      final changed = custom.copyWith(type: TransactionType.expense);
      expect(
        () => repo.updateCategory(changed),
        throwsA(isA<MoneyValidationException>().having(
          (e) => e.message,
          'message',
          contains('Cannot change category type'),
        )),
      );
    });

    test('deleteCategory prevents deleting built-in categories', () async {
      expect(
        () => repo.deleteCategory('food'),
        throwsA(isA<MoneyValidationException>()),
      );
      expect(
        () => repo.deleteCategory('salary'),
        throwsA(isA<MoneyValidationException>()),
      );
    });

    test('deleteCategory prevents deleting custom category when used by transaction', () async {
      const custom = MoneyCategory(
        id: 'c-rent',
        name: 'Apartment Rent',
        type: TransactionType.expense,
      );
      await repo.addCategory(custom);

      final t = MoneyTransaction(
        id: 't-rent',
        type: TransactionType.expense,
        amount: 15000.0,
        category: 'Apartment Rent',
      );
      await repo.addTransaction(t);

      expect(
        () => repo.deleteCategory('c-rent'),
        throwsA(isA<MoneyValidationException>().having(
          (e) => e.message,
          'message',
          contains('used by existing transactions and cannot be deleted'),
        )),
      );
    });

    test('deleteCategory deletes unused custom categories', () async {
      const custom = MoneyCategory(id: 'c-gardening', name: 'Gardening');
      await repo.addCategory(custom);

      final deleted = await repo.deleteCategory('c-gardening');
      expect(deleted, isTrue);

      final categories = await repo.getCategories();
      expect(categories.any((c) => c.id == 'c-gardening'), isFalse);
    });

    test('addBudget and getBudgets retrieves and filters by month/year', () async {
      final b1 = MoneyBudget(
        id: 'b-1',
        categoryId: 'food',
        year: 2026,
        month: 9,
        amount: 8000,
      );
      final b2 = MoneyBudget(
        id: 'b-2',
        categoryId: 'transport',
        year: 2026,
        month: 10,
        amount: 3000,
      );

      await repo.addBudget(b1);
      await repo.addBudget(b2);

      final all = await repo.getBudgets();
      expect(all.length, 2);

      final sep = await repo.getBudgets(year: 2026, month: 9);
      expect(sep.length, 1);
      expect(sep.first.id, 'b-1');

      final oct = await repo.getBudgets(year: 2026, month: 10);
      expect(oct.length, 1);
      expect(oct.first.id, 'b-2');
    });

    test('getBudgetById and getBudgetByCategory returns matching budget', () async {
      final b = MoneyBudget(
        id: 'b-search',
        categoryId: 'shopping',
        year: 2026,
        month: 9,
        amount: 5000,
      );
      await repo.addBudget(b);

      final byId = await repo.getBudgetById('b-search');
      expect(byId, isNotNull);
      expect(byId!.amount, 5000);

      final byCat = await repo.getBudgetByCategory(
        categoryId: 'shopping',
        year: 2026,
        month: 9,
      );
      expect(byCat, isNotNull);
      expect(byCat!.id, 'b-search');
    });

    test('updateBudget updates budget amount and preserves stability', () async {
      final b = MoneyBudget(
        id: 'b-update',
        categoryId: 'bills',
        year: 2026,
        month: 9,
        amount: 4000,
      );
      await repo.addBudget(b);

      final updated = b.copyWith(amount: 5500);
      await repo.updateBudget(updated);

      final retrieved = await repo.getBudgetById('b-update');
      expect(retrieved!.amount, 5500);
    });

    test('deleteBudget removes budget', () async {
      final b = MoneyBudget(
        id: 'b-del',
        categoryId: 'entertainment',
        year: 2026,
        month: 9,
        amount: 2500,
      );
      await repo.addBudget(b);

      expect(await repo.deleteBudget('b-del'), isTrue);
      expect(await repo.getBudgetById('b-del'), isNull);
      expect(await repo.deleteBudget('b-del'), isFalse);
    });

    test('deleteCategory is blocked when active budget exists for category', () async {
      const custom = MoneyCategory(
        id: 'custom-cat-budget',
        name: 'Gym Membership',
        type: TransactionType.expense,
      );
      await repo.addCategory(custom);

      final b = MoneyBudget(
        id: 'b-gym',
        categoryId: 'custom-cat-budget',
        year: 2026,
        month: 9,
        amount: 2000,
      );
      await repo.addBudget(b);

      expect(
        () => repo.deleteCategory('custom-cat-budget'),
        throwsA(isA<MoneyValidationException>().having(
          (e) => e.message,
          'message',
          contains('used by an existing budget and cannot be deleted'),
        )),
      );
    });
  });

  group('SharedPreferencesMoneyRepository Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initializes with default categories when preferences are empty (15 built-ins)', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPreferencesMoneyRepository(prefs);

      final categories = await repo.getCategories();
      expect(categories.length, 15);
      expect(categories.map((c) => c.id), containsAll([
        'food', 'transport', 'education', 'shopping', 'bills',
        'entertainment', 'health', 'work', 'home', 'other',
        'salary', 'freelance', 'business', 'gift', 'income_other',
      ]));
    });

    test('persists transactions and reloads intact on restart-style recreation', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo1 = SharedPreferencesMoneyRepository(prefs);

      final t1 = MoneyTransaction(
        id: 'p-1',
        type: TransactionType.income,
        amount: 4000.0,
        category: 'Work',
        note: 'Paycheck',
      );
      final t2 = MoneyTransaction(
        id: 'p-2',
        type: TransactionType.expense,
        amount: 150.0,
        category: 'Food',
      );

      await repo1.addTransaction(t1);
      await repo1.addTransaction(t2);

      // Simulate app restart by constructing a new repository from same prefs
      final repo2 = SharedPreferencesMoneyRepository(prefs);
      final loaded = await repo2.getTransactions();

      expect(loaded.length, 2);
      expect(loaded[0].id, 'p-1');
      expect(loaded[0].amount, 4000.0);
      expect(loaded[0].note, 'Paycheck');
      expect(loaded[1].id, 'p-2');
      expect(loaded[1].amount, 150.0);
    });

    test('persists custom categories and preserves them after reload', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo1 = SharedPreferencesMoneyRepository(prefs);

      const custom = MoneyCategory(
        id: 'pet-care',
        name: 'Pet Care',
        icon: 'pets',
        type: TransactionType.expense,
      );
      await repo1.addCategory(custom);

      // Simulate restart
      final repo2 = SharedPreferencesMoneyRepository(prefs);
      final categories = await repo2.getCategories();

      expect(categories.any((c) => c.id == 'pet-care' && c.name == 'Pet Care'), isTrue);
      // Ensure built-in categories remain intact as well
      expect(categories.any((c) => c.id == 'food'), isTrue);
      expect(categories.any((c) => c.id == 'salary'), isTrue);
    });

    test('handles completely corrupted JSON string defensively without crashing', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesMoneyRepository.transactionsKey: '{not-a-valid-json',
        SharedPreferencesMoneyRepository.categoriesKey: 'corrupted-categories-data',
      });

      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPreferencesMoneyRepository(prefs);

      final transactions = await repo.getTransactions();
      expect(transactions, isEmpty);

      final categories = await repo.getCategories();
      expect(categories.length, 15);
      expect(categories.every((c) => c.isBuiltIn), isTrue);
    });

    test('handles malformed individual transaction elements defensively', () async {
      final validJson = MoneyTransaction(
        id: 'valid-trans',
        type: TransactionType.expense,
        amount: 99.0,
        category: 'Shopping',
      ).toJson();

      final mixedList = [
        validJson,
        {'invalid_field': 'corrupted', 'amount': -10}, // Invalid amount
        'not a map', // Invalid type
        {'id': '', 'amount': 20.0, 'category': 'Food'}, // Empty ID
      ];

      SharedPreferences.setMockInitialValues({
        SharedPreferencesMoneyRepository.transactionsKey: jsonEncode(mixedList),
      });

      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPreferencesMoneyRepository(prefs);

      final transactions = await repo.getTransactions();
      expect(transactions.length, 1);
      expect(transactions.first.id, 'valid-trans');
      expect(transactions.first.amount, 99.0);
    });

    test('persists budgets and reloads intact on restart-style recreation', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo1 = SharedPreferencesMoneyRepository(prefs);

      final b1 = MoneyBudget(
        id: 'pref-b1',
        categoryId: 'food',
        year: 2026,
        month: 9,
        amount: 12000,
      );
      final b2 = MoneyBudget(
        id: 'pref-b2',
        categoryId: 'transport',
        year: 2026,
        month: 9,
        amount: 4000,
      );

      await repo1.addBudget(b1);
      await repo1.addBudget(b2);

      // Verify written to preferences with isolated key
      final rawBudgets = prefs.getString(SharedPreferencesMoneyRepository.budgetsKey);
      expect(rawBudgets, isNotNull);
      expect(rawBudgets, contains('pref-b1'));
      expect(rawBudgets, contains('pref-b2'));

      // Simulate restart
      final repo2 = SharedPreferencesMoneyRepository(prefs);
      final reloaded = await repo2.getBudgets(year: 2026, month: 9);

      expect(reloaded.length, 2);
      expect(reloaded.any((b) => b.id == 'pref-b1' && b.amount == 12000), isTrue);
      expect(reloaded.any((b) => b.id == 'pref-b2' && b.amount == 4000), isTrue);
    });

    test('handles corrupted budget JSON defensively', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesMoneyRepository.budgetsKey: 'not-valid-json{{{',
      });

      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPreferencesMoneyRepository(prefs);

      final budgets = await repo.getBudgets();
      expect(budgets, isEmpty);
    });

    test('storage keys are strictly isolated from Activity keys', () {
      expect(
        SharedPreferencesMoneyRepository.transactionsKey,
        'money_transactions_key',
      );
      expect(
        SharedPreferencesMoneyRepository.categoriesKey,
        'money_categories_key',
      );
      expect(
        SharedPreferencesMoneyRepository.budgetsKey,
        'money_budgets_key',
      );
      expect(
        SharedPreferencesMoneyRepository.budgetsKey,
        isNot(contains('routine')),
      );
      expect(
        SharedPreferencesMoneyRepository.budgetsKey,
        isNot(contains('activity')),
      );
    });
  });
}
