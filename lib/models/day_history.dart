import 'activity.dart';

/// Represents a historical snapshot of all activities and completions for a given calendar day.
class DayHistory {
  final String dateKey; // Format: YYYY-MM-DD
  final List<Activity> activities;
  final DateTime recordedAt;

  const DayHistory({
    required this.dateKey,
    required this.activities,
    required this.recordedAt,
  });

  int get completedCount => activities.where((a) => a.isCompleted).length;
  int get skippedCount => activities.where((a) => a.isSkipped).length;
  int get totalCount => activities.length;

  double get completionRate {
    if (totalCount == 0) return 0.0;
    return completedCount / totalCount;
  }

  bool get isAllCompleted => totalCount > 0 && completedCount == totalCount;

  /// Returns a clean human-readable date display.
  String get displayTitle {
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final date = DateTime(year, month, day);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = DateTime(now.year, now.month, now.day - 1);

        if (date.year == today.year && date.month == today.month && date.day == today.day) {
          return 'Today';
        }
        if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
          return 'Yesterday';
        }

        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final monthName = months[month - 1];
        final weekday = weekdays[date.weekday - 1];
        return '$weekday, $monthName $day';
      }
    } catch (_) {}
    return dateKey;
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'recordedAt': recordedAt.toIso8601String(),
      'activities': activities.map((a) => a.toJson()).toList(),
    };
  }

  factory DayHistory.fromJson(Map<String, dynamic> json) {
    final rawActivities = json['activities'];
    final List<Activity> loadedActivities = [];
    if (rawActivities is List) {
      for (final item in rawActivities) {
        if (item is Map) {
          try {
            loadedActivities.add(Activity.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
    }

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['recordedAt']?.toString() ?? '');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return DayHistory(
      dateKey: json['dateKey']?.toString() ?? '',
      activities: loadedActivities,
      recordedAt: parsedDate,
    );
  }
}
