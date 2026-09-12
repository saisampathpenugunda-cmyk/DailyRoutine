import 'package:flutter/material.dart';
import '../../controllers/user_profile_controller.dart';
import '../../repositories/activity_repository.dart';
import '../../services/notification_service.dart';
import 'money_settings_screen.dart';
import '../models/money_budget.dart';
import '../models/money_category.dart';
import '../models/money_transaction.dart';
import '../repositories/money_repository.dart';
import '../services/money_calculator.dart';
import '../theme/money_theme.dart';
import '../utils/money_formatter.dart';
import 'add_edit_transaction_screen.dart';
import 'budgets_screen.dart';
import 'categories_screen.dart';
import 'monthly_view_screen.dart';
import 'recurring_transactions_screen.dart';
import 'statistics_screen.dart';
import 'transactions_screen.dart';
import '../services/recurring_transaction_service.dart';

/// Money Dashboard screen showcasing balances, summaries, and recent activity.
class MoneyDashboardScreen extends StatefulWidget {
  final MoneyRepository repository;
  final ActivityRepository? activityRepository;
  final NotificationService? notificationService;
  final UserProfileController? userProfileController;

  const MoneyDashboardScreen({
    super.key,
    required this.repository,
    this.activityRepository,
    this.notificationService,
    this.userProfileController,
  });

  @override
  State<MoneyDashboardScreen> createState() => _MoneyDashboardScreenState();
}

class _MoneyDashboardScreenState extends State<MoneyDashboardScreen> {
  List<MoneyTransaction> _transactions = [];
  List<MoneyBudget> _monthBudgets = [];
  List<MoneyCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await RecurringTransactionService.generateDueTransactions(widget.repository);

    final now = DateTime.now();
    final transactionsFuture = widget.repository.getTransactions();
    final budgetsFuture = widget.repository.getBudgets(year: now.year, month: now.month);
    final categoriesFuture = widget.repository.getCategories();

    final results = await Future.wait([
      transactionsFuture,
      budgetsFuture,
      categoriesFuture,
    ]);

    if (!mounted) return;

    final loaded = results[0] as List<MoneyTransaction>;
    final sorted = List<MoneyTransaction>.from(loaded)
      ..sort((a, b) {
        final dateCmp = b.date.compareTo(a.date);
        if (dateCmp != 0) return dateCmp;
        return b.createdAt.compareTo(a.createdAt);
      });

