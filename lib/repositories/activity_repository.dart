import '../controllers/routine_timer_controller.dart';
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

  RoutineTimerController getTimerController(
    String activityId, {
    Duration? defaultDuration,
    DateTime Function()? now,
  });
  void resetTimer(String activityId);
  Future<bool> checkDateRollover({DateTime? now});
  double getActivityProgress(Activity activity);
  bool isActivityInProgress(String activityId);
  bool setActivityEnabled(String activityId, bool isEnabled);
  bool deleteActivity(String activityId);
}

class InMemoryActivityRepository implements ActivityRepository {
  late final List<Activity> _activities;
  final List<DayHistory> _history = [];
  final Map<String, ReminderConfig> _reminderConfigs = {};
  final Map<String, RoutineTimerController> _timerControllers = {};
  final NotificationService? notificationService;
  final DateTime Function() _clock;
  String? _lastDateKey;
  String? _firstDateKey;
  final bool autoCreateTodayHistory;

  InMemoryActivityRepository({
    List<Activity>? initialActivities,
    List<DayHistory>? initialHistory,
    List<ReminderConfig>? initialReminderConfigs,
    this.notificationService,
    DateTime Function()? now,
    this.autoCreateTodayHistory = true,
  }) : _clock = now ?? DateTime.now {
    _lastDateKey = _formatDateKey(_clock());
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

    _initFirstTrackedDate();
    if (autoCreateTodayHistory) {
      _ensureDailyRecords(_lastDateKey!, _clock());
    }
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
      _syncTodayHistory();
      if (willBeCompleted) {
        notificationService?.cancelActivityReminders(id);
        _timerControllers[id]?.finish();
      } else {
        _timerControllers[id]?.reset();
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
      _syncTodayHistory();
      if (isCompleted) {
        notificationService?.cancelActivityReminders(id);
        _timerControllers[id]?.finish();
      } else {
        _timerControllers[id]?.reset();
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
      _syncTodayHistory();
      if (isSkipped) {
        notificationService?.cancelActivityReminders(id);
        _timerControllers[id]?.reset();
      }
    }
  }

  @override
  void addActivity(Activity activity) {
    final existingIndex = _activities.indexWhere((a) => a.id == activity.id);
    if (existingIndex != -1) {
      _activities[existingIndex] = activity;
    } else {
      _activities.add(activity);
    }
    _syncTodayHistory();
  }

  @override
  void updateActivity(Activity activity) {
    final index = _activities.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      _activities[index] = activity;

      // If timer is unstarted (initial), update duration immediately.
      // If timer is running or paused, leave the current session untouched.
      final controller = _timerControllers[activity.id];
      if (controller != null && controller.isInitial) {
        controller.updateDurationIfInitial(activity.defaultDuration);
      }

      _syncTodayHistory();
      if (!activity.isEnabled) {
        notificationService?.cancelActivityReminders(activity.id);
      } else if (activity.isCompleted || activity.isSkipped) {
        notificationService?.cancelActivityReminders(activity.id);
      } else {
        final config = getReminderConfig(activity.id);
        if (config.hasAnyReminder) {
          notificationService?.scheduleActivityReminders(
            config,
            isCompletedToday: activity.isCompleted,
            isSkippedToday: activity.isSkipped,
          );
        }
      }
    }
  }

  @override
  bool isActivityInProgress(String activityId) {
    final activity = getActivityById(activityId);
    if (activity == null) return false;

    final controller = _timerControllers[activityId];
    if (controller != null && (controller.isRunning || controller.isPaused)) {
      return true;
    }

    if ((activity.activityType == ActivityType.dumbbells ||
            activity.activityType == ActivityType.workout) &&
        activity.completedSetsReps.isNotEmpty &&
        !activity.isCompleted) {
      return true;
    }

    return false;
  }

  @override
  bool setActivityEnabled(String activityId, bool isEnabled) {
    if (!isEnabled && isActivityInProgress(activityId)) {
      return false;
    }

    final index = _activities.indexWhere((a) => a.id == activityId);
    if (index == -1) return false;

    final current = _activities[index];
    if (current.isEnabled == isEnabled) return true;

    final updated = current.copyWith(isEnabled: isEnabled);
    _activities[index] = updated;

    if (!isEnabled) {
      notificationService?.cancelActivityReminders(activityId);
    } else {
      final config = getReminderConfig(activityId);
      if (config.hasAnyReminder && !updated.isCompleted && !updated.isSkipped) {
        notificationService?.scheduleActivityReminders(
          config,
          isCompletedToday: updated.isCompleted,
          isSkippedToday: updated.isSkipped,
        );
      }
    }

    _syncTodayHistory();
    return true;
  }

