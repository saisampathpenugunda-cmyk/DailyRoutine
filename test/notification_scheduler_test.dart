import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/models/reminder_config.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });
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

  group('LocalNotificationService Timezone Calculation Tests', () {
    late LocalNotificationService localService;

    setUp(() {
      localService = LocalNotificationService();
    });

    test('calculateNextScheduleTime schedules today for future time in Asia/Calcutta', () {
      final calcutta = tz.getLocation('Asia/Calcutta');
      tz.setLocalLocation(calcutta);

      // Current time is 10:00 AM on Sep 7, 2026
      final now = DateTime(2026, 9, 7, 10, 0);

      // Target time is 11:30 AM today
      final target = localService.calculateNextScheduleTime(
        11,
        30,
        isCompletedToday: false,
        isSkippedToday: false,
        testNow: now,
      );

      expect(target.year, 2026);
      expect(target.month, 9);
      expect(target.day, 7);
      expect(target.hour, 11);
      expect(target.minute, 30);
      expect(target.location.name, 'Asia/Calcutta');
      expect(target.timeZoneOffset, const Duration(hours: 5, minutes: 30));
    });

    test('calculateNextScheduleTime schedules tomorrow when time has passed in Asia/Calcutta', () {
      final calcutta = tz.getLocation('Asia/Calcutta');
      tz.setLocalLocation(calcutta);

      // Current time is 10:00 PM (22:00) on Sep 7, 2026
      final now = DateTime(2026, 9, 7, 22, 0);

      // Target time was 8:00 AM today (already passed)
      final target = localService.calculateNextScheduleTime(
        8,
        0,
        isCompletedToday: false,
        isSkippedToday: false,
        testNow: now,
      );

      expect(target.year, 2026);
      expect(target.month, 9);
      expect(target.day, 8); // Tomorrow
      expect(target.hour, 8);
      expect(target.minute, 0);
      expect(target.location.name, 'Asia/Calcutta');
    });

    test('calculateNextScheduleTime schedules tomorrow when habit is already completed today', () {
      final calcutta = tz.getLocation('Asia/Calcutta');
      tz.setLocalLocation(calcutta);

      // Current time is 7:00 AM, target is 8:00 AM (still in future today)
      final now = DateTime(2026, 9, 7, 7, 0);

      // Completed today
      final target = localService.calculateNextScheduleTime(
        8,
        0,
        isCompletedToday: true,
        isSkippedToday: false,
        testNow: now,
      );

      expect(target.year, 2026);
      expect(target.month, 9);
      expect(target.day, 8); // Tomorrow because today is finished
      expect(target.hour, 8);
      expect(target.minute, 0);
    });
  });
}
