import 'activity.dart';
import '../repositories/activity_repository.dart';

/// Represents a single activity's status and progress inside Today's Summary.
class DailySummaryItem {
  final Activity activity;
  final ActivityRecordStatus status;
  final Duration activeDuration;
  final double progress;
  final String metricLabel;
  final String progressLabel;

  const DailySummaryItem({
    required this.activity,
    required this.status,
    required this.activeDuration,
    required this.progress,
    required this.metricLabel,
    required this.progressLabel,
  });
}

/// Aggregated daily summary metrics for today's enabled activities.
class DailySummaryData {
  final double overallCompletion;
  final int completedCount;
  final int partialCount;
  final int skippedCount;
  final int missedCount;
  final Duration totalActiveTime;
  final List<DailySummaryItem> items;

  const DailySummaryData({
    required this.overallCompletion,
    required this.completedCount,
    required this.partialCount,
    required this.skippedCount,
    required this.missedCount,
    required this.totalActiveTime,
    required this.items,
  });

  int get totalCount => items.length;

  int get completionPercentage => (overallCompletion * 100).round().clamp(0, 100);

  String get formattedActiveTime {
    final totalSeconds = totalActiveTime.inSeconds;
    if (totalSeconds == 0) return '0 min';
    final hours = totalActiveTime.inHours;
    final minutes = totalActiveTime.inMinutes % 60;
    if (hours > 0) {
      if (minutes > 0) {
        return '$hours hr $minutes min';
      }
      return '$hours hr';
    }
    if (minutes == 0 && totalSeconds > 0) {
      return '$totalSeconds sec';
    }
    return '$minutes min';
  }

  factory DailySummaryData.empty() {
    return const DailySummaryData(
      overallCompletion: 0.0,
      completedCount: 0,
      partialCount: 0,
      skippedCount: 0,
      missedCount: 0,
      totalActiveTime: Duration.zero,
      items: [],
    );
  }

  /// Computes the Daily Summary from today's activities and repository state.
  /// Strictly excludes disabled activities.
  factory DailySummaryData.compute({
    required List<Activity> activities,
    ActivityRepository? repository,
  }) {
    final enabledActivities = activities.where((a) => a.isEnabled).toList();
    if (enabledActivities.isEmpty) {
      return DailySummaryData.empty();
    }

    int completed = 0;
    int partial = 0;
    int skipped = 0;
    int missed = 0;
    Duration activeTime = Duration.zero;
    double progressSum = 0.0;
    final List<DailySummaryItem> list = [];

    for (final activity in enabledActivities) {
      if (activity.isCompleted) {
        completed++;
        progressSum += 1.0;
        final duration = activity.actualDuration > Duration.zero
            ? activity.actualDuration
            : activity.defaultDuration;
        activeTime += duration;

        String metric = activity.formattedDuration;
        if ((activity.activityType == ActivityType.dumbbells ||
                activity.activityType == ActivityType.workout) &&
            activity.completedSetsReps.isNotEmpty) {
          metric = '${activity.completedSetsReps.length}/3 sets';
        }

        list.add(
          DailySummaryItem(
            activity: activity,
            status: ActivityRecordStatus.completed,
            activeDuration: duration,
            progress: 1.0,
            metricLabel: metric,
            progressLabel: '✓',
          ),
        );
      } else if (activity.isSkipped) {
        skipped++;
        list.add(
          DailySummaryItem(
            activity: activity,
            status: ActivityRecordStatus.skipped,
            activeDuration: Duration.zero,
            progress: 0.0,
            metricLabel: '—',
            progressLabel: '—',
          ),
        );
      } else {
        // Check partial progress
        double p = 0.0;
        if (repository != null) {
          p = repository.getActivityProgress(activity);
        }

        if (p <= 0.0) {
          if ((activity.activityType == ActivityType.dumbbells ||
                  activity.activityType == ActivityType.workout) &&
              activity.completedSetsReps.isNotEmpty) {
            p = (activity.completedSetsReps.length / 3.0).clamp(0.0, 1.0);
          } else if (activity.actualDuration > Duration.zero &&
              activity.defaultDuration > Duration.zero) {
            p = (activity.actualDuration.inSeconds /
                    activity.defaultDuration.inSeconds)
                .clamp(0.0, 1.0);
          }
        }

        if (p > 0.0) {
          partial++;
          progressSum += p;
          Duration actDuration = activity.actualDuration;
          if (actDuration == Duration.zero &&
              (activity.activityType == ActivityType.dumbbells ||
                  activity.activityType == ActivityType.workout) &&
              activity.completedSetsReps.isNotEmpty) {
            actDuration = Duration(
              seconds: (activity.defaultDuration.inSeconds *
                      (activity.completedSetsReps.length / 3.0))
                  .round(),
            );
          }
          activeTime += actDuration;

          String metric;
          if (activity.activityType == ActivityType.dumbbells ||
              activity.activityType == ActivityType.workout) {
            metric = '${activity.completedSetsReps.length}/3 sets';
          } else {
            metric = actDuration > Duration.zero
                ? activity.formattedActualDuration
                : activity.formattedDuration;
          }

          final pct = (p * 100).round().clamp(0, 100);
          list.add(
            DailySummaryItem(
              activity: activity,
              status: ActivityRecordStatus.partial,
              activeDuration: actDuration,
              progress: p,
              metricLabel: metric,
              progressLabel: '$pct%',
            ),
          );
        } else {
          missed++;
          list.add(
            DailySummaryItem(
              activity: activity,
              status: ActivityRecordStatus.missed,
              activeDuration: Duration.zero,
              progress: 0.0,
              metricLabel: '—',
              progressLabel: '✕',
            ),
          );
        }
      }
    }

    final overall = enabledActivities.isNotEmpty
        ? (progressSum / enabledActivities.length).clamp(0.0, 1.0)
        : 0.0;

    return DailySummaryData(
      overallCompletion: overall,
      completedCount: completed,
      partialCount: partial,
      skippedCount: skipped,
      missedCount: missed,
      totalActiveTime: activeTime,
      items: list,
    );
  }
}
