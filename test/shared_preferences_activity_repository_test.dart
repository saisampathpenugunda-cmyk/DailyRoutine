import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      // History remains empty since rollover has not happened
      expect(repo2.getHistory().isEmpty, isTrue);
    });

    test('Date rollover archives previous day into history and resets daily state', () async {
      final repo = await SharedPreferencesActivityRepository.init();
      repo.setActivityCompletion('meditation', isCompleted: true);
      repo.setActivitySkipped('walking', isSkipped: true);
      final dumbbells = repo.getActivityById('dumbbells')!;
      repo.updateActivity(dumbbells.copyWith(completedSetsReps: [10, 10]));
      await repo.flush();

      // Simulate a rollover to tomorrow
      await repo.simulateDateRollover(DateTime(2099, 1, 1));

      // History must have archived yesterday's entry
      final history = repo.getHistory();
      expect(history.length, 1);
      final archivedMeditation = history[0].activities.firstWhere((a) => a.id == 'meditation');
      final archivedWalking = history[0].activities.firstWhere((a) => a.id == 'walking');
      final archivedDumbbells = history[0].activities.firstWhere((a) => a.id == 'dumbbells');

      expect(archivedMeditation.isCompleted, isTrue);
      expect(archivedWalking.isSkipped, isTrue);
      expect(archivedDumbbells.completedSetsReps, [10, 10]);

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
      final repo1 = await SharedPreferencesActivityRepository.init();
      repo1.setActivityCompletion('meditation', isCompleted: true);
      await repo1.simulateDateRollover(DateTime(2099, 1, 1));
      await repo1.flush();

      // Re-initialize repository
      final repo2 = await SharedPreferencesActivityRepository.init();
      final history = repo2.getHistory();
      expect(history.length, 1);
      expect(history[0].completedCount, 1);
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
  });
}