    setState(() {
      _transactions = sorted;
      _monthBudgets = results[1] as List<MoneyBudget>;
      _categories = results[2] as List<MoneyCategory>;
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

  Future<void> _openCategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoriesScreen(repository: widget.repository),
      ),
    );
    await _loadData();
  }

  Future<void> _openTransactions() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionsScreen(repository: widget.repository),
      ),
    );
    await _loadData();
  }

  Future<void> _openStatistics() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StatisticsScreen(repository: widget.repository),
      ),
    );
    await _loadData();
  }

  Future<void> _openMonthlyView() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MonthlyViewScreen(repository: widget.repository),
      ),
    );
    await _loadData();
  }

  Future<void> _openBudgets() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BudgetsScreen(repository: widget.repository),
      ),
    );
    await _loadData();
  }

  Future<void> _openRecurring() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecurringTransactionsScreen(repository: widget.repository),
      ),
    );
    await _loadData();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MoneySettingsScreen(
          repository: widget.repository,
        ),
      ),
    );
    await _loadData();
  }

  String _formatCurrency(double amount) {
    return MoneyFormatter.format(amount);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final today = MoneyTransaction.localToday();
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    }
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = MoneyTheme.of(context);

    final balance = MoneyCalculator.calculateBalance(_transactions);
    final totalIncome = MoneyCalculator.calculateTotalIncome(_transactions);
    final totalExpenses = MoneyCalculator.calculateTotalExpenses(_transactions);
    final totalSavings = MoneyCalculator.calculateSavings(_transactions);

    final now = DateTime.now();
    final monthTransactions = MoneyCalculator.filterByMonth(
      _transactions,
      year: now.year,
      month: now.month,
    );
    final monthIncome = MoneyCalculator.calculateTotalIncome(monthTransactions);
    final monthExpenses = MoneyCalculator.calculateTotalExpenses(monthTransactions);
    final monthSavings = MoneyCalculator.calculateSavings(monthTransactions);

    final budgetSummary = MoneyCalculator.calculateMonthlyBudgetSummary(
      budgets: _monthBudgets,
      transactions: _transactions,
      categories: _categories,
      year: now.year,
      month: now.month,
    );

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final currentMonthName = '${monthNames[now.month - 1]} ${now.year}';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Money',
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
            key: const Key('dashboard_settings_button'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.primaryAccent))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: colors.primaryAccent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. MAIN BALANCE CARD
                    _buildBalanceCard(balance, colors),
                    const SizedBox(height: 16),

                    // 3. SUMMARY (Income, Expenses, Savings)
                    _buildSummaryRow(
                      income: totalIncome,
                      expenses: totalExpenses,
                      savings: totalSavings,
                      colors: colors,
                    ),
                    const SizedBox(height: 16),

                    // 4. PRIMARY ACTIONS: + ADD TRANSACTION & RECURRING
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openAddTransaction,
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            label: const Text(
                              'Add Transaction',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primaryAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          key: const Key('dashboard_recurring_entry'),
                          onPressed: _openRecurring,
                          icon: Icon(
                            Icons.repeat_rounded,
                            size: 18,
                            color: colors.primaryAccent,
                          ),
                          label: Text(
                            'Recurring',
                            style: TextStyle(
                              color: colors.primaryAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: colors.primaryAccent.withValues(alpha: 0.5),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 5. MONEY NAVIGATION HUB
                    _buildMoneyNavigation(colors),
                    const SizedBox(height: 24),

                    // 6. MONTHLY SUMMARY CARD
                    _buildMonthlySummaryCard(
                      monthName: currentMonthName,
                      income: monthIncome,
                      expenses: monthExpenses,
                      saved: monthSavings,
                      colors: colors,
                    ),
                    const SizedBox(height: 20),

                    // 7. BUDGET STATUS CARD
                    _buildBudgetSummaryCard(budgetSummary, colors),
                    const SizedBox(height: 24),

                    // 8. RECENT TRANSACTIONS
                    _buildRecentTransactionsSection(colors),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard(double balance, MoneyColors colors) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Balance',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'All Time',
                  style: TextStyle(
                    color: colors.primaryAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatCurrency(balance),
            style: TextStyle(
              color: balance >= 0 ? colors.textPrimary : colors.error,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required double income,
    required double expenses,
    required double savings,
    required MoneyColors colors,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryMetric(
            label: 'Income',
            amount: income,
            color: colors.income,
            icon: Icons.arrow_downward,
            colors: colors,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryMetric(
            label: 'Expenses',
            amount: expenses,
            color: colors.expense,
            icon: Icons.arrow_upward,
            colors: colors,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryMetric(
            label: 'Savings',
            amount: savings,
            color: colors.savings,
            icon: Icons.savings_outlined,
            colors: colors,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
    required MoneyColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              Text(
                label,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatCurrency(amount),
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCard({
    required String monthName,
    required double income,
    required double expenses,
    required double saved,
    required MoneyColors colors,
  }) {
    return InkWell(
      key: const Key('dashboard_monthly_summary_card'),
      onTap: _openMonthlyView,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                  'Monthly Summary',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      monthName,
                      style: TextStyle(
                        color: colors.secondaryAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: colors.secondaryAccent,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMonthlyColumn('Income', income, colors.income, colors),
                _buildMonthlyColumn('Expenses', expenses, colors.expense, colors),
                _buildMonthlyColumn('Saved', saved, colors.savings, colors),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyColumn(
    String label,
    double amount,
    Color valueColor,
    MoneyColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            color: valueColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSummaryCard(MonthlyBudgetSummary summary, MoneyColors colors) {
    if (summary.budgetCount == 0) {
      return Container(
        key: const Key('dashboard_budget_empty_card'),
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
                Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 18,
                  color: colors.primaryAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Budget Status',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'No budgets set for this month',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              key: const Key('dashboard_set_budget_button'),
              onPressed: _openBudgets,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Set Budget', style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryAccent,
                side: BorderSide(color: colors.primaryAccent.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      );
    }

    final isOver = summary.isOverBudget;
    final progressColor = isOver
        ? colors.expense
        : (summary.progress >= 0.8 ? colors.warning : colors.primaryAccent);

    return InkWell(
      key: const Key('dashboard_budget_summary_card'),
      onTap: _openBudgets,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOver
                ? colors.expense.withValues(alpha: 0.5)
                : colors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 18,
                      color: colors.primaryAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Budget Status',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOver
                        ? colors.expense.withValues(alpha: 0.15)
                        : colors.income.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOver ? 'Over Budget' : 'On Track',
                    style: TextStyle(
                      color: isOver ? colors.expense : colors.income,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                        _formatCurrency(summary.totalBudget),
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
                          _formatCurrency(summary.totalSpent),
                          style: TextStyle(
                            color: isOver ? colors.expense : colors.textPrimary,
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
                          _formatCurrency(summary.remaining),
                          style: TextStyle(
                            color: summary.remaining < 0
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
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: summary.clampedProgress,
                backgroundColor: colors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${summary.budgetCount} ${summary.budgetCount == 1 ? 'category' : 'categories'} budgeted',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
                Text(
                  '${summary.percentage.round()}% used',
                  style: TextStyle(
                    color: progressColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection(MoneyColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_transactions.isNotEmpty)
              InkWell(
                key: const Key('dashboard_view_all_button'),
                onTap: _openTransactions,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'View All',
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
        const SizedBox(height: 12),

        if (_transactions.isEmpty)
          _buildEmptyState(colors)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _transactions.take(10).length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final t = _transactions[index];
              return _buildTransactionTile(t, colors);
            },
          ),
      ],
    );
  }

  Widget _buildTransactionTile(MoneyTransaction t, MoneyColors colors) {
    final isIncome = t.type.isIncome;
    final amountColor = isIncome ? colors.income : colors.expense;
    final sign = isIncome ? '+' : '-';

    return InkWell(
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
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
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
                  '$sign${_formatCurrency(t.amount)}',
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
                      _formatDate(t.date),
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
  }

  Widget _buildEmptyState(MoneyColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: colors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + Add Transaction to record your first income or expense.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoneyNavigation(MoneyColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(Icons.explore_outlined, size: 16, color: colors.primaryAccent),
              const SizedBox(width: 6),
              Text(
                'Explore Money',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildNavTile(
                  key: const Key('dashboard_transactions_button'),
                  icon: Icons.receipt_long_rounded,
                  label: 'Transactions',
                  colors: colors,
                  onTap: _openTransactions,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNavTile(
                  key: const Key('dashboard_statistics_button'),
                  icon: Icons.bar_chart_rounded,
                  label: 'Statistics',
                  colors: colors,
                  onTap: _openStatistics,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNavTile(
                  key: const Key('dashboard_monthly_view_button'),
                  icon: Icons.calendar_month_rounded,
                  label: 'Monthly View',
                  colors: colors,
                  onTap: _openMonthlyView,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildNavTile(
                  key: const Key('dashboard_budgets_button'),
                  icon: Icons.pie_chart_outline_rounded,
                  label: 'Budgets',
                  colors: colors,
                  onTap: _openBudgets,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNavTile(
                  key: const Key('dashboard_categories_button'),
                  icon: Icons.category_outlined,
                  label: 'Categories',
                  colors: colors,
                  onTap: _openCategories,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNavTile(
                  key: const Key('dashboard_recurring_button'),
                  icon: Icons.repeat_rounded,
                  label: 'Recurring',
                  colors: colors,
                  onTap: _openRecurring,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile({
    required Key key,
    required IconData icon,
    required String label,
    required MoneyColors colors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: colors.primaryAccent),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
