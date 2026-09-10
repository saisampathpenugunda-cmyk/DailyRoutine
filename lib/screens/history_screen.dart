import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../models/day_history.dart';
import '../repositories/activity_repository.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  final ActivityRepository repository;

  const HistoryScreen({
    super.key,
    required this.repository,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late List<DayHistory> _history;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _history = widget.repository.getHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.barBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: colors.border,
                    width: AppTheme.borderWidth,
                  ),
                ),
                child: Icon(
                  Icons.history_toggle_off,
                  size: 32,
                  color: colors.secondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No History Recorded Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textMain,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Complete your routines today. All past data will be archived and viewable here across days.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final day = _history[index];
        return _DayHistoryCard(day: day);
      },
    );
  }
}

class _DayHistoryCard extends StatelessWidget {
  final DayHistory day;

  const _DayHistoryCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final is100Percent = day.isAllCompleted;
    final badgeColor = is100Percent ? colors.completed : colors.skipped;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: colors.border,
          width: AppTheme.borderWidth,
        ),
        boxShadow: isDark ? null : AppTheme.lightCardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: colors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      day.displayTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textMain,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${day.completedCount}/${day.totalCount} DONE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: 8),
            ...day.enabledActivities.map((activity) => _ActivityHistoryRow(activity: activity)),
          ],
        ),
      ),
    );
  }
}

class _ActivityHistoryRow extends StatelessWidget {
  final Activity activity;

  const _ActivityHistoryRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusColor = activity.isCompleted
        ? colors.completed
        : activity.isSkipped
            ? colors.skipped
            : colors.secondary;

    final statusIcon = activity.isCompleted
        ? Icons.check_circle
        : activity.isSkipped
            ? Icons.cancel
            : Icons.radio_button_unchecked;

    String details = activity.formattedDuration;
    if (activity.activityType == ActivityType.dumbbells && activity.completedSetsReps.isNotEmpty) {
      details = 'Sets: ${activity.completedSetsReps.join(', ')} reps';
    } else if (activity.actualDuration > Duration.zero && !activity.isCompleted) {
      details = 'Done: ${activity.formattedActualDuration} of ${activity.formattedDuration}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          // Circular activity icon container
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.highlight,
              shape: BoxShape.circle,
              border: Border.all(
                color: activity.isCompleted
                    ? colors.completed.withValues(alpha: 0.25)
                    : colors.border,
                width: 1,
              ),
            ),
            child: Icon(
              activity.activityType.icon,
              size: 16,
              color: activity.isCompleted
                  ? colors.completed
                  : activity.isSkipped
                      ? colors.skipped
                      : colors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: activity.isCompleted
                        ? colors.completed
                        : activity.isSkipped
                            ? colors.textSecondary
                            : colors.textMain,
                  ),
                ),
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Icon(statusIcon, size: 18, color: statusColor),
        ],
      ),
    );
  }
}
