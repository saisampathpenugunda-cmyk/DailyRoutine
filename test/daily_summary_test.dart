import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/models/daily_summary.dart';
import 'package:daily_routine/models/day_history.dart';
import 'package:daily_routine/models/progress_statistics.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/screens/progress_screen.dart';
import 'package:daily_routine/services/progress_calculator.dart';

void main() {
  group('DailySummaryData Unit Tests', () {
    test('Calculates completed, partial, skipped, and missed counts accurately', () {
      final activities = [
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
          actualDuration: Duration(minutes: 15),
          isCompleted: false,
        ),
        const Activity(
          id: 'guitar',
          name: 'Guitar',
          activityType: ActivityType.guitar,
          defaultDuration: Duration(minutes: 20),
          isSkipped: true,
        ),
        const Activity(
          id: 'reading',
          name: 'Reading',
          activityType: ActivityType.reading,
          defaultDuration: Duration(minutes: 15),
          isCompleted: false,
          isSkipped: false,
        ),
      ];

      final summary = DailySummaryData.compute(activities: activities);

      expect(summary.totalCount, 4);
      expect(summary.completedCount, 1);
      expect(summary.partialCount, 1);
      expect(summary.skippedCount, 1);
      expect(summary.missedCount, 1);
      // Meditation (10 min) + Walking (15 min) = 25 min
      expect(summary.totalActiveTime, const Duration(minutes: 25));
      expect(summary.formattedActiveTime, '25 min');

      // Overall: (1.0 + 0.5 + 0.0 + 0.0) / 4 = 1.5 / 4 = 0.375 = 38%
      expect(summary.completionPercentage, 38);

      final items = summary.items;
      expect(items[0].status, ActivityRecordStatus.completed);
      expect(items[0].progressLabel, '✓');
      expect(items[0].metricLabel, '10 min');

      expect(items[1].status, ActivityRecordStatus.partial);
      expect(items[1].progressLabel, '50%');
      expect(items[1].metricLabel, '15 min');

      expect(items[2].status, ActivityRecordStatus.skipped);
      expect(items[2].progressLabel, '—');
      expect(items[2].metricLabel, '—');

      expect(items[3].status, ActivityRecordStatus.missed);
      expect(items[3].progressLabel, '✕');
      expect(items[3].metricLabel, '—');
    });

    test('Disabled activities are strictly excluded from summary', () {
      final activities = [
        const Activity(
          id: 'act1',
          name: 'Enabled Completed',
          activityType: ActivityType.general,
          defaultDuration: Duration(minutes: 10),
          isEnabled: true,
          isCompleted: true,
        ),
        const Activity(
          id: 'act2',
          name: 'Disabled Completed',
          activityType: ActivityType.general,
          defaultDuration: Duration(minutes: 10),
          isEnabled: false,
          isCompleted: true,
        ),
        const Activity(
          id: 'act3',
          name: 'Disabled Partial',
          activityType: ActivityType.general,
          defaultDuration: Duration(minutes: 10),
          actualDuration: Duration(minutes: 5),
          isEnabled: false,
        ),
        const Activity(
          id: 'act4',
          name: 'Enabled Missed',
          activityType: ActivityType.general,
          defaultDuration: Duration(minutes: 10),
          isEnabled: true,
          isCompleted: false,
        ),
      ];

      final summary = DailySummaryData.compute(activities: activities);

      expect(summary.totalCount, 2);
      expect(summary.completedCount, 1);
      expect(summary.partialCount, 0);
      expect(summary.skippedCount, 0);
      expect(summary.missedCount, 1);
      expect(summary.items.any((item) => item.activity.id == 'act2'), isFalse);
      expect(summary.items.any((item) => item.activity.id == 'act3'), isFalse);
    });

    test('Dumbbell set-based progress calculates sets and 67% progress', () {
      final activities = [
        const Activity(
          id: 'dumbbells',
          name: 'Dumbbells',
          activityType: ActivityType.dumbbells,
          defaultDuration: Duration(minutes: 20),
          completedSetsReps: [12, 12],
        ),
      ];

      final summary = DailySummaryData.compute(activities: activities);

      expect(summary.totalCount, 1);
      expect(summary.partialCount, 1);
      expect(summary.completedCount, 0);
      expect(summary.items.first.metricLabel, '2/3 sets');
      expect(summary.items.first.progressLabel, '67%');
      expect(summary.completionPercentage, 67);
    });

    test('Timer-based partial progress calculates actual duration and percentage', () {
      final activities = [
        const Activity(
          id: 'meditation',
          name: 'Meditation',
          activityType: ActivityType.meditation,
          defaultDuration: Duration(minutes: 20),
          actualDuration: Duration(minutes: 15),
        ),
      ];

      final summary = DailySummaryData.compute(activities: activities);

      expect(summary.partialCount, 1);
      expect(summary.items.first.metricLabel, '15 min');
      expect(summary.items.first.progressLabel, '75%');
      expect(summary.completionPercentage, 75);
      expect(summary.formattedActiveTime, '15 min');
    });

    test('Empty / 0 enabled activities returns empty summary without error', () {
      final summary = DailySummaryData.compute(activities: []);

      expect(summary.totalCount, 0);
      expect(summary.completedCount, 0);
      expect(summary.partialCount, 0);
      expect(summary.skippedCount, 0);
      expect(summary.missedCount, 0);
      expect(summary.completionPercentage, 0);
      expect(summary.totalActiveTime, Duration.zero);
      expect(summary.formattedActiveTime, '0 min');
      expect(summary.items, isEmpty);
    });

    test('Existing Progress calculations remain 100% unchanged', () {
      final history = [
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
          ],
        ),
      ];

      final todayActivities = [
        const Activity(
          id: 'walking',
          name: 'Walking',
          activityType: ActivityType.walking,
          defaultDuration: Duration(minutes: 30),
          isCompleted: true,
        ),
      ];

      final stats = ProgressCalculator.calculate(
        history: history,
        todayActivities: todayActivities,
        period: ProgressPeriod.day,
        now: DateTime(2026, 9, 7, 12, 0),
      );

      expect(stats.completedCount, 1);
      expect(stats.totalActivities, 1);
      expect(stats.completionPercentage, 100.0);
      expect(stats.formattedDuration, '30 min');
    });
  });

  group('DailySummary Widget & ProgressScreen Integration Tests', () {
    late InMemoryActivityRepository repository;
    final testDate = DateTime(2026, 9, 10, 10, 0);

    setUp(() {
      repository = InMemoryActivityRepository();
    });

    testWidgets('Renders Today\'s Summary card on Day view with all components', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Complete meditation (10 min)
      repository.setActivityCompletion('meditation', isCompleted: true);
      // Skip walking
      repository.setActivitySkipped('walking', isSkipped: true);
      // Partial dumbbells (2 sets)
      final dumbbells = repository.getActivityById('dumbbells');
      if (dumbbells != null) {
        repository.updateActivity(
          dumbbells.copyWith(completedSetsReps: [10, 10]),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressScreen(
              repository: repository,
              testNow: testDate,
            ),
          ),
        ),
      );

      // Verify card existence
      expect(find.byKey(const Key('todays_summary_card')), findsOneWidget);
      expect(find.text("Today's Summary"), findsOneWidget);

      // Verify counts
      expect(find.byKey(const Key('today_summary_completed_count')), findsOneWidget);
      expect(find.text('✓ Completed'), findsOneWidget);
      expect(find.text('— Skipped'), findsOneWidget);
      expect(find.text('↗ Partial'), findsOneWidget);

      // Verify Active Time container
      expect(find.text('Total active time'), findsOneWidget);
      expect(find.byKey(const Key('today_summary_active_time')), findsOneWidget);

      // Verify Activities breakdown section
      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('Meditation'), findsOneWidget);
      expect(find.text('Walking'), findsOneWidget);
      expect(find.text('Dumbbells'), findsOneWidget);
      expect(find.text('2/3 sets'), findsOneWidget);
    });

    testWidgets('Updates reactively when activity completion changes', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ProgressScreen(
                  repository: repository,
                  testNow: testDate,
                );
              },
            ),
          ),
        ),
      );

      // Initially meditation is not completed
      expect(find.byKey(const Key('todays_summary_card')), findsOneWidget);

      // Now complete meditation
      repository.setActivityCompletion('meditation', isCompleted: true);

      // Rebuild with updated repository state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressScreen(
              repository: repository,
              testNow: testDate,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final summary = DailySummaryData.compute(
        activities: repository.getActivities(),
        repository: repository,
      );
      expect(summary.completedCount, 1);
    });

    testWidgets('Handles 0 enabled activities gracefully', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final emptyRepo = InMemoryActivityRepository(
        initialActivities: [],
        initialHistory: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressScreen(
              repository: emptyRepo,
              testNow: testDate,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('todays_summary_card')), findsOneWidget);
      expect(find.text('No enabled activities today.'), findsOneWidget);
    });
  });
}