  @override
  List<DayHistory> getHistory() {
    return List.unmodifiable(_history);
  }

  void addHistoryEntry(DayHistory history) {
    _history.removeWhere((h) => h.dateKey == history.dateKey);
    _history.insert(0, history);
    _history.sort((a, b) => b.dateKey.compareTo(a.dateKey));
  }

  @override
  Future<void> flush() async {
    // In-memory flush is immediate
  }

  @override
  bool deleteActivity(String activityId) {
    final activity = getActivityById(activityId);
    if (activity == null) return false;
    if (isActivityInProgress(activityId)) return false;

    _activities.removeWhere((a) => a.id == activityId);
    _reminderConfigs.remove(activityId);
    _timerControllers.remove(activityId);
    notificationService?.cancelActivityReminders(activityId);
    _syncTodayHistory();
    return true;
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
    if (activity == null || !activity.isEnabled) {
      notificationService?.cancelActivityReminders(config.activityId);
      return;
    }
    notificationService?.scheduleActivityReminders(
      config,
      isCompletedToday: activity.isCompleted,
      isSkippedToday: activity.isSkipped,
    );
  }

  @override
  RoutineTimerController getTimerController(
    String activityId, {
    Duration? defaultDuration,
    DateTime Function()? now,
  }) {
    return _timerControllers.putIfAbsent(activityId, () {
      final activity = getActivityById(activityId);
      final duration = defaultDuration ?? activity?.defaultDuration ?? const Duration(minutes: 10);
      final isDone = activity?.isCompleted ?? false;
      return RoutineTimerController(
        totalDuration: duration,
        initialState: isDone ? TimerState.completed : TimerState.initial,
        initialRemaining: isDone ? Duration.zero : duration,
        now: now ?? _clock,
      );
    });
  }

  @override
  void resetTimer(String activityId) {
    final activity = getActivityById(activityId);
    final duration = activity?.defaultDuration ?? const Duration(minutes: 10);
    _timerControllers[activityId] = RoutineTimerController(
      totalDuration: duration,
      initialRemaining: duration,
      now: _clock,
    );
  }

  @override
  double getActivityProgress(Activity activity) {
    if (activity.isCompleted) return 1.0;
    if (activity.isSkipped) return 0.0;

    if (activity.activityType == ActivityType.meditation ||
        activity.activityType == ActivityType.walking ||
        activity.activityType == ActivityType.timer) {
      final controller = getTimerController(
        activity.id,
        defaultDuration: activity.defaultDuration,
      );
      if (controller.isCompleted || controller.remaining <= Duration.zero) {
        if (!activity.isCompleted) {
          setActivityCompletion(activity.id, isCompleted: true);
        }
        return 1.0;
      }
      return controller.completionProgress;
    }

    if (activity.activityType == ActivityType.dumbbells ||
        activity.activityType == ActivityType.workout) {
      if (activity.completedSetsReps.isNotEmpty) {
        final progress = (activity.completedSetsReps.length / 3.0).clamp(0.0, 1.0);
        if (progress >= 1.0 && !activity.isCompleted) {
          setActivityCompletion(activity.id, isCompleted: true);
        }
        return progress;
      }
      return 0.0;
    }

    return 0.0;
  }

  String _formatDateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<Activity> _createCleanActivitiesSnapshot() {
    if (_activities.isNotEmpty) {
      return _activities.map((a) => a.copyWith(
        isCompleted: false,
        isSkipped: false,
        actualDuration: Duration.zero,
        completedSetsReps: const [],
      )).toList();
    }
    return const [
      Activity(
        id: 'meditation',
        name: 'Meditation',
        activityType: ActivityType.meditation,
        defaultDuration: Duration(minutes: 10),
        isCompleted: false,
        isSkipped: false,
      ),
      Activity(
        id: 'walking',
        name: 'Walking',
        activityType: ActivityType.walking,
        defaultDuration: Duration(minutes: 30),
        isCompleted: false,
        isSkipped: false,
      ),
      Activity(
        id: 'dumbbells',
        name: 'Dumbbells',
        activityType: ActivityType.dumbbells,
        defaultDuration: Duration(minutes: 20),
        isCompleted: false,
        isSkipped: false,
      ),
    ];
  }

