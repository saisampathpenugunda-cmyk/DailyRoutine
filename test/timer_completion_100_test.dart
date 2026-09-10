import 'package:daily_routine/controllers/routine_timer_controller.dart';
import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/widgets/activity_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoutineTimerController 100% vs 99% logic', () {
    test('10:00 timer with 09:59 elapsed gives completionProgress < 1.0 (99.8%) and elapsedDuration 9m 59s', () {
      var fakeNow = DateTime(2026, 9, 9, 10, 0, 0);
      final controller = RoutineTimerController(
        totalDuration: const Duration(minutes: 10),
        now: () => fakeNow,
      );

      controller.start();
      // Advance 9 minutes and 59 seconds (599 seconds out of 600)
      fakeNow = fakeNow.add(const Duration(seconds: 599));
      controller.tick();

      expect(controller.isCompleted, isFalse);
      expect(controller.remaining, const Duration(seconds: 1));
      expect(controller.completionProgress, lessThan(1.0));
      expect(controller.completionProgress, closeTo(0.9983, 0.001));
      expect(controller.elapsedDuration, const Duration(seconds: 599));
    });

    test('10:00 timer reaching 10:00 (00:00 remaining) auto-completes to exactly 100% and total duration', () {
      var fakeNow = DateTime(2026, 9, 9, 10, 0, 0);
      final controller = RoutineTimerController(
        totalDuration: const Duration(minutes: 10),
        now: () => fakeNow,
      );

      controller.start();
      // Advance full 10 minutes (600 seconds)
      fakeNow = fakeNow.add(const Duration(minutes: 10));
      final autoCompleted = controller.tick();

      expect(autoCompleted, isTrue);
      expect(controller.isCompleted, isTrue);
      expect(controller.state, TimerState.completed);
      expect(controller.remaining, Duration.zero);
      expect(controller.progress, 0.0);
      expect(controller.completionProgress, 1.0);
      expect(controller.elapsedDuration, const Duration(minutes: 10));
    });

    test('Controller detects completion when now >= endTime even before tick', () {
      var fakeNow = DateTime(2026, 9, 9, 10, 0, 0);
      final controller = RoutineTimerController(
        totalDuration: const Duration(minutes: 10),
        now: () => fakeNow,
      );

      controller.start();
      fakeNow = fakeNow.add(const Duration(minutes: 10, seconds: 1));

      // Before tick() is called:
      expect(controller.isCompleted, isTrue);
      expect(controller.completionProgress, 1.0);
      expect(controller.elapsedDuration, const Duration(minutes: 10));
    });

    test('Manual finish sets completionProgress to exactly 1.0', () {
      final controller = RoutineTimerController(
        totalDuration: const Duration(minutes: 15),
      );
      controller.start();
      controller.finish();

      expect(controller.isCompleted, isTrue);
      expect(controller.completionProgress, 1.0);
      expect(controller.elapsedDuration, const Duration(minutes: 15));
    });

    test('Initial unstarted state has 0.0 completionProgress and Duration.zero elapsed', () {
      final controller = RoutineTimerController(
        totalDuration: const Duration(minutes: 10),
      );

      expect(controller.isCompleted, isFalse);
      expect(controller.completionProgress, 0.0);
      expect(controller.elapsedDuration, Duration.zero);
    });
  });

  group('ActivityCard 100% vs 99% display rules', () {
    const activity = Activity(
      id: 'meditation',
      name: 'Meditation',
      defaultDuration: Duration(minutes: 10),
      activityType: ActivityType.meditation,
    );

    testWidgets('Genuinely incomplete session at 99.8% displays 99% and unchecked checkbox', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activity: activity,
              progress: 0.9983, // 599s of 600s
              onTap: () {},
            ),
          ),
        ),
      );

      // Should strictly show 99%, NOT 100%
      expect(find.text('99%'), findsOneWidget);
      expect(find.text('100%'), findsNothing);

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });

    testWidgets('Completed session with progress 1.0 displays 100% and checked checkbox', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activity: activity,
              progress: 1.0,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
      expect(find.text('99%'), findsNothing);

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('Activity with isCompleted: true displays 100% even if progress passed is 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activity: activity.copyWith(isCompleted: true),
              progress: 0.0,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('Partial 50% session displays 50%', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activity: activity,
              progress: 0.5,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('50%'), findsOneWidget);
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });
  });

  group('ActivityRepository progress auto-sync', () {
    test('getActivityProgress returns 1.0 and marks activity completed when timer completes', () {
      var fakeNow = DateTime(2026, 9, 9, 10, 0, 0);
      final repo = InMemoryActivityRepository(now: () => fakeNow);

      final act = repo.getActivityById('meditation')!;
      final timer = repo.getTimerController(act.id);
      timer.start();

      fakeNow = fakeNow.add(act.defaultDuration);
      timer.tick();

      expect(timer.isCompleted, isTrue);

      final progress = repo.getActivityProgress(act);
      expect(progress, 1.0);

      // Verify repo marked activity as completed
      final updatedAct = repo.getActivityById('meditation')!;
      expect(updatedAct.isCompleted, isTrue);
    });

    test('getActivityProgress returns 99% range for 599s out of 600s', () {
      var fakeNow = DateTime(2026, 9, 9, 10, 0, 0);
      final repo = InMemoryActivityRepository(now: () => fakeNow);

      final act = repo.getActivityById('meditation')!;
      final timer = repo.getTimerController(act.id);
      timer.start();

      fakeNow = fakeNow.add(const Duration(seconds: 599));
      timer.tick();

      expect(timer.isCompleted, isFalse);

      final progress = repo.getActivityProgress(act);
      expect(progress, lessThan(1.0));
      expect((progress * 100).round().clamp(1, 99), 99);

      final updatedAct = repo.getActivityById('meditation')!;
      expect(updatedAct.isCompleted, isFalse);
    });
  });
}
