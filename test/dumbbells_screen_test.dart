import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/main.dart';
import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/screens/dumbbells_screen.dart';

void main() {
  group('DumbbellsScreen Widget Tests', () {
    late Activity testActivity;
    late ActivityRepository mockRepository;

    setUp(() {
      testActivity = const Activity(
        id: '3',
        name: 'Dumbbells',
        activityType: ActivityType.dumbbells,
        defaultDuration: Duration.zero,
      );
      mockRepository = InMemoryActivityRepository();
      // Ensure we clear and seed specifically for our tests if needed
    });

    testWidgets('renders initial Set 1 of 3 and Complete Set 1 button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DumbbellsScreen(
            activity: testActivity,
            repository: mockRepository,
          ),
        ),
      );

      expect(find.text('Dumbbells'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      expect(find.text('Complete Set 1'), findsOneWidget);
      expect(find.text("Can't do today"), findsOneWidget);
    });

    testWidgets('tapping Complete Set asks for reps and advances to next set', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DumbbellsScreen(
            activity: testActivity,
            repository: mockRepository,
          ),
        ),
      );

      await tester.tap(find.text('Complete Set 1'));
      await tester.pumpAndSettle();

      expect(find.text('Set 1 Completed'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '12');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('2/3'), findsOneWidget);
      expect(find.text('Complete Set 2'), findsOneWidget);
    });

    testWidgets('completing final set shows Done state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DumbbellsScreen(
            activity: testActivity,
            repository: mockRepository,
          ),
        ),
      );

      // Complete Set 1
      await tester.tap(find.text('Complete Set 1'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '12');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Complete Set 2
      await tester.tap(find.text('Complete Set 2'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '10');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Complete Final Set (Set 3)
      await tester.tap(find.text('Complete Final Set'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '8');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Great job!'), findsOneWidget);
      expect(find.text('All 3 sets completed.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('tapping Can\'t do today calls pop', (WidgetTester tester) async {
      bool didPop = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onDidRemovePage: (route) {
              didPop = true;
            },
            pages: [
              MaterialPage(
                child: DumbbellsScreen(
                  activity: testActivity,
                  repository: mockRepository,
                ),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text("Can't do today"));
      await tester.pumpAndSettle();

      expect(didPop, isTrue);
    });

    testWidgets('resumes from existing completed sets when opened', (WidgetTester tester) async {
      const existingActivity = Activity(
        id: '3',
        name: 'Dumbbells',
        activityType: ActivityType.dumbbells,
        defaultDuration: Duration.zero,
        completedSetsReps: [12, 10], // 2 sets already done
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DumbbellsScreen(
            activity: existingActivity,
            repository: mockRepository,
          ),
        ),
      );

      // Should show Set 3 of 3, not Set 1
      expect(find.text('3/3'), findsOneWidget);
      expect(find.text('Complete Final Set'), findsOneWidget);
    });

    testWidgets('validates rep input and prevents negative or invalid values', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DumbbellsScreen(
            activity: testActivity,
            repository: mockRepository,
          ),
        ),
      );

      await tester.tap(find.text('Complete Set 1'));
      await tester.pumpAndSettle();

      // Enter negative number
      await tester.enterText(find.byType(TextField), '-5');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show error and remain on Set 1
      expect(find.text('Please enter valid reps (1-999)'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);

      // Correct the input
      await tester.enterText(find.byType(TextField), '12');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Now dialog is closed and advanced to Set 2
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('2/3'), findsOneWidget);
    });

    testWidgets(
      'completing Set 1, navigating back to Home, and reopening Dumbbells preserves Set 2 position',
      (tester) async {
        final repo = InMemoryActivityRepository();
        await tester.pumpWidget(DailyRoutineApp(repository: repo));

        // 1. Open Dumbbells
        await tester.tap(find.text('Dumbbells'));
        await tester.pumpAndSettle();
        expect(find.text('1/3'), findsOneWidget);
        expect(find.text('Complete Set 1'), findsOneWidget);

        // 2. Complete Set 1 with 12 reps
        await tester.tap(find.text('Complete Set 1'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '12');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('2/3'), findsOneWidget);
        expect(find.text('Complete Set 2'), findsOneWidget);

        // 3. Navigate back to Home
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Daily Routine'), findsOneWidget);

        // 4. Reopen Dumbbells
        await tester.tap(find.text('Dumbbells'));
        await tester.pumpAndSettle();

        // 5. Verify it is still at Set 2 of 3
        expect(find.text('2/3'), findsOneWidget);
        expect(find.text('Complete Set 2'), findsOneWidget);
      },
    );
  });
}
