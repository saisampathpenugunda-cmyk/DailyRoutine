import 'package:flutter/material.dart';
import '../models/progress_statistics.dart';
import '../theme/app_theme.dart';

/// Renders a horizontal segmented distribution bar for Day view.
class DayActivityBreakdownBar extends StatelessWidget {
  final int completedCount;
  final int skippedCount;
  final int missedCount;

  const DayActivityBreakdownBar({
    super.key,
    required this.completedCount,
    required this.skippedCount,
    required this.missedCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final total = completedCount + skippedCount + missedCount;

    if (total == 0) {
      return Container(
        height: 16,
        decoration: BoxDecoration(
          color: colors.barBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: colors.border, width: 1),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          child: SizedBox(
            height: 16,
            child: Row(
              children: [
                if (completedCount > 0)
                  Expanded(
                    flex: completedCount,
                    child: Container(color: colors.completed),
                  ),
                if (skippedCount > 0)
                  Expanded(
                    flex: skippedCount,
                    child: Container(color: colors.skipped),
                  ),
                if (missedCount > 0)
                  Expanded(
                    flex: missedCount,
                    child: Container(color: colors.secondary.withValues(alpha: 0.3)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _LegendItem(
              color: colors.completed,
              label: 'Done ($completedCount)',
            ),
            _LegendItem(
              color: colors.skipped,
              label: 'Skipped ($skippedCount)',
            ),
            _LegendItem(
              color: colors.secondary,
              label: 'Missed/Pending ($missedCount)',
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Renders a 7-day vertical bar chart for Week view.
class WeekProgressBarChart extends StatelessWidget {
  final List<DailyProgressPoint> points;

  const WeekProgressBarChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: points.map((point) {
        final rate = point.completionRate;
        final hasRecord = point.isRecorded;
        final barHeight = hasRecord ? (rate * 80).clamp(4.0, 80.0) : 0.0;
        final barColor = rate >= 1.0
            ? colors.completed
            : rate > 0
                ? colors.primary
                : colors.secondary.withValues(alpha: 0.3);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasRecord ? '${(rate * 100).toInt()}%' : '—',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: hasRecord && rate > 0 ? colors.textMain : colors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 28,
              height: 80,
              decoration: BoxDecoration(
                color: colors.barBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: colors.border,
                  width: AppTheme.borderWidth,
                ),
              ),
              alignment: Alignment.bottomCenter,
              child: hasRecord && barHeight > 0
                  ? Container(
                      width: 28,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall - 1),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              point.shortLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textMain,
              ),
            ),
            Text(
              '${point.date.day}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// Renders a horizontal scrollable day-by-day bar chart for Month view.
class MonthDayProgressBarChart extends StatelessWidget {
  final List<DailyProgressPoint> points;

  const MonthDayProgressBarChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (points.isEmpty) {
      return Center(
        child: Text(
          'No data for this month',
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((point) {
          final rate = point.completionRate;
          final hasRecord = point.isRecorded;
          final barHeight = hasRecord ? (rate * 64).clamp(4.0, 64.0) : 0.0;
          final barColor = rate >= 1.0
              ? colors.completed
              : rate > 0
                  ? colors.primary
                  : colors.secondary.withValues(alpha: 0.3);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasRecord ? '${(rate * 100).toInt()}%' : '—',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: hasRecord && rate > 0 ? colors.textMain : colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 22,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.barBackground,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: colors.border,
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.bottomCenter,
                  child: hasRecord && barHeight > 0
                      ? Container(
                          width: 22,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall - 1),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  point.shortLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.textMain,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
