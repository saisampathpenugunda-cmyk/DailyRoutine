import 'package:flutter/material.dart';
import '../models/money_budget.dart';
import '../models/money_category.dart';
import '../models/money_transaction.dart';
import '../repositories/money_repository.dart';
import '../services/money_calculator.dart';
import '../theme/money_theme.dart';
import '../utils/money_formatter.dart';
import '../widgets/category_breakdown_bars.dart';
import '../widgets/daily_trend_line_chart.dart';
import '../widgets/income_expense_comparison_chart.dart';
import 'add_edit_transaction_screen.dart';
import 'budgets_screen.dart';

/// Available period filtering options for Statistics.
enum StatisticsPeriod {
  thisMonth,
  lastMonth,
  customRange,
}

/// Statistics screen providing in-depth analytics, breakdowns, and trend charts.
class StatisticsScreen extends StatefulWidget {
  final MoneyRepository repository;
  final DateTime? now;

  const StatisticsScreen({
    super.key,
    required this.repository,
    this.now,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<MoneyTransaction> _allTransactions = [];
  List<MoneyBudget> _allBudgets = [];
  List<MoneyCategory> _allCategories = [];
  bool _isLoading = true;

  StatisticsPeriod _selectedPeriod = StatisticsPeriod.thisMonth;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  @override
  void initState() {
    super.initState();
    _initPeriodDates();
    _loadData();
  }

  void _initPeriodDates() {
    final now = widget.now ?? DateTime.now();
    switch (_selectedPeriod) {
      case StatisticsPeriod.thisMonth:
        final range = MoneyCalculator.getThisMonthRange(now);
        _rangeStart = range.start;
        _rangeEnd = range.end;
        break;
      case StatisticsPeriod.lastMonth:
        final range = MoneyCalculator.getLastMonthRange(now);
        _rangeStart = range.start;
        _rangeEnd = range.end;
        break;
      case StatisticsPeriod.customRange:
        // Keep existing custom range or default to this month
        break;
    }
  }

  Future<void> _loadData() async {
    final transactionsFuture = widget.repository.getTransactions();
    final budgetsFuture = widget.repository.getBudgets();
    final categoriesFuture = widget.repository.getCategories();

    final results = await Future.wait([
      transactionsFuture,
      budgetsFuture,
      categoriesFuture,
    ]);

    if (!mounted) return;
    setState(() {
      _allTransactions = results[0] as List<MoneyTransaction>;
      _allBudgets = results[1] as List<MoneyBudget>;
      _allCategories = results[2] as List<MoneyCategory>;
      _isLoading = false;
    });
  }

  Future<void> _navigateToBudgets() async {
    final initialMonth = DateTime(_rangeStart.year, _rangeStart.month, 1);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BudgetsScreen(
          repository: widget.repository,
          initialMonth: initialMonth,
        ),
      ),
    );
    _loadData();
  }

