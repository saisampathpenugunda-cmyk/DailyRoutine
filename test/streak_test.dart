import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_routine/controllers/streak_controller.dart';
import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/models/day_history.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/screens/home_screen.dart';
import 'package:daily_routine/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Activity makeActivity({
    required String id,
    required String name,
    bool isCompleted = false,
    bool isSkipped = false,
    bool isEnabled = true,
  }) {
    return Activity(
      id: id,
      name: name,
      activityType: ActivityType.meditation,
      defaultDuration: const Duration(minutes: 10),
      isCompleted: isCompleted,
      isSkipped: isSkipped,
      isEnabled: isEnabled,
    );
  }

  DayHistory makeDayHistory({
    required String dateKey,
    required List<Activity> activities,
  }) {
    return DayHistory(
      dateKey: dateKey,
      activities: activities,
      recordedAt: DateTime.parse('${dateKey}T23:59:59Z'),
    );
  }

  group('StreakController Unit & Calculation Tests', () {
    test('1. First successful day increments current and best streak to 1', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final repo = InMemoryActivityRepository(
        now: () => DateTime(2026, 9, 10, 10, 0),
      );

      final controller = await StreakController.init(
        repository: repo,
        prefs: prefs,
        now: () => DateTime(2026, 9, 10, 10, 0),
      );

      // Initially today is not completed
      expect(controller.currentStreak, 0);
      expect(controller.bestStreak, 0);

      // Complete all enabled activities today
      repo.setActivityCompletion('meditation', isCompleted: true);
      repo.setActivityCompletion('walking', isCompleted: true);
      repo.setActivityCompletion('dumbbells', isCompleted: true);

      controller.recalculate();

      expect(controller.currentStreak, 1);
      expect(controller.bestStreak, 1);
      expect(prefs.getInt(StreakController.currentStreakKey), 1);
      expect(prefs.getInt(StreakController.bestStreakKey), 1);
    });

    test('2. Consecutive successful days calculate correct streak across calendar dates', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Day 1 (Sep 8) and Day 2 (Sep 9) completed in history
      final history = [
        makeDayHistory(
          dateKey: '2026-09-08',
          activities: [
            makeActivity(id: 'meditation', name: 'Meditation', isCompleted: true),
            makeActivity(id: 'walking', name: 'Walking', isCompleted: true),
          ],
        ),
        makeDayHistory(
          dateKey: '2026-09-09',
          activities: [
            makeActivity(id: 'meditation', name: 'Meditation', isCompleted: true),
            makeActivity(id: 'walking', name: 'Walking', isCompleted: true),
          ],
        ),
      ];

      final repo = InMemoryActivityRepository(
        initialHistory: history,
        now: () => DateTime(2026, 9, 10, 10, 0),
      );

      final controller = await StreakController.init(
        repository: repo,
        prefs: prefs,
        now: () => DateTime(2026, 9, 10, 10, 0),
      );

      // Before completing today (Sep 10), streak from yesterday is 2
      expect(controller.currentStreak, 2);
      expect(controller.bestStreak, 2);

      // Complete all activities today (Sep 10) -> streak becomes 3
      repo.setActivityCompletion('meditation', isCompleted: true);
      repo.setActivityCompletion('walking', isCompleted: true);
      repo.setActivityCompletion('dumbbells', isCompleted: true);

      controller.recalculate();

      expect(controller.currentStreak, 3);
      expect(controller.bestStreak, 3);
      expect(prefs.getInt(StreakController.currentStreakKey), 3);
      expect(prefs.getInt(StreakController.bestStreakKey), 3);
    });

    test('3. Missed, skipped, or partial days reset current streak', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Case A: Partial day in history (1 of 2 completed on Sep 9)
      final historyPartial = [
        makeDayHistory(
          dateKey: '2026-09-08',
          activities: [
            makeActivity(id: 'meditation', name: 'Meditation', isCompleted: true),
          ],
        ),
        makeDayHistory(
          dateKey: '2026-09-09',
          activities: [
            makeActivity(id: 'meditation', name: 'Meditation', isCompleted: true),
            makeActivity(id: 'walking', name: 'Walking', isCompleted: false), // Partial!
          ],
        ),
      ];

      final repoPartial = InMemoryActivityRepository(
        initialHistory: historyPartial,
        now: () => DateTime(2026, 9, 10, 10, 0),
      );

      final controllerPartial = await StreakController.init(
        repository: repoPartial,
        prefs: prefs,
        now: () => DateTime(2026, 9, 10, 10, 0),
      );

      // Current streak is 0 because yesterday was partial
      expect(controllerPartial.currentStreak, 0);
      // Best streak retains the 1 from Sep 8
      expect(controllerPartial.bestStreak, 1);

      // Case B: Skipped day in history (Sep 9 had a skipped activity)
      final historySkipped = [
        makeDayHistory(
          dateKey: '2026-09-08',
          activities: [
            makeActivity(id: 'meditation', name: 'Meditation', isCompleted: true),
          ],
        ),
        makeDayHistory(
          dateKey: '2026-09-09',
          activities: [
            makeActivity(id: 'meditation', name: 'Meditation', isCompleted: true),
            makeActivity(id: 'walking', name: 'Walking', isSkipped: true), // Skipped!
          ],
        ),
      ];

      final repoSkipped = InMemoryActivityRepository(
        initialHistory: historySkipped,
        now: () => DateTime(2026, 9, 10, 10, 0),
      );

      final controllerSkipped = await StreakController.init(
        repository: repoSkipped,
        prefs: prefs,
        now: () => DateTime(2026, 9, 10, 10, 0),
      );

      expect(controllerSkipped.currentStreak, 0);
      expect(controllerSkipped.bestStreak, 1);

      // Case C: Missing calendar date (Sep 8 completed, Sep 9 missing, today is Sep 10)
      final historyMissed = [
        makeDayHistory(
          dateKey: '2026-09-08',
          activities: [
            makeActivity(id: 'meditation', name: 'Meditation', isCompleted: true),
          ],
        ),
      ];

      final repoMissed = InMemoryActivityRepository(
        initialHistory: historyMissed,
        now: () => DateTime(2026, 9, 10, 10, 0),
      );

      final controllerMissed = await StreakController.init(
        repository: repoMissed,
        prefs: prefs,
        now: () => DateTime(2026, 9, 10, 10, 0),
      );

      // Sep 9 was missed entirely -> current streak resets to 0
      expect(controllerMissed.currentStreak, 0);
      expect(controllerMissed.bestStreak, 1);
    });

    test('4. Best streak remains intact after current streak reset', () async {
      SharedPreferences.setMockInitialValues({
        StreakController.currentStreakKey: 5,
        StreakController.bestStreakKey: 12,
      });
      final prefs = await SharedPreferences.getInstance();

      // Only today exists, not yet completed
      final repo = InMemoryActivityRepository(
        now: () => DateTime(2026, 9, 10, 10, 0),
      );

      final controller = await StreakController.init(
        repository: repo,
        prefs: prefs,
        now: () => DateTime(2026, 9, 10, 10, 0),
      );

      // Current streak resets to 0 because yesterday is absent/missed
      expect(controller.currentStreak, 0);
      // Best streak must NEVER decrease
      expect(controller.bestStreak, 12);
      expect(prefs.getInt(StreakController.bestStreakKey), 12);

      // Completing today gives current streak = 1, best streak remains 12
      repo.setActivityCompletion('meditation', isCompleted: true);
      repo.setActivityCompletion('walking', isCompleted: true);
      repo.setActivityCompletion('dumbbells', isCompleted: true);

      controller.recalculate();

      expect(controller.currentStreak, 1);
      expect(controller.bestStreak, 12);
    });

    test('5. 0 enabled activities days do not count toward streak', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Past day with 0 enabled activities
      final history = [
        makeDayHistory(
          dateKey: '2026-09-08',
          activities: [
            makeActivity(id: 'meditation', name: 'Meditation', isCompleted: true),
          ],
        ),
        makeDayHistory(
          dateKey: '2026-09-09',
          activities: [
            makeActivity(id: 'meditation', name: 'Meditation', isEnabled: false),
            makeActivity(id: 'walking', name: 'Walking', isEnabled: false),
          ],
        ),
      ];

      final repo = InMemoryActivityRepository(
        initialHistory: history,
        now: () => DateTime(2026, 9, 10, 10, 0),
      );

      final controller = await StreakController.init(
        repository: repo,
        prefs: prefs,
        now: () => DateTime(2026, 9, 10, 10, 0),
      );

      // Sep 9 had 0 enabled activities, so it does not count and breaks the streak
      expect(controller.currentStreak, 0);

      // Also if all activities today are disabled:
      repo.setActivityEnabled('meditation', false);
      repo.setActivityEnabled('walking', false);
      repo.setActivityEnabled('dumbbells', false);

      controller.recalculate();
      expect(controller.currentStreak, 0);
    });

    test('6. Streaks persist across simulated app restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final history = [
        makeDayHistory(
          dateKey: '2026-09-08',
          activities: [makeActivity(id: 'meditation', name: 'Meditation', isCompleted: true)],
        ),
        makeDayHistory(
          dateKey: '2026-09-09',
          activities: [makeActivity(id: 'meditation', name: 'Meditation', isCompleted: true)],
        ),
      ];

      final repo = InMemoryActivityRepository(
        initialHistory: history,
        now: () => DateTime(2026, 9, 10, 10, 0),
      );

      final controller1 = await StreakController.init(
        repository: repo,
        prefs: prefs,
        now: () => DateTime(2026, 9, 10, 10, 0),
      );

      // Complete today to achieve 3-day streak
      repo.setActivityCompletion('meditation', isCompleted: true);
      repo.setActivityCompletion('walking', isCompleted: true);
      repo.setActivityCompletion('dumbbells', isCompleted: true);
      controller1.recalculate();

      expect(controller1.currentStreak, 3);
      expect(controller1.bestStreak, 3);

      // Simulate app restart: re-initialize with the same SharedPreferences
      final controller2 = await StreakController.init(
        repository: repo,
        prefs: prefs,
        now: () => DateTime(2026, 9, 10, 10, 0),
      );

      expect(controller2.currentStreak, 3);
      expect(controller2.bestStreak, 3);
      expect(prefs.getInt(StreakController.currentStreakKey), 3);
      expect(prefs.getInt(StreakController.bestStreakKey), 3);
    });

    test('7. Reordering, deleting, or changing duration does not corrupt past streak data', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final history = [
        makeDayHistory(
          dateKey: '2026-09-08',
          activities: [makeActivity(id: 'meditation', name: 'Meditation', isCompleted: true)],
        ),
        makeDayHistory(
          dateKey: '2026-09-09',
          activities: [makeActivity(id: 'meditation', name: 'Meditation', isCompleted: true)],
        ),
      ];

      final repo = InMemoryActivityRepository(
        initialHistory: history,
        now: () => DateTime(2026, 9, 10, 10, 0),
      );

      final controller = await StreakController.init(
        repository: repo,
        prefs: prefs,
        now: () => DateTime(2026, 9, 10, 10, 0),
      );

      expect(controller.currentStreak, 2);
      expect(controller.bestStreak, 2);

      // Reorder activities
      repo.reorderEnabledActivities(0, 1);
      controller.recalculate();
      expect(controller.currentStreak, 2);
      expect(controller.bestStreak, 2);

      // Delete an activity
      repo.deleteActivity('walking');
      controller.recalculate();
      expect(controller.currentStreak, 2);
      expect(controller.bestStreak, 2);

      // Update default duration of an activity
      final med = repo.getActivityById('meditation');
      if (med != null) {
        repo.updateActivity(med.copyWith(defaultDuration: const Duration(minutes: 25)));
      }
      controller.recalculate();
      expect(controller.currentStreak, 2);
      expect(controller.bestStreak, 2);
    });
  });

  group('Home Screen Streak Card UI Integration Tests', () {
    late InMemoryActivityRepository repository;
    late ThemeController themeController;
    late StreakController streakController;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repository = InMemoryActivityRepository();
      themeController = ThemeController(ThemeMode.light);
      streakController = StreakController(repository: repository);
    });

    Widget buildTestApp() {
      return ThemeScope(
        controller: themeController,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.value,
          home: HomeScreen(
            repository: repository,
            streakController: streakController,
          ),
        ),
      );
    }

    testWidgets('8. Home renders compact streak card with 🔥 0 Day Streak initially', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('streak_card')), findsOneWidget);
      expect(find.byKey(const Key('current_streak_text')), findsOneWidget);
      expect(find.text('🔥 0 Day Streak'), findsOneWidget);
      expect(find.byKey(const Key('best_streak_text')), findsOneWidget);
      expect(find.text('Best: 0 days'), findsOneWidget);
    });

    testWidgets('9. Completing all activities updates streak card in real-time', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('🔥 0 Day Streak'), findsOneWidget);

      // Complete all 3 activities on Home screen
      repository.setActivityCompletion('meditation', isCompleted: true);
      repository.setActivityCompletion('walking', isCompleted: true);
      repository.setActivityCompletion('dumbbells', isCompleted: true);

      // Trigger UI reload
      streakController.recalculate();
      await tester.pumpAndSettle();

      expect(find.text('🔥 1 Day Streak'), findsOneWidget);
      expect(find.text('Best: 1 day'), findsOneWidget);

      // Unchecking an activity updates streak back to 0
      repository.setActivityCompletion('meditation', isCompleted: false);
      streakController.recalculate();
      await tester.pumpAndSettle();

      expect(find.text('🔥 0 Day Streak'), findsOneWidget);
      // Best streak remains 1
      expect(find.text('Best: 1 day'), findsOneWidget);
    });

    testWidgets('10. Streak card renders consistently in Dark Mode', (tester) async {
      themeController.setThemeMode(ThemeMode.dark);
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('streak_card')), findsOneWidget);
      expect(find.text('🔥 0 Day Streak'), findsOneWidget);
    });
  });
}
