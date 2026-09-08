import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/main.dart';
import 'package:daily_routine/repositories/activity_repository.dart';

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
}
