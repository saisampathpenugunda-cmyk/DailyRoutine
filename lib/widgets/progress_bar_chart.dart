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
    final total = completedCount + skippedCount + missedCount;

    if (total == 0) {
      return Container(
        height: 16,
        decoration: BoxDecoration(
          color: AppTheme.slate100,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: AppTheme.slate200, width: 1),
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
                    child: Container(color: AppTheme.emeraldGreen),
                  ),
                if (skippedCount > 0)
                  Expanded(
                    flex: skippedCount,
                    child: Container(color: AppTheme.amberWarning),
                  ),
                if (missedCount > 0)
                  Expanded(
                    flex: missedCount,
                    child: Container(color: AppTheme.slate300),
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
              color: AppTheme.emeraldGreen,
              label: 'Done ($completedCount)',
            ),
            _LegendItem(
              color: AppTheme.amberWarning,
              label: 'Skipped ($skippedCount)',
            ),
            _LegendItem(
              color: AppTheme.slate400,
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.slate700,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: points.map((point) {
        final rate = point.completionRate;
        final hasRecord = point.isRecorded;
        final barHeight = hasRecord ? (rate * 80).clamp(4.0, 80.0) : 0.0;
        final barColor = rate >= 1.0
            ? AppTheme.emeraldGreen
            : rate > 0
                ? AppTheme.cobaltBlue
                : AppTheme.slate300;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasRecord ? '${(rate * 100).toInt()}%' : '—',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: hasRecord && rate > 0 ? AppTheme.slate900 : AppTheme.slate400,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 28,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.slate100,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: AppTheme.slate200,
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
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.slate700,
              ),
            ),
            Text(
              '${point.date.day}',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.slate400,
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
    if (points.isEmpty) {
      return const Center(
        child: Text(
          'No data for this month',
          style: TextStyle(fontSize: 13, color: AppTheme.slate400),
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
              ? AppTheme.emeraldGreen
              : rate > 0
                  ? AppTheme.cobaltBlue
                  : AppTheme.slate300;

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
                    color: hasRecord && rate > 0 ? AppTheme.slate900 : AppTheme.slate400,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 22,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.slate100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: AppTheme.slate200,
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
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.slate700,
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
