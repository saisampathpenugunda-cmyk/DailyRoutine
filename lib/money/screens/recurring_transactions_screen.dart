import 'package:flutter/material.dart';
import '../models/money_category.dart';
import '../models/money_transaction.dart';
import '../models/recurring_money_transaction.dart';
import '../models/transaction_type.dart';
import '../repositories/money_repository.dart';
import '../services/recurring_transaction_service.dart';
import '../theme/money_theme.dart';
import '../utils/money_formatter.dart';
import '../validation/money_validator.dart';

/// Screen for managing recurring transaction rules in Money V2.
///
/// Supports listing recurring transactions, viewing next occurrences,
/// adding, editing, pausing/resuming, and deleting recurring rules.
class RecurringTransactionsScreen extends StatefulWidget {
  final MoneyRepository repository;

  const RecurringTransactionsScreen({
    super.key,
    required this.repository,
  });

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  List<RecurringMoneyTransaction> _recurringRules = [];
  List<MoneyCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final rulesFuture = widget.repository.getRecurringTransactions();
    final categoriesFuture = widget.repository.getCategories();

    final results = await Future.wait([rulesFuture, categoriesFuture]);

    if (!mounted) return;

    final loadedRules = results[0] as List<RecurringMoneyTransaction>;
    final loadedCategories = results[1] as List<MoneyCategory>;

    final sortedRules = List<RecurringMoneyTransaction>.from(loadedRules)
      ..sort((a, b) {
        // Active rules first
        if (a.isActive != b.isActive) {
          return a.isActive ? -1 : 1;
        }
        // Then sort by next occurrence ascending
        return a.nextOccurrence.compareTo(b.nextOccurrence);
      });

