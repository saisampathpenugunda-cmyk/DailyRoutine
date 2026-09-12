import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/money_theme.dart';
import '../utils/money_formatter.dart';

/// Side-by-side comparative visual chart for total Income vs Expenses.
class IncomeExpenseComparisonChart extends StatelessWidget {
  final double income;
  final double expenses;

  const IncomeExpenseComparisonChart({
    super.key,
    required this.income,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MoneyTheme.of(context);
    final hasData = income > 0 || expenses > 0;
    final total = income + expenses;
    final incomePct = total > 0 ? (income / total) * 100 : 0.0;
    final expensePct = total > 0 ? (expenses / total) * 100 : 0.0;

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
                'Income vs Expenses',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasData)
                Text(
                  'Total: ${MoneyFormatter.format(total)}',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (!hasData)
            Container(
              height: 120,
              alignment: Alignment.center,
              child: Text(
                'No data for this period',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else ...[
            // Side-by-side comparative bars
            SizedBox(
              height: 170,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _buildBarColumn(
                      context: context,
                      label: 'Income',
                      amount: income,
                      percentage: incomePct,
                      color: colors.income,
                      maxAmount: math.max(income, expenses),
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildBarColumn(
                      context: context,
                      label: 'Expenses',
                      amount: expenses,
                      percentage: expensePct,
                      color: colors.expense,
                      maxAmount: math.max(income, expenses),
                      colors: colors,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Proportional Ratio Indicator Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (income > 0)
                      Expanded(
                        flex: (incomePct * 10).round().clamp(1, 1000),
                        child: Container(color: colors.income),
                      ),
                    if (expenses > 0)
                      Expanded(
                        flex: (expensePct * 10).round().clamp(1, 1000),
                        child: Container(color: colors.expense),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBarColumn({
    required BuildContext context,
    required String label,
    required double amount,
    required double percentage,
    required Color color,
    required double maxAmount,
    required MoneyColors colors,
  }) {
    // Determine bar height ratio relative to maxAmount (minimum 6px for non-zero)
    final ratio = maxAmount > 0 ? (amount / maxAmount) : 0.0;
    const maxBarHeight = 80.0;
    final barHeight = amount > 0 ? math.max(8.0, ratio * maxBarHeight) : 4.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Numeric value formatted via MoneyFormatter
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            MoneyFormatter.format(amount),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Percentage badge
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // Visual Bar
        Container(
          height: barHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Label
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
