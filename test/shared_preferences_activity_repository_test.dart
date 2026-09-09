import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_routine/controllers/routine_timer_controller.dart';
import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/repositories/shared_preferences_activity_repository.dart';

void main() {
  group('SharedPreferencesActivityRepository Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initializes with default activities when empty', () async {
      final repository = await SharedPreferencesActivityRepository.init();
      final activities = repository.getActivities();
      
      expect(activities.length, 3);
      expect(activities[0].id, 'meditation');
      expect(activities[1].id, 'walking');
      expect(activities[2].id, 'dumbbells');
    });

    test('Saves and loads completion persistence', () async {
      final repo1 = await SharedPreferencesActivityRepository.init();
      repo1.setActivityCompletion('walking', isCompleted: true);
      
      // Simulate app restart by recreating the repository
      final repo2 = await SharedPreferencesActivityRepository.init();
      final walkingActivity = repo2.getActivityById('walking');
      
      expect(walkingActivity, isNotNull);
      expect(walkingActivity!.isCompleted, isTrue);
      expect(walkingActivity.isSkipped, isFalse);
    });

    test('Saves and loads skipped persistence', () async {
      final repo1 = await SharedPreferencesActivityRepository.init();
      repo1.setActivitySkipped('meditation', isSkipped: true);
      
      final repo2 = await SharedPreferencesActivityRepository.init();
      final meditationActivity = repo2.getActivityById('meditation');
      
      expect(meditationActivity, isNotNull);
      expect(meditationActivity!.isSkipped, isTrue);
      expect(meditationActivity.isCompleted, isFalse);
    });

    test('Saves and loads dumbbell set/rep persistence', () async {
      final repo1 = await SharedPreferencesActivityRepository.init();
      final dumbbells = repo1.getActivityById('dumbbells')!;
      
      final updatedDumbbells = dumbbells.copyWith(
        completedSetsReps: [12, 10, 8],
      );
      repo1.updateActivity(updatedDumbbells);
      
      final repo2 = await SharedPreferencesActivityRepository.init();
      final loadedDumbbells = repo2.getActivityById('dumbbells');
      
      expect(loadedDumbbells, isNotNull);
      expect(loadedDumbbells!.completedSetsReps, [12, 10, 8]);
    });

    test('Loads existing activity state properly (saving activity state)', () async {
      final repo1 = await SharedPreferencesActivityRepository.init();
      final customActivity = const Activity(
        id: 'custom',
        name: 'Custom',
        activityType: ActivityType.walking,
        defaultDuration: Duration(minutes: 5),
        isCompleted: true,
        completedSetsReps: [5],
      );
      repo1.addActivity(customActivity);

      final repo2 = await SharedPreferencesActivityRepository.init();
      final loadedCustom = repo2.getActivityById('custom');
      
      expect(loadedCustom, isNotNull);
      expect(loadedCustom!.name, 'Custom');
      expect(loadedCustom.isCompleted, isTrue);
      expect(loadedCustom.completedSetsReps, [5]);
    });

    test('Preserves corrupted storage data into backup key without wiping', () async {
      final prefs = await SharedPreferences.getInstance();
      const corruptedJson = '{invalid_json_data...';
      await prefs.setString('activities', corruptedJson);

      final repo = SharedPreferencesActivityRepository(prefs);
      // Defaults loaded into memory to keep app operational
      expect(repo.getActivities().length, 3);
      // But the raw corrupted data was backed up
      expect(prefs.getString('activities_corrupted_backup'), corruptedJson);
    });

    test('addActivity with existing ID replaces rather than duplicates', () async {
      final repo = await SharedPreferencesActivityRepository.init();
      final initialCount = repo.getActivities().length;

      const updatedMeditation = Activity(
        id: 'meditation',
        name: 'Mindful Meditation',
        activityType: ActivityType.meditation,
        defaultDuration: Duration(minutes: 15),
      );

      repo.addActivity(updatedMeditation);
      expect(repo.getActivities().length, initialCount);
      expect(repo.getActivityById('meditation')?.name, 'Mindful Meditation');
      expect(repo.getActivityById('meditation')?.defaultDuration.inMinutes, 15);
    });

    test('Maintains same-day in-progress state across restarts without reset', () async {
      final repo1 = await SharedPreferencesActivityRepository.init();
      repo1.setActivityCompletion('meditation', isCompleted: true);
      final dumbbells = repo1.getActivityById('dumbbells')!;
      repo1.updateActivity(dumbbells.copyWith(completedSetsReps: [12]));
      await repo1.flush();

      // Simulate app restart on the same day
      final repo2 = await SharedPreferencesActivityRepository.init();
      expect(repo2.getActivityById('meditation')?.isCompleted, isTrue);
      expect(repo2.getActivityById('dumbbells')?.completedSetsReps, [12]);
      // Today record exists in history with in-progress completion
      expect(repo2.getHistory().length, 1);
      expect(repo2.getHistory()[0].completedCount, 1);
    });

    test('Date rollover archives previous day into history and resets daily state', () async {
      final repo = await SharedPreferencesActivityRepository.init();
      repo.setActivityCompletion('meditation', isCompleted: true);
      repo.setActivitySkipped('walking', isSkipped: true);
      final dumbbells = repo.getActivityById('dumbbells')!;
      repo.updateActivity(dumbbells.copyWith(completedSetsReps: [10, 10]));
      await repo.flush();

      // Simulate a rollover to tomorrow
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await repo.simulateDateRollover(tomorrow);

      // History must have archived yesterday's entry (index 1) and created today's (index 0 at 0%)
      final history = repo.getHistory();
      expect(history.length, 2);
      final archivedMeditation = history[1].activities.firstWhere((a) => a.id == 'meditation');
      final archivedWalking = history[1].activities.firstWhere((a) => a.id == 'walking');
      final archivedDumbbells = history[1].activities.firstWhere((a) => a.id == 'dumbbells');

      expect(archivedMeditation.isCompleted, isTrue);
      expect(archivedWalking.isSkipped, isTrue);
      expect(archivedDumbbells.completedSetsReps, [10, 10]);
      expect(history[0].completedCount, 0);

      // Current activities for new day must be reset but templates preserved
      final todayMeditation = repo.getActivityById('meditation');
      final todayWalking = repo.getActivityById('walking');
      final todayDumbbells = repo.getActivityById('dumbbells');

      expect(todayMeditation?.isCompleted, isFalse);
      expect(todayWalking?.isSkipped, isFalse);
      expect(todayDumbbells?.completedSetsReps, isEmpty);
      // Durations preserved
      expect(todayMeditation?.defaultDuration.inMinutes, 10);
      expect(todayWalking?.defaultDuration.inMinutes, 30);
      expect(todayDumbbells?.defaultDuration.inMinutes, 20);
    });

    test('History persists across repository reinitialization', () async {
      final prefs = await SharedPreferences.getInstance();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final y = yesterday.year.toString().padLeft(4, '0');
      final m = yesterday.month.toString().padLeft(2, '0');
      final d = yesterday.day.toString().padLeft(2, '0');
      await prefs.setString('last_active_date', '$y-$m-$d');

      final repo1 = SharedPreferencesActivityRepository(prefs);
      repo1.setActivityCompletion('meditation', isCompleted: true);
      await repo1.simulateDateRollover(DateTime.now());

      // Re-initialize repository on the same day
      final repo2 = await SharedPreferencesActivityRepository.init();
      final history = repo2.getHistory();
      expect(history.length, 2);
      expect(history[1].completedCount, 1);
      expect(history[0].completedCount, 0);
    });

    test('Reminder configurations persist across repository instances', () async {
      final repo1 = await SharedPreferencesActivityRepository.init();
      final currentMeditation = repo1.getReminderConfig('meditation');
      final updatedMeditation = currentMeditation.copyWith(
        mainHour: 6,
        mainMinute: 45,
        isBackupEnabled: true,
        backupHour: 7,
        backupMinute: 15,
      );
      repo1.updateReminderConfig(updatedMeditation);
      await repo1.flush();

      // Simulate app restart
      final repo2 = await SharedPreferencesActivityRepository.init();
      final loaded = repo2.getReminderConfig('meditation');

      expect(loaded.mainHour, 6);
      expect(loaded.mainMinute, 45);
      expect(loaded.isBackupEnabled, isTrue);
      expect(loaded.backupHour, 7);
      expect(loaded.backupMinute, 15);
    });

    test('getTimerController caches and returns same controller instance', () async {
      final repo = await SharedPreferencesActivityRepository.init();
      final timer1 = repo.getTimerController('meditation');
      final timer2 = repo.getTimerController('meditation');

      expect(identical(timer1, timer2), isTrue);
      expect(timer1.totalDuration, const Duration(minutes: 10));
    });

    test('Timer paused state persists to storage and restores on repo re-init', () async {
      final repo1 = await SharedPreferencesActivityRepository.init();
      final timer = repo1.getTimerController('meditation');

      timer.start();
      timer.pause();
      await repo1.flush();

      expect(timer.state, TimerState.paused);

      // Simulate app restart on same day
      final repo2 = await SharedPreferencesActivityRepository.init();
      final restoredTimer = repo2.getTimerController('meditation');

      expect(restoredTimer.state, TimerState.paused);
      expect(restoredTimer.isPaused, isTrue);
      expect(restoredTimer.remaining.inMinutes, inInclusiveRange(9, 10));
    });

    test('Date rollover resets timer controllers and clears saved timer states', () async {
      final repo = await SharedPreferencesActivityRepository.init();
      final timer = repo.getTimerController('meditation');

      timer.start();
      timer.pause();
      await repo.flush();
      expect(timer.isPaused, isTrue);

      // Simulate rollover to tomorrow
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await repo.simulateDateRollover(tomorrow);

      expect(timer.state, TimerState.initial);
      expect(timer.remaining, const Duration(minutes: 10));
    });

    test('No silent last_active_date overwrite: activity save or flush does not mutate last_active_date', () async {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final y = today.year.toString().padLeft(4, '0');
      final m = today.month.toString().padLeft(2, '0');
      final d = today.day.toString().padLeft(2, '0');
      final todayKey = '$y-$m-$d';
      await prefs.setString('last_active_date', todayKey);

      final repo = SharedPreferencesActivityRepository(prefs);
      // Simulate activity toggle and flush
      repo.setActivityCompletion('meditation', isCompleted: true);
      await repo.flush();

      // last_active_date must NOT have been changed by saving or flushing
      expect(prefs.getString('last_active_date'), todayKey);
    });

    test('Day 2 completion isolation: completing activity on Day 2 leaves Day 1 history unchanged', () async {
      final repo = await SharedPreferencesActivityRepository.init();
      final day2 = DateTime(2026, 9, 9, 10, 0);

      // Setup Day 1
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_active_date', '2026-09-08');
      repo.setActivityCompletion('meditation', isCompleted: true);
      repo.setActivityCompletion('walking', isCompleted: true);
      await repo.flush();

      // Rollover to Day 2
      final rolledOver = await repo.checkDateRollover(now: day2);
      expect(rolledOver, isTrue);
      await repo.flush();

      // History must have Day 2 (newest, 0 completed) and Day 1 (2 completed)
      final history = repo.getHistory();
      expect(history.length, 2);
      expect(history[0].dateKey, '2026-09-09');
      expect(history[0].completedCount, 0);
      expect(history[1].dateKey, '2026-09-08');
      expect(history[1].completedCount, 2);

      // Complete Meditation on Day 2
      repo.setActivityCompletion('meditation', isCompleted: true);
      await repo.flush();

      // Day 1 history must remain completely unchanged
      final historyAfterDay2 = repo.getHistory();
      expect(historyAfterDay2.length, 2);
      expect(historyAfterDay2[1].dateKey, '2026-09-08');
      expect(historyAfterDay2[1].completedCount, 2);
      expect(historyAfterDay2[1].activities.firstWhere((a) => a.id == 'meditation').isCompleted, isTrue);
      expect(historyAfterDay2[1].activities.firstWhere((a) => a.id == 'walking').isCompleted, isTrue);

      // Day 2 history and live activities must have meditation completed
      expect(historyAfterDay2[0].dateKey, '2026-09-09');
      expect(historyAfterDay2[0].completedCount, 1);
      final todayActs = repo.getActivities();
      expect(todayActs.firstWhere((a) => a.id == 'meditation').isCompleted, isTrue);
      expect(todayActs.firstWhere((a) => a.id == 'walking').isCompleted, isFalse);
    });

    test('Repeated checkDateRollover calls on the same day are idempotent and do not duplicate history', () async {
      final repo = await SharedPreferencesActivityRepository.init();
      final day2 = DateTime(2026, 9, 9, 10, 0);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_active_date', '2026-09-08');
      repo.setActivityCompletion('meditation', isCompleted: true);
      await repo.flush();

      // First check: triggers rollover
      final firstCheck = await repo.checkDateRollover(now: day2);
      expect(firstCheck, isTrue);

      // Second check on same Day 2: should be false, no extra history entry
      final secondCheck = await repo.checkDateRollover(now: day2);
      expect(secondCheck, isFalse);

      // Third check on same Day 2: should be false
      final thirdCheck = await repo.checkDateRollover(now: day2.add(const Duration(hours: 3)));
      expect(thirdCheck, isFalse);

      // Contains Day 2 (today at 0%) and Day 1 (yesterday)
      expect(repo.getHistory().length, 2);
      expect(repo.getHistory()[0].dateKey, '2026-09-09');
      expect(repo.getHistory()[1].dateKey, '2026-09-08');
    });
  });

  group('Continuous Daily History & Date Tracking Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Cold start creates today record immediately with 0% completion', () async {
      final today = DateTime(2026, 9, 9, 9, 0);
      final repo = await SharedPreferencesActivityRepository.init(now: today);

      final history = repo.getHistory();
      expect(history.length, 1);
      expect(history[0].dateKey, '2026-09-09');
      expect(history[0].completedCount, 0);
      expect(history[0].totalCount, 3);
      expect(history[0].completionRate, 0.0);
    });

    test('Completing an activity immediately updates today history record', () async {
      final today = DateTime(2026, 9, 9, 9, 0);
      final repo = await SharedPreferencesActivityRepository.init(now: today);

      repo.setActivityCompletion('meditation', isCompleted: true);
      await repo.flush();

      final history = repo.getHistory();
      expect(history.length, 1);
      expect(history[0].dateKey, '2026-09-09');
      expect(history[0].completedCount, 1);
      expect(history[0].completionRate, closeTo(1 / 3, 0.01));
      expect(history[0].activities.firstWhere((a) => a.id == 'meditation').isCompleted, isTrue);
    });

    test('Multiple missing days (gap) are created as 0% records without losing past results', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('first_tracked_date', '2026-09-07');
      await prefs.setString('last_active_date', '2026-09-07');

      final sep7 = DateTime(2026, 9, 7, 10, 0);
      final repo = await SharedPreferencesActivityRepository.init(now: sep7);
      // On Sep 7, user completed 2 activities
      repo.setActivityCompletion('meditation', isCompleted: true);
      repo.setActivityCompletion('walking', isCompleted: true);
      await repo.flush();

      // App is not opened on Sep 8 or Sep 9. Opens on Sep 10:
      final sep10 = DateTime(2026, 9, 10, 10, 0);
      final rolledOver = await repo.checkDateRollover(now: sep10);
      expect(rolledOver, isTrue);
      await repo.flush();

      final history = repo.getHistory();
      // Should have: Sep 10, Sep 9, Sep 8, Sep 7
      expect(history.length, 4);
      expect(history[0].dateKey, '2026-09-10'); // Today
      expect(history[0].completedCount, 0); // 0%

      expect(history[1].dateKey, '2026-09-09'); // Missing day
      expect(history[1].completedCount, 0); // 0%

      expect(history[2].dateKey, '2026-09-08'); // Missing day
      expect(history[2].completedCount, 0); // 0%

      expect(history[3].dateKey, '2026-09-07'); // Sep 7
      expect(history[3].completedCount, 2); // Preserved previous result!
    });

    test('Existing historical days are never duplicated or overwritten by backfill', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('first_tracked_date', '2026-09-07');
      await prefs.setString('last_active_date', '2026-09-08');

      final repo = await SharedPreferencesActivityRepository.init();
      final day8 = DateTime(2026, 9, 8, 10, 0);
      await repo.checkDateRollover(now: day8);

      final day9 = DateTime(2026, 9, 9, 10, 0);
      await repo.checkDateRollover(now: day9);

      // Check multiple times
      await repo.checkDateRollover(now: day9);
      await repo.checkDateRollover(now: day9.add(const Duration(hours: 4)));

      final history = repo.getHistory();
      final dateKeys = history.map((h) => h.dateKey).toList();
      // Every dateKey must be unique
      expect(dateKeys.toSet().length, dateKeys.length);
    });

    test('Initial 0% DayHistory creation never overwrites live Activity state', () async {
      final today = DateTime(2026, 9, 9, 10, 0);
      final repo = await SharedPreferencesActivityRepository.init();
      repo.setActivityCompletion('walking', isCompleted: true);
      await repo.flush();

      // Trigger rollover check on same day
      await repo.checkDateRollover(now: today);

      // Live activity state must still have walking completed
      final walking = repo.getActivityById('walking');
      expect(walking?.isCompleted, isTrue);
    });

    group('getActivityProgress tests', () {
      test('returns 0.0 initially for fresh activities', () async {
        final repo = await SharedPreferencesActivityRepository.init();
        final meditation = repo.getActivityById('meditation')!;
        expect(repo.getActivityProgress(meditation), 0.0);
      });

      test('returns accurate fraction for paused timer', () async {
        final repo = await SharedPreferencesActivityRepository.init();
        final controller = repo.getTimerController('meditation');
        controller.start();
        // Pause with 4 minutes remaining out of 10
        controller.pause();

        final meditation = repo.getActivityById('meditation')!;
        // Paused immediately after start: elapsed is close to 0
        expect(repo.getActivityProgress(meditation), inInclusiveRange(0.0, 0.05));
      });

      test('returns 1.0 when activity is completed', () async {
        final repo = await SharedPreferencesActivityRepository.init();
        repo.setActivityCompletion('meditation', isCompleted: true);
        final meditation = repo.getActivityById('meditation')!;
        expect(repo.getActivityProgress(meditation), 1.0);
      });

      test('returns accurate fraction for dumbbells sets completed', () async {
        final repo = await SharedPreferencesActivityRepository.init();
        final dumbbells = repo.getActivityById('dumbbells')!;
        expect(repo.getActivityProgress(dumbbells), 0.0);

        // 1 set of 3 completed
        final updated1 = dumbbells.copyWith(completedSetsReps: [12]);
        repo.updateActivity(updated1);
        expect(repo.getActivityProgress(updated1), closeTo(1 / 3, 0.001));

        // 2 sets of 3 completed
        final updated2 = dumbbells.copyWith(completedSetsReps: [12, 12]);
        repo.updateActivity(updated2);
        expect(repo.getActivityProgress(updated2), closeTo(2 / 3, 0.001));
      });

      test('resets to 0.0 when activity is unchecked from completed', () async {
        final repo = await SharedPreferencesActivityRepository.init();
        repo.setActivityCompletion('walking', isCompleted: true);
        var walking = repo.getActivityById('walking')!;
        expect(repo.getActivityProgress(walking), 1.0);

        repo.toggleActivityCompletion('walking');
        walking = repo.getActivityById('walking')!;
        expect(walking.isCompleted, isFalse);
        expect(repo.getActivityProgress(walking), 0.0);
      });
    });
  });
}
