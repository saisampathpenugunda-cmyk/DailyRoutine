import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/money/models/money_budget.dart';
import 'package:daily_routine/money/models/money_category.dart';
import 'package:daily_routine/money/models/money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/repositories/in_memory_money_repository.dart';
import 'package:daily_routine/money/screens/categories_screen.dart';

void main() {
  group('CategoriesScreen Widget Tests', () {
    late InMemoryMoneyRepository repo;

    setUp(() {
      repo = InMemoryMoneyRepository();
    });

    Widget createScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      return MaterialApp(
        home: CategoriesScreen(repository: repo),
      );
    }

    testWidgets('renders screen with header, tabs, and 10 built-in expense categories by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen(tester));
      await tester.pumpAndSettle();

      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Your Categories'), findsOneWidget);
      expect(find.text('10'), findsOneWidget); // 10 built-in expenses

      // Built-ins exist
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Shopping'), findsOneWidget);
      expect(find.text('Built-in'), findsWidgets);

      // Income categories not visible in Expenses tab
      expect(find.text('Salary'), findsNothing);
      expect(find.text('Freelance'), findsNothing);
    });

    testWidgets('switching to Income tab displays 5 built-in income categories', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen(tester));
      await tester.pumpAndSettle();

      // Tap Income tab
      await tester.tap(find.byKey(const Key('categories_tab_income')));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget); // 5 built-in income categories
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('Freelance'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
      expect(find.text('Gift'), findsOneWidget);

      // Expense categories hidden
      expect(find.text('Food'), findsNothing);
      expect(find.text('Transport'), findsNothing);
    });

    testWidgets('built-in categories do not render edit or delete buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen(tester));
      await tester.pumpAndSettle();

      // Food is built-in
      expect(find.byKey(const Key('edit_category_food')), findsNothing);
      expect(find.byKey(const Key('delete_category_food')), findsNothing);
    });

    testWidgets('adds a new custom expense category with icon picker', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen(tester));
      await tester.pumpAndSettle();

      // Tap + Add Category FAB
      await tester.tap(find.byKey(const Key('add_category_fab')));
      await tester.pumpAndSettle();

      expect(find.text('Add Expense Category'), findsOneWidget);
      expect(find.text('Type: Expense'), findsOneWidget);

      // Try empty name
      await tester.tap(find.byKey(const Key('save_category_button')));
      await tester.pumpAndSettle();
      expect(find.text('Category name cannot be empty'), findsOneWidget);

      // Try duplicate name within same type
      await tester.enterText(find.byKey(const Key('add_category_name_field')), 'Food');
      await tester.tap(find.byKey(const Key('save_category_button')));
      await tester.pumpAndSettle();
      expect(find.text('A category with the name "Food" already exists'), findsOneWidget);

      // Enter valid name and select icon (first row icon: directions_car)
      await tester.enterText(find.byKey(const Key('add_category_name_field')), 'Coffee & Snacks');
      await tester.tap(find.byKey(const Key('category_icon_option_directions_car')));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.byKey(const Key('save_category_button')));
      await tester.pumpAndSettle();

      // Modal closed and category appears in list
      expect(find.text('Add Expense Category'), findsNothing);
      expect(find.text('Coffee & Snacks'), findsOneWidget);

      // Custom category has edit and delete buttons
      final categories = await repo.getCategories(type: TransactionType.expense);
      final custom = categories.firstWhere((c) => c.name == 'Coffee & Snacks');
      expect(custom.isBuiltIn, isFalse);
      expect(custom.icon, 'directions_car');
      expect(find.byKey(Key('edit_category_${custom.id}')), findsOneWidget);
      expect(find.byKey(Key('delete_category_${custom.id}')), findsOneWidget);
    });

    testWidgets('adds a custom income category when Income tab is active', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen(tester));
      await tester.pumpAndSettle();

      // Switch to Income
      await tester.tap(find.byKey(const Key('categories_tab_income')));
      await tester.pumpAndSettle();

      // Tap + Add Category FAB
      await tester.tap(find.byKey(const Key('add_category_fab')));
      await tester.pumpAndSettle();

      expect(find.text('Add Income Category'), findsOneWidget);
      expect(find.text('Type: Income'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('add_category_name_field')), 'Investments');
      await tester.tap(find.byKey(const Key('save_category_button')));
      await tester.pumpAndSettle();

      expect(find.text('Investments'), findsOneWidget);
      final incomeCats = await repo.getCategories(type: TransactionType.income);
      expect(incomeCats.any((c) => c.name == 'Investments'), isTrue);
    });

    testWidgets('allows same category name across different types', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen(tester));
      await tester.pumpAndSettle();

      // Add "Consulting" under Expense
      await tester.tap(find.byKey(const Key('add_category_fab')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('add_category_name_field')), 'Consulting');
      await tester.tap(find.byKey(const Key('save_category_button')));
      await tester.pumpAndSettle();
      expect(find.text('Consulting'), findsOneWidget);

      // Switch to Income tab
      await tester.tap(find.byKey(const Key('categories_tab_income')));
      await tester.pumpAndSettle();

      // Add "Consulting" under Income as well
      await tester.tap(find.byKey(const Key('add_category_fab')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('add_category_name_field')), 'Consulting');
      await tester.tap(find.byKey(const Key('save_category_button')));
      await tester.pumpAndSettle();
      expect(find.text('Consulting'), findsOneWidget);

      final expenses = await repo.getCategories(type: TransactionType.expense);
      final incomes = await repo.getCategories(type: TransactionType.income);
      expect(expenses.any((c) => c.name == 'Consulting'), isTrue);
      expect(incomes.any((c) => c.name == 'Consulting'), isTrue);
    });

    testWidgets('edits an existing custom category', (
      WidgetTester tester,
    ) async {
      await repo.addCategory(
        const MoneyCategory(
          id: 'custom-gym-id',
          name: 'Gym',
          type: TransactionType.expense,
          isBuiltIn: false,
          icon: 'fitness_center',
        ),
      );

      await tester.pumpWidget(createScreen(tester));
      await tester.pumpAndSettle();

      expect(find.text('Gym'), findsOneWidget);
      final editBtn = find.byKey(const Key('edit_category_custom-gym-id'));
      expect(editBtn, findsOneWidget);

      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(find.text('Edit Category'), findsOneWidget);
      expect(find.text('Type: Expense (Cannot change)'), findsOneWidget);
      expect(find.byKey(const Key('edit_category_name_field')), findsOneWidget);

      // Rename to Fitness Club
      await tester.enterText(find.byKey(const Key('edit_category_name_field')), 'Fitness Club');
      await tester.tap(find.byKey(const Key('save_category_button')));
      await tester.pumpAndSettle();

      expect(find.text('Fitness Club'), findsOneWidget);
      expect(find.text('Gym'), findsNothing);

      final updated = await repo.getCategories();
      expect(updated.any((c) => c.id == 'custom-gym-id' && c.name == 'Fitness Club'), isTrue);
    });

    testWidgets('blocks deletion when custom category is used by existing transactions', (
      WidgetTester tester,
    ) async {
      await repo.addCategory(
        const MoneyCategory(
          id: 'custom-sub-id',
          name: 'Subscriptions',
          type: TransactionType.expense,
          isBuiltIn: false,
        ),
      );
      await repo.addTransaction(
        MoneyTransaction(
          id: 't-netflix',
          type: TransactionType.expense,
          amount: 649.0,
          category: 'Subscriptions',
        ),
      );

      await tester.pumpWidget(createScreen(tester));
      await tester.pumpAndSettle();

      expect(find.text('Subscriptions'), findsOneWidget);
      final deleteBtn = find.byKey(const Key('delete_category_custom-sub-id'));
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Blocked dialog shown
      expect(find.text('Cannot Delete Category'), findsOneWidget);
      expect(
        find.text('This category is used by existing transactions and cannot be deleted.'),
        findsOneWidget,
      );

      // Tap OK
      await tester.tap(find.byKey(const Key('dialog_ok_button')));
      await tester.pumpAndSettle();

      // Category remains
      expect(find.text('Subscriptions'), findsOneWidget);
      final categories = await repo.getCategories();
      expect(categories.any((c) => c.id == 'custom-sub-id'), isTrue);
    });

    testWidgets('blocks deletion when custom category is used by active budgets', (
      WidgetTester tester,
    ) async {
      await repo.addCategory(
        const MoneyCategory(
          id: 'custom-dining-id',
          name: 'Fine Dining',
          type: TransactionType.expense,
          isBuiltIn: false,
        ),
      );
      await repo.addBudget(
        MoneyBudget(
          id: 'b-dining-2026-09',
          categoryId: 'custom-dining-id',
          amount: 5000.0,
          year: 2026,
          month: 9,
        ),
      );

      await tester.pumpWidget(createScreen(tester));
      await tester.pumpAndSettle();

      expect(find.text('Fine Dining'), findsOneWidget);
      final deleteBtn = find.byKey(const Key('delete_category_custom-dining-id'));
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Blocked dialog shown with clear explanation
      expect(find.text('Cannot Delete Category'), findsOneWidget);
      expect(
        find.text('This category is used by active budgets and cannot be deleted.'),
        findsOneWidget,
      );

      // Tap OK
      await tester.tap(find.byKey(const Key('dialog_ok_button')));
      await tester.pumpAndSettle();

      // Category remains
      expect(find.text('Fine Dining'), findsOneWidget);
      final categories = await repo.getCategories();
      expect(categories.any((c) => c.id == 'custom-dining-id'), isTrue);
    });

    testWidgets('confirms and successfully deletes unused custom category', (
      WidgetTester tester,
    ) async {
      await repo.addCategory(
        const MoneyCategory(
          id: 'custom-unused-id',
          name: 'Old Hobby',
          type: TransactionType.expense,
          isBuiltIn: false,
        ),
      );

      await tester.pumpWidget(createScreen(tester));
      await tester.pumpAndSettle();

      expect(find.text('Old Hobby'), findsOneWidget);
      final deleteBtn = find.byKey(const Key('delete_category_custom-unused-id'));
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog shown
      expect(find.text('Delete Category'), findsOneWidget);
      expect(find.text('Are you sure you want to delete "Old Hobby"?'), findsOneWidget);

      // Cancel first
      await tester.tap(find.byKey(const Key('cancel_delete_category_button')));
      await tester.pumpAndSettle();
      expect(find.text('Old Hobby'), findsOneWidget);

      // Tap delete again and confirm
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_delete_category_button')));
      await tester.pumpAndSettle();

      // Successfully removed
      expect(find.text('Old Hobby'), findsNothing);
      final categories = await repo.getCategories();
      expect(categories.any((c) => c.id == 'custom-unused-id'), isFalse);
    });
  });
}