  List<Activity> _createActivitiesSnapshotWithElapsed() {
    return _activities.map((activity) {
      Duration elapsed = Duration.zero;
      final controller = _timerControllers[activity.id];
      if (activity.isCompleted) {
        elapsed = controller != null ? controller.totalDuration : activity.defaultDuration;
      } else if (controller != null) {
        elapsed = controller.elapsedDuration;
      }
      return activity.copyWith(actualDuration: elapsed);
    }).toList();
  }

  void _initFirstTrackedDate() {
    String? earliest;
    for (final h in _history) {
      if (h.dateKey.isNotEmpty) {
        if (earliest == null || h.dateKey.compareTo(earliest) < 0) {
          earliest = h.dateKey;
        }
      }
    }
    _firstDateKey = earliest ?? _lastDateKey ?? _formatDateKey(_clock());
  }

  void _ensureDailyRecords(String todayKey, DateTime current) {
    _initFirstTrackedDate();
    final firstTrackedKey = _firstDateKey ?? todayKey;

    DateTime parseKey(String k) {
      final parts = k.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }

    final firstDate = parseKey(firstTrackedKey);
    final todayDate = parseKey(todayKey);

    DateTime cursor = firstDate;
    while (!cursor.isAfter(todayDate)) {
      final key = _formatDateKey(cursor);
      final existingIndex = _history.indexWhere((h) => h.dateKey == key);

      if (key == todayKey) {
        final todaySnapshot = DayHistory(
          dateKey: todayKey,
          activities: _createActivitiesSnapshotWithElapsed(),
          recordedAt: current,
        );
        if (existingIndex != -1) {
          _history[existingIndex] = todaySnapshot;
        } else {
          _history.add(todaySnapshot);
        }
      } else {
        if (existingIndex == -1) {
          _history.add(DayHistory(
            dateKey: key,
            activities: _createCleanActivitiesSnapshot(),
            recordedAt: cursor,
          ));
        }
      }

      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }

    _history.sort((a, b) => b.dateKey.compareTo(a.dateKey));
  }

  void _syncTodayHistory({DateTime? now}) {
    if (!autoCreateTodayHistory) return;
    final current = now ?? _clock();
    final todayKey = _formatDateKey(current);
    final snapshot = DayHistory(
      dateKey: todayKey,
      activities: _createActivitiesSnapshotWithElapsed(),
      recordedAt: current,
    );
    final index = _history.indexWhere((h) => h.dateKey == todayKey);
    if (index != -1) {
      _history[index] = snapshot;
    } else {
      _history.add(snapshot);
      _history.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    }
  }

  @override
  Future<bool> checkDateRollover({DateTime? now}) async {
    final current = now ?? _clock();
    final todayKey = _formatDateKey(current);

    if (_lastDateKey != null && _lastDateKey != todayKey) {
      if (_activities.isNotEmpty) {
        final existingIndex = _history.indexWhere((h) => h.dateKey == _lastDateKey);
        final snapshot = DayHistory(
          dateKey: _lastDateKey!,
          activities: _createActivitiesSnapshotWithElapsed(),
          recordedAt: current,
        );
        if (existingIndex != -1) {
          _history[existingIndex] = snapshot;
        } else {
          _history.add(snapshot);
        }
      }

      for (int i = 0; i < _activities.length; i++) {
        _activities[i] = _activities[i].copyWith(
          isCompleted: false,
          isSkipped: false,
          actualDuration: Duration.zero,
          completedSetsReps: const [],
        );
      }
      for (final controller in _timerControllers.values) {
        controller.reset();
      }
      _timerControllers.clear();

      if (autoCreateTodayHistory) {
        _ensureDailyRecords(todayKey, current);
      }

      _lastDateKey = todayKey;
      notificationService?.rescheduleAll(getReminderConfigs(), _activities, testNow: current);
      return true;
    } else {
      _lastDateKey ??= todayKey;
      if (autoCreateTodayHistory) {
        _ensureDailyRecords(todayKey, current);
      }
      return false;
    }
  }
}
