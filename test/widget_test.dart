import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/main.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/widgets/activity_card.dart';

void main() {
  testWidgets('Home screen displays Daily Routine header and 3 activity cards', (
    WidgetTester tester,
  ) async {
    final repo = InMemoryActivityRepository();
    await tester.pumpWidget(DailyRoutineApp(repository: repo));

    // Verify Title and Subheader
    expect(find.text('Daily Routine'), findsOneWidget);
    expect(find.text("Today's Plan"), findsOneWidget);
    expect(find.text('0 of 3 activities completed'), findsOneWidget);

    // Verify 3 Cards with names and durations
    expect(find.text('Meditation'), findsOneWidget);
    expect(find.text('10 min'), findsOneWidget);

    expect(find.text('Walking'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);

    expect(find.text('Dumbbells'), findsOneWidget);
    expect(find.text('20 min'), findsOneWidget);
  });

  testWidgets('Tapping Meditation card opens MeditationScreen', (
    WidgetTester tester,
  ) async {
    final repo = InMemoryActivityRepository();
    await tester.pumpWidget(DailyRoutineApp(repository: repo));

    // Tap on the Meditation card
    await tester.tap(find.text('Meditation'));
    await tester.pumpAndSettle();

    // Verify Meditation screen shows timer and Start button
    expect(find.text('10:00'), findsOneWidget);
    expect(find.byKey(const Key('start_button')), findsOneWidget);

    // Tap back button
    final backButton = find.byType(BackButton);
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await tester.pumpAndSettle();
    }

    // Back to Home screen
    expect(find.text('Daily Routine'), findsOneWidget);
  });

  testWidgets('Tapping Dumbbells card opens DumbbellsScreen', (
    WidgetTester tester,
  ) async {
    final repo = InMemoryActivityRepository();
    await tester.pumpWidget(DailyRoutineApp(repository: repo));

    // Tap on the Dumbbells card
    await tester.tap(find.text('Dumbbells'));
    await tester.pumpAndSettle();

    // Verify Dumbbells screen shows Sets text
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('Complete Set 1'), findsOneWidget);

    // Tap back button
    final backButton = find.byType(BackButton);
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await tester.pumpAndSettle();
    }

    // Back to Home screen
    expect(find.text('Daily Routine'), findsOneWidget);
  });

  testWidgets('Tapping Walking card opens WalkingScreen', (
    WidgetTester tester,
  ) async {
    final repo = InMemoryActivityRepository();
    await tester.pumpWidget(DailyRoutineApp(repository: repo));

    // Tap on the Walking card
    await tester.tap(find.text('Walking'));
    await tester.pumpAndSettle();

    // Verify Walking screen shows timer and Start button
    expect(find.text('30:00'), findsOneWidget);
    expect(find.byKey(const Key('start_button')), findsOneWidget);

    // Tap back button
    final backButton = find.byType(BackButton);
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await tester.pumpAndSettle();
    }

    // Back to Home screen
    expect(find.text('Daily Routine'), findsOneWidget);
  });

  testWidgets('Toggling activity completion updates status', (
    WidgetTester tester,
  ) async {
    final repo = InMemoryActivityRepository();
    await tester.pumpWidget(DailyRoutineApp(repository: repo));

    // Initially 0 of 3 completed
    expect(find.text('0 of 3 activities completed'), findsOneWidget);

    // Tap first checkbox
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    // Now 1 of 3 completed
    expect(find.text('1 of 3 activities completed'), findsOneWidget);
  });

  testWidgets('Bottom navigation switches between Today, History, and Progress', (
    WidgetTester tester,
  ) async {
    final repo = InMemoryActivityRepository();
    await tester.pumpWidget(DailyRoutineApp(repository: repo));

    // Verify 3 tabs in bottom navigation bar
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);

    // Initial title is Daily Routine
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Daily Routine')), findsOneWidget);

    // Tap History tab
    await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('History')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('History')), findsOneWidget);

    // Tap Progress tab
    await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Progress')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Progress')), findsOneWidget);
    expect(find.text('Completion Rate'), findsOneWidget);
    expect(find.text('Workout Metrics'), findsOneWidget);

    // Tap Today tab
    await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Today')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Daily Routine')), findsOneWidget);
  });

  group('Daily Rollover & Lifecycle Tests', () {
    testWidgets('App backgrounded on Day 1, resumed on Day 2 resets HomeScreen and archives Day 1', (
      WidgetTester tester,
    ) async {
      var simulatedDate = DateTime(2026, 9, 8);
      final repo = InMemoryActivityRepository(now: () => simulatedDate);
      await tester.pumpWidget(DailyRoutineApp(repository: repo));
      await tester.pumpAndSettle();

      // Day 1: Complete 2 activities
      await tester.tap(find.text('Meditation'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('finish_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('done_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Walking'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('finish_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('done_button')));
      await tester.pumpAndSettle();

      expect(find.text('2 of 3 activities completed'), findsOneWidget);

      // User pauses app on Day 1
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // MIDNIGHT PASSES -> Day 2: Clock advances to 2026-09-09
      simulatedDate = DateTime(2026, 9, 9);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pumpAndSettle();

      // Today should display 0 of 3 completed
      expect(find.text('0 of 3 activities completed'), findsOneWidget);

      // Switch to History tab: Day 1 should be visible with 2 completed
      await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('History')));
      await tester.pumpAndSettle();
      expect(find.text('2/3 DONE'), findsOneWidget);

      // Switch to Progress tab: Day 1 data is preserved in Week view
      await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Progress')));
      await tester.pumpAndSettle();
      expect(find.text('Completion Rate'), findsOneWidget);
    });

    testWidgets('Repeated pause and resume does not duplicate history or corrupt state', (
      WidgetTester tester,
    ) async {
      var simulatedDate = DateTime(2026, 9, 8);
      final repo = InMemoryActivityRepository(now: () => simulatedDate);
      repo.setActivityCompletion('meditation', isCompleted: true);
      await tester.pumpWidget(DailyRoutineApp(repository: repo));
      await tester.pumpAndSettle();

      // Advance to Day 2 and trigger rollover via resume
      simulatedDate = DateTime(2026, 9, 9);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('0 of 3 activities completed'), findsOneWidget);
      // History contains Day 1 (Sep 8) and Day 2 (Sep 9, today at 0%)
      expect(repo.getHistory().length, 2);

      // Repeated pause / resume cycles
      for (int i = 0; i < 3; i++) {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();
      }

      expect(find.text('0 of 3 activities completed'), findsOneWidget);
      expect(repo.getHistory().length, 2);
    });

    testWidgets('Progress 7-day graph shows 0% instead of — for tracked empty days', (
      WidgetTester tester,
    ) async {
      // Initialize with tracked history starting from Sep 7
      var simulatedDate = DateTime(2026, 9, 7);
      final repo = InMemoryActivityRepository(now: () => simulatedDate);
      await tester.pumpWidget(DailyRoutineApp(repository: repo));
      await tester.pumpAndSettle();

      // Advance to Sep 8 (empty day)
      simulatedDate = DateTime(2026, 9, 8);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Advance to Sep 9 (today, with 1 activity completed)
      simulatedDate = DateTime(2026, 9, 9);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      repo.setActivityCompletion('meditation', isCompleted: true);
      await tester.pumpAndSettle();

      // Switch to Progress tab
      await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Progress')));
      await tester.pumpAndSettle();

      // Switch to Week view
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      // Tracked empty days (Sep 7 and Sep 8) must show 0% on the 7-day graph, not —
      expect(find.text('0%'), findsWidgets);
      // Today (Sep 9) shows 33%
      expect(find.text('33%'), findsWidgets);
    });
  });

  group('Partial Task Completion Status Bar Tests', () {
    testWidgets('Partially completed meditation timer displays exact percentage on Home status bar', (
      WidgetTester tester,
    ) async {
      var simulatedDate = DateTime(2026, 9, 9, 10, 0, 0);
      final repo = InMemoryActivityRepository(now: () => simulatedDate);
      await tester.pumpWidget(DailyRoutineApp(repository: repo));
      await tester.pumpAndSettle();

      // Open Meditation
      await tester.tap(find.text('Meditation'));
      await tester.pumpAndSettle();

      // Start timer
      await tester.tap(find.byKey(const Key('start_button')));
      await tester.pump();

      // Advance clock by 4 minutes (40% of 10:00)
      simulatedDate = simulatedDate.add(const Duration(minutes: 4));
      // Pause timer
      await tester.tap(find.byKey(const Key('pause_button')));
      await tester.pumpAndSettle();

      // Navigate back to Home
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Meditation card on Home must now display 40%
      final meditationCard = find.ancestor(
        of: find.text('Meditation'),
        matching: find.byType(ActivityCard),
      );
      expect(find.descendant(of: meditationCard, matching: find.text('40%')), findsOneWidget);

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.descendant(of: meditationCard, matching: find.byType(LinearProgressIndicator)),
      );
      expect(progressIndicator.value, closeTo(0.4, 0.01));
    });

    testWidgets('Toggling checkbox on partially completed card completes it to 100%, unchecking resets to 0%', (
      WidgetTester tester,
    ) async {
      var simulatedDate = DateTime(2026, 9, 9, 10, 0, 0);
      final repo = InMemoryActivityRepository(now: () => simulatedDate);
      await tester.pumpWidget(DailyRoutineApp(repository: repo));
      await tester.pumpAndSettle();

      // Partially complete Walking (15 minutes out of 30:00 = 50%)
      await tester.tap(find.text('Walking'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start_button')));
      await tester.pump();
      simulatedDate = simulatedDate.add(const Duration(minutes: 15));
      await tester.tap(find.byKey(const Key('pause_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      final walkingCard = find.ancestor(
        of: find.text('Walking'),
        matching: find.byType(ActivityCard),
      );
      expect(find.descendant(of: walkingCard, matching: find.text('50%')), findsOneWidget);

      // Check the checkbox directly on the card
      final checkbox = find.descendant(of: walkingCard, matching: find.byType(Checkbox));
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      expect(find.descendant(of: walkingCard, matching: find.text('100%')), findsOneWidget);

      // Uncheck the checkbox
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      expect(find.descendant(of: walkingCard, matching: find.text('0%')), findsOneWidget);
    });

    testWidgets('Partially completing dumbbell sets updates Dumbbells card status bar', (
      WidgetTester tester,
    ) async {
      final repo = InMemoryActivityRepository();
      await tester.pumpWidget(DailyRoutineApp(repository: repo));
      await tester.pumpAndSettle();

      // Open Dumbbells
      await tester.tap(find.text('Dumbbells'));
      await tester.pumpAndSettle();

      // Complete Set 1
      await tester.tap(find.text('Complete Set 1'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '12');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Navigate back to Home
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      final dumbbellsCard = find.ancestor(
        of: find.text('Dumbbells'),
        matching: find.byType(ActivityCard),
      );
      expect(find.descendant(of: dumbbellsCard, matching: find.text('33%')), findsOneWidget);
    });
  });

  group('Circular Progress Ring Layout & Text Containment Tests', () {
    testWidgets('Circular progress ring renders at 66x66 with safe centered text at 0%, 33%, 66%, and 100%', (
      WidgetTester tester,
    ) async {
      final repo = InMemoryActivityRepository();
      await tester.pumpWidget(DailyRoutineApp(repository: repo));
      await tester.pumpAndSettle();

      // At 0%
      expect(find.text('0%'), findsWidgets);
      expect(find.text('Complete'), findsOneWidget);

      final indicatorFinder = find.byType(CircularProgressIndicator);
      expect(indicatorFinder, findsOneWidget);
      final indicatorSize = tester.getSize(indicatorFinder);
      expect(indicatorSize.width, 66.0);
      expect(indicatorSize.height, 66.0);

      // Verify FittedBox is used for text containment
      expect(find.byType(FittedBox), findsWidgets);

      // Complete 1 activity -> 33%
      repo.setActivityCompletion('meditation', isCompleted: true);
      await tester.pumpWidget(DailyRoutineApp(key: UniqueKey(), repository: repo));
      await tester.pumpAndSettle();
      expect(find.text('33%'), findsWidgets);
      expect(find.text('Complete'), findsOneWidget);

      // Complete 2nd activity -> 66%
      repo.setActivityCompletion('walking', isCompleted: true);
      await tester.pumpWidget(DailyRoutineApp(key: UniqueKey(), repository: repo));
      await tester.pumpAndSettle();
      expect(find.text('66%'), findsWidgets);
      expect(find.text('Complete'), findsOneWidget);

      // Complete 3rd activity -> 100%
      repo.setActivityCompletion('dumbbells', isCompleted: true);
      await tester.pumpWidget(DailyRoutineApp(key: UniqueKey(), repository: repo));
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsWidgets);
      expect(find.text('Complete'), findsOneWidget);

      // Verify indicator is still 66x66 and no rendering overflow occurred
      final indicatorSize100 = tester.getSize(indicatorFinder);
      expect(indicatorSize100.width, 66.0);
      expect(indicatorSize100.height, 66.0);
    });
  });
}
