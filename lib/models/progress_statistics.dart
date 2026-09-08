enum ProgressPeriod {
  day,
  week,
  month;

  String get displayName {
    switch (this) {
      case ProgressPeriod.day:
        return 'Day';
      case ProgressPeriod.week:
        return 'Week';
      case ProgressPeriod.month:
        return 'Month';
    }
  }
}

/// Represents a single day data point for charts and timelines.
class DailyProgressPoint {
  final String dateKey;
  final DateTime date;
  final String shortLabel;
  final int completedCount;
  final int totalCount;
  final bool isRecorded;

  const DailyProgressPoint({
    required this.dateKey,
    required this.date,
    required this.shortLabel,
    required this.completedCount,
    required this.totalCount,
    required this.isRecorded,
  });

  double get completionRate {
    if (!isRecorded || totalCount == 0) return 0.0;
    return (completedCount / totalCount).clamp(0.0, 1.0);
  }
}

/// Aggregated metrics for a given time window.
class ProgressStatistics {
  final ProgressPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final int totalActivities;
  final int completedCount;
  final int skippedCount;
  final int missedCount;
  final Duration totalWorkoutDuration;
  final int dumbbellSetsCount;
  final int dumbbellRepsCount;
  final List<DailyProgressPoint> dailyPoints;
  final int recordedDaysCount;
  final double? monthlyAccuracy;

  const ProgressStatistics({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.totalActivities,
    required this.completedCount,
    required this.skippedCount,
    required this.missedCount,
    required this.totalWorkoutDuration,
    required this.dumbbellSetsCount,
    required this.dumbbellRepsCount,
    required this.dailyPoints,
    required this.recordedDaysCount,
    this.monthlyAccuracy,
  });

  double get completionPercentage {
    if (totalActivities == 0) return 0.0;
    return ((completedCount / totalActivities) * 100).clamp(0.0, 100.0);
  }

  String get formattedDuration {
    final totalSeconds = totalWorkoutDuration.inSeconds;
    if (totalSeconds == 0) return '0 min';
    final hours = totalWorkoutDuration.inHours;
    final minutes = totalWorkoutDuration.inMinutes % 60;
    if (hours > 0) {
      if (minutes > 0) {
        return '$hours hr $minutes min';
      }
      return '$hours hr';
    }
    return '$minutes min';
  }
}