    setState(() {
      _recurringRules = sortedRules;
      _categories = loadedCategories;
      _isLoading = false;
    });
  }

  Future<void> _toggleActive(RecurringMoneyTransaction rule) async {
    final updated = rule.copyWith(isActive: !rule.isActive);
    await widget.repository.updateRecurring(updated);

    if (updated.isActive) {
      // When resuming, evaluate due occurrences immediately
      await RecurringTransactionService.generateDueTransactions(
        widget.repository,
      );
    }

    await _loadData();
  }

  Future<void> _confirmDelete(RecurringMoneyTransaction rule) async {
    final colors = MoneyTheme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete recurring transaction?',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Existing transactions will remain unchanged.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.repository.deleteRecurring(rule.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recurring transaction deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openAddEditModal({RecurringMoneyTransaction? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _AddEditRecurringSheet(
        repository: widget.repository,
        categories: _categories,
        existing: existing,
      ),
    );

    if (result == true) {
      await RecurringTransactionService.generateDueTransactions(
        widget.repository,
      );
      await _loadData();
    }
  }

  MoneyCategory? _getCategory(String categoryId) {
    try {
      return _categories.firstWhere(
        (c) =>
            c.id == categoryId ||
            c.name.trim().toLowerCase() == categoryId.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final today = MoneyTransaction.localToday();
    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Today';
    }
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = MoneyTheme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Recurring Transactions',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          IconButton(
            key: const Key('appbar_add_recurring_button'),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Recurring',
            onPressed: () => _openAddEditModal(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_recurring_button'),
        onPressed: () => _openAddEditModal(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Recurring',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colors.primaryAccent,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: colors.primaryAccent),
            )
          : _recurringRules.isEmpty
              ? _buildEmptyState(colors)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: colors.primaryAccent,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _recurringRules.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final rule = _recurringRules[index];
                      return _buildRecurringCard(rule, colors);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(MoneyColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.primaryAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.repeat_rounded,
                size: 64,
                color: colors.primaryAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No recurring transactions',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Automate regular expenses and income like rent, bills, or salary.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: const Key('empty_add_recurring_button'),
              onPressed: () => _openAddEditModal(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Recurring'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringCard(RecurringMoneyTransaction rule, MoneyColors colors) {
    final cat = _getCategory(rule.categoryId);
    final categoryName = cat?.name ?? rule.categoryId;
    final categoryIcon =
        MoneyFormatter.getCategoryIcon(categoryName, cat?.icon);
    final isIncome = rule.type == TransactionType.income;
    final typeColor = isIncome ? colors.income : colors.expense;
    final sign = isIncome ? '+' : '-';

    return InkWell(
      key: Key('recurring_card_${rule.id}'),
      onTap: () => _openAddEditModal(existing: rule),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: rule.isActive ? colors.border : colors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Category icon, Category name & Amount
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(categoryIcon, size: 22, color: typeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: TextStyle(
                          color: rule.isActive
                              ? colors.textPrimary
                              : colors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (rule.note != null && rule.note!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          rule.note!,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '$sign${MoneyFormatter.format(rule.amount)}',
                  style: TextStyle(
                    color: rule.isActive
                        ? typeColor
                        : typeColor.withValues(alpha: 0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Row 2: Badges (Frequency, Next occurrence, Status) & Switch/Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    // Frequency Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        rule.frequency.displayName,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Next Occurrence Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.primaryAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Next: ${_formatDate(rule.nextOccurrence)}',
                        style: TextStyle(
                          color: colors.primaryAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Active / Paused Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: rule.isActive
                            ? colors.income.withValues(alpha: 0.12)
                            : colors.textSecondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rule.isActive ? 'Active' : 'Paused',
                        style: TextStyle(
                          color: rule.isActive ? colors.income : colors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pause / Resume switch
                    Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        key: Key('pause_switch_${rule.id}'),
                        value: rule.isActive,
                        activeThumbColor: colors.primaryAccent,
                        onChanged: (_) => _toggleActive(rule),
                      ),
                    ),
                    IconButton(
                      key: Key('edit_recurring_${rule.id}'),
                      icon: Icon(Icons.edit_outlined, size: 18, color: colors.textSecondary),
                      tooltip: 'Edit',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _openAddEditModal(existing: rule),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      key: Key('delete_recurring_${rule.id}'),
                      icon: Icon(Icons.delete_outline_rounded, size: 18, color: colors.expense),
                      tooltip: 'Delete',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _confirmDelete(rule),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal bottom sheet for adding or editing a [RecurringMoneyTransaction].
class _AddEditRecurringSheet extends StatefulWidget {
  final MoneyRepository repository;
  final List<MoneyCategory> categories;
  final RecurringMoneyTransaction? existing;

  const _AddEditRecurringSheet({
    required this.repository,
    required this.categories,
    this.existing,
  });

  @override
  State<_AddEditRecurringSheet> createState() => _AddEditRecurringSheetState();
}

class _AddEditRecurringSheetState extends State<_AddEditRecurringSheet> {
  late TransactionType _selectedType;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late RecurrenceFrequency _selectedFrequency;
  late DateTime _startDate;
  DateTime? _endDate;
  String? _selectedCategoryId;
  String? _errorMessage;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex != null) {
      _selectedType = ex.type;
      _amountController = TextEditingController(
        text: ex.amount.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), ''),
      );
      _noteController = TextEditingController(text: ex.note ?? '');
      _selectedFrequency = ex.frequency;
      _startDate = ex.startDate;
      _endDate = ex.endDate;
      _selectedCategoryId = ex.categoryId;
    } else {
      _selectedType = TransactionType.expense;
      _amountController = TextEditingController();
      _noteController = TextEditingController();
      _selectedFrequency = RecurrenceFrequency.monthly;
      _startDate = MoneyTransaction.localToday();
      _endDate = null;
      _setDefaultCategory();
    }
  }

  void _setDefaultCategory() {
    final matching = widget.categories.where((c) => c.type == _selectedType).toList();
    if (matching.isNotEmpty) {
      _selectedCategoryId = matching.first.id;
    } else {
      _selectedCategoryId = null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _selectEndDate() async {
    final initial = _endDate ?? _startDate.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(_startDate) ? _startDate : initial,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _errorMessage = null;
    });

    final amountText = _amountController.text.trim();
    final double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid amount greater than 0';
      });
      return;
    }

    if (_selectedCategoryId == null || _selectedCategoryId!.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please select a category';
      });
      return;
    }

    final noteText = _noteController.text.trim();
    final note = noteText.isNotEmpty ? noteText : null;

    try {
      if (isEditing) {
        final existingRule = widget.existing!;
        final updated = existingRule.copyWith(
          type: _selectedType,
          amount: amount,
          categoryId: _selectedCategoryId,
          frequency: _selectedFrequency,
          startDate: _startDate,
          endDate: _endDate,
          clearEndDate: _endDate == null,
          note: note,
          clearNote: note == null,
        );

        MoneyValidator.validateRecurringTransactionUpdate(
          existingRule,
          updated,
          widget.categories,
        );

        await widget.repository.updateRecurring(updated);
      } else {
        final newRule = RecurringMoneyTransaction(
          type: _selectedType,
          amount: amount,
          categoryId: _selectedCategoryId!,
          frequency: _selectedFrequency,
          startDate: _startDate,
          endDate: _endDate,
          note: note,
        );

        MoneyValidator.validateRecurringTransaction(
          newRule,
          widget.categories,
        );

        await widget.repository.addRecurring(newRule);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on MoneyValidationException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save recurring transaction: $e';
        });
      }
    }
  }

  String _formatDateString(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = MoneyTheme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final matchingCategories =
        widget.categories.where((c) => c.type == _selectedType).toList();

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
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
                  isEditing
                      ? 'Edit Recurring Transaction'
                      : 'Add Recurring Transaction',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Error banner
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.expense.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.expense.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 18, color: colors.expense),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: colors.expense,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 1. Transaction Type Toggle
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('recurring_type_expense'),
                    onPressed: () {
                      setState(() {
                        _selectedType = TransactionType.expense;
                        _setDefaultCategory();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _selectedType == TransactionType.expense
                          ? colors.expense.withValues(alpha: 0.15)
                          : Colors.transparent,
                      side: BorderSide(
                        color: _selectedType == TransactionType.expense
                            ? colors.expense
                            : colors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Expense',
                      style: TextStyle(
                        color: _selectedType == TransactionType.expense
                            ? colors.expense
                            : colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('recurring_type_income'),
                    onPressed: () {
                      setState(() {
                        _selectedType = TransactionType.income;
                        _setDefaultCategory();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _selectedType == TransactionType.income
                          ? colors.income.withValues(alpha: 0.15)
                          : Colors.transparent,
                      side: BorderSide(
                        color: _selectedType == TransactionType.income
                            ? colors.income
                            : colors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Income',
                      style: TextStyle(
                        color: _selectedType == TransactionType.income
                            ? colors.income
                            : colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Amount Input
            TextField(
              key: const Key('recurring_amount_input'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: colors.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                labelStyle: TextStyle(color: colors.textSecondary),
                prefixText: '₹ ',
                prefixStyle: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.primaryAccent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Category Selector
            DropdownButtonFormField<String>(
              key: const Key('recurring_category_select'),
              initialValue: matchingCategories.any((c) => c.id == _selectedCategoryId)
                  ? _selectedCategoryId
                  : (matchingCategories.isNotEmpty
                      ? matchingCategories.first.id
                      : null),
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: colors.textSecondary),
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
              dropdownColor: colors.card,
              items: matchingCategories.map((c) {
                return DropdownMenuItem<String>(
                  value: c.id,
                  child: Row(
                    children: [
                      Icon(
                        MoneyFormatter.getCategoryIcon(c.name, c.icon),
                        size: 18,
                        color: colors.primaryAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.name,
                        style: TextStyle(color: colors.textPrimary),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategoryId = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // 4. Frequency Selector
            DropdownButtonFormField<RecurrenceFrequency>(
              key: const Key('recurring_frequency_select'),
              initialValue: _selectedFrequency,
              decoration: InputDecoration(
                labelText: 'Frequency',
                labelStyle: TextStyle(color: colors.textSecondary),
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
              dropdownColor: colors.card,
              items: RecurrenceFrequency.values.map((f) {
                return DropdownMenuItem<RecurrenceFrequency>(
                  value: f,
                  child: Text(
                    f.displayName,
                    style: TextStyle(color: colors.textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedFrequency = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // 5. Start Date & End Date Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    key: const Key('recurring_start_date_button'),
                    onTap: _selectStartDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Date',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: colors.primaryAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDateString(_startDate),
                                style: TextStyle(
                                  color: colors.textPrimary,
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    key: const Key('recurring_end_date_button'),
                    onTap: _selectEndDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'End Date (Optional)',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              if (_endDate != null)
                                GestureDetector(
                                  key: const Key('clear_end_date_button'),
                                  onTap: () {
                                    setState(() {
                                      _endDate = null;
                                    });
                                  },
                                  child: Icon(
                                    Icons.cancel,
                                    size: 14,
                                    color: colors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.event_available_outlined,
                                size: 14,
                                color: _endDate != null
                                    ? colors.primaryAccent
                                    : colors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _endDate != null
                                    ? _formatDateString(_endDate!)
                                    : 'None',
                                style: TextStyle(
                                  color: _endDate != null
                                      ? colors.textPrimary
                                      : colors.textSecondary,
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
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 6. Note input
            TextField(
              key: const Key('recurring_note_input'),
              controller: _noteController,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Note (Optional)',
                labelStyle: TextStyle(color: colors.textSecondary),
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 7. Save Button
            ElevatedButton(
              key: const Key('save_recurring_button'),
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                isEditing
                    ? 'Update Recurring Rule'
                    : 'Create Recurring Rule',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
