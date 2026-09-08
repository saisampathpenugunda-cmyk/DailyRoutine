import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/activity.dart';
import '../models/reminder_config.dart';

abstract class NotificationService {
  Future<void> init();
  Future<bool> requestPermissions();
  Future<void> scheduleActivityReminders(
    ReminderConfig config, {
    required bool isCompletedToday,
    required bool isSkippedToday,
    DateTime? testNow,
  });
  Future<void> cancelActivityReminders(String activityId);
  Future<void> cancelAll();
  Future<void> rescheduleAll(
    List<ReminderConfig> configs,
    List<Activity> activities, {
    DateTime? testNow,
  });
}

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _initialized = false;

  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _notificationsPlugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'daily_routine_reminders';
  static const String channelName = 'Daily Routine Reminders';
  static const String channelDescription =
      'Notifications reminding you of your daily routines and backup alerts';

  @override
  Future<void> init() async {
    if (_initialized) return;

    // Initialize local timezone database
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initSettings);

    // Create high importance notification channel on Android
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
      );
      await androidPlugin.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  @override
  Future<bool> requestPermissions() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  @override
  Future<void> scheduleActivityReminders(
    ReminderConfig config, {
    required bool isCompletedToday,
    required bool isSkippedToday,
    DateTime? testNow,
  }) async {
    // First cancel existing scheduled reminders for this activity to avoid duplicates
    await cancelActivityReminders(config.activityId);

    // If main reminder is enabled
    if (config.isMainEnabled) {
      final targetTime = _calculateNextScheduleTime(
        config.mainHour,
        config.mainMinute,
        isCompletedToday: isCompletedToday,
        isSkippedToday: isSkippedToday,
        testNow: testNow,
      );

      final activityName = _getActivityDisplayName(config.activityId);

      await _scheduleNotification(
        id: config.mainNotificationId,
        title: 'Time for $activityName!',
        body: 'Keep your momentum going. Tap to begin your daily routine.',
        scheduledDate: targetTime,
      );
    }

    // If backup reminder is enabled
    if (config.isBackupEnabled) {
      final targetTime = _calculateNextScheduleTime(
        config.backupHour,
        config.backupMinute,
        isCompletedToday: isCompletedToday,
        isSkippedToday: isSkippedToday,
        testNow: testNow,
      );

      final activityName = _getActivityDisplayName(config.activityId);

      await _scheduleNotification(
        id: config.backupNotificationId,
        title: 'Reminder: $activityName pending',
        body: "Don't forget your $activityName session today!",
        scheduledDate: targetTime,
      );
    }
  }

  @override
  Future<void> cancelActivityReminders(String activityId) async {
    final defaults = ReminderConfig.defaultFor(activityId);
    await _notificationsPlugin.cancel(defaults.mainNotificationId);
    await _notificationsPlugin.cancel(defaults.backupNotificationId);
  }

  @override
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  @override
  Future<void> rescheduleAll(
    List<ReminderConfig> configs,
    List<Activity> activities, {
    DateTime? testNow,
  }) async {
    for (final config in configs) {
      final activity = activities.cast<Activity?>().firstWhere(
            (a) => a?.id == config.activityId,
            orElse: () => null,
          );

      final isCompleted = activity?.isCompleted ?? false;
      final isSkipped = activity?.isSkipped ?? false;

      await scheduleActivityReminders(
        config,
        isCompletedToday: isCompleted,
        isSkippedToday: isSkipped,
        testNow: testNow,
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling notification $id: $e');
    }
  }

  tz.TZDateTime _calculateNextScheduleTime(
    int hour,
    int minute, {
    required bool isCompletedToday,
    required bool isSkippedToday,
    DateTime? testNow,
  }) {
    final nowLocal = testNow != null
        ? tz.TZDateTime.from(testNow, tz.local)
        : tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
      hour,
      minute,
    );

    // If the reminder time has already passed today OR today's session is already
    // finished/skipped, schedule the reminder for tomorrow.
    if (scheduled.isBefore(nowLocal) || isCompletedToday || isSkippedToday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  String _getActivityDisplayName(String activityId) {
    switch (activityId) {
      case 'meditation':
        return 'Meditation';
      case 'walking':
        return 'Walking';
      case 'dumbbells':
        return 'Dumbbells';
      default:
        return 'Routine';
    }
  }
}

/// In-memory implementation of NotificationService for unit and widget testing.
class InMemoryNotificationService implements NotificationService {
  final Map<int, ScheduledTestNotification> scheduledNotifications = {};
  bool permissionGranted = true;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermissions() async => permissionGranted;

  @override
  Future<void> scheduleActivityReminders(
    ReminderConfig config, {
    required bool isCompletedToday,
    required bool isSkippedToday,
    DateTime? testNow,
  }) async {
    final defaults = ReminderConfig.defaultFor(config.activityId);
    scheduledNotifications.remove(defaults.mainNotificationId);
    scheduledNotifications.remove(defaults.backupNotificationId);

    final now = testNow ?? DateTime.now();

    if (config.isMainEnabled) {
      final scheduled = _calculateNextDateTime(
        config.mainHour,
        config.mainMinute,
        isCompletedToday: isCompletedToday,
        isSkippedToday: isSkippedToday,
        now: now,
      );

      scheduledNotifications[config.mainNotificationId] = ScheduledTestNotification(
        id: config.mainNotificationId,
        activityId: config.activityId,
        title: 'Time for ${config.activityId}!',
        scheduledDate: scheduled,
        isBackup: false,
      );
    }

    if (config.isBackupEnabled) {
      final scheduled = _calculateNextDateTime(
        config.backupHour,
        config.backupMinute,
        isCompletedToday: isCompletedToday,
        isSkippedToday: isSkippedToday,
        now: now,
      );

      scheduledNotifications[config.backupNotificationId] = ScheduledTestNotification(
        id: config.backupNotificationId,
        activityId: config.activityId,
        title: 'Reminder: ${config.activityId} pending',
        scheduledDate: scheduled,
        isBackup: true,
      );
    }
  }

  @override
  Future<void> cancelActivityReminders(String activityId) async {
    final defaults = ReminderConfig.defaultFor(activityId);
    scheduledNotifications.remove(defaults.mainNotificationId);
    scheduledNotifications.remove(defaults.backupNotificationId);
  }

  @override
  Future<void> cancelAll() async {
    scheduledNotifications.clear();
  }

  @override
  Future<void> rescheduleAll(
    List<ReminderConfig> configs,
    List<Activity> activities, {
    DateTime? testNow,
  }) async {
    for (final config in configs) {
      final activity = activities.cast<Activity?>().firstWhere(
            (a) => a?.id == config.activityId,
            orElse: () => null,
          );
      final isCompleted = activity?.isCompleted ?? false;
      final isSkipped = activity?.isSkipped ?? false;

      await scheduleActivityReminders(
        config,
        isCompletedToday: isCompleted,
        isSkippedToday: isSkipped,
        testNow: testNow,
      );
    }
  }

  DateTime _calculateNextDateTime(
    int hour,
    int minute, {
    required bool isCompletedToday,
    required bool isSkippedToday,
    required DateTime now,
  }) {
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now) || isCompletedToday || isSkippedToday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

class ScheduledTestNotification {
  final int id;
  final String activityId;
  final String title;
  final DateTime scheduledDate;
  final bool isBackup;

  ScheduledTestNotification({
    required this.id,
    required this.activityId,
    required this.title,
    required this.scheduledDate,
    required this.isBackup,
  });
}
