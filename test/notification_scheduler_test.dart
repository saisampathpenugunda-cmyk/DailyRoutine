import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/models/reminder_config.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/services/notification_service.dart';

void main() {
  group('Notification Scheduler & Cancellation Tests', () {
    late InMemoryNotificationService notificationService;
    late InMemoryActivityRepository repository;

    setUp(() {
      notificationService = InMemoryNotificationService();
      repository = InMemoryActivityRepository(
        notificationService: notificationService,
      );
    });

    test('Schedules main reminder for pending activity', () async {
      final config = ReminderConfig.defaultFor('meditation');
      await notificationService.scheduleActivityReminders(
        config,
        isCompletedToday: false,
        isSkippedToday: false,
        testNow: DateTime(2026, 9, 7, 7, 0), // 7:00 AM, before 8:00 AM
      );

      expect(notificationService.scheduledNotifications.containsKey(101), isTrue);
      expect(notificationService.scheduledNotifications[101]!.isBackup, isFalse);
      expect(
        notificationService.scheduledNotifications[101]!.scheduledDate,
        DateTime(2026, 9, 7, 8, 0),
      );
      // Backup disabled by default
      expect(notificationService.scheduledNotifications.containsKey(102), isFalse);
    });

    test('Schedules both main and backup reminders when backup enabled', () async {
      final config = ReminderConfig.defaultFor('meditation').copyWith(
        isBackupEnabled: true,
      );
      await notificationService.scheduleActivityReminders(
        config,
        isCompletedToday: false,
        isSkippedToday: false,
        testNow: DateTime(2026, 9, 7, 7, 0),
      );

      expect(notificationService.scheduledNotifications.containsKey(101), isTrue);
      expect(notificationService.scheduledNotifications.containsKey(102), isTrue);
      expect(notificationService.scheduledNotifications[102]!.isBackup, isTrue);
      expect(
        notificationService.scheduledNotifications[102]!.scheduledDate,
        DateTime(2026, 9, 7, 8, 30),
      );
    });

    test('Completing an activity cancels its scheduled reminders', () async {
      // Schedule meditation
      final config = ReminderConfig.defaultFor('meditation').copyWith(isBackupEnabled: true);
      repository.updateReminderConfig(config);

      expect(notificationService.scheduledNotifications.containsKey(101), isTrue);
      expect(notificationService.scheduledNotifications.containsKey(102), isTrue);

      // User marks meditation complete
      repository.setActivityCompletion('meditation', isCompleted: true);

      // Remaining alerts for today must be cancelled
      expect(notificationService.scheduledNotifications.containsKey(101), isFalse);
      expect(notificationService.scheduledNotifications.containsKey(102), isFalse);
    });

    test('Toggling activity completion cancels reminders when completing', () async {
      final config = ReminderConfig.defaultFor('walking');
      repository.updateReminderConfig(config);
      expect(notificationService.scheduledNotifications.containsKey(201), isTrue);

      // Toggle walking to completed
      repository.toggleActivityCompletion('walking');

      expect(notificationService.scheduledNotifications.containsKey(201), isFalse);
    });

    test('Skipping an activity ("Can\'t do today") cancels its reminders', () async {
      final config = ReminderConfig.defaultFor('dumbbells').copyWith(isBackupEnabled: true);
      repository.updateReminderConfig(config);

      expect(notificationService.scheduledNotifications.containsKey(301), isTrue);
      expect(notificationService.scheduledNotifications.containsKey(302), isTrue);

      // User marks dumbbells skipped
      repository.setActivitySkipped('dumbbells', isSkipped: true);

      expect(notificationService.scheduledNotifications.containsKey(301), isFalse);
      expect(notificationService.scheduledNotifications.containsKey(302), isFalse);
    });

    test('Scheduling when already completed schedules for tomorrow instead of today', () async {
      final config = ReminderConfig.defaultFor('meditation');
      await notificationService.scheduleActivityReminders(
        config,
        isCompletedToday: true,
        isSkippedToday: false,
        testNow: DateTime(2026, 9, 7, 7, 0),
      );

      // Reminder is placed on tomorrow (Sep 8), not today
      expect(notificationService.scheduledNotifications.containsKey(101), isTrue);
      expect(
        notificationService.scheduledNotifications[101]!.scheduledDate,
        DateTime(2026, 9, 8, 8, 0),
      );
    });

    test('Scheduling when past today’s time schedules for tomorrow', () async {
      final config = ReminderConfig.defaultFor('meditation'); // 8:00 AM
      await notificationService.scheduleActivityReminders(
        config,
        isCompletedToday: false,
        isSkippedToday: false,
        testNow: DateTime(2026, 9, 7, 9, 0), // 9:00 AM (past 8:00 AM)
      );

      expect(notificationService.scheduledNotifications.containsKey(101), isTrue);
      expect(
        notificationService.scheduledNotifications[101]!.scheduledDate,
        DateTime(2026, 9, 8, 8, 0),
      );
    });
  });
}
