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
        const SizedBox(height: 12),

        // ── Date Range Label ────────────────────────────────────────────────
        Text(
          _getDateRangeLabel(stats),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.slate500,
          ),
        ),
        const SizedBox(height: 12),

        // ── 2. Completion Statistics Card ───────────────────────────────────
        _CompletionStatsCard(stats: stats),
        const SizedBox(height: 12),

        // ── 3. Visual Graph Card ────────────────────────────────────────────
        _ChartCard(stats: stats),
        const SizedBox(height: 12),

        // ── 4. Workout Statistics Card ──────────────────────────────────────
        _WorkoutStatsCard(stats: stats),
        const SizedBox(height: 12),

        // ── 5. Monthly Final Accuracy (Month View Only) ─────────────────────
        if (_selectedPeriod == ProgressPeriod.month && stats.monthlyAccuracy != null) ...[
          _MonthlyAccuracyCard(stats: stats),
          const SizedBox(height: 12),
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.slate100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.slate200,
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
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: isSelected
                      ? Border.all(color: AppTheme.slate300, width: 1)
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
                    color: isSelected ? AppTheme.cobaltBlue : AppTheme.slate600,
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
    final percent = stats.completionPercentage.toInt();
    final progress = stats.totalActivities > 0
        ? stats.completedCount / stats.totalActivities
        : 0.0;
    final progressColor = percent == 100
        ? AppTheme.emeraldGreen
        : percent > 0
            ? AppTheme.cobaltBlue
            : AppTheme.slate400;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.slate200,
          width: AppTheme.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Completion Rate',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate900,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: progressColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 14,
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
              minHeight: 8,
              backgroundColor: AppTheme.slate100,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  label: 'Completed',
                  value: '${stats.completedCount}',
                  color: AppTheme.emeraldGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(
                  label: 'Skipped',
                  value: '${stats.skippedCount}',
                  color: AppTheme.amberWarning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(
                  label: 'Missed',
                  value: '${stats.missedCount}',
                  color: AppTheme.slate500,
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

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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
              fontWeight: FontWeight.w700,
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

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.slate200,
          width: AppTheme.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate900,
            ),
          ),
          const SizedBox(height: 16),
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
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.slate200,
          width: AppTheme.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Workout Metrics',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate900,
            ),
          ),
          const SizedBox(height: 14),
          _MetricRow(
            icon: Icons.timer_outlined,
            iconColor: AppTheme.cobaltBlue,
            label: 'Total Workout Duration',
            value: stats.formattedDuration,
          ),
          const SizedBox(height: 10),
          const Divider(color: AppTheme.slate200, height: 1),
          const SizedBox(height: 10),
          _MetricRow(
            icon: Icons.fitness_center_outlined,
            iconColor: AppTheme.emeraldGreen,
            label: 'Dumbbell Sets Completed',
            value: '${stats.dumbbellSetsCount} sets',
          ),
          const SizedBox(height: 10),
          const Divider(color: AppTheme.slate200, height: 1),
          const SizedBox(height: 10),
          _MetricRow(
            icon: Icons.repeat_outlined,
            iconColor: AppTheme.amberWarning,
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.slate700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.slate900,
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
    final accuracy = stats.monthlyAccuracy?.toInt() ?? 0;
    final color = accuracy >= 80
        ? AppTheme.emeraldGreen
        : accuracy >= 50
            ? AppTheme.cobaltBlue
            : AppTheme.amberWarning;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: AppTheme.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(Icons.verified_outlined, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Monthly Accuracy',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slate900,
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.slate500,
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
