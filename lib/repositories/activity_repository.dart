import '../models/activity.dart';
import '../models/day_history.dart';
import '../models/reminder_config.dart';
import '../services/notification_service.dart';

abstract class ActivityRepository {
  List<Activity> getActivities();
  Activity? getActivityById(String id);
  void toggleActivityCompletion(String id);
  void setActivityCompletion(String id, {required bool isCompleted});
  void setActivitySkipped(String id, {required bool isSkipped});
  void addActivity(Activity activity);
  void updateActivity(Activity activity);
  List<DayHistory> getHistory();
  Future<void> flush();

  List<ReminderConfig> getReminderConfigs();
  ReminderConfig getReminderConfig(String activityId);
  void updateReminderConfig(ReminderConfig config);
}

class InMemoryActivityRepository implements ActivityRepository {
  late final List<Activity> _activities;
  final List<DayHistory> _history = [];
  final Map<String, ReminderConfig> _reminderConfigs = {};
  final NotificationService? notificationService;

  InMemoryActivityRepository({
    List<Activity>? initialActivities,
    List<DayHistory>? initialHistory,
    List<ReminderConfig>? initialReminderConfigs,
    this.notificationService,
  }) {
    if (initialHistory != null) {
      _history.addAll(initialHistory);
    }
    if (initialReminderConfigs != null) {
      for (final cfg in initialReminderConfigs) {
        _reminderConfigs[cfg.activityId] = cfg;
      }
    } else {
      _reminderConfigs['meditation'] = ReminderConfig.defaultFor('meditation');
      _reminderConfigs['walking'] = ReminderConfig.defaultFor('walking');
      _reminderConfigs['dumbbells'] = ReminderConfig.defaultFor('dumbbells');
    }
    _activities = initialActivities ??
        [
          const Activity(
            id: 'meditation',
            name: 'Meditation',
            activityType: ActivityType.meditation,
            defaultDuration: Duration(minutes: 10),
            isCompleted: false,
            isSkipped: false,
          ),
          const Activity(
            id: 'walking',
            name: 'Walking',
            activityType: ActivityType.walking,
            defaultDuration: Duration(minutes: 30),
            isCompleted: false,
            isSkipped: false,
          ),
          const Activity(
            id: 'dumbbells',
            name: 'Dumbbells',
            activityType: ActivityType.dumbbells,
            defaultDuration: Duration(minutes: 20),
            isCompleted: false,
            isSkipped: false,
          ),
        ];
  }

  @override
  List<Activity> getActivities() {
    return List.unmodifiable(_activities);
  }

  @override
  Activity? getActivityById(String id) {
    try {
      return _activities.firstWhere((activity) => activity.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void toggleActivityCompletion(String id) {
    final index = _activities.indexWhere((activity) => activity.id == id);
    if (index != -1) {
      final current = _activities[index];
      final willBeCompleted = !current.isCompleted;
      // When completing, reset skipped status
      _activities[index] = current.copyWith(
        isCompleted: willBeCompleted,
        isSkipped: false,
      );
      if (willBeCompleted) {
        notificationService?.cancelActivityReminders(id);
      }
    }
  }

  @override
  void setActivityCompletion(String id, {required bool isCompleted}) {
    final index = _activities.indexWhere((activity) => activity.id == id);
    if (index != -1) {
      // When completing, reset skipped status
      _activities[index] = _activities[index].copyWith(
        isCompleted: isCompleted,
        isSkipped: false,
      );
      if (isCompleted) {
        notificationService?.cancelActivityReminders(id);
      }
    }
  }

  @override
  void setActivitySkipped(String id, {required bool isSkipped}) {
    final index = _activities.indexWhere((activity) => activity.id == id);
    if (index != -1) {
      // When skipping, reset completed status
      _activities[index] = _activities[index].copyWith(
        isSkipped: isSkipped,
        isCompleted: false,
      );
      if (isSkipped) {
        notificationService?.cancelActivityReminders(id);
      }
    }
  }

  @override
  void addActivity(Activity activity) {
    _activities.add(activity);
  }

  @override
  void updateActivity(Activity activity) {
    final index = _activities.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      _activities[index] = activity;
      if (activity.isCompleted || activity.isSkipped) {
        notificationService?.cancelActivityReminders(activity.id);
      }
    }
  }

  @override
  List<DayHistory> getHistory() {
    return List.unmodifiable(_history);
  }

  void addHistoryEntry(DayHistory history) {
    _history.removeWhere((h) => h.dateKey == history.dateKey);
    _history.insert(0, history);
  }

  @override
  Future<void> flush() async {
    // In-memory flush is immediate
  }

  @override
  List<ReminderConfig> getReminderConfigs() {
    return List.unmodifiable(_reminderConfigs.values.toList());
  }

  @override
  ReminderConfig getReminderConfig(String activityId) {
    return _reminderConfigs[activityId] ?? ReminderConfig.defaultFor(activityId);
  }

  @override
  void updateReminderConfig(ReminderConfig config) {
    _reminderConfigs[config.activityId] = config;
    final activity = getActivityById(config.activityId);
    notificationService?.scheduleActivityReminders(
      config,
      isCompletedToday: activity?.isCompleted ?? false,
      isSkippedToday: activity?.isSkipped ?? false,
    );
  }
}
