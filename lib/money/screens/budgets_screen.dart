import 'package:flutter/material.dart';
import '../models/money_budget.dart';
import '../models/money_category.dart';
import '../models/money_transaction.dart';
import '../models/transaction_type.dart';
import '../repositories/money_repository.dart';
import '../services/money_calculator.dart';
import '../theme/money_theme.dart';
import '../utils/money_formatter.dart';
import '../validation/money_validator.dart';

/// Screen for managing monthly category expense budgets in Money V2.
class BudgetsScreen extends StatefulWidget {
  final MoneyRepository repository;
  final DateTime? initialMonth;

  const BudgetsScreen({
    super.key,
    required this.repository,
    this.initialMonth,
  });

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late DateTime _selectedMonth;
  List<MoneyBudget> _budgets = [];
  List<MoneyTransaction> _transactions = [];
  List<MoneyCategory> _categories = [];
  bool _isLoading = true;

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMonth ?? DateTime.now();
    _selectedMonth = DateTime(initial.year, initial.month, 1);
    _loadData();
  }

  @override
  void didUpdateWidget(covariant BudgetsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMonth != null && widget.initialMonth != oldWidget.initialMonth) {
      _selectedMonth = DateTime(widget.initialMonth!.year, widget.initialMonth!.month, 1);
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final budgetsFuture = widget.repository.getBudgets(
      year: _selectedMonth.year,
      month: _selectedMonth.month,
    );
    final transactionsFuture = widget.repository.getTransactions();
    final categoriesFuture = widget.repository.getCategories();

    final results = await Future.wait([
      budgetsFuture,
      transactionsFuture,
      categoriesFuture,
    ]);

    if (!mounted) return;
    setState(() {
      _budgets = results[0] as List<MoneyBudget>;
      _transactions = results[1] as List<MoneyTransaction>;
      _categories = results[2] as List<MoneyCategory>;
      _isLoading = false;
    });
  }

  void _prevMonth() {
    setState(() {
      if (_selectedMonth.month == 1) {
        _selectedMonth = DateTime(_selectedMonth.year - 1, 12, 1);
      } else {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
      }
      _isLoading = true;
    });
    _loadData();
  }

  void _nextMonth() {
    setState(() {
      if (_selectedMonth.month == 12) {
        _selectedMonth = DateTime(_selectedMonth.year + 1, 1, 1);
      } else {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
      }
      _isLoading = true;
    });
    _loadData();
  }

  String _getMonthName(int month) => _monthNames[month - 1];

  MoneyCategory? _resolveCategory(String categoryId) {
    final norm = categoryId.trim().toLowerCase();
    return _categories.cast<MoneyCategory?>().firstWhere(
      (c) => c?.id == categoryId || c?.name.trim().toLowerCase() == norm,
      orElse: () => null,
    );
  }

  double _getCategorySpent(MoneyBudget budget) {
    final cat = _resolveCategory(budget.categoryId);
    return MoneyCalculator.spentForCategoryInMonth(
      _transactions,
      categoryId: budget.categoryId,
      categoryName: cat?.name,
      year: _selectedMonth.year,
      month: _selectedMonth.month,
    );
  }

  double get _totalBudget =>
      MoneyCalculator.totalBudgetForMonth(_budgets, year: _selectedMonth.year, month: _selectedMonth.month);

  double get _totalSpent {
    double sum = 0.0;
    for (final b in _budgets) {
      sum += _getCategorySpent(b);
    }
    return sum;
  }

  double get _totalRemaining => MoneyCalculator.budgetRemaining(limit: _totalBudget, spent: _totalSpent);

  Future<void> _openAddBudgetSheet() async {
    final colors = MoneyTheme.of(context);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final expenseCategories = _categories.where((c) => c.type == TransactionType.expense).toList();

    // Determine available categories that don't already have a budget this month
    final availableCategories = expenseCategories.where((c) {
      final normName = c.name.trim().toLowerCase();
      return !_budgets.any((b) =>
          b.categoryId == c.id ||
          b.categoryId.trim().toLowerCase() == normName);
    }).toList();

    String? selectedCategoryId = availableCategories.isNotEmpty ? availableCategories.first.id : null;
    final amountController = TextEditingController();
    String? errorMessage;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Budget',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (availableCategories.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.divider),
                        ),
                        child: Text(
                          'All expense categories have a budget set for this month.',
                          style: TextStyle(color: colors.textSecondary, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      // Category Dropdown
                      Text(
                        'Category',
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
                          border: Border.all(color: colors.divider),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            key: const Key('budget_category_dropdown'),
                            value: selectedCategoryId,
                            isExpanded: true,
                            dropdownColor: colors.card,
                            icon: Icon(Icons.arrow_drop_down_rounded, color: colors.textPrimary),
                            items: availableCategories.map((c) {
                              return DropdownMenuItem<String>(
                                value: c.id,
                                child: Row(
                                  children: [
                                    Icon(
                                      MoneyFormatter.getCategoryIcon(c.name, c.icon),
                                      size: 20,
                                      color: colors.primaryAccent,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      c.name,
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setModalState(() {
                                selectedCategoryId = val;
                                errorMessage = null;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Limit Amount Field
                      Text(
                        'Monthly Limit Amount',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('budget_amount_field'),
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5)),
                          prefixText: '${MoneyFormatter.rupeeSymbol} ',
                          prefixStyle: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          filled: true,
                          fillColor: colors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.primaryAccent, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onChanged: (_) {
                          if (errorMessage != null) {
                            setModalState(() => errorMessage = null);
                          }
                        },
                      ),
                      const SizedBox(height: 8),

                      if (errorMessage != null) ...[
                        Text(
                          errorMessage!,
                          style: TextStyle(
                            color: colors.expense,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 16),

                      // Save Button
                      ElevatedButton(
                        key: const Key('save_budget_button'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryAccent,
                          foregroundColor: colors.background,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (selectedCategoryId == null) {
                            setModalState(() => errorMessage = 'Please select a category');
                            return;
                          }
                          final parsedAmount = double.tryParse(amountController.text.trim());
                          if (parsedAmount == null || parsedAmount <= 0) {
                            setModalState(() => errorMessage = 'Amount must be greater than 0');
                            return;
                          }

                          try {
                            final budget = MoneyBudget(
                              categoryId: selectedCategoryId!,
                              year: _selectedMonth.year,
                              month: _selectedMonth.month,
                              amount: parsedAmount,
                            );

                            await widget.repository.addBudget(budget);
                            if (!mounted) return;
                            nav.pop();
                            _loadData();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Budget added successfully'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } catch (e) {
                            setModalState(() {
                              errorMessage = e is MoneyValidationException ? e.message : e.toString();
                            });
                          }
                        },
                        child: const Text(
                          'Save Budget',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openEditBudgetSheet(MoneyBudget budget) async {
    final colors = MoneyTheme.of(context);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cat = _resolveCategory(budget.categoryId);
    final categoryName = cat?.name ?? budget.categoryId;
    final categoryIcon = MoneyFormatter.getCategoryIcon(categoryName, cat?.icon);

    final amountText = budget.amount.truncateToDouble() == budget.amount
        ? budget.amount.toInt().toString()
        : budget.amount.toStringAsFixed(2);
    final amountController = TextEditingController(text: amountText);
    String? errorMessage;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Budget',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.divider),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.primaryAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              categoryIcon,
                              size: 20,
                              color: colors.primaryAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              categoryName,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Limit Amount Field
                    Text(
                      'Monthly Limit Amount',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('budget_amount_field'),
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: '${MoneyFormatter.rupeeSymbol} ',
                        prefixStyle: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        filled: true,
                        fillColor: colors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.primaryAccent, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (_) {
                        if (errorMessage != null) {
                          setModalState(() => errorMessage = null);
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    if (errorMessage != null) ...[
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: colors.expense,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 20),

                    // Actions: Save Changes & Delete
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('delete_budget_button'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.expense,
                              side: BorderSide(color: colors.expense.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded, size: 20),
                            label: const Text(
                              'Delete',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            onPressed: () => _confirmDeleteBudget(sheetContext, budget, categoryName),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            key: const Key('save_budget_changes_button'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primaryAccent,
                              foregroundColor: colors.background,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final parsedAmount = double.tryParse(amountController.text.trim());
                              if (parsedAmount == null || parsedAmount <= 0) {
                                setModalState(() => errorMessage = 'Amount must be greater than 0');
                                return;
                              }

                              try {
                                final updated = budget.copyWith(
                                  amount: parsedAmount,
                                  updatedAt: DateTime.now(),
                                );
                                await widget.repository.updateBudget(updated);
                                if (!mounted) return;
                                nav.pop();
                                _loadData();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Budget updated successfully'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } catch (e) {
                                setModalState(() {
                                  errorMessage = e is MoneyValidationException ? e.message : e.toString();
                                });
                              }
                            },
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteBudget(
    BuildContext sheetContext,
    MoneyBudget budget,
    String categoryName,
  ) async {
    final colors = MoneyTheme.of(context);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Budget?',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete the budget for "$categoryName" in ${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}?',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            key: const Key('confirm_delete_budget_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.expense,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.repository.deleteBudget(budget.id);
      if (!mounted) return;
      nav.pop();
      _loadData();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Budget deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Color _getProgressColor(double progress, MoneyColors colors) {
    if (progress >= 1.0) {
      return colors.expense;
    } else if (progress >= 0.8) {
      return colors.warning;
    } else {
      return colors.primaryAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = MoneyTheme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Budgets',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_budget_fab'),
        onPressed: _openAddBudgetSheet,
        backgroundColor: colors.primaryAccent,
        foregroundColor: colors.background,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Budget',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Month Selector Header
          _buildMonthHeader(colors),

          // Content Area
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colors.primaryAccent))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: colors.primaryAccent,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 88),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Monthly Overview Summary
                          _buildOverviewCard(colors),
                          const SizedBox(height: 20),

                          // 2. Category Budget Cards or Empty State
                          if (_budgets.isEmpty)
                            _buildEmptyState(colors)
                          else
                            ..._budgets.map((b) => _buildCategoryBudgetCard(b, colors)),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(MoneyColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            key: const Key('budget_prev_month'),
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: colors.textPrimary,
            tooltip: 'Previous Month',
            onPressed: _prevMonth,
          ),
          Text(
            '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
            key: const Key('budget_month_title'),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            key: const Key('budget_next_month'),
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
            color: colors.textPrimary,
            tooltip: 'Next Month',
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(MoneyColors colors) {
    final isOverBudget = _totalSpent > _totalBudget && _totalBudget > 0;
    final progress = _totalBudget > 0 ? (_totalSpent / _totalBudget) : 0.0;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final percentage = _totalBudget > 0 ? (progress * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverBudget
              ? colors.expense.withValues(alpha: 0.5)
              : colors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row with title & status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Overview',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_budgets.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOverBudget
                        ? colors.expense.withValues(alpha: 0.15)
                        : colors.income.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOverBudget ? 'Over Budget' : 'On Track',
                    style: TextStyle(
                      color: isOverBudget ? colors.expense : colors.income,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Numbers Grid: Total Budget | Total Spent | Total Remaining
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Budget',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      MoneyFormatter.format(_totalBudget),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: colors.divider),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Spent',
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        MoneyFormatter.format(_totalSpent),
                        style: TextStyle(
                          color: isOverBudget ? colors.expense : colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(width: 1, height: 36, color: colors.divider),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remaining',
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        MoneyFormatter.format(_totalRemaining),
                        style: TextStyle(
                          color: _totalRemaining < 0
                              ? colors.expense
                              : colors.income,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_budgets.isNotEmpty) ...[
            const SizedBox(height: 16),
            // Overall Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: clampedProgress,
                backgroundColor: colors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(progress, colors)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_budgets.length} ${_budgets.length == 1 ? 'category' : 'categories'} budgeted',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
                Text(
                  '$percentage% used',
                  style: TextStyle(
                    color: _getProgressColor(progress, colors),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetCard(MoneyBudget budget, MoneyColors colors) {
    final cat = _resolveCategory(budget.categoryId);
    final categoryName = cat?.name ?? budget.categoryId;
    final categoryIcon = MoneyFormatter.getCategoryIcon(categoryName, cat?.icon);

    final spent = _getCategorySpent(budget);
    final remaining = MoneyCalculator.budgetRemaining(limit: budget.amount, spent: spent);
    final progress = MoneyCalculator.budgetProgress(limit: budget.amount, spent: spent);
    final clampedProgress = progress.clamp(0.0, 1.0);
    final percentage = (progress * 100).round();
    final isExceeded = remaining < 0;
    final progressColor = _getProgressColor(progress, colors);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExceeded
              ? colors.expense.withValues(alpha: 0.4)
              : colors.divider,
        ),
      ),
      child: InkWell(
        key: Key('budget_card_${budget.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openEditBudgetSheet(budget),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Row: Icon + Category Name + Percentage Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      categoryIcon,
                      size: 22,
                      color: progressColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Budget: ${MoneyFormatter.format(budget.amount)}',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$percentage%',
                      style: TextStyle(
                        color: progressColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: clampedProgress,
                  backgroundColor: colors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 10),

              // Bottom Info: Spent & Remaining
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spent: ${MoneyFormatter.format(spent)}',
                    style: TextStyle(
                      color: isExceeded ? colors.expense : colors.textSecondary,
                      fontSize: 13,
                      fontWeight: isExceeded ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    isExceeded
                        ? 'Over budget by: ${MoneyFormatter.format(spent - budget.amount)}'
                        : 'Remaining: ${MoneyFormatter.format(remaining)}',
                    style: TextStyle(
                      color: isExceeded ? colors.expense : colors.income,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(MoneyColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.primaryAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: colors.primaryAccent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No budgets set for this month',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Plan your monthly spending by setting category limits',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            key: const Key('empty_add_budget_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryAccent,
              foregroundColor: colors.background,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Set First Budget',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            onPressed: _openAddBudgetSheet,
          ),
        ],
      ),
    );
  }
}
