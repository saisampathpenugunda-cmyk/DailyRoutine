import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/models/day_history.dart';
import 'package:daily_routine/models/progress_statistics.dart';
import 'package:daily_routine/services/progress_calculator.dart';

void main() {
  group('ProgressCalculator Unit Tests', () {
    final testNow = DateTime(2026, 9, 7, 10, 0); // Monday, Sep 7, 2026

    final sampleTodayActivities = [
      const Activity(
        id: 'meditation',
        name: 'Meditation',
        activityType: ActivityType.meditation,
        defaultDuration: Duration(minutes: 10),
        isCompleted: true,
      ),
      const Activity(
        id: 'walking',
        name: 'Walking',
        activityType: ActivityType.walking,
        defaultDuration: Duration(minutes: 30),
        isSkipped: true,
      ),
      const Activity(
        id: 'dumbbells',
        name: 'Dumbbells',
        activityType: ActivityType.dumbbells,
        defaultDuration: Duration(minutes: 20),
        isCompleted: false,
        isSkipped: false,
        completedSetsReps: [12, 10], // In-progress sets
      ),
    ];

    test('Calculates Day metrics correctly with completed, skipped, and missed', () {
      final stats = ProgressCalculator.calculate(
        history: [],
        todayActivities: sampleTodayActivities,
        period: ProgressPeriod.day,
        now: testNow,
      );

      expect(stats.period, ProgressPeriod.day);
      expect(stats.totalActivities, 3);
      expect(stats.completedCount, 1);
      expect(stats.skippedCount, 1);
      expect(stats.missedCount, 1);
      expect(stats.completionPercentage, closeTo(33.33, 0.05));
      expect(stats.totalWorkoutDuration, const Duration(minutes: 10)); // Only completed count towards duration
      expect(stats.formattedDuration, '10 min');
      expect(stats.dumbbellSetsCount, 2);
      expect(stats.dumbbellRepsCount, 22);
      expect(stats.dailyPoints.length, 1);
      expect(stats.dailyPoints.first.shortLabel, 'Today');
      expect(stats.monthlyAccuracy, isNull);
    });

    test('Calculates Day metrics when all activities are completed', () {
      final allCompleted = [
        const Activity(
          id: 'meditation',
          name: 'Meditation',
          activityType: ActivityType.meditation,
          defaultDuration: Duration(minutes: 10),
          isCompleted: true,
        ),
        const Activity(
          id: 'walking',
          name: 'Walking',
          activityType: ActivityType.walking,
          defaultDuration: Duration(minutes: 30),
          isCompleted: true,
        ),
        const Activity(
          id: 'dumbbells',
          name: 'Dumbbells',
          activityType: ActivityType.dumbbells,
          defaultDuration: Duration(minutes: 20),
          isCompleted: true,
          completedSetsReps: [12, 12, 10],
        ),
      ];

      final stats = ProgressCalculator.calculate(
        history: [],
        todayActivities: allCompleted,
        period: ProgressPeriod.day,
        now: testNow,
      );

      expect(stats.totalActivities, 3);
      expect(stats.completedCount, 3);
      expect(stats.skippedCount, 0);
      expect(stats.missedCount, 0);
      expect(stats.completionPercentage, 100.0);
      expect(stats.totalWorkoutDuration, const Duration(minutes: 60));
      expect(stats.formattedDuration, '1 hr');
      expect(stats.dumbbellSetsCount, 3);
      expect(stats.dumbbellRepsCount, 34);
    });

    test('Handles empty history and empty activities safely without NaN or division by zero', () {
      final stats = ProgressCalculator.calculate(
        history: [],
        todayActivities: [],
        period: ProgressPeriod.day,
        now: testNow,
      );

      expect(stats.totalActivities, 0);
      expect(stats.completedCount, 0);
      expect(stats.skippedCount, 0);
      expect(stats.missedCount, 0);
      expect(stats.completionPercentage, 0.0);
      expect(stats.totalWorkoutDuration, Duration.zero);
      expect(stats.formattedDuration, '0 min');
      expect(stats.dumbbellSetsCount, 0);
      expect(stats.dumbbellRepsCount, 0);
    });

    test('Calculates Week metrics across 7-day window including today and past history', () {
      // Sep 7 is Monday. Window: Sep 1 to Sep 7 (7 days).
      final pastDays = [
        // Sep 6 (Sunday)
        DayHistory(
          dateKey: '2026-09-06',
          recordedAt: DateTime(2026, 9, 6, 20, 0),
          activities: const [
            Activity(
              id: 'meditation',
              name: 'Meditation',
              activityType: ActivityType.meditation,
              defaultDuration: Duration(minutes: 10),
              isCompleted: true,
            ),
            Activity(
              id: 'walking',
              name: 'Walking',
              activityType: ActivityType.walking,
              defaultDuration: Duration(minutes: 30),
              isCompleted: true,
            ),
            Activity(
              id: 'dumbbells',
              name: 'Dumbbells',
              activityType: ActivityType.dumbbells,
              defaultDuration: Duration(minutes: 20),
              isCompleted: true,
              completedSetsReps: [15, 12, 10],
            ),
          ],
        ),
        // Sep 5 (Saturday) - unrecorded day (skipped or no app usage)
        // Sep 4 (Friday)
        DayHistory(
          dateKey: '2026-09-04',
          recordedAt: DateTime(2026, 9, 4, 18, 0),
          activities: const [
            Activity(
              id: 'meditation',
              name: 'Meditation',
              activityType: ActivityType.meditation,
              defaultDuration: Duration(minutes: 10),
              isCompleted: true,
            ),
            Activity(
              id: 'walking',
              name: 'Walking',
              activityType: ActivityType.walking,
              defaultDuration: Duration(minutes: 30),
              isSkipped: true,
            ),
            Activity(
              id: 'dumbbells',
              name: 'Dumbbells',
              activityType: ActivityType.dumbbells,
              defaultDuration: Duration(minutes: 20),
              isCompleted: false,
            ),
          ],
        ),
        // Older record outside 7 days: Aug 25 (should NOT be included in week)
        DayHistory(
          dateKey: '2026-08-25',
          recordedAt: DateTime(2026, 8, 25, 12, 0),
          activities: const [
            Activity(
              id: 'meditation',
              name: 'Meditation',
              activityType: ActivityType.meditation,
              defaultDuration: Duration(minutes: 10),
              isCompleted: true,
            ),
          ],
        ),
      ];

      final stats = ProgressCalculator.calculate(
        history: pastDays,
        todayActivities: sampleTodayActivities,
        period: ProgressPeriod.week,
        now: testNow,
      );

      // Recorded days: Sep 4, Sep 6, and Sep 7 (Today) = 3 days
      expect(stats.recordedDaysCount, 3);
      // Total activities across 3 recorded days: 3 + 3 + 3 = 9
      expect(stats.totalActivities, 9);
      // Completed: Sep 4 (1) + Sep 6 (3) + Sep 7 (1) = 5
      expect(stats.completedCount, 5);
      // Skipped: Sep 4 (1) + Sep 6 (0) + Sep 7 (1) = 2
      expect(stats.skippedCount, 2);
      // Missed: Sep 4 (1) + Sep 6 (0) + Sep 7 (1) = 2
      expect(stats.missedCount, 2);
      expect(stats.completionPercentage, closeTo((5 / 9) * 100, 0.01));

      // Dumbbell sets: Sep 6 (3) + Sep 7 (2) = 5 sets
      expect(stats.dumbbellSetsCount, 5);
      // Dumbbell reps: Sep 6 (37) + Sep 7 (22) = 59 reps
      expect(stats.dumbbellRepsCount, 59);

      // Duration: Sep 4 (10) + Sep 6 (60) + Sep 7 (10) = 80 min = 1 hr 20 min
      expect(stats.totalWorkoutDuration, const Duration(minutes: 80));
      expect(stats.formattedDuration, '1 hr 20 min');

      // Points: Exactly 7 daily points for the 7-day window
      expect(stats.dailyPoints.length, 7);
      // Verify unrecorded day is marked isRecorded = false
      final sep5Point = stats.dailyPoints.firstWhere((p) => p.dateKey == '2026-09-05');
      expect(sep5Point.isRecorded, isFalse);
      expect(sep5Point.completionRate, 0.0);

      // Verify Sep 6 is recorded
      final sep6Point = stats.dailyPoints.firstWhere((p) => p.dateKey == '2026-09-06');
      expect(sep6Point.isRecorded, isTrue);
      expect(sep6Point.completionRate, 1.0);
    });

    test('Calculates Month metrics and monthly accuracy based on available history', () {
      final pastDays = [
        DayHistory(
          dateKey: '2026-09-06',
          recordedAt: DateTime(2026, 9, 6),
          activities: const [
            Activity(
              id: 'meditation',
              name: 'Meditation',
              activityType: ActivityType.meditation,
              defaultDuration: Duration(minutes: 10),
              isCompleted: true,
            ),
            Activity(
              id: 'walking',
              name: 'Walking',
              activityType: ActivityType.walking,
              defaultDuration: Duration(minutes: 30),
              isCompleted: true,
            ),
            Activity(
              id: 'dumbbells',
              name: 'Dumbbells',
              activityType: ActivityType.dumbbells,
              defaultDuration: Duration(minutes: 20),
              isCompleted: true,
            ),
          ],
        ),
        // Day from August (should NOT be included in September month view)
        DayHistory(
          dateKey: '2026-08-31',
          recordedAt: DateTime(2026, 8, 31),
          activities: const [
            Activity(
              id: 'meditation',
              name: 'Meditation',
              activityType: ActivityType.meditation,
              defaultDuration: Duration(minutes: 10),
              isCompleted: true,
            ),
          ],
        ),
      ];

      final stats = ProgressCalculator.calculate(
        history: pastDays,
        todayActivities: sampleTodayActivities, // 1 of 3 completed
        period: ProgressPeriod.month,
        now: testNow, // Sep 7
      );

      expect(stats.period, ProgressPeriod.month);
      expect(stats.startDate, DateTime(2026, 9, 1));
      expect(stats.endDate, DateTime(2026, 9, 7));

      // Available recorded days in Sep: Sep 6 and Sep 7 = 2 days
      expect(stats.recordedDaysCount, 2);
      // Total activities: Sep 6 (3) + Sep 7 (3) = 6
      expect(stats.totalActivities, 6);
      // Completed: Sep 6 (3) + Sep 7 (1) = 4
      expect(stats.completedCount, 4);

      // Monthly accuracy: 4 / 6 = 66.67%
      expect(stats.monthlyAccuracy, isNotNull);
      expect(stats.monthlyAccuracy!, closeTo(66.67, 0.05));
    });

    test('Handles month transition boundary safely (Aug 31 to Sep 1)', () {
      final sep1Now = DateTime(2026, 9, 1, 8, 0);

      final aug31Record = DayHistory(
        dateKey: '2026-08-31',
        recordedAt: DateTime(2026, 8, 31),
        activities: const [
          Activity(
            id: 'meditation',
            name: 'Meditation',
            activityType: ActivityType.meditation,
            defaultDuration: Duration(minutes: 10),
            isCompleted: true,
          ),
        ],
      );

      final stats = ProgressCalculator.calculate(
        history: [aug31Record],
        todayActivities: [
          const Activity(
            id: 'walking',
            name: 'Walking',
            activityType: ActivityType.walking,
            defaultDuration: Duration(minutes: 30),
            isCompleted: true,
          ),
        ],
        period: ProgressPeriod.month,
        now: sep1Now,
      );

      // Sep 1 is start and end of current month window
      expect(stats.startDate, DateTime(2026, 9, 1));
      expect(stats.endDate, DateTime(2026, 9, 1));
      // Only Sep 1 record is in this month
      expect(stats.totalActivities, 1);
      expect(stats.completedCount, 1);
      expect(stats.monthlyAccuracy, 100.0);
    });
  });
}
