import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/repositories/activity_repository.dart';

void main() {
  group('Activity Model Tests', () {
    test('Activity properties and formatted duration', () {
      const activity = Activity(
        id: 'meditation',
        name: 'Meditation',
        activityType: ActivityType.meditation,
        defaultDuration: Duration(minutes: 10),
        isCompleted: false,
      );

      expect(activity.id, 'meditation');
      expect(activity.name, 'Meditation');
      expect(activity.activityType, ActivityType.meditation);
      expect(activity.defaultDuration.inMinutes, 10);
      expect(activity.formattedDuration, '10 min');
      expect(activity.isCompleted, false);
    });

    test('Activity copyWith works correctly', () {
      const activity = Activity(
        id: 'study',
        name: 'Study',
        activityType: ActivityType.study,
        defaultDuration: Duration(minutes: 45),
        isCompleted: false,
      );

      final updated = activity.copyWith(isCompleted: true);
      expect(updated.isCompleted, true);
      expect(updated.name, 'Study');
      expect(updated.id, 'study');
      expect(updated.defaultDuration.inMinutes, 45);
    });

    test('Activity JSON serialization and deserialization', () {
      const activity = Activity(
        id: 'guitar',
        name: 'Guitar',
        activityType: ActivityType.guitar,
        defaultDuration: Duration(minutes: 15),
        isCompleted: true,
      );

      final json = activity.toJson();
      expect(json['id'], 'guitar');
      expect(json['name'], 'Guitar');
      expect(json['activityType'], 'guitar');
      expect(json['defaultDurationMinutes'], 15);
      expect(json['isCompleted'], true);

      final deserialized = Activity.fromJson(json);
      expect(deserialized, equals(activity));
    });

    test('Activity retains second-level duration precision across serialization', () {
      const activity = Activity(
        id: 'sprint',
        name: 'Sprint',
        activityType: ActivityType.walking,
        defaultDuration: Duration(seconds: 45),
      );

      final json = activity.toJson();
      expect(json['defaultDurationSeconds'], 45);

      final deserialized = Activity.fromJson(json);
      expect(deserialized.defaultDuration.inSeconds, 45);
      expect(deserialized.formattedDuration, '45 sec');
    });

    test('Activity supports backward-compatible deserialization from legacy defaultDurationMinutes', () {
      final legacyJson = {
        'id': 'legacy_meditation',
        'name': 'Meditation Legacy',
        'activityType': 'meditation',
        'defaultDurationMinutes': 25,
        'isCompleted': false,
      };

      final activity = Activity.fromJson(legacyJson);
      expect(activity.defaultDuration, const Duration(minutes: 25));
      expect(activity.formattedDuration, '25 min');
    });

    test('Activity safely handles non-numeric and negative values in completedSetsReps', () {
      final dirtyJson = {
        'id': 'dirty_activity',
        'name': 'Dirty Data',
        'activityType': 'dumbbells',
        'defaultDurationSeconds': 60,
        'completedSetsReps': [10, -5, 'bad_value', 15.0, null],
      };

      final activity = Activity.fromJson(dirtyJson);
      expect(activity.completedSetsReps, [10, 15]);
    });
  });

  group('InMemoryActivityRepository Tests', () {
    test('Initializes with default 3 seeded activities', () {
      final repo = InMemoryActivityRepository();
      final activities = repo.getActivities();

      expect(activities.length, 3);
      expect(activities[0].name, 'Meditation');
      expect(activities[0].formattedDuration, '10 min');
      expect(activities[1].name, 'Walking');
      expect(activities[1].formattedDuration, '30 min');
      expect(activities[2].name, 'Dumbbells');
      expect(activities[2].formattedDuration, '20 min');
    });

    test('Toggles activity completion', () {
      final repo = InMemoryActivityRepository();
      expect(repo.getActivityById('meditation')?.isCompleted, false);

      repo.toggleActivityCompletion('meditation');
      expect(repo.getActivityById('meditation')?.isCompleted, true);

      repo.toggleActivityCompletion('meditation');
      expect(repo.getActivityById('meditation')?.isCompleted, false);
    });

    test('Adds new activity dynamically', () {
      final repo = InMemoryActivityRepository();
      const newActivity = Activity(
        id: 'reading',
        name: 'Reading',
        activityType: ActivityType.reading,
        defaultDuration: Duration(minutes: 25),
      );

      repo.addActivity(newActivity);
      expect(repo.getActivities().length, 4);
      expect(repo.getActivityById('reading')?.name, 'Reading');
    });
  });
}
