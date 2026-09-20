import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../models/money_savings.dart';
import '../models/money_transaction.dart';
import '../repositories/money_repository.dart';
import '../services/money_calculator.dart';
import '../theme/money_theme.dart';
import '../utils/money_formatter.dart';

/// Screen displaying automatic 5% savings allocations, metrics, and history.
class SavingsScreen extends StatefulWidget {
  final MoneyRepository repository;
  final NotificationService? notificationService;

  const SavingsScreen({
    super.key,
    required this.repository,
    this.notificationService,
  });

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  List<MoneySavings> _savings = [];
  List<MoneyTransaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final savings = await widget.repository.getSavings();
    final transactions = await widget.repository.getTransactions();

    if (!mounted) return;
    setState(() {
      _savings = savings;
      _transactions = transactions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = MoneyTheme.of(context);
    final now = DateTime.now();

    final totalSavings = MoneyCalculator.calculateTotalSavingsAllocations(_savings);
    final monthSavings = MoneyCalculator.calculateMonthlySavingsAllocations(
      _savings,
      year: now.year,
      month: now.month,
    );

    // Sort newest first
    final sortedSavings = List<MoneySavings>.from(_savings)
      ..sort((a, b) {
        final dateCmp = b.date.compareTo(a.date);
        if (dateCmp != 0) return dateCmp;
        return b.createdAt.compareTo(a.createdAt);
      });

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Savings',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          key: const Key('savings_screen_back_button'),
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                children: [
                  // ── Hero Summary Card ──────────────────────────────────────
                  Container(
                    key: const Key('savings_hero_card'),
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.primaryAccent.withValues(alpha: 0.18),
                          colors.card,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colors.primaryAccent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colors.primaryAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.savings_rounded,
                                color: colors.primaryAccent,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL SAVINGS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                    color: colors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '5% Auto-Allocation',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.primaryAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          MoneyFormatter.format(totalSavings),
                          key: const Key('savings_total_amount'),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: colors.border, height: 1),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatColumn(
                              label: 'This Month',
                              value: MoneyFormatter.format(monthSavings),
                              valueKey: const Key('savings_month_amount'),
                              colors: colors,
                            ),
                            _buildStatColumn(
                              label: 'Savings Rate',
                              value: '5%',
                              valueKey: const Key('savings_rate_text'),
                              colors: colors,
                            ),
                            _buildStatColumn(
                              label: 'Allocations',
                              value: '${_savings.length}',
                              valueKey: const Key('savings_allocations_count'),
                              colors: colors,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Explanatory Note ───────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '5% of every recorded income is automatically allocated to your savings repository to help grow your emergency fund.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Section Header ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SAVINGS HISTORY',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: colors.textSecondary,
                        ),
                      ),
                      if (sortedSavings.isNotEmpty)
                        Text(
                          '${sortedSavings.length} total',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── History List / Empty State ─────────────────────────────
                  if (sortedSavings.isEmpty)
                    Container(
                      key: const Key('savings_empty_state'),
                      padding: const EdgeInsets.all(32.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.savings_outlined,
                            size: 48,
                            color: colors.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No automatic savings yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add an income transaction to automatically save 5%.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedSavings.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = sortedSavings[index];
                        final sourceTx = _transactions.cast<MoneyTransaction?>().firstWhere(
                              (t) => t?.id == item.sourceTransactionId,
                              orElse: () => null,
                            );
                        final categoryName = sourceTx?.category ?? 'Income';

                        return Container(
                          key: Key('savings_item_${item.id}'),
                          padding: const EdgeInsets.all(14.0),
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
                                  color: colors.income.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.savings_rounded,
                                  color: colors.income,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      categoryName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'From ${MoneyFormatter.format(item.incomeAmount)} income • ${MoneyFormatter.formatDate(item.date)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '+${MoneyFormatter.format(item.savingsAmount)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: colors.income,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '5% saved',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required Key valueKey,
    required MoneyColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          key: valueKey,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
