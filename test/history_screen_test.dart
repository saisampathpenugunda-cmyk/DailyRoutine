import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/main.dart';
import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/models/day_history.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/screens/history_screen.dart';

void main() {
  group('HistoryScreen and Navigation Tests', () {
    testWidgets('Displays empty history placeholder when no history exists', (
      WidgetTester tester,
    ) async {
      final repo = InMemoryActivityRepository(autoCreateTodayHistory: false);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryScreen(repository: repo),
          ),
        ),
      );

      expect(find.text('No History Recorded Yet'), findsOneWidget);
      expect(
        find.text(
          'Complete your routines today. All past data will be archived and viewable here across days.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Displays historical days and activity rows when history exists', (
      WidgetTester tester,
    ) async {
      final repo = InMemoryActivityRepository(
        autoCreateTodayHistory: false,
        initialHistory: [
          DayHistory(
            dateKey: '2026-09-06',
            recordedAt: DateTime(2026, 9, 6, 21, 0),
            activities: [
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
                isCompleted: false,
                isSkipped: true,
              ),
              const Activity(
                id: 'dumbbells',
                name: 'Dumbbells',
                activityType: ActivityType.dumbbells,
                defaultDuration: Duration(minutes: 20),
                isCompleted: true,
                completedSetsReps: [12, 10, 8],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryScreen(repository: repo),
          ),
        ),
      );

      expect(find.text('2/3 DONE'), findsOneWidget);
      expect(find.text('Meditation'), findsOneWidget);
      expect(find.text('Walking'), findsOneWidget);
      expect(find.text('Dumbbells'), findsOneWidget);
      expect(find.text('Sets: 12, 10, 8 reps'), findsOneWidget);
    });

    testWidgets('Bottom navigation switches between Today and History tabs', (
      WidgetTester tester,
    ) async {
      final repo = InMemoryActivityRepository();
      await tester.pumpWidget(DailyRoutineApp(repository: repo));

      // Initially on Today tab
      expect(find.text('Daily Routine'), findsOneWidget);
      expect(find.text("Today's Plan"), findsOneWidget);

      // Tap History tab in bottom navigation
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Today's record is immediately present in History with 0/3 DONE
      expect(find.text('0/3 DONE'), findsOneWidget);

      // Tap back to Today tab
      await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Today')));
      await tester.pumpAndSettle();

      // Back on Today screen
      expect(find.text("Today's Plan"), findsOneWidget);
    });
  });
}
