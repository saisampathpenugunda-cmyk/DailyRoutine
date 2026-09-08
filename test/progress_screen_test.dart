import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/models/day_history.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/screens/progress_screen.dart';

void main() {
  group('ProgressScreen Widget Tests', () {
    late InMemoryActivityRepository repository;
    final testDate = DateTime(2026, 9, 7, 10, 0); // Monday, Sep 7, 2026

    setUp(() {
      repository = InMemoryActivityRepository();
      // Set today's activities:
      // Meditation: completed (10 min)
      // Walking: skipped
      // Dumbbells: 2 sets [10, 10]
      repository.setActivityCompletion('meditation', isCompleted: true);
      repository.setActivitySkipped('walking', isSkipped: true);
      final dumbbells = repository.getActivityById('dumbbells');
      if (dumbbells != null) {
        repository.updateActivity(
          dumbbells.copyWith(completedSetsReps: [10, 10]),
        );
      }

      // Add a history record for Sep 6
      repository.addHistoryEntry(
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
              completedSetsReps: [12, 12, 12],
            ),
          ],
        ),
      );
    });

    testWidgets('Renders Day view with period selector, completion rate, and workout metrics', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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

      // Verify period selector buttons
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);

      // Verify header
      expect(find.text('Today'), findsOneWidget);

      // Verify completion rate for today (1 of 3 = 33%)
      expect(find.text('Completion Rate'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);

      // Verify stat pills
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Skipped'), findsOneWidget);
      expect(find.text('Missed'), findsOneWidget);

      // Verify workout metrics
      expect(find.text('Workout Metrics'), findsOneWidget);
      expect(find.text('Total Workout Duration'), findsOneWidget);
      expect(find.text('10 min'), findsOneWidget);
      expect(find.text('Dumbbell Sets Completed'), findsOneWidget);
      expect(find.text('2 sets'), findsOneWidget);
      expect(find.text('Dumbbell Reps Completed'), findsOneWidget);
      expect(find.text('20 reps'), findsOneWidget);

      // In Day view, monthly accuracy card should NOT be displayed
      expect(find.text('Monthly Accuracy'), findsNothing);
    });

    testWidgets('Tapping Week switches to 7-day view and updates metrics', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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

      // Tap Week selector
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      // Range label: Sep 1 – Sep 7, 2026
      expect(find.text('Sep 1 – 7, 2026'), findsOneWidget);

      // Total completed: Sep 6 (3) + Sep 7 (1) = 4 of 6 = 66%
      expect(find.text('66%'), findsOneWidget);

      // Duration: Sep 6 (60 min) + Sep 7 (10 min) = 70 min = 1 hr 10 min
      expect(find.text('1 hr 10 min'), findsOneWidget);

      // Dumbbell sets: Sep 6 (3) + Sep 7 (2) = 5 sets
      expect(find.text('5 sets'), findsOneWidget);
      // Dumbbell reps: Sep 6 (36) + Sep 7 (20) = 56 reps
      expect(find.text('56 reps'), findsOneWidget);

      // 7-day chart title visible
      expect(find.text('7-Day Completion Trend'), findsOneWidget);
    });

    testWidgets('Tapping Month shows Monthly Final Accuracy card', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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

      // Tap Month selector
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('Daily Completion This Month'), findsOneWidget);

      // Monthly Final Accuracy card is visible
      expect(find.text('Monthly Accuracy'), findsOneWidget);
      expect(find.text('66%'), findsNWidgets(2)); // in header card and monthly accuracy card
      expect(find.textContaining('Based on 2 recorded days'), findsOneWidget);
    });

    testWidgets('Handles completely empty repository without crashing', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
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

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('0 min'), findsOneWidget);
      expect(find.text('0 sets'), findsOneWidget);
      expect(find.text('0 reps'), findsOneWidget);
    });
  });
}
