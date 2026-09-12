import 'package:flutter/material.dart';
import '../models/money_transaction.dart';
import '../repositories/money_repository.dart';
import '../services/money_calculator.dart';
import '../theme/money_theme.dart';
import '../utils/money_formatter.dart';
import '../widgets/category_breakdown_bars.dart';
import 'add_edit_transaction_screen.dart';

/// Screen providing a calendar month-based view of finances, categories, and transactions.
class MonthlyViewScreen extends StatefulWidget {
  final MoneyRepository repository;
  final DateTime? initialMonth;

  const MonthlyViewScreen({
    super.key,
    required this.repository,
    this.initialMonth,
  });

  @override
  State<MonthlyViewScreen> createState() => _MonthlyViewScreenState();
}

class _MonthlyViewScreenState extends State<MonthlyViewScreen> {
  late DateTime _selectedMonth;
  List<MoneyTransaction> _allTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = widget.initialMonth ?? DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    _loadData();
  }

  @override
  void didUpdateWidget(covariant MonthlyViewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMonth != null && widget.initialMonth != oldWidget.initialMonth) {
      _selectedMonth = DateTime(widget.initialMonth!.year, widget.initialMonth!.month, 1);
    }
  }

  Future<void> _loadData() async {
    final transactions = await widget.repository.getTransactions();
    if (!mounted) return;
    setState(() {
      _allTransactions = transactions;
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
    });
  }

  void _nextMonth() {
    setState(() {
      if (_selectedMonth.month == 12) {
        _selectedMonth = DateTime(_selectedMonth.year + 1, 1, 1);
      } else {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
      }
    });
  }

  Future<void> _openAddTransaction() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(repository: widget.repository),
      ),
    );
    if (result == true) {
      _loadData();
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
      _loadData();
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _formatTransactionDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = MoneyTheme.of(context);
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final monthTitle = '${_getMonthName(month)} $year';

    // Query month analytics from MoneyCalculator
    final monthTransactions = MoneyCalculator.transactionsForMonth(
      _allTransactions,
      year: year,
      month: month,
    );
    final income = MoneyCalculator.incomeForMonth(
      _allTransactions,
      year: year,
      month: month,
    );
    final expenses = MoneyCalculator.expensesForMonth(
      _allTransactions,
      year: year,
      month: month,
    );
    final savings = MoneyCalculator.savingsForMonth(
      _allTransactions,
      year: year,
      month: month,
    );
    final expensesByCategory = MoneyCalculator.expensesByCategoryForMonth(
      _allTransactions,
      year: year,
      month: month,
    );
    final incomeByCategory = MoneyCalculator.incomeByCategoryForMonth(
      _allTransactions,
      year: year,
      month: month,
    );
    final incomeCount = MoneyCalculator.incomeCountForMonth(
      _allTransactions,
      year: year,
      month: month,
    );
    final expenseCount = MoneyCalculator.expenseCountForMonth(
      _allTransactions,
      year: year,
      month: month,
    );

    final hasTransactions = monthTransactions.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Monthly View',
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.primaryAccent))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: colors.primaryAccent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. MONTH NAVIGATION HEADER: <  September 2026  >
                    _buildMonthNavigationHeader(monthTitle, colors),
                    const SizedBox(height: 16),

                    // 2. MONTH SUMMARY CARD
                    _buildMonthSummaryCard(
                      income: income,
                      expenses: expenses,
                      savings: savings,
                      colors: colors,
                    ),
                    const SizedBox(height: 20),

                    // 3. MAIN CONTENT: EMPTY STATE OR DETAILED SECTIONS
                    if (!hasTransactions)
                      _buildEmptyState(colors)
                    else ...[
                      // MONTHLY OVERVIEW (Overview with counts)
                      _buildMonthlyOverviewCard(
                        monthTitle: monthTitle,
                        income: income,
                        expenses: expenses,
                        savings: savings,
                        incomeCount: incomeCount,
                        expenseCount: expenseCount,
                        colors: colors,
                      ),
                      const SizedBox(height: 20),

                      // SPENDING BY CATEGORY
                      CategoryBreakdownBars(
                        title: 'Spending by Category',
                        categoryAmounts: expensesByCategory,
                        totalAmount: expenses,
                        barColor: colors.expense,
                        emptyMessage: 'No expenses this month',
                      ),
                      const SizedBox(height: 20),

                      // INCOME BY CATEGORY
                      CategoryBreakdownBars(
                        title: 'Income by Category',
                        categoryAmounts: incomeByCategory,
                        totalAmount: income,
                        barColor: colors.income,
                        emptyMessage: 'No income this month',
                      ),
                      const SizedBox(height: 24),

                      // TRANSACTIONS LIST
                      _buildTransactionsSection(monthTransactions, colors),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMonthNavigationHeader(String monthTitle, MoneyColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            key: const Key('monthly_prev_month_button'),
            icon: const Icon(Icons.chevron_left_rounded),
            color: colors.textPrimary,
            iconSize: 28,
            tooltip: 'Previous Month',
            onPressed: _prevMonth,
          ),
          Text(
            monthTitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          IconButton(
            key: const Key('monthly_next_month_button'),
            icon: const Icon(Icons.chevron_right_rounded),
            color: colors.textPrimary,
            iconSize: 28,
            tooltip: 'Next Month',
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSummaryCard({
    required double income,
    required double expenses,
    required double savings,
    required MoneyColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetricItem(
                  label: 'Income',
                  amount: income,
                  color: colors.income,
                  icon: Icons.arrow_downward_rounded,
                  colors: colors,
                ),
              ),
              Container(
                height: 48,
                width: 1,
                color: colors.divider,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Expanded(
                child: _buildSummaryMetricItem(
                  label: 'Expenses',
                  amount: expenses,
                  color: colors.expense,
                  icon: Icons.arrow_upward_rounded,
                  colors: colors,
                ),
              ),
              Container(
                height: 48,
                width: 1,
                color: colors.divider,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Expanded(
                child: _buildSummaryMetricItem(
                  label: 'Savings',
                  amount: savings,
                  color: savings >= 0 ? colors.savings : colors.error,
                  icon: Icons.savings_outlined,
                  colors: colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetricItem({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
    required MoneyColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            MoneyFormatter.format(amount),
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyOverviewCard({
    required String monthTitle,
    required double income,
    required double expenses,
    required double savings,
    required int incomeCount,
    required int expenseCount,
    required MoneyColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Overview',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                monthTitle,
                style: TextStyle(
                  color: colors.secondaryAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Total Income row
          _buildOverviewRow('Total Income', MoneyFormatter.format(income), colors.income, colors),
          const SizedBox(height: 8),
          // Total Expenses row
          _buildOverviewRow('Total Expenses', MoneyFormatter.format(expenses), colors.expense, colors),
          const SizedBox(height: 8),
          // Net Savings row
          _buildOverviewRow(
            'Net Savings',
            MoneyFormatter.format(savings),
            savings >= 0 ? colors.savings : colors.error,
            colors,
          ),
          const SizedBox(height: 12),
          Divider(color: colors.divider, height: 1),
          const SizedBox(height: 12),
          // Transaction Counts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Income transactions',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              Text(
                '$incomeCount',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expense transactions',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              Text(
                '$expenseCount',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewRow(String label, String value, Color valueColor, MoneyColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsSection(List<MoneyTransaction> transactions, MoneyColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transactions',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${transactions.length} total',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final t = transactions[index];
            final isIncome = t.type.isIncome;
            final amountColor = isIncome ? colors.income : colors.expense;
            final sign = isIncome ? '+' : '-';
            final icon = MoneyFormatter.getCategoryIcon(t.category);

            return InkWell(
              key: Key('monthly_transaction_${t.id}'),
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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: amountColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: amountColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$sign${MoneyFormatter.format(t.amount)}',
                          style: TextStyle(
                            color: amountColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTransactionDate(t.date),
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12,
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
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(MoneyColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_month_outlined,
              size: 40,
              color: colors.primaryAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions this month',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a transaction to start tracking your money.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            key: const Key('monthly_empty_add_transaction_button'),
            onPressed: _openAddTransaction,
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text(
              'Add Transaction',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
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
    );
  }
}
