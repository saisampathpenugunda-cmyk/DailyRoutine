import 'package:flutter/material.dart';
import '../models/money_category.dart';
import '../models/money_transaction.dart';
import '../models/transaction_type.dart';
import '../repositories/money_repository.dart';
import '../theme/money_theme.dart';
import '../utils/money_formatter.dart';
import '../validation/money_validator.dart';

/// Screen for creating a new transaction or editing an existing one.
class AddEditTransactionScreen extends StatefulWidget {
  final MoneyRepository repository;
  final MoneyTransaction? initialTransaction;

  const AddEditTransactionScreen({
    super.key,
    required this.repository,
    this.initialTransaction,
  });

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late TransactionType _selectedType;
  String? _selectedCategory;
  late DateTime _selectedDate;

  List<MoneyCategory> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  bool get isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTransaction;

    if (initial != null) {
      _amountController = TextEditingController(
        text: initial.amount.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), ''),
      );
      _selectedType = initial.type;
      _selectedCategory = initial.category;
      _selectedDate = initial.date;
      _noteController = TextEditingController(text: initial.note ?? '');
    } else {
      _amountController = TextEditingController();
      _selectedType = TransactionType.expense; // Expense by default
      _selectedDate = MoneyTransaction.localToday(); // Local today
      _noteController = TextEditingController();
    }

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final loaded = await widget.repository.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = loaded;
      final matching = _categories.where((c) => c.type == _selectedType).toList();
      if (_selectedCategory == null || !matching.any((c) => c.name == _selectedCategory)) {
        if (matching.isNotEmpty) {
          _selectedCategory = matching.first.name;
        }
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final colors = MoneyTheme.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: colors.primaryAccent,
                    surface: colors.surface,
                    onSurface: colors.textPrimary,
                  )
                : ColorScheme.light(
                    primary: colors.primaryAccent,
                    surface: colors.card,
                    onSurface: colors.textPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
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

    final category = _selectedCategory?.trim() ?? '';
    if (category.isEmpty) {
      setState(() {
        _errorMessage = 'Please select a category';
      });
      return;
    }

    final noteText = _noteController.text.trim();
    final note = noteText.isNotEmpty ? noteText : null;

    try {
      if (isEditing) {
        final updated = widget.initialTransaction!.copyWith(
          type: _selectedType,
          amount: amount,
          category: category,
          date: _selectedDate,
          note: note,
          clearNote: note == null,
        );
        MoneyValidator.validateTransactionUpdate(
          widget.initialTransaction!,
          updated,
        );
        await widget.repository.updateTransaction(updated);
      } else {
        final newTransaction = MoneyTransaction(
          type: _selectedType,
          amount: amount,
          category: category,
          date: _selectedDate,
          note: note,
        );
        MoneyValidator.validateTransaction(newTransaction);
        await widget.repository.addTransaction(newTransaction);
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
          _errorMessage = 'Failed to save transaction: $e';
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final today = MoneyTransaction.localToday();
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today, ${months[date.month - 1]} ${date.day}, ${date.year}';
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
          isEditing ? 'Edit Transaction' : 'Add Transaction',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: colors.primaryAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. AMOUNT INPUT (Prominent)
                  Text(
                    'Amount',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          MoneyFormatter.rupeeSymbol,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colors.primaryAccent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            autofocus: !isEditing,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: colors.textSecondary.withValues(alpha: 0.4),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. EXPENSE / INCOME SEGMENTED CONTROL
                  Text(
                    'Transaction Type',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTypeSegment(
                            type: TransactionType.expense,
                            label: 'Expense',
                            icon: Icons.arrow_downward,
                            activeColor: colors.expense,
                            colors: colors,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildTypeSegment(
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
                  const SizedBox(height: 24),

                  // 3. CATEGORY SELECTION
                  Text(
                    'Category',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories
                        .where((c) => c.type == _selectedType)
                        .map((cat) {
                      final isSelected = _selectedCategory == cat.name;
                      return ChoiceChip(
                        key: Key('category_chip_${cat.id}'),
                        label: Text(cat.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat.name;
                            });
                          }
                        },
                        selectedColor: colors.primaryAccent.withValues(alpha: 0.2),
                        backgroundColor: colors.card,
                        side: BorderSide(
                          color: isSelected ? colors.primaryAccent : colors.border,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? colors.primaryAccent : colors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // 4. DATE SELECTION
                  Text(
                    'Date',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 20, color: colors.primaryAccent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _formatDate(_selectedDate),
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: colors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. NOTE (OPTIONAL)
                  Text(
                    'Note (Optional)',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: TextField(
                      controller: _noteController,
                      style: TextStyle(color: colors.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Add details or tags...',
                        hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.error.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: colors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: colors.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // 6. SAVE BUTTON
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isEditing ? 'Save Changes' : 'Save Transaction',
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

  Widget _buildTypeSegment({
    required TransactionType type,
    required String label,
    required IconData icon,
    required Color activeColor,
    required MoneyColors colors,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () {
        if (_selectedType == type) return;
        setState(() {
          _selectedType = type;
          final matching = _categories.where((c) => c.type == type).toList();
          if (!matching.any((c) => c.name == _selectedCategory)) {
            _selectedCategory = matching.isNotEmpty ? matching.first.name : null;
          }
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
}
