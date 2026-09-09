import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/main.dart';
import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/screens/walking_screen.dart';

void main() {
  group('WalkingScreen Widget Tests', () {
    Widget buildWalkingScreen({
      ActivityRepository? repo,
      Activity? activity,
    }) {
      final r = repo ?? InMemoryActivityRepository();
      final a = activity ??
          const Activity(
            id: 'walking',
            name: 'Walking',
            activityType: ActivityType.walking,
            defaultDuration: Duration(minutes: 30),
          );
      return MaterialApp(
        home: WalkingScreen(activity: a, repository: r),
      );
    }

    testWidgets('renders initial 30:00 and Start button', (tester) async {
      await tester.pumpWidget(buildWalkingScreen());

      expect(find.text('Walking'), findsAtLeastNWidgets(1));
      expect(find.text('30:00'), findsOneWidget);
      expect(find.text('Default: 30 min'), findsOneWidget);
      expect(find.byKey(const Key('start_button')), findsOneWidget);
    });

    testWidgets('tapping Start shows Pause and Finish buttons', (tester) async {
      await tester.pumpWidget(buildWalkingScreen());

      await tester.tap(find.byKey(const Key('start_button')));
      await tester.pump();

      expect(find.byKey(const Key('pause_button')), findsOneWidget);
      expect(find.byKey(const Key('finish_button')), findsOneWidget);
      expect(find.byKey(const Key('start_button')), findsNothing);
    });

    testWidgets('tapping Pause shows Resume and Finish buttons', (tester) async {
      await tester.pumpWidget(buildWalkingScreen());

      await tester.tap(find.byKey(const Key('start_button')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('pause_button')));
      await tester.pump();

      expect(find.byKey(const Key('resume_button')), findsOneWidget);
      expect(find.byKey(const Key('finish_early_button')), findsOneWidget);
      expect(find.byKey(const Key('pause_button')), findsNothing);
    });

    testWidgets('tapping Resume from paused returns to running', (tester) async {
      await tester.pumpWidget(buildWalkingScreen());

      await tester.tap(find.byKey(const Key('start_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pause_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('resume_button')));
      await tester.pump();

      expect(find.byKey(const Key('pause_button')), findsOneWidget);
      expect(find.byKey(const Key('finish_button')), findsOneWidget);
    });

    testWidgets('Finish button marks walking completed and shows Done', (tester) async {
      final repo = InMemoryActivityRepository();
      await tester.pumpWidget(buildWalkingScreen(repo: repo));

      // Start then finish
      await tester.tap(find.byKey(const Key('start_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('finish_button')));
      await tester.pump();

      // Walking should now be completed in the repo
      expect(repo.getActivityById('walking')?.isCompleted, true);
      expect(repo.getActivityById('walking')?.isSkipped, false);

      // UI should show Done button and completed message
      expect(find.byKey(const Key('done_button')), findsOneWidget);
      expect(find.text('Walking completed for today!'), findsOneWidget);
    });

    testWidgets('Finish from paused state also completes walking', (tester) async {
      final repo = InMemoryActivityRepository();
      await tester.pumpWidget(buildWalkingScreen(repo: repo));

      await tester.tap(find.byKey(const Key('start_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pause_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('finish_early_button')));
      await tester.pump();

      expect(repo.getActivityById('walking')?.isCompleted, true);
      expect(find.byKey(const Key('done_button')), findsOneWidget);
    });

    testWidgets('auto-completion via tick marks walking completed', (tester) async {
      final repo = InMemoryActivityRepository();
      // Use a 0-duration activity so the first tick auto-completes
      const zeroActivity = Activity(
        id: 'walking',
        name: 'Walking',
        activityType: ActivityType.walking,
        defaultDuration: Duration.zero,
      );
      await tester.pumpWidget(buildWalkingScreen(repo: repo, activity: zeroActivity));

      await tester.tap(find.byKey(const Key('start_button')));
      await tester.pump();

      // Advance 1 second so the ticker fires once
      await tester.pump(const Duration(seconds: 1));

      expect(repo.getActivityById('walking')?.isCompleted, true);
      expect(find.byKey(const Key('done_button')), findsOneWidget);
    });

    testWidgets('tapping Can\'t do today calls pop and marks skipped', (tester) async {
      final repo = InMemoryActivityRepository();
      bool didPop = false;
      const activity = Activity(
        id: 'walking',
        name: 'Walking',
        activityType: ActivityType.walking,
        defaultDuration: Duration(minutes: 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onDidRemovePage: (route) {
              didPop = true;
            },
            pages: [
              MaterialPage(
                child: WalkingScreen(
                  activity: activity,
                  repository: repo,
                ),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text("Can't do today"));
      await tester.pumpAndSettle();

      expect(repo.getActivityById('walking')?.isSkipped, true);
      expect(repo.getActivityById('walking')?.isCompleted, false);
      expect(didPop, isTrue);
    });

    testWidgets(
      'Start -> Pause -> Back -> Reopen preserves Walking paused state and does not decrease time',
      (tester) async {
        var simulatedNow = DateTime(2026, 9, 9, 8, 0, 0);
        final repo = InMemoryActivityRepository();
        repo.getTimerController('walking', now: () => simulatedNow);
        await tester.pumpWidget(DailyRoutineApp(repository: repo));

        // 1. Open Walking
        await tester.tap(find.text('Walking'));
        await tester.pumpAndSettle();
        expect(find.text('30:00'), findsOneWidget);

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
        expect(find.text('29:58'), findsOneWidget);
        expect(find.text('Paused'), findsOneWidget);

        // 4. Navigate back to Home screen
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Daily Routine'), findsOneWidget);

        // 5. Stay away on Home screen for 5 minutes (paused time must NOT decrease)
        simulatedNow = simulatedNow.add(const Duration(minutes: 5));
        await tester.pump(const Duration(minutes: 5));

        // 6. Reopen Walking
        await tester.tap(find.text('Walking'));
        await tester.pumpAndSettle();

        // 7. Verify timer is still PAUSED with 29:58 remaining
        expect(find.text('29:58'), findsOneWidget);
        expect(find.text('Paused'), findsOneWidget);
        expect(find.byKey(const Key('resume_button')), findsOneWidget);
        expect(find.byKey(const Key('finish_early_button')), findsOneWidget);
        expect(find.byKey(const Key('start_button')), findsNothing);

        // 8. Tap Resume and verify countdown resumes from 29:58
        await tester.tap(find.byKey(const Key('resume_button')));
        await tester.pump();
        expect(find.text('Running'), findsOneWidget);

        simulatedNow = simulatedNow.add(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('29:57'), findsOneWidget);

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
  });
}
