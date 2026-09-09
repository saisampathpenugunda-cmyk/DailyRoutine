import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/main.dart';
import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/screens/meditation_screen.dart';

void main() {
  // ── Meditation screen widget tests ──────────────────────────────────────────────

  group('MeditationScreen Widget Tests', () {
    Widget buildMeditationScreen({
      ActivityRepository? repo,
      Activity? activity,
    }) {
      final r = repo ?? InMemoryActivityRepository();
      final a = activity ??
          const Activity(
            id: 'meditation',
            name: 'Meditation',
            activityType: ActivityType.meditation,
            defaultDuration: Duration(minutes: 10),
          );
      return MaterialApp(
        home: MeditationScreen(activity: a, repository: r),
      );
    }

    testWidgets('renders initial 10:00 and Start button', (tester) async {
      await tester.pumpWidget(buildMeditationScreen());

      // 'Meditation' appears in both AppBar and info card — verify at least one exists
      expect(find.text('Meditation'), findsAtLeastNWidgets(1));
      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('Default: 10 min'), findsOneWidget);
      expect(find.byKey(const Key('start_button')), findsOneWidget);
    });

    testWidgets('tapping Start shows Pause and Finish buttons', (tester) async {
      await tester.pumpWidget(buildMeditationScreen());

      await tester.tap(find.byKey(const Key('start_button')));
      await tester.pump();

      expect(find.byKey(const Key('pause_button')), findsOneWidget);
      expect(find.byKey(const Key('finish_button')), findsOneWidget);
      expect(find.byKey(const Key('start_button')), findsNothing);
    });

    testWidgets('tapping Pause shows Resume and Finish buttons', (tester) async {
      await tester.pumpWidget(buildMeditationScreen());

      await tester.tap(find.byKey(const Key('start_button')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('pause_button')));
      await tester.pump();

      expect(find.byKey(const Key('resume_button')), findsOneWidget);
      expect(find.byKey(const Key('finish_early_button')), findsOneWidget);
      expect(find.byKey(const Key('pause_button')), findsNothing);
    });

    testWidgets('tapping Resume from paused returns to running', (tester) async {
      await tester.pumpWidget(buildMeditationScreen());

      await tester.tap(find.byKey(const Key('start_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pause_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('resume_button')));
      await tester.pump();

      expect(find.byKey(const Key('pause_button')), findsOneWidget);
      expect(find.byKey(const Key('finish_button')), findsOneWidget);
    });

    testWidgets('Finish button marks meditation completed and shows Done', (
      tester,
    ) async {
      final repo = InMemoryActivityRepository();
      await tester.pumpWidget(buildMeditationScreen(repo: repo));

      // Start then finish
      await tester.tap(find.byKey(const Key('start_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('finish_button')));
      await tester.pump();

      // Meditation should now be completed in the repo
      expect(repo.getActivityById('meditation')?.isCompleted, true);

      // UI should show Done button and completed message
      expect(find.byKey(const Key('done_button')), findsOneWidget);
      expect(find.text('Meditation completed for today!'), findsOneWidget);
    });

    testWidgets('Finish from paused state also completes meditation', (tester) async {
      final repo = InMemoryActivityRepository();
      await tester.pumpWidget(buildMeditationScreen(repo: repo));

      await tester.tap(find.byKey(const Key('start_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pause_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('finish_early_button')));
      await tester.pump();

      expect(repo.getActivityById('meditation')?.isCompleted, true);
      expect(find.byKey(const Key('done_button')), findsOneWidget);
    });

    testWidgets('auto-completion via tick marks meditation completed', (tester) async {
      final repo = InMemoryActivityRepository();
      // Use a 0-duration activity so the first tick auto-completes
      const zeroActivity = Activity(
        id: 'meditation',
        name: 'Meditation',
        activityType: ActivityType.meditation,
        defaultDuration: Duration.zero,
      );
      await tester.pumpWidget(buildMeditationScreen(repo: repo, activity: zeroActivity));

      await tester.tap(find.byKey(const Key('start_button')));
      await tester.pump();

      // Advance 1 second so the ticker fires once
      await tester.pump(const Duration(seconds: 1));

      expect(repo.getActivityById('meditation')?.isCompleted, true);
      expect(find.byKey(const Key('done_button')), findsOneWidget);
    });
  });

  // ── Home screen navigation tests ──────────────────────────────────────────

  group('HomeScreen → Meditation navigation', () {
    testWidgets('tapping Meditation card opens MeditationScreen', (tester) async {
      final repo = InMemoryActivityRepository();
      await tester.pumpWidget(DailyRoutineApp(repository: repo));

      await tester.tap(find.text('Meditation'));
      await tester.pumpAndSettle();

      // Should now be on MeditationScreen
      expect(find.text('10:00'), findsOneWidget);
      expect(find.byKey(const Key('start_button')), findsOneWidget);
    });

    testWidgets(
      'Meditation completion reflected on Home screen after returning',
      (tester) async {
        final repo = InMemoryActivityRepository();
        await tester.pumpWidget(DailyRoutineApp(repository: repo));

        expect(find.text('0 of 3 activities completed'), findsOneWidget);

        // Navigate to Meditation
        await tester.tap(find.text('Meditation'));
        await tester.pumpAndSettle();

        // Start and Finish
        await tester.tap(find.byKey(const Key('start_button')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('finish_button')));
        await tester.pump();

        // Tap Done to navigate back
        await tester.tap(find.byKey(const Key('done_button')));
        await tester.pumpAndSettle();

        // Home screen should now reflect 1 completion
        expect(find.text('1 of 3 activities completed'), findsOneWidget);
      },
    );

    testWidgets(
      'Start -> Pause -> Back -> Reopen preserves paused state and does not decrease time',
      (tester) async {
        var simulatedNow = DateTime(2026, 9, 9, 8, 0, 0);
        final repo = InMemoryActivityRepository();
        repo.getTimerController('meditation', now: () => simulatedNow);
        await tester.pumpWidget(DailyRoutineApp(repository: repo));

        // 1. Open Meditation
        await tester.tap(find.text('Meditation'));
        await tester.pumpAndSettle();
        expect(find.text('10:00'), findsOneWidget);

        // 2. Start timer and let run 2 seconds
        await tester.tap(find.byKey(const Key('start_button')));
        await tester.pump();
        simulatedNow = simulatedNow.add(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        simulatedNow = simulatedNow.add(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));

        // 3. Pause timer
        await tester.tap(find.byKey(const Key('pause_button')));
        await tester.pump();
        expect(find.text('09:58'), findsOneWidget);
        expect(find.text('Paused'), findsOneWidget);

        // 4. Navigate back to Home screen
        final backButton = find.byType(BackButton);
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();
        expect(find.text('Daily Routine'), findsOneWidget);

        // 5. Stay away on Home screen for 5 minutes (paused time must NOT decrease)
        simulatedNow = simulatedNow.add(const Duration(minutes: 5));
        await tester.pump(const Duration(minutes: 5));

        // 6. Reopen Meditation
        await tester.tap(find.text('Meditation'));
        await tester.pumpAndSettle();

        // 7. Verify timer is still PAUSED with 09:58 remaining
        expect(find.text('09:58'), findsOneWidget);
        expect(find.text('Paused'), findsOneWidget);
        expect(find.byKey(const Key('resume_button')), findsOneWidget);
        expect(find.byKey(const Key('finish_early_button')), findsOneWidget);
        expect(find.byKey(const Key('start_button')), findsNothing);

        // 8. Tap Resume and verify countdown resumes from 09:58
        await tester.tap(find.byKey(const Key('resume_button')));
        await tester.pump();
        expect(find.text('Running'), findsOneWidget);

        simulatedNow = simulatedNow.add(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('09:57'), findsOneWidget);

        // 9. Finish early
        await tester.tap(find.byKey(const Key('pause_button')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('finish_early_button')));
        await tester.pumpAndSettle();

        expect(find.text('Completed!'), findsOneWidget);
        await tester.tap(find.byKey(const Key('done_button')));
        await tester.pumpAndSettle();

        expect(find.text('1 of 3 activities completed'), findsOneWidget);
      },
    );

    testWidgets(
      'Running timer preserves state and elapsed wall-clock time across navigation',
      (tester) async {
        var simulatedNow = DateTime(2026, 9, 9, 8, 0, 0);
        final repo = InMemoryActivityRepository();
        repo.getTimerController('meditation', now: () => simulatedNow);
        await tester.pumpWidget(DailyRoutineApp(repository: repo));

        // 1. Open Meditation and start timer
        await tester.tap(find.text('Meditation'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('start_button')));
        await tester.pump();
        simulatedNow = simulatedNow.add(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Running'), findsOneWidget);

        // 2. Navigate back to Home while running
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // 3. 3 seconds pass
        simulatedNow = simulatedNow.add(const Duration(seconds: 3));
        await tester.pump(const Duration(seconds: 3));

        // 4. Reopen Meditation
        await tester.tap(find.text('Meditation'));
        await tester.pumpAndSettle();

        // 5. Timer should still be running and shows approximately 09:56
        expect(find.text('Running'), findsOneWidget);
        expect(find.byKey(const Key('pause_button')), findsOneWidget);
        expect(find.text('09:56'), findsOneWidget);

        // Clean up: pause timer before test teardown
        await tester.tap(find.byKey(const Key('pause_button')));
        await tester.pump();
      },
    );
  });
}
