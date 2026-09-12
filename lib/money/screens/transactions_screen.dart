import 'package:flutter/material.dart';
import '../models/money_category.dart';
import '../models/money_transaction.dart';
import '../models/transaction_type.dart';
import '../repositories/money_repository.dart';
import '../theme/money_theme.dart';
import '../utils/money_formatter.dart';
import 'add_edit_transaction_screen.dart';

enum TransactionSortOption {
  newestFirst('Newest first'),
  oldestFirst('Oldest first'),
  highestAmount('Highest amount'),
  lowestAmount('Lowest amount');

  final String label;
  const TransactionSortOption(this.label);
}

enum TransactionDateFilter {
  all('All'),
  thisMonth('This month'),
  customRange('Custom date range');

  final String label;
  const TransactionDateFilter(this.label);
}

/// Dedicated screen for browsing, searching, filtering, sorting, editing, and deleting Money transactions.
class TransactionsScreen extends StatefulWidget {
  final MoneyRepository repository;

  const TransactionsScreen({
    super.key,
    required this.repository,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<MoneyTransaction> _allTransactions = [];
  List<MoneyCategory> _availableCategories = [];
  bool _isLoading = true;

  // Filters
  TransactionType? _selectedType; // null means "All"
  String? _selectedCategory; // null means "All"
  TransactionDateFilter _selectedDateFilter = TransactionDateFilter.all;
  DateTimeRange? _customDateRange;

  // Sorting
  TransactionSortOption _selectedSort = TransactionSortOption.newestFirst;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  Future<void> _loadData() async {
    final transactions = await widget.repository.getTransactions();
    final categories = await widget.repository.getCategories();
    if (!mounted) return;

    setState(() {
      _allTransactions = transactions;
      _availableCategories = categories;
      _isLoading = false;
    });
  }

  Future<void> _openAddTransaction() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(repository: widget.repository),
      ),
    );
    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _openEditTransaction(MoneyTransaction transaction) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(
          repository: widget.repository,
          initialTransaction: transaction,
        ),
      ),
    );
    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _confirmDeleteTransaction(MoneyTransaction transaction) async {
    final colors = MoneyTheme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        title: Text(
          'Delete transaction?',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this transaction?',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            key: const Key('cancel_delete_transaction_button'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          TextButton(
            key: const Key('confirm_delete_transaction_button'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(
                color: colors.expense,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.repository.deleteTransaction(transaction.id);
      await _loadData();
    }
  }

  List<MoneyTransaction> _getFilteredAndSortedTransactions() {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();

    final filtered = _allTransactions.where((t) {
      // 1. Search Query (Category name and Note)
      if (query.isNotEmpty) {
        final categoryMatch = t.category.toLowerCase().contains(query);
        final noteMatch = t.note != null && t.note!.toLowerCase().contains(query);
        if (!categoryMatch && !noteMatch) {
          return false;
        }
      }

      // 2. Transaction Type Filter
      if (_selectedType != null && t.type != _selectedType) {
        return false;
      }

      // 3. Category Filter
      if (_selectedCategory != null &&
          t.category.toLowerCase() != _selectedCategory!.toLowerCase()) {
        return false;
      }

      // 4. Date Filter
      switch (_selectedDateFilter) {
        case TransactionDateFilter.all:
          break;
        case TransactionDateFilter.thisMonth:
          if (t.date.year != now.year || t.date.month != now.month) {
            return false;
          }
          break;
        case TransactionDateFilter.customRange:
          if (_customDateRange != null) {
            final tDate = DateTime(t.date.year, t.date.month, t.date.day);
            final startDate = DateTime(
              _customDateRange!.start.year,
              _customDateRange!.start.month,
              _customDateRange!.start.day,
            );
            final endDate = DateTime(
              _customDateRange!.end.year,
              _customDateRange!.end.month,
              _customDateRange!.end.day,
            );
            if (tDate.isBefore(startDate) || tDate.isAfter(endDate)) {
              return false;
            }
          }
          break;
      }

      return true;
    }).toList();

    // Sorting
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case TransactionSortOption.newestFirst:
          final dateCmp = b.date.compareTo(a.date);
          if (dateCmp != 0) return dateCmp;
          return b.createdAt.compareTo(a.createdAt);
        case TransactionSortOption.oldestFirst:
          final dateCmp = a.date.compareTo(b.date);
          if (dateCmp != 0) return dateCmp;
          return a.createdAt.compareTo(b.createdAt);
        case TransactionSortOption.highestAmount:
          final amtCmp = b.amount.compareTo(a.amount);
          if (amtCmp != 0) return amtCmp;
          return b.date.compareTo(a.date);
        case TransactionSortOption.lowestAmount:
          final amtCmp = a.amount.compareTo(b.amount);
          if (amtCmp != 0) return amtCmp;
          return b.date.compareTo(a.date);
      }
    });

    return filtered;
  }

  void _showSortModal() {
    final colors = MoneyTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Sort Transactions',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...TransactionSortOption.values.map((option) {
                  final isSelected = _selectedSort == option;
                  return ListTile(
                    key: Key('sort_option_${option.name}'),
                    title: Text(
                      option.label,
                      style: TextStyle(
                        color: isSelected ? colors.primaryAccent : colors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_rounded, color: colors.primaryAccent)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedSort = option;
                      });
                      Navigator.of(ctx).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterModal() {
    final colors = MoneyTheme.of(context);
    String? tempCategory = _selectedCategory;
    TransactionDateFilter tempDateFilter = _selectedDateFilter;
    DateTimeRange? tempRange = _customDateRange;

    // Collect all distinct category names from transactions and available categories
    final Set<String> catSet = {};
    for (final c in _availableCategories) {
      catSet.add(c.name);
    }
    for (final t in _allTransactions) {
      catSet.add(t.category);
    }
    final categoryList = catSet.toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter Transactions',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            key: const Key('reset_filters_button'),
                            onPressed: () {
                              setModalState(() {
                                tempCategory = null;
                                tempDateFilter = TransactionDateFilter.all;
                                tempRange = null;
                              });
                            },
                            child: Text(
                              'Reset',
                              style: TextStyle(color: colors.primaryAccent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category Filter
                      Text(
                        'Category',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            key: const Key('category_filter_all'),
                            label: const Text('All'),
                            selected: tempCategory == null,
                            selectedColor: colors.primaryAccent.withValues(alpha: 0.2),
                            side: BorderSide(
                              color: tempCategory == null
                                  ? colors.primaryAccent
                                  : colors.border,
                            ),
                            labelStyle: TextStyle(
                              color: tempCategory == null
                                  ? colors.primaryAccent
                                  : colors.textSecondary,
                              fontWeight: tempCategory == null
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            onSelected: (_) {
                              setModalState(() {
                                tempCategory = null;
                              });
                            },
                          ),
                          ...categoryList.map((cat) {
                            final isSelected =
                                tempCategory?.toLowerCase() == cat.toLowerCase();
                            return ChoiceChip(
                              key: Key('category_filter_$cat'),
                              label: Text(cat),
                              selected: isSelected,
                              selectedColor:
                                  colors.primaryAccent.withValues(alpha: 0.2),
                              side: BorderSide(
                                color: isSelected
                                    ? colors.primaryAccent
                                    : colors.border,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? colors.primaryAccent
                                    : colors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              onSelected: (_) {
                                setModalState(() {
                                  tempCategory = isSelected ? null : cat;
                                });
                              },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Date Filter
                      Text(
                        'Date',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...TransactionDateFilter.values.map((dFilter) {
                            final isSelected = tempDateFilter == dFilter;
                            return ChoiceChip(
                              key: Key('date_filter_${dFilter.name}'),
                              label: Text(dFilter.label),
                              selected: isSelected,
                              selectedColor:
                                  colors.primaryAccent.withValues(alpha: 0.2),
                              side: BorderSide(
                                color: isSelected
                                    ? colors.primaryAccent
                                    : colors.border,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? colors.primaryAccent
                                    : colors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              onSelected: (_) async {
                                if (dFilter == TransactionDateFilter.customRange) {
                                  final picked = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                    initialDateRange: tempRange ??
                                        DateTimeRange(
                                          start: DateTime.now().subtract(
                                              const Duration(days: 7)),
                                          end: DateTime.now(),
                                        ),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      tempDateFilter = dFilter;
                                      tempRange = picked;
                                    });
                                  }
                                } else {
                                  setModalState(() {
                                    tempDateFilter = dFilter;
                                    tempRange = null;
                                  });
                                }
                              },
                            );
                          }),
                        ],
                      ),
                      if (tempDateFilter == TransactionDateFilter.customRange &&
                          tempRange != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${MoneyFormatter.formatDate(tempRange!.start)} – ${MoneyFormatter.formatDate(tempRange!.end)}',
                          style: TextStyle(
                            color: colors.primaryAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),

                      // Apply button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          key: const Key('apply_filters_button'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primaryAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedCategory = tempCategory;
                              _selectedDateFilter = tempDateFilter;
                              _customDateRange = tempRange;
                            });
                            Navigator.of(ctx).pop();
                          },
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedCategory != null) count++;
    if (_selectedDateFilter != TransactionDateFilter.all) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final colors = MoneyTheme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Transactions',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(color: colors.primaryAccent),
        ),
      );
    }

    // 1. Completely empty state (No transactions in repository at all)
    if (_allTransactions.isEmpty) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          elevation: 0,
          leading: IconButton(
            key: const Key('transactions_back_button'),
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Transactions',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: colors.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 48,
                      color: colors.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add your first income or expense\nfrom the Add Transaction button.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    key: const Key('empty_add_transaction_button'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text(
                      'Add Transaction',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _openAddTransaction,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final filteredTransactions = _getFilteredAndSortedTransactions();
    final activeFilterCount = _getActiveFilterCount();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          key: const Key('transactions_back_button'),
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Text(
              'Transactions',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                '${filteredTransactions.length}',
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
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('transactions_fab_add'),
        backgroundColor: colors.primaryAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Transaction',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: _openAddTransaction,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Section 1: Search bar ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: TextField(
                  key: const Key('transactions_search_field'),
                  controller: _searchController,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    hintStyle: TextStyle(
                      color: colors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            key: const Key('transactions_search_clear'),
                            icon: Icon(
                              Icons.close_rounded,
                              color: colors.textSecondary,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            // ── Section 2: Quick Type Filter Chips ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTypeSegment(
                      label: 'All',
                      isSelected: _selectedType == null,
                      onTap: () {
                        setState(() {
                          _selectedType = null;
                        });
                      },
                      colors: colors,
                      keyName: 'type_filter_all',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeSegment(
                      label: 'Income',
                      isSelected: _selectedType == TransactionType.income,
                      onTap: () {
                        setState(() {
                          _selectedType = TransactionType.income;
                        });
                      },
                      colors: colors,
                      activeColor: colors.income,
                      keyName: 'type_filter_income',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeSegment(
                      label: 'Expense',
                      isSelected: _selectedType == TransactionType.expense,
                      onTap: () {
                        setState(() {
                          _selectedType = TransactionType.expense;
                        });
                      },
                      colors: colors,
                      activeColor: colors.expense,
                      keyName: 'type_filter_expense',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Section 3: Filter & Sort Row ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Filter Button
                  OutlinedButton.icon(
                    key: const Key('open_filter_button'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: activeFilterCount > 0
                          ? colors.primaryAccent
                          : colors.textSecondary,
                      side: BorderSide(
                        color: activeFilterCount > 0
                            ? colors.primaryAccent
                            : colors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    icon: Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: activeFilterCount > 0
                          ? colors.primaryAccent
                          : colors.textSecondary,
                    ),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Filter'),
                        if (activeFilterCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: colors.primaryAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$activeFilterCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    onPressed: _showFilterModal,
                  ),

                  // Sort Button
                  OutlinedButton.icon(
                    key: const Key('open_sort_button'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    icon: Icon(
                      Icons.swap_vert_rounded,
                      size: 18,
                      color: colors.textSecondary,
                    ),
                    label: Text(_selectedSort.label),
                    onPressed: _showSortModal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Divider(color: colors.border, height: 1),

            // ── Section 4: Transactions List or Empty Search State ────────────
            Expanded(
              child: filteredTransactions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: colors.textSecondary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions found',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try a different search.',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: filteredTransactions.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final t = filteredTransactions[index];
                        return _buildTransactionRow(t, colors);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSegment({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required MoneyColors colors,
    Color? activeColor,
    required String keyName,
  }) {
    final effectiveColor = activeColor ?? colors.primaryAccent;
    return InkWell(
      key: Key(keyName),
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveColor.withValues(alpha: 0.15)
              : colors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? effectiveColor : colors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? effectiveColor : colors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionRow(MoneyTransaction t, MoneyColors colors) {
    final isIncome = t.type.isIncome;
    final amountColor = isIncome ? colors.income : colors.expense;
    final formattedAmount = MoneyFormatter.format(
      isIncome ? t.amount : -t.amount,
      showSign: true,
    );
    final categoryIcon = MoneyFormatter.getCategoryIcon(t.category);
    final formattedDate = MoneyFormatter.formatDate(t.date);

    return InkWell(
      key: Key('transaction_item_${t.id}'),
      onTap: () => _openEditTransaction(t),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            // Category Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: amountColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                categoryIcon,
                color: amountColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Category name + Optional Note + Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.category,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (t.note != null && t.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      t.note!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: colors.textSecondary.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (t.id.startsWith('rec_')) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.repeat_rounded,
                          size: 12,
                          color: colors.secondaryAccent,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Amount
            Text(
              formattedAmount,
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),

            // Delete Action
            IconButton(
              key: Key('delete_transaction_${t.id}'),
              icon: Icon(
                Icons.delete_outline_rounded,
                color: colors.textSecondary.withValues(alpha: 0.6),
                size: 20,
              ),
              tooltip: 'Delete transaction',
              onPressed: () => _confirmDeleteTransaction(t),
            ),
          ],
        ),
      ),
    );
  }
}
