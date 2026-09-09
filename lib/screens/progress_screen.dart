import 'package:flutter/material.dart';
import '../models/progress_statistics.dart';
import '../repositories/activity_repository.dart';
import '../services/progress_calculator.dart';
import '../theme/app_theme.dart';
import '../widgets/progress_bar_chart.dart';

class ProgressScreen extends StatefulWidget {
  final ActivityRepository repository;
  final DateTime? testNow;

  const ProgressScreen({
    super.key,
    required this.repository,
    this.testNow,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  ProgressPeriod _selectedPeriod = ProgressPeriod.day;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final history = widget.repository.getHistory();
    final todayActivities = widget.repository.getActivities();

    final stats = ProgressCalculator.calculate(
      history: history,
      todayActivities: todayActivities,
      period: _selectedPeriod,
      now: widget.testNow,
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      children: [
        // ── 1. Period Selector ──────────────────────────────────────────────
        _PeriodSelector(
          selectedPeriod: _selectedPeriod,
          onPeriodChanged: (period) {
            setState(() {
              _selectedPeriod = period;
            });
          },
        ),
        const SizedBox(height: 10),

        // ── Date Range Label ────────────────────────────────────────────────
        Text(
          _getDateRangeLabel(stats),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),

        // ── 2. Completion Statistics Card ───────────────────────────────────
        _CompletionStatsCard(stats: stats),
        const SizedBox(height: 10),

        // ── 3. Visual Graph Card ────────────────────────────────────────────
        _ChartCard(stats: stats),
        const SizedBox(height: 10),

        // ── 4. Workout Statistics Card ──────────────────────────────────────
        _WorkoutStatsCard(stats: stats),
        const SizedBox(height: 10),

        // ── 5. Monthly Final Accuracy (Month View Only) ─────────────────────
        if (_selectedPeriod == ProgressPeriod.month && stats.monthlyAccuracy != null) ...[
          _MonthlyAccuracyCard(stats: stats),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  String _getDateRangeLabel(ProgressStatistics stats) {
    switch (stats.period) {
      case ProgressPeriod.day:
        return 'Today';
      case ProgressPeriod.week:
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final startMonth = months[stats.startDate.month - 1];
        final endMonth = months[stats.endDate.month - 1];
        if (stats.startDate.month == stats.endDate.month) {
          return '$startMonth ${stats.startDate.day} – ${stats.endDate.day}, ${stats.endDate.year}';
        }
        return '$startMonth ${stats.startDate.day} – $endMonth ${stats.endDate.day}, ${stats.endDate.year}';
      case ProgressPeriod.month:
        const fullMonths = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        return '${fullMonths[stats.startDate.month - 1]} ${stats.startDate.year}';
    }
  }
}

class _PeriodSelector extends StatelessWidget {
  final ProgressPeriod selectedPeriod;
  final ValueChanged<ProgressPeriod> onPeriodChanged;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.barBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: colors.border,
          width: AppTheme.borderWidth,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: ProgressPeriod.values.map((period) {
          final isSelected = period == selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => onPeriodChanged(period),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? colors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: isSelected
                      ? Border.all(color: colors.border, width: 1)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  period.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? colors.primary : colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CompletionStatsCard extends StatelessWidget {
  final ProgressStatistics stats;

  const _CompletionStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percent = stats.completionPercentage.toInt();
    final progress = stats.totalActivities > 0
        ? stats.completedCount / stats.totalActivities
        : 0.0;
    final progressColor = percent == 100
        ? colors.completed
        : percent > 0
            ? colors.primary
            : colors.secondary;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: colors.border,
          width: AppTheme.borderWidth,
        ),
        boxShadow: isDark ? null : AppTheme.lightCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completion Rate',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textMain,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: progressColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: progressColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: colors.barBackground,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  label: 'Completed',
                  value: '${stats.completedCount}',
                  color: colors.completed,
                  bgColor: colors.highlight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(
                  label: 'Skipped',
                  value: '${stats.skippedCount}',
                  color: colors.skipped,
                  bgColor: isDark ? colors.card : const Color(0xFFEDF4F7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(
                  label: 'Missed',
                  value: '${stats.missedCount}',
                  color: colors.missed,
                  bgColor: isDark ? colors.card : const Color(0xFFFDF0ED),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color? bgColor;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor ?? color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final ProgressStatistics stats;

  const _ChartCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    String title = 'Activity Distribution';
    Widget chartWidget;

    if (stats.period == ProgressPeriod.day) {
      title = "Today's Distribution";
      chartWidget = DayActivityBreakdownBar(
        completedCount: stats.completedCount,
        skippedCount: stats.skippedCount,
        missedCount: stats.missedCount,
      );
    } else if (stats.period == ProgressPeriod.week) {
      title = '7-Day Completion Trend';
      chartWidget = WeekProgressBarChart(points: stats.dailyPoints);
    } else {
      title = 'Daily Completion This Month';
      chartWidget = MonthDayProgressBarChart(points: stats.dailyPoints);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: colors.border,
          width: AppTheme.borderWidth,
        ),
        boxShadow: isDark ? null : AppTheme.lightCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textMain,
            ),
          ),
          const SizedBox(height: 14),
          chartWidget,
        ],
      ),
    );
  }
}

class _WorkoutStatsCard extends StatelessWidget {
  final ProgressStatistics stats;

  const _WorkoutStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: colors.border,
          width: AppTheme.borderWidth,
        ),
        boxShadow: isDark ? null : AppTheme.lightCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workout Metrics',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            icon: Icons.timer_outlined,
            iconColor: colors.primary,
            label: 'Total Workout Duration',
            value: stats.formattedDuration,
          ),
          const SizedBox(height: 9),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: 9),
          _MetricRow(
            icon: Icons.fitness_center_outlined,
            iconColor: colors.completed,
            label: 'Dumbbell Sets Completed',
            value: '${stats.dumbbellSetsCount} sets',
          ),
          const SizedBox(height: 9),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: 9),
          _MetricRow(
            icon: Icons.repeat_outlined,
            iconColor: colors.skipped,
            label: 'Dumbbell Reps Completed',
            value: '${stats.dumbbellRepsCount} reps',
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _MetricRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colors.textMain,
          ),
        ),
      ],
    );
  }
}

class _MonthlyAccuracyCard extends StatelessWidget {
  final ProgressStatistics stats;

  const _MonthlyAccuracyCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accuracy = stats.monthlyAccuracy?.toInt() ?? 0;
    final color = accuracy >= 80
        ? colors.completed
        : accuracy >= 50
            ? colors.primary
            : colors.skipped;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: AppTheme.borderWidth,
        ),
        boxShadow: isDark ? null : AppTheme.lightCardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_outlined, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Accuracy',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textMain,
                      ),
                    ),
                    Text(
                      '$accuracy%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on ${stats.recordedDaysCount} recorded day${stats.recordedDaysCount == 1 ? '' : 's'} (${stats.completedCount} of ${stats.totalActivities} activities done)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
