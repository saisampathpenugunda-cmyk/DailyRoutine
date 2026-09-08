import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/models/reminder_config.dart';

void main() {
  group('ReminderConfig Model Tests', () {
    test('Default configurations have expected values and deterministic IDs', () {
      final meditation = ReminderConfig.defaultFor('meditation');
      expect(meditation.activityId, 'meditation');
      expect(meditation.isMainEnabled, isTrue);
      expect(meditation.mainHour, 8);
      expect(meditation.mainMinute, 0);
      expect(meditation.isBackupEnabled, isFalse);
      expect(meditation.backupHour, 8);
      expect(meditation.backupMinute, 30);
      expect(meditation.mainNotificationId, 101);
      expect(meditation.backupNotificationId, 102);

      final walking = ReminderConfig.defaultFor('walking');
      expect(walking.activityId, 'walking');
      expect(walking.mainHour, 17);
      expect(walking.mainNotificationId, 201);
      expect(walking.backupNotificationId, 202);

      final dumbbells = ReminderConfig.defaultFor('dumbbells');
      expect(dumbbells.activityId, 'dumbbells');
      expect(dumbbells.mainHour, 19);
      expect(dumbbells.mainNotificationId, 301);
      expect(dumbbells.backupNotificationId, 302);
    });

    test('formatTime produces correct 12-hour AM/PM representations', () {
      expect(ReminderConfig.formatTime(8, 0), '8:00 AM');
      expect(ReminderConfig.formatTime(12, 0), '12:00 PM');
      expect(ReminderConfig.formatTime(17, 30), '5:30 PM');
      expect(ReminderConfig.formatTime(0, 5), '12:05 AM');
      expect(ReminderConfig.formatTime(23, 45), '11:45 PM');
    });

    test('toJson and fromJson serialize and deserialize accurately', () {
      const config = ReminderConfig(
        activityId: 'meditation',
        isMainEnabled: true,
        mainHour: 7,
        mainMinute: 15,
        isBackupEnabled: true,
        backupHour: 7,
        backupMinute: 45,
      );

      final json = config.toJson();
      final restored = ReminderConfig.fromJson(json);

      expect(restored.activityId, config.activityId);
      expect(restored.isMainEnabled, isTrue);
      expect(restored.mainHour, 7);
      expect(restored.mainMinute, 15);
      expect(restored.isBackupEnabled, isTrue);
      expect(restored.backupHour, 7);
      expect(restored.backupMinute, 45);
      expect(restored, equals(config));
    });

    test('copyWith updates specific properties immutably', () {
      final initial = ReminderConfig.defaultFor('walking');
      final updated = initial.copyWith(
        mainHour: 6,
        isBackupEnabled: true,
      );

      expect(updated.mainHour, 6);
      expect(updated.isBackupEnabled, isTrue);
      expect(updated.mainMinute, initial.mainMinute);
      expect(updated.activityId, initial.activityId);
      expect(initial.mainHour, 17);
    });
  });
}
