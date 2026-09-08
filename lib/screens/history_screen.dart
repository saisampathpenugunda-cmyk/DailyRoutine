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
                  color: AppTheme.slate100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: AppTheme.slate200,
                    width: AppTheme.borderWidth,
                  ),
                ),
                child: const Icon(
                  Icons.history_toggle_off,
                  size: 32,
                  color: AppTheme.slate500,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No History Recorded Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Complete your routines today. All past data will be archived and viewable here across days.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.slate500,
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
    final is100Percent = day.isAllCompleted;
    final badgeColor = is100Percent ? AppTheme.emeraldGreen : AppTheme.amberWarning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.slate200,
          width: AppTheme.borderWidth,
        ),
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
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppTheme.slate700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      day.displayTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slate900,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.3),
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
            const SizedBox(height: 12),
            const Divider(color: AppTheme.slate200, height: 1),
            const SizedBox(height: 10),
            ...day.activities.map((activity) => _ActivityHistoryRow(activity: activity)),
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
    final statusColor = activity.isCompleted
        ? AppTheme.emeraldGreen
        : activity.isSkipped
            ? AppTheme.crimsonRed
            : AppTheme.slate400;

    final statusIcon = activity.isCompleted
        ? Icons.check_circle
        : activity.isSkipped
            ? Icons.cancel
            : Icons.radio_button_unchecked;

    String details = activity.formattedDuration;
    if (activity.activityType == ActivityType.dumbbells && activity.completedSetsReps.isNotEmpty) {
      details = 'Sets: ${activity.completedSetsReps.join(', ')} reps';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              activity.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: activity.isCompleted || activity.isSkipped
                    ? AppTheme.slate900
                    : AppTheme.slate500,
              ),
            ),
          ),
          Text(
            details,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.slate500,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
