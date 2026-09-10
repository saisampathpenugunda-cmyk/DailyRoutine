import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/models/day_history.dart';
import 'package:daily_routine/models/progress_statistics.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/screens/activity_detail_screen.dart';
import 'package:daily_routine/screens/meditation_screen.dart';
import 'package:daily_routine/screens/walking_screen.dart';
import 'package:daily_routine/screens/dumbbells_screen.dart';
import 'package:daily_routine/services/progress_calculator.dart';
import 'package:daily_routine/theme/app_theme.dart';
import 'package:daily_routine/widgets/duration_control.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({required Widget child}) {
    return MaterialApp(
      theme: ThemeData(
        extensions: const [AppTheme.lightAppColors],
      ),
      home: child,
    );
  }

  group('STEP 2 — Editable Duration & Timer Tests', () {
    late InMemoryActivityRepository repository;

    setUp(() {
      repository = InMemoryActivityRepository();
    });

    testWidgets('ActivityDetailScreen renders timer, controls, and DurationControl', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final activity = Activity(
        id: 'custom_reading',
        name: 'Reading',
        activityType: ActivityType.timer,
        defaultDuration: const Duration(minutes: 15),
      );
      repository.addActivity(activity);

      await tester.pumpWidget(
        createTestWidget(
          child: ActivityDetailScreen(
            activity: activity,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check name, countdown timer, start button, and duration control
      expect(find.text('Reading'), findsWidgets);
      expect(find.text('15:00'), findsOneWidget);
      expect(find.byKey(const Key('start_button')), findsOneWidget);
      expect(find.byKey(const Key('duration_control_button')), findsOneWidget);
      expect(find.text('15 min 00 sec'), findsOneWidget);
    });

    testWidgets('Tapping DurationControl opens bottom sheet with Minutes/Seconds and updates duration', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final activity = Activity(
        id: 'custom_study',
        name: 'Study',
        activityType: ActivityType.timer,
        defaultDuration: const Duration(minutes: 15),
      );
      repository.addActivity(activity);

      await tester.pumpWidget(
        createTestWidget(
          child: ActivityDetailScreen(
            activity: activity,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap duration control
      await tester.tap(find.byKey(const Key('duration_control_button')));
      await tester.pumpAndSettle();

      // Bottom sheet is visible
      expect(find.text('Set Duration'), findsOneWidget);
      expect(find.text('Minutes'), findsOneWidget);
      expect(find.text('Seconds'), findsOneWidget);
      expect(find.byKey(const Key('minutes_value_text')), findsOneWidget);
      expect(find.text('15'), findsOneWidget);

      // Increment minutes by 5
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('increment_minutes_button')));
        await tester.pump();
      }
      expect(find.text('20'), findsOneWidget);

      // Increment seconds by 30
      for (int i = 0; i < 30; i++) {
        await tester.tap(find.byKey(const Key('increment_seconds_button')));
        await tester.pump();
      }
      expect(find.text('30'), findsOneWidget);

      // Tap Save
      await tester.tap(find.byKey(const Key('duration_picker_save_button')));
      await tester.pumpAndSettle();

      // Bottom sheet closed
      expect(find.text('Set Duration'), findsNothing);

      // Duration control updated
      expect(find.text('20 min 30 sec'), findsOneWidget);

      // Timer countdown updated immediately because timer was not running
      expect(find.text('20:30'), findsOneWidget);

      // Persisted in repository
      final updatedActivity = repository.getActivityById('custom_study');
      expect(updatedActivity?.defaultDuration, const Duration(minutes: 20, seconds: 30));
    });

    testWidgets('Active running timer session is NOT disrupted when duration changes', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final activity = Activity(
        id: 'meditation',
        name: 'Meditation',
        activityType: ActivityType.meditation,
        defaultDuration: const Duration(minutes: 10),
      );

      final controller = repository.getTimerController('meditation', defaultDuration: const Duration(minutes: 10));

      await tester.pumpWidget(
        createTestWidget(
          child: ActivityDetailScreen(
            activity: activity,
            repository: repository,
            timer: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start the timer
      await tester.tap(find.byKey(const Key('start_button')));
      await tester.pump();
      expect(controller.isRunning, isTrue);

      // Let 30 seconds pass
      await tester.pump(const Duration(seconds: 30));

      // Active timer remaining is less than 10 minutes
      final remainingBefore = controller.remaining;
      expect(remainingBefore, lessThan(const Duration(minutes: 10)));

      // Open duration picker while running and change to 25 minutes
      await tester.tap(find.byKey(const Key('duration_control_button')));
      await tester.pumpAndSettle();

      for (int i = 0; i < 15; i++) {
        await tester.tap(find.byKey(const Key('increment_minutes_button')));
        await tester.pump();
      }
      await tester.tap(find.byKey(const Key('duration_picker_save_button')));
      await tester.pumpAndSettle();

      // The running session is still running and did not jump to 25 minutes!
      expect(controller.isRunning, isTrue);
      expect(controller.remaining.inMinutes, lessThan(11));
      expect(controller.remaining.inMinutes, greaterThanOrEqualTo(8));

      // Activity defaultDuration is updated in repository
      final savedActivity = repository.getActivityById('meditation');
      expect(savedActivity?.defaultDuration, const Duration(minutes: 25));

      // Reset timer and verify next session starts with the updated 25 minutes
      repository.resetTimer('meditation');
      final newController = repository.getTimerController('meditation');
      expect(newController.remaining, const Duration(minutes: 25));
    });

    test('History snapshot invariance: updating duration never alters past history records', () {
      final pastDateKey = '2026-09-08';
      final pastActivity = Activity(
        id: 'walking',
        name: 'Walking',
        activityType: ActivityType.walking,
        defaultDuration: const Duration(minutes: 15),
        actualDuration: const Duration(minutes: 15),
        isCompleted: true,
      );

      final pastDay = DayHistory(
        dateKey: pastDateKey,
        activities: [pastActivity],
        recordedAt: DateTime(2026, 9, 8, 23, 59),
      );

      final repo = InMemoryActivityRepository(
        initialHistory: [pastDay],
      );

      // Verify past day snapshot
      final pastDayBefore = repo.getHistory().firstWhere((d) => d.dateKey == pastDateKey);
      expect(pastDayBefore.activities.first.defaultDuration, const Duration(minutes: 15));

      // Now update walking duration today to 45 minutes
      final todayWalking = repo.getActivityById('walking')!;
      repo.updateActivity(todayWalking.copyWith(defaultDuration: const Duration(minutes: 45)));

      // Past history record is unchanged!
      final pastDayAfter = repo.getHistory().firstWhere((d) => d.dateKey == pastDateKey);
      expect(pastDayAfter.activities.first.defaultDuration, const Duration(minutes: 15));
    });

    test('Completion rate uses completed enabled / total enabled and never averages partial timer', () {
      final a1 = Activity(
        id: '1',
        name: 'A1',
        activityType: ActivityType.timer,
        defaultDuration: const Duration(minutes: 10),
        actualDuration: const Duration(minutes: 5), // 50% partial
        isCompleted: false,
        isEnabled: true,
      );
      final a2 = Activity(
        id: '2',
        name: 'A2',
        activityType: ActivityType.timer,
        defaultDuration: const Duration(minutes: 10),
        actualDuration: const Duration(minutes: 10),
        isCompleted: true,
        isEnabled: true,
      );
      final a3 = Activity(
        id: '3',
        name: 'A3',
        activityType: ActivityType.timer,
        defaultDuration: const Duration(minutes: 10),
        actualDuration: const Duration(minutes: 0),
        isCompleted: false,
        isEnabled: false, // Disabled activity
      );

      final dayHistory = DayHistory(
        dateKey: '2026-09-09',
        activities: [a1, a2, a3],
        recordedAt: DateTime(2026, 9, 9, 12, 0),
      );

      // Total enabled = 2 (a1, a2), completed enabled = 1 (a2)
      expect(dayHistory.totalCount, 2);
      expect(dayHistory.completedCount, 1);
      // Completion rate is exactly 1 / 2 = 0.5 (50%), NOT (0.5 + 1.0) / 2 = 75%
      expect(dayHistory.completionRate, 0.5);

      // Test with ProgressCalculator
      final stats = ProgressCalculator.calculate(
        history: [],
        todayActivities: [a1, a2, a3],
        period: ProgressPeriod.day,
        now: DateTime(2026, 9, 9, 12, 0),
      );

      expect(stats.totalActivities, 2);
      expect(stats.completedCount, 1);
    });

    testWidgets('MeditationScreen, WalkingScreen, and DumbbellsScreen have DurationControl', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final medActivity = repository.getActivityById('meditation')!;
      await tester.pumpWidget(
        createTestWidget(
          child: MeditationScreen(
            activity: medActivity,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DurationControl), findsOneWidget);

      final walkActivity = repository.getActivityById('walking')!;
      await tester.pumpWidget(
        createTestWidget(
          child: WalkingScreen(
            activity: walkActivity,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DurationControl), findsOneWidget);

      final dumbActivity = repository.getActivityById('dumbbells')!;
      await tester.pumpWidget(
        createTestWidget(
          child: DumbbellsScreen(
            activity: dumbActivity,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DurationControl), findsOneWidget);
    });
  });
}
