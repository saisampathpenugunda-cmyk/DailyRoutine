import '../models/activity.dart';
import '../models/day_history.dart';
import '../models/progress_statistics.dart';

class ProgressCalculator {
  static String formatDateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String weekdayShort(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (weekday >= 1 && weekday <= 7) {
      return days[weekday - 1];
    }
    return '';
  }

  /// Calculates progress metrics for the selected [period].
  ///
  /// Combines [history] and [todayActivities] so today's live progress is always
  /// reflected immediately. Accepts an optional [now] timestamp for deterministic testing.
  static ProgressStatistics calculate({
    required List<DayHistory> history,
    required List<Activity> todayActivities,
    required ProgressPeriod period,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final todayKey = formatDateKey(today);

    // Build unified map of recorded days (today + past history)
    final Map<String, DayHistory> historyMap = {};
    for (final day in history) {
      historyMap[day.dateKey] = day;
    }
    // Always use today's live activities as the source of truth for today
    historyMap[todayKey] = DayHistory(
      dateKey: todayKey,
      activities: List.unmodifiable(todayActivities),
      recordedAt: current,
    );

    switch (period) {
      case ProgressPeriod.day:
        return _calculateDay(today, historyMap);
      case ProgressPeriod.week:
        return _calculateWeek(today, historyMap);
      case ProgressPeriod.month:
        return _calculateMonth(today, historyMap);
    }
  }

  static ProgressStatistics _calculateDay(
    DateTime today,
    Map<String, DayHistory> historyMap,
  ) {
    final todayKey = formatDateKey(today);
    final todayRecord = historyMap[todayKey];
    final List<DayHistory> records = todayRecord != null ? [todayRecord] : [];

    final dailyPoints = [
      DailyProgressPoint(
        dateKey: todayKey,
        date: today,
        shortLabel: 'Today',
        completedCount: todayRecord?.completedCount ?? 0,
        totalCount: todayRecord?.totalCount ?? 0,
        isRecorded: todayRecord != null && todayRecord.totalCount > 0,
      ),
    ];

    return _aggregate(
      period: ProgressPeriod.day,
      startDate: today,
      endDate: today,
      records: records,
      dailyPoints: dailyPoints,
      isMonth: false,
    );
  }

  static ProgressStatistics _calculateWeek(
    DateTime today,
    Map<String, DayHistory> historyMap,
  ) {
    // 7-day rolling window: 6 days ago up to today
    final startDate = today.subtract(const Duration(days: 6));
    final endDate = today;

    final List<DayHistory> records = [];
    final List<DailyProgressPoint> dailyPoints = [];

    for (int i = 0; i < 7; i++) {
      final dayDate = startDate.add(Duration(days: i));
      final key = formatDateKey(dayDate);
      final record = historyMap[key];

      final bool isRecorded = record != null && record.totalCount > 0;
      if (isRecorded) {
        records.add(record);
      }

      dailyPoints.add(
        DailyProgressPoint(
          dateKey: key,
          date: dayDate,
          shortLabel: weekdayShort(dayDate.weekday),
          completedCount: record?.completedCount ?? 0,
          totalCount: record?.totalCount ?? 0,
          isRecorded: isRecorded,
        ),
      );
    }

    return _aggregate(
      period: ProgressPeriod.week,
      startDate: startDate,
      endDate: endDate,
      records: records,
      dailyPoints: dailyPoints,
      isMonth: false,
    );
  }

  static ProgressStatistics _calculateMonth(
    DateTime today,
    Map<String, DayHistory> historyMap,
  ) {
    final startDate = DateTime(today.year, today.month, 1);
    final endDate = today;

    final List<DayHistory> records = [];
    final List<DailyProgressPoint> dailyPoints = [];

    // From 1st of month up to today
    final daysInWindow = today.day;
    for (int i = 0; i < daysInWindow; i++) {
      final dayDate = startDate.add(Duration(days: i));
      final key = formatDateKey(dayDate);
      final record = historyMap[key];

      final bool isRecorded = record != null && record.totalCount > 0;
      if (isRecorded) {
        records.add(record);
      }

      dailyPoints.add(
        DailyProgressPoint(
          dateKey: key,
          date: dayDate,
          shortLabel: '${dayDate.day}',
          completedCount: record?.completedCount ?? 0,
          totalCount: record?.totalCount ?? 0,
          isRecorded: isRecorded,
        ),
      );
    }

    return _aggregate(
      period: ProgressPeriod.month,
      startDate: startDate,
      endDate: endDate,
      records: records,
      dailyPoints: dailyPoints,
      isMonth: true,
    );
  }

  static ProgressStatistics _aggregate({
    required ProgressPeriod period,
    required DateTime startDate,
    required DateTime endDate,
    required List<DayHistory> records,
    required List<DailyProgressPoint> dailyPoints,
    required bool isMonth,
  }) {
    int totalActivities = 0;
    int completedCount = 0;
    int skippedCount = 0;
    int missedCount = 0;
    Duration totalDuration = Duration.zero;
    int dumbbellSets = 0;
    int dumbbellReps = 0;

    for (final day in records) {
      for (final activity in day.enabledActivities) {
        totalActivities++;
        if (activity.isCompleted) {
          completedCount++;
          totalDuration += activity.actualDuration > Duration.zero
              ? activity.actualDuration
              : activity.defaultDuration;
        } else if (activity.actualDuration > Duration.zero) {
          totalDuration += activity.actualDuration;
          if (activity.isSkipped) {
            skippedCount++;
          } else {
            missedCount++;
          }
        } else if (activity.isSkipped) {
          skippedCount++;
        } else {
          missedCount++;
        }

        if (activity.activityType == ActivityType.dumbbells ||
            activity.id == 'dumbbells') {
          dumbbellSets += activity.completedSetsReps.length;
          for (final reps in activity.completedSetsReps) {
            dumbbellReps += reps;
          }
        }
      }
    }

    double? monthlyAccuracy;
    if (isMonth) {
      monthlyAccuracy = totalActivities > 0
          ? ((completedCount / totalActivities) * 100).clamp(0.0, 100.0)
          : 0.0;
    }

    return ProgressStatistics(
      period: period,
      startDate: startDate,
      endDate: endDate,
      totalActivities: totalActivities,
      completedCount: completedCount,
      skippedCount: skippedCount,
      missedCount: missedCount,
      totalWorkoutDuration: totalDuration,
      dumbbellSetsCount: dumbbellSets,
      dumbbellRepsCount: dumbbellReps,
      dailyPoints: dailyPoints,
      recordedDaysCount: records.length,
      monthlyAccuracy: monthlyAccuracy,
    );
  }
}
