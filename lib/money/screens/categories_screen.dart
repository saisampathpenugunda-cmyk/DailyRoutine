import 'package:flutter/material.dart';
import '../models/money_category.dart';
import '../models/transaction_type.dart';
import '../repositories/money_repository.dart';
import '../theme/money_theme.dart';
import '../utils/money_formatter.dart';
import '../validation/money_validator.dart';

/// Dedicated screen for managing Money V2 categories.
/// Supports switching between Expense and Income categories, creating custom
/// categories with icon selection, editing, and transaction-safe deletion.
class CategoriesScreen extends StatefulWidget {
  final MoneyRepository repository;

  const CategoriesScreen({
    super.key,
    required this.repository,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  TransactionType _selectedType = TransactionType.expense;
  List<MoneyCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final loaded = await widget.repository.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = loaded;
      _isLoading = false;
    });
  }

  List<MoneyCategory> get _filteredCategories {
    return _categories.where((c) => c.type == _selectedType).toList();
  }

  Future<void> _openAddCategoryModal() async {
    final colors = MoneyTheme.of(context);
    final nameController = TextEditingController();
    String selectedIcon = _selectedType == TransactionType.expense
        ? 'restaurant'
        : 'payments';
    String? errorMessage;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final bottomInset = MediaQuery.of(modalCtx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: bottomInset + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add ${_selectedType == TransactionType.expense ? 'Expense' : 'Income'} Category',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                          onPressed: () => Navigator.of(sheetContext).pop(false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Type Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedType == TransactionType.expense
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            size: 16,
                            color: _selectedType == TransactionType.expense
                                ? colors.expense
                                : colors.income,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Type: ${_selectedType == TransactionType.expense ? 'Expense' : 'Income'}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Name Input
                    Text(
                      'Category Name',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: TextField(
                        key: const Key('add_category_name_field'),
                        controller: nameController,
                        autofocus: true,
                        style: TextStyle(color: colors.textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'e.g. Groceries, Gym, Dividends',
                          hintStyle: TextStyle(
                            color: colors.textSecondary.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Icon Selection Grid
                    Text(
                      'Select Icon',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 180,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: GridView.builder(
                        itemCount: MoneyFormatter.selectableIcons.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemBuilder: (context, index) {
                          final entry = MoneyFormatter.selectableIcons.entries.elementAt(index);
                          final isSelected = selectedIcon == entry.key;
                          return InkWell(
                            key: Key('category_icon_option_${entry.key}'),
                            onTap: () {
                              setModalState(() {
                                selectedIcon = entry.key;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.primaryAccent.withValues(alpha: 0.2)
                                    : colors.card,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? colors.primaryAccent
                                      : colors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Icon(
                                entry.value,
                                color: isSelected
                                    ? colors.primaryAccent
                                    : colors.textPrimary,
                                size: 22,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.error.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: colors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(color: colors.error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Save Button
                    FilledButton(
                      key: const Key('save_category_button'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final trimmed = nameController.text.trim();
                        if (trimmed.isEmpty) {
                          setModalState(() {
                            errorMessage = 'Category name cannot be empty';
                          });
                          return;
                        }

                        final id = 'cat_${DateTime.now().millisecondsSinceEpoch}';
                        final newCategory = MoneyCategory(
                          id: id,
                          name: trimmed,
                          isBuiltIn: false,
                          icon: selectedIcon,
                          type: _selectedType,
                        );

                        try {
                          await widget.repository.addCategory(newCategory);
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop(true);
                          }
                        } on MoneyValidationException catch (e) {
                          setModalState(() {
                            errorMessage = e.message;
                          });
                        } catch (e) {
                          setModalState(() {
                            errorMessage = 'Failed to create category: $e';
                          });
                        }
                      },
                      child: const Text(
                        'Save Category',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    await _loadCategories();
  }

  Future<void> _openEditCategoryModal(MoneyCategory category) async {
    final colors = MoneyTheme.of(context);
    final nameController = TextEditingController(text: category.name);
    String selectedIcon = category.icon ??
        (category.type == TransactionType.expense ? 'restaurant' : 'payments');
    String? errorMessage;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final bottomInset = MediaQuery.of(modalCtx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: bottomInset + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Category',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                          onPressed: () => Navigator.of(sheetContext).pop(false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Locked Type Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            category.type == TransactionType.expense
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            size: 16,
                            color: category.type == TransactionType.expense
                                ? colors.expense
                                : colors.income,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Type: ${category.type == TransactionType.expense ? 'Expense' : 'Income'} (Cannot change)',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name Input
                    Text(
                      'Category Name',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: TextField(
                        key: const Key('edit_category_name_field'),
                        controller: nameController,
                        style: TextStyle(color: colors.textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Category name',
                          hintStyle: TextStyle(
                            color: colors.textSecondary.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Icon Picker Grid
                    Text(
                      'Select Icon',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 180,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: GridView.builder(
                        itemCount: MoneyFormatter.selectableIcons.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemBuilder: (context, index) {
                          final entry = MoneyFormatter.selectableIcons.entries.elementAt(index);
                          final isSelected = selectedIcon == entry.key;
                          return InkWell(
                            key: Key('category_icon_option_${entry.key}'),
                            onTap: () {
                              setModalState(() {
                                selectedIcon = entry.key;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.primaryAccent.withValues(alpha: 0.2)
                                    : colors.card,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? colors.primaryAccent
                                      : colors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Icon(
                                entry.value,
                                color: isSelected
                                    ? colors.primaryAccent
                                    : colors.textPrimary,
                                size: 22,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.error.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: colors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(color: colors.error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Save Button
                    FilledButton(
                      key: const Key('save_category_button'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final trimmed = nameController.text.trim();
                        if (trimmed.isEmpty) {
                          setModalState(() {
                            errorMessage = 'Category name cannot be empty';
                          });
                          return;
                        }

                        final updated = category.copyWith(
                          name: trimmed,
                          icon: selectedIcon,
                        );

                        try {
                          await widget.repository.updateCategory(updated);
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop(true);
                          }
                        } on MoneyValidationException catch (e) {
                          setModalState(() {
                            errorMessage = e.message;
                          });
                        } catch (e) {
                          setModalState(() {
                            errorMessage = 'Failed to update category: $e';
                          });
                        }
                      },
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    await _loadCategories();
  }

  Future<void> _handleDeleteCategory(MoneyCategory category) async {
    final colors = MoneyTheme.of(context);

    // 1. Check if category is used by any transactions
    final transactions = await widget.repository.getTransactions();
    final isUsedInTransactions = transactions.any((t) =>
        t.category.trim().toLowerCase() == category.name.trim().toLowerCase() ||
        t.category.trim().toLowerCase() == category.id.trim().toLowerCase());

    // 2. Check if category is used by any active budgets
    final budgets = await widget.repository.getBudgets();
    final isUsedInBudgets = budgets.any((b) =>
        b.categoryId == category.id ||
        b.categoryId.trim().toLowerCase() == category.name.trim().toLowerCase());

    // 3. Check if category is used by any recurring rules
    final recurringRules = await widget.repository.getRecurringTransactions();
    final isUsedInRecurring = recurringRules.any((r) =>
        r.categoryId == category.id ||
        r.categoryId.trim().toLowerCase() == category.name.trim().toLowerCase());

    if (!mounted) return;

    if (isUsedInTransactions) {
      // Show blocked dialog for transactions
      await showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border),
          ),
          title: Text(
            'Cannot Delete Category',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This category is used by existing transactions and cannot be deleted.',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          actions: [
            FilledButton(
              key: const Key('dialog_ok_button'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (isUsedInBudgets) {
      // Show blocked dialog for active budgets
      await showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border),
          ),
          title: Text(
            'Cannot Delete Category',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This category is used by active budgets and cannot be deleted.',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          actions: [
            FilledButton(
              key: const Key('dialog_ok_button'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (isUsedInRecurring) {
      // Show blocked dialog for recurring rules
      await showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border),
          ),
          title: Text(
            'Cannot Delete Category',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This category is used by recurring transaction rules and cannot be deleted.',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          actions: [
            FilledButton(
              key: const Key('dialog_ok_button'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // 4. Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        title: Text(
          'Delete Category',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"?',
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            key: const Key('cancel_delete_category_button'),
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            key: const Key('confirm_delete_category_button'),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: colors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await widget.repository.deleteCategory(category.id);
        await _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Category "${category.name}" deleted'),
              backgroundColor: colors.surface,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: colors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = MoneyTheme.of(context);
    final displayedCategories = _filteredCategories;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          key: const Key('categories_back_button'),
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Categories',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_category_fab'),
        backgroundColor: colors.primaryAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Category',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: _openAddCategoryModal,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.primaryAccent))
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Expense / Income Segmented Control
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTypeTab(
                              key: const Key('categories_tab_expense'),
                              type: TransactionType.expense,
                              label: 'Expenses',
                              icon: Icons.arrow_downward,
                              activeColor: colors.expense,
                              colors: colors,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildTypeTab(
                              key: const Key('categories_tab_income'),
                              type: TransactionType.income,
                              label: 'Income',
                              icon: Icons.arrow_upward,
                              activeColor: colors.income,
                              colors: colors,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Section Header: "Your Categories" + Count Badge
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Categories',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.border),
                          ),
                          child: Text(
                            '${displayedCategories.length}',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Category List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                      itemCount: displayedCategories.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final cat = displayedCategories[index];
                        return _buildCategoryTile(cat, colors);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTypeTab({
    required Key key,
    required TransactionType type,
    required String label,
    required IconData icon,
    required Color activeColor,
    required MoneyColors colors,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      key: key,
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: activeColor, width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? activeColor : colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(MoneyCategory cat, MoneyColors colors) {
    final isExpense = cat.type == TransactionType.expense;
    final typeColor = isExpense ? colors.expense : colors.income;
    final iconData = MoneyFormatter.getCategoryIcon(cat.name, cat.icon);

    return Container(
      key: Key('category_tile_${cat.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              color: typeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              cat.name,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          if (cat.isBuiltIn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                'Built-in',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else ...[
            IconButton(
              key: Key('edit_category_${cat.id}'),
              icon: Icon(Icons.edit_outlined, size: 20, color: colors.primaryAccent),
              tooltip: 'Edit Category',
              onPressed: () => _openEditCategoryModal(cat),
            ),
            IconButton(
              key: Key('delete_category_${cat.id}'),
              icon: Icon(Icons.delete_outline, size: 20, color: colors.error),
              tooltip: 'Delete Category',
              onPressed: () => _handleDeleteCategory(cat),
            ),
          ],
        ],
      ),
    );
  }
}