  Future<void> _selectPeriod(StatisticsPeriod period) async {
    final now = widget.now ?? DateTime.now();
    if (period == StatisticsPeriod.thisMonth) {
      final range = MoneyCalculator.getThisMonthRange(now);
      setState(() {
        _selectedPeriod = period;
        _rangeStart = range.start;
        _rangeEnd = range.end;
      });
    } else if (period == StatisticsPeriod.lastMonth) {
      final range = MoneyCalculator.getLastMonthRange(now);
      setState(() {
        _selectedPeriod = period;
        _rangeStart = range.start;
        _rangeEnd = range.end;
      });
    } else if (period == StatisticsPeriod.customRange) {
      final initialRange = DateTimeRange(
        start: _rangeStart,
        end: _rangeEnd,
      );
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDateRange: initialRange,
      );

      if (picked != null && mounted) {
        setState(() {
          _selectedPeriod = period;
          _rangeStart = DateTime(picked.start.year, picked.start.month, picked.start.day);
          _rangeEnd = DateTime(picked.end.year, picked.end.month, picked.end.day);
        });
      }
    }
  }

  Future<void> _navigateToAddTransaction() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(repository: widget.repository),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case StatisticsPeriod.thisMonth:
        return 'This Month';
      case StatisticsPeriod.lastMonth:
        return 'Last Month';
      case StatisticsPeriod.customRange:
        return 'Custom Range';
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (start.year == end.year) {
      return '${start.day} ${months[start.month - 1]} – ${end.day} ${months[end.month - 1]} ${end.year}';
    }
    return '${start.day} ${months[start.month - 1]} ${start.year} – ${end.day} ${months[end.month - 1]} ${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = MoneyTheme.of(context);

    // Compute period analytics
    final periodTransactions = MoneyCalculator.filterByDateRange(
      _allTransactions,
      start: _rangeStart,
      end: _rangeEnd,
    );
    final hasTransactions = periodTransactions.isNotEmpty;

    final income = MoneyCalculator.incomeForRange(
      _allTransactions,
      start: _rangeStart,
      end: _rangeEnd,
    );
    final expenses = MoneyCalculator.expensesForRange(
      _allTransactions,
      start: _rangeStart,
      end: _rangeEnd,
    );
    final savings = MoneyCalculator.savingsForRange(
      _allTransactions,
      start: _rangeStart,
      end: _rangeEnd,
    );

    final expensesByCategory = MoneyCalculator.expensesByCategoryForRange(
      _allTransactions,
      start: _rangeStart,
      end: _rangeEnd,
    );
    final incomeByCategory = MoneyCalculator.incomeByCategoryForRange(
      _allTransactions,
      start: _rangeStart,
      end: _rangeEnd,
    );

    final dailyExpenses = MoneyCalculator.dailyExpensesForRange(
      _allTransactions,
      start: _rangeStart,
      end: _rangeEnd,
    );
    final dailySavings = MoneyCalculator.dailySavingsForRange(
      _allTransactions,
      start: _rangeStart,
      end: _rangeEnd,
    );

    final List<CategoryBudgetComparison> budgetComparisons;
    if (_selectedPeriod == StatisticsPeriod.customRange) {
      budgetComparisons = MoneyCalculator.budgetVsActualForRange(
        budgets: _allBudgets,
        transactions: _allTransactions,
        categories: _allCategories,
        start: _rangeStart,
        end: _rangeEnd,
      );
    } else {
      budgetComparisons = MoneyCalculator.budgetVsActualForMonth(
        budgets: _allBudgets,
        transactions: _allTransactions,
        categories: _allCategories,
        year: _rangeStart.year,
        month: _rangeStart.month,
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Statistics',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. PERIOD SELECTOR
                    _buildPeriodSelector(colors),
                    const SizedBox(height: 18),

                    // 2. FINANCIAL SUMMARY CARDS
                    _buildSummaryCards(
                      income: income,
                      expenses: expenses,
                      savings: savings,
                      colors: colors,
                    ),
                    const SizedBox(height: 20),

                    // 3. MAIN CONTENT: EMPTY STATE OR DETAILED ANALYTICS
                    if (!hasTransactions)
                      _buildEmptyState(colors)
                    else ...[
                      // COMPARATIVE CHART: Income vs Expenses
                      IncomeExpenseComparisonChart(
                        income: income,
                        expenses: expenses,
                      ),
                      const SizedBox(height: 20),

                      // BUDGET VS ACTUAL
                      _buildBudgetVsActualSection(budgetComparisons, colors),
                      const SizedBox(height: 20),

                      // CATEGORY BREAKDOWN: Spending by Category
                      CategoryBreakdownBars(
                        title: 'Spending by Category',
                        categoryAmounts: expensesByCategory,
                        totalAmount: expenses,
                        barColor: colors.expense,
                        emptyMessage: 'No expenses in this period',
                      ),
                      const SizedBox(height: 20),

                      // CATEGORY BREAKDOWN: Income by Category
                      CategoryBreakdownBars(
                        title: 'Income by Category',
                        categoryAmounts: incomeByCategory,
                        totalAmount: income,
                        barColor: colors.income,
                        emptyMessage: 'No income in this period',
                      ),
                      const SizedBox(height: 20),

                      // SPENDING TREND
                      DailyTrendLineChart(
                        title: 'Spending Trend',
                        dailyData: dailyExpenses,
                        lineColor: colors.expense,
                        allowNegative: false,
                      ),
                      const SizedBox(height: 20),

                      // SAVINGS TREND
                      DailyTrendLineChart(
                        title: 'Savings Trend',
                        dailyData: dailySavings,
                        lineColor: colors.savings,
                        allowNegative: true,
                        subtitle: 'Net Daily Savings',
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector(MoneyColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Time Period',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDateRange(_rangeStart, _rangeEnd),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          PopupMenuButton<StatisticsPeriod>(
            key: const Key('statistics_period_selector'),
            initialValue: _selectedPeriod,
            onSelected: _selectPeriod,
            color: colors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.border),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: StatisticsPeriod.thisMonth,
                child: Text(
                  'This Month',
                  style: TextStyle(
                    color: _selectedPeriod == StatisticsPeriod.thisMonth
                        ? colors.primaryAccent
                        : colors.textPrimary,
                    fontWeight: _selectedPeriod == StatisticsPeriod.thisMonth
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ),
              PopupMenuItem(
                value: StatisticsPeriod.lastMonth,
                child: Text(
                  'Last Month',
                  style: TextStyle(
                    color: _selectedPeriod == StatisticsPeriod.lastMonth
                        ? colors.primaryAccent
                        : colors.textPrimary,
                    fontWeight: _selectedPeriod == StatisticsPeriod.lastMonth
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ),
              PopupMenuItem(
                value: StatisticsPeriod.customRange,
                child: Text(
                  'Custom Range',
                  style: TextStyle(
                    color: _selectedPeriod == StatisticsPeriod.customRange
                        ? colors.primaryAccent
                        : colors.textPrimary,
                    fontWeight: _selectedPeriod == StatisticsPeriod.customRange
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primaryAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.primaryAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getPeriodLabel(),
                    style: TextStyle(
                      color: colors.primaryAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    color: colors.primaryAccent,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards({
    required double income,
    required double expenses,
    required double savings,
    required MoneyColors colors,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            label: 'Income',
            amount: income,
            color: colors.income,
            icon: Icons.arrow_downward_rounded,
            colors: colors,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            label: 'Expenses',
            amount: expenses,
            color: colors.expense,
            icon: Icons.arrow_upward_rounded,
            colors: colors,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            label: 'Savings',
            amount: savings,
            color: savings >= 0 ? colors.savings : colors.error,
            icon: Icons.savings_outlined,
            colors: colors,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
    required MoneyColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
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
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
      ),
    );
  }

  Widget _buildBudgetVsActualSection(
    List<CategoryBudgetComparison> comparisons,
    MoneyColors colors,
  ) {
    return Container(
      key: const Key('statistics_budget_vs_actual_section'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget vs Actual',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              InkWell(
                key: const Key('statistics_manage_budgets_button'),
                onTap: _navigateToBudgets,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Manage',
                    style: TextStyle(
                      color: colors.primaryAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedPeriod == StatisticsPeriod.customRange && comparisons.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Combined monthly budgets for selected range',
              style: TextStyle(color: colors.textSecondary, fontSize: 11),
            ),
          ],
          const SizedBox(height: 14),
          if (comparisons.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No budgets set for this period',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comparisons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = comparisons[index];
                return _buildBudgetVsActualItem(item, colors);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBudgetVsActualItem(CategoryBudgetComparison item, MoneyColors colors) {
    final isOver = item.isOverBudget;
    final statusText = isOver ? 'Over Budget' : 'On Track';
    final statusColor = isOver ? colors.expense : colors.income;
    final progressColor = isOver
        ? colors.expense
        : (item.progress >= 0.8 ? colors.warning : colors.primaryAccent);

    final iconData = MoneyFormatter.getCategoryIcon(item.categoryName, item.categoryIcon);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOver
              ? colors.expense.withValues(alpha: 0.4)
              : colors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(iconData, size: 18, color: progressColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.categoryName,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.clampedProgress,
              backgroundColor: colors.card,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    MoneyFormatter.format(item.budgetAmount),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actual',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    MoneyFormatter.format(item.actualSpent),
                    style: TextStyle(
                      color: isOver ? colors.expense : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remaining',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    MoneyFormatter.format(item.remaining),
                    style: TextStyle(
                      color: item.remaining < 0 ? colors.expense : colors.income,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Used',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.percentage.round()}%',
                    style: TextStyle(
                      color: progressColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
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
              Icons.analytics_outlined,
              size: 40,
              color: colors.primaryAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing to analyze yet',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some transactions to see your statistics.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            key: const Key('statistics_add_transaction_button'),
            onPressed: _navigateToAddTransaction,
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
