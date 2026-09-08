import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/models/day_history.dart';

void main() {
  group('DayHistory Model Tests', () {
    test('Calculates completedCount and completionRate correctly', () {
      final activities = [
        const Activity(
          id: '1',
          name: 'Meditation',
          activityType: ActivityType.meditation,
          defaultDuration: Duration(minutes: 10),
          isCompleted: true,
        ),
        const Activity(
          id: '2',
          name: 'Walking',
          activityType: ActivityType.walking,
          defaultDuration: Duration(minutes: 30),
          isCompleted: false,
          isSkipped: true,
        ),
        const Activity(
          id: '3',
          name: 'Dumbbells',
          activityType: ActivityType.dumbbells,
          defaultDuration: Duration(minutes: 20),
          isCompleted: true,
          completedSetsReps: [10, 10, 10],
        ),
      ];

      final history = DayHistory(
        dateKey: '2026-09-07',
        recordedAt: DateTime(2026, 9, 7, 23, 59),
        activities: activities,
      );

      expect(history.totalCount, 3);
      expect(history.completedCount, 2);
      expect(history.isAllCompleted, isFalse);
      expect(history.completionRate, closeTo(2 / 3, 0.001));
    });

    test('isAllCompleted is true when all activities are completed', () {
      final activities = [
        const Activity(
          id: '1',
          name: 'Meditation',
          activityType: ActivityType.meditation,
          defaultDuration: Duration(minutes: 10),
          isCompleted: true,
        ),
      ];

      final history = DayHistory(
        dateKey: '2026-09-07',
        recordedAt: DateTime(2026, 9, 7),
        activities: activities,
      );

      expect(history.isAllCompleted, isTrue);
      expect(history.completionRate, 1.0);
    });

    test('toJson and fromJson round-trip accurately', () {
      final original = DayHistory(
        dateKey: '2026-09-06',
        recordedAt: DateTime(2026, 9, 6, 22, 30),
        activities: [
          const Activity(
            id: 'walk',
            name: 'Walking',
            activityType: ActivityType.walking,
            defaultDuration: Duration(minutes: 45),
            isCompleted: true,
          ),
          const Activity(
            id: 'dumbbells',
            name: 'Dumbbells',
            activityType: ActivityType.dumbbells,
            defaultDuration: Duration(minutes: 20),
            completedSetsReps: [15, 12, 10],
          ),
        ],
      );

      final json = original.toJson();
      final restored = DayHistory.fromJson(json);

      expect(restored.dateKey, original.dateKey);
      expect(restored.recordedAt, original.recordedAt);
      expect(restored.activities.length, 2);
      expect(restored.activities[0].name, 'Walking');
      expect(restored.activities[0].isCompleted, isTrue);
      expect(restored.activities[1].completedSetsReps, [15, 12, 10]);
    });

    test('displayTitle handles Today, Yesterday and formatted dates', () {
      final now = DateTime.now();
      final todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final todayHistory = DayHistory(
        dateKey: todayKey,
        recordedAt: now,
        activities: [],
      );
      expect(todayHistory.displayTitle, 'Today');

      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayKey =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      final yesterdayHistory = DayHistory(
        dateKey: yesterdayKey,
        recordedAt: yesterday,
        activities: [],
      );
      expect(yesterdayHistory.displayTitle, 'Yesterday');

      final pastHistory = DayHistory(
        dateKey: '2025-01-15',
        recordedAt: DateTime(2025, 1, 15),
        activities: [],
      );
      expect(pastHistory.displayTitle, contains('Jan 15'));
    });
  });
}
