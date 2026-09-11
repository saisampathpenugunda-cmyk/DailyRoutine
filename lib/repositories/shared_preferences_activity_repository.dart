import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/routine_timer_controller.dart';
import '../models/activity.dart';
import '../models/day_history.dart';
import '../models/reminder_config.dart';
import '../services/notification_service.dart';
import 'activity_repository.dart';

class SharedPreferencesActivityRepository implements ActivityRepository {
  static const String _storageKey = 'activities';
  static const String _historyKey = 'activity_history';
  static const String _lastDateKey = 'last_active_date';
  static const String _firstTrackedDateKey = 'first_tracked_date';
  static const String _corruptedBackupKey = 'activities_corrupted_backup';
  static const String _remindersKey = 'activity_reminders';
  static const String _timersKey = 'activity_timer_states';
  static const String _enabledOrderKey = 'enabled_activity_order';
  
  final SharedPreferences _prefs;
  final NotificationService? notificationService;
  final List<Activity> _activities = [];
  final List<String> _enabledOrder = [];
  final List<DayHistory> _history = [];
  final Map<String, ReminderConfig> _reminderConfigs = {};
  final Map<String, RoutineTimerController> _timerControllers = {};
  final DateTime Function() _clock;

  SharedPreferencesActivityRepository(
    this._prefs, {
    this.notificationService,
    DateTime? now,
    DateTime Function()? clock,
  }) : _clock = clock ?? (now != null ? () => now : () => DateTime.now()) {
    _loadAll();
  }

  static Future<SharedPreferencesActivityRepository> init({
    NotificationService? notificationService,
    DateTime? now,
    DateTime Function()? clock,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final repo = SharedPreferencesActivityRepository(
      prefs,
      notificationService: notificationService,
      now: now,
      clock: clock,
    );
    await repo.checkDateRollover(now: now ?? repo._clock());
    return repo;
  }

  String _formatDateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _loadAll() {
    _loadHistory();
    _loadActivities();
    _loadEnabledOrder();
    _loadReminderConfigs();
    _loadTimerStates();
    checkDateRollover(now: _clock());
  }

  void _loadEnabledOrder() {
    _enabledOrder.clear();
    final List<String>? savedOrder = _prefs.getStringList(_enabledOrderKey);
    final existingEnabledIds = _activities.where((a) => a.isEnabled).map((a) => a.id).toSet();

    if (savedOrder != null && savedOrder.isNotEmpty) {
      for (final id in savedOrder) {
        if (existingEnabledIds.contains(id) && !_enabledOrder.contains(id)) {
          _enabledOrder.add(id);
        }
      }
    }
    for (final act in _activities) {
      if (act.isEnabled && !_enabledOrder.contains(act.id)) {
        _enabledOrder.add(act.id);
      }
    }
    _sortActivitiesByOrder();
  }

  Future<void> _saveEnabledOrder() async {
    try {
      await _prefs.setStringList(_enabledOrderKey, List<String>.from(_enabledOrder));
    } catch (e) {
      debugPrint('Error saving enabled activity order: $e');
    }
  }

  void _sortActivitiesByOrder() {
    final originalIndices = {
      for (int i = 0; i < _activities.length; i++) _activities[i].id: i,
    };
    final enabledMap = {
      for (int i = 0; i < _enabledOrder.length; i++) _enabledOrder[i]: i,
    };
    _activities.sort((a, b) {
      if (a.isEnabled && b.isEnabled) {
        final orderA = enabledMap[a.id] ?? 999999;
        final orderB = enabledMap[b.id] ?? 999999;
        final cmp = orderA.compareTo(orderB);
        if (cmp != 0) return cmp;
        return (originalIndices[a.id] ?? 0).compareTo(originalIndices[b.id] ?? 0);
      } else if (a.isEnabled && !b.isEnabled) {
        return -1;
      } else if (!a.isEnabled && b.isEnabled) {
        return 1;
      } else {
        return (originalIndices[a.id] ?? 0).compareTo(originalIndices[b.id] ?? 0);
      }
    });
  }

  void _loadTimerStates() {
    _timerControllers.clear();
    final String? timersJson = _prefs.getString(_timersKey);
    if (timersJson != null) {
      try {
        final dynamic decoded = jsonDecode(timersJson);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final key = entry.key.toString();
            final val = entry.value;
            if (val is Map) {
              final act = getActivityById(key);
              final ctrl = RoutineTimerController.fromJson(
                Map<String, dynamic>.from(val),
                fallbackTotalDuration: act?.defaultDuration,
              );
              _timerControllers[key] = ctrl;
              _attachTimerListener(key, ctrl);
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading timer states: $e');
      }
    }
  }

  Future<void> _saveTimerStates() async {
    try {
      final Map<String, dynamic> data = {};
      for (final entry in _timerControllers.entries) {
        data[entry.key] = entry.value.toJson();
      }
      await _prefs.setString(_timersKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving timer states: $e');
    }
  }

  void _attachTimerListener(String activityId, RoutineTimerController controller) {
    TimerState lastState = controller.state;
    controller.addListener(() {
      if (controller.state != lastState) {
        lastState = controller.state;
        _saveTimerStates();
      }
    });
  }

  void _loadReminderConfigs() {
    _reminderConfigs.clear();
    final String? remindersJson = _prefs.getString(_remindersKey);
    if (remindersJson != null) {
      try {
        final dynamic decoded = jsonDecode(remindersJson);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              try {
                final cfg = ReminderConfig.fromJson(Map<String, dynamic>.from(item));
                _reminderConfigs[cfg.activityId] = cfg;
              } catch (_) {}
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading reminder configs: $e');
      }
    }
    for (final activity in _activities) {
      _reminderConfigs.putIfAbsent(activity.id, () => ReminderConfig.defaultFor(activity.id));
    }
  }

  Future<void> _saveReminderConfigs() async {
    try {
      final String encoded = jsonEncode(
        _reminderConfigs.values.map((c) => c.toJson()).toList(),
      );
      await _prefs.setString(_remindersKey, encoded);
    } catch (e) {
      debugPrint('Error saving reminder configs: $e');
    }
  }

  void _loadHistory() {
    _history.clear();
    final String? historyJson = _prefs.getString(_historyKey);
    if (historyJson != null) {
      try {
        final dynamic decoded = jsonDecode(historyJson);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              try {
                _history.add(DayHistory.fromJson(Map<String, dynamic>.from(item)));
              } catch (_) {}
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading history: $e');
      }
    }
  }

  void _loadActivities() {
    final String? activitiesJson = _prefs.getString(_storageKey);
    if (activitiesJson != null) {
      try {
        final dynamic decoded = jsonDecode(activitiesJson);
        if (decoded is List) {
          final List<Activity> loadedActivities = [];
          for (final item in decoded) {
            if (item is Map) {
              try {
                loadedActivities.add(Activity.fromJson(Map<String, dynamic>.from(item)));
              } catch (e) {
                debugPrint('Skipping malformed activity entry: $e');
              }
            }
          }
          if (decoded.isEmpty || loadedActivities.isNotEmpty) {
            if (!loadedActivities.any((a) => a.id == 'guitar')) {
              loadedActivities.add(const Activity(
                id: 'guitar',
                name: 'Guitar',
                activityType: ActivityType.guitar,
                defaultDuration: Duration(minutes: 15),
                isEnabled: true,
                isCompleted: false,
              ));
            } else {
              final gIdx = loadedActivities.indexWhere((a) => a.id == 'guitar');
              if (gIdx != -1 && !loadedActivities[gIdx].isEnabled) {
                loadedActivities[gIdx] = loadedActivities[gIdx].copyWith(isEnabled: true);
              }
            }
            _activities.clear();
            _activities.addAll(loadedActivities);
            return;
          }
        }
        _preserveCorruptedData(activitiesJson);
        _initializeDefaults();
      } catch (e) {
        _preserveCorruptedData(activitiesJson);
        _initializeDefaults();
      }
    } else {
      _initializeDefaults();
    }
  }

  @override
  Future<bool> checkDateRollover({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final todayKey = _formatDateKey(current);
    final lastActiveDate = _prefs.getString(_lastDateKey);

    if (lastActiveDate != null && lastActiveDate != todayKey) {
      // 1. Archive old day into DayHistory and persist
      await _archiveDay(lastActiveDate, recordedAt: current);

      // 2. Reset activities for the new day
      for (int i = 0; i < _activities.length; i++) {
        _activities[i] = _activities[i].copyWith(
          isCompleted: false,
          isSkipped: false,
          actualDuration: Duration.zero,
          completedSetsReps: const [],
        );
      }

      // 3. Clear/reset active timer state
      for (final controller in _timerControllers.values) {
        controller.reset();
      }
      _timerControllers.clear();
      await _prefs.remove(_timersKey);

      // 4. Ensure all missing days are created at 0% and today's record exists at 0%
      await _ensureDailyRecords(todayKey, current);

      // 5. Set last_active_date to today's date
      await _prefs.setString(_lastDateKey, todayKey);

      // 6. Persist today's fresh activity state
      await _saveActivities();

      // 7. Reschedule reminders if required
      notificationService?.rescheduleAll(getReminderConfigs(), _activities, testNow: current);
      return true;
    } else {
      if (lastActiveDate == null) {
        await _prefs.setString(_lastDateKey, todayKey);
      }
      // Ensure records up to today exist even on same-day runs or cold start
      await _ensureDailyRecords(todayKey, current);
      return false;
    }
  }

  Future<void> _archiveDay(String dateKey, {DateTime? recordedAt}) async {
    if (_activities.isEmpty) return;

    final existingIndex = _history.indexWhere((h) => h.dateKey == dateKey);
    final snapshot = DayHistory(
      dateKey: dateKey,
      activities: _createActivitiesSnapshotWithElapsed(),
      recordedAt: recordedAt ?? DateTime.now(),
    );

    if (existingIndex != -1) {
      _history[existingIndex] = snapshot;
    } else {
      _history.add(snapshot);
    }
    _history.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    await _saveHistory();
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

  String _determineFirstTrackedDate(String todayKey) {
    final persisted = _prefs.getString(_firstTrackedDateKey);
    if (persisted != null && persisted.isNotEmpty) {
      return persisted;
    }

    String? earliest;
    for (final h in _history) {
      if (h.dateKey.isNotEmpty) {
        if (earliest == null || h.dateKey.compareTo(earliest) < 0) {
          earliest = h.dateKey;
        }
      }
    }

    final lastDate = _prefs.getString(_lastDateKey);
    if (lastDate != null && lastDate.isNotEmpty) {
      if (earliest == null || lastDate.compareTo(earliest) < 0) {
        earliest = lastDate;
      }
    }

    final firstDate = earliest ?? todayKey;
    _prefs.setString(_firstTrackedDateKey, firstDate);
    return firstDate;
  }

  Future<void> _ensureDailyRecords(String todayKey, DateTime current) async {
    final firstTrackedKey = _determineFirstTrackedDate(todayKey);

    DateTime parseKey(String k) {
      final parts = k.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }

    final firstDate = parseKey(firstTrackedKey);
    final todayDate = parseKey(todayKey);

    bool changed = false;

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
        changed = true;
      } else {
        if (existingIndex == -1) {
          _history.add(DayHistory(
            dateKey: key,
            activities: _createCleanActivitiesSnapshot(),
            recordedAt: cursor,
          ));
          changed = true;
        }
      }

      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }

    _history.sort((a, b) => b.dateKey.compareTo(a.dateKey));

    if (changed) {
      await _saveHistory();
    }
  }

  void _syncTodayHistory({DateTime? now}) {
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
    _saveHistory();
  }

  void _preserveCorruptedData(String corruptedData) {
    debugPrint('Warning: Activity data corrupted in storage. Preserving backup in $_corruptedBackupKey');
    _prefs.setString(_corruptedBackupKey, corruptedData);
  }

  void _initializeDefaults() {
    _activities.clear();
    _activities.addAll([
      const Activity(
        id: 'meditation',
        name: 'Meditation',
        activityType: ActivityType.meditation,
        defaultDuration: Duration(minutes: 10),
      ),
      const Activity(
        id: 'walking',
        name: 'Walking',
        activityType: ActivityType.walking,
        defaultDuration: Duration(minutes: 30),
      ),
      const Activity(
        id: 'dumbbells',
        name: 'Dumbbells',
        activityType: ActivityType.dumbbells,
        defaultDuration: Duration(minutes: 20),
      ),
      const Activity(
        id: 'guitar',
        name: 'Guitar',
        activityType: ActivityType.guitar,
        defaultDuration: Duration(minutes: 15),
      ),
    ]);
    _enabledOrder.clear();
    _enabledOrder.addAll(['meditation', 'walking', 'dumbbells', 'guitar']);
    _saveEnabledOrder();
    _saveActivities();
  }

  Future<void> _saveActivities() async {
    try {
      final String encodedList = jsonEncode(
        _activities.map((activity) => activity.toJson()).toList(),
      );
      await _prefs.setString(_storageKey, encodedList);
    } catch (e) {
      debugPrint('Error saving activities to SharedPreferences: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final String encodedHistory = jsonEncode(
        _history.map((h) => h.toJson()).toList(),
      );
      await _prefs.setString(_historyKey, encodedHistory);
    } catch (e) {
      debugPrint('Error saving history to SharedPreferences: $e');
    }
  }

  @override
  List<Activity> getActivities() {
    return List.unmodifiable(_activities);
  }

  @override
  List<DayHistory> getHistory() {
    return List.unmodifiable(_history);
  }

  @override
  Activity? getActivityById(String id) {
    for (final activity in _activities) {
      if (activity.id == id) return activity;
    }
    return null;
  }

  @override
  void toggleActivityCompletion(String id) {
    final index = _activities.indexWhere((activity) => activity.id == id);
    if (index != -1) {
      final current = _activities[index];
      final willBeCompleted = !current.isCompleted;
      _activities[index] = current.copyWith(
        isCompleted: willBeCompleted,
        isSkipped: false,
      );
      _saveActivities();
      _syncTodayHistory();
      if (willBeCompleted) {
        notificationService?.cancelActivityReminders(id);
        _timerControllers[id]?.finish();
      } else {
        _timerControllers[id]?.reset();
      }
      _saveTimerStates();
    }
  }

  @override
  void setActivityCompletion(String id, {required bool isCompleted}) {
    final index = _activities.indexWhere((activity) => activity.id == id);
    if (index != -1) {
      _activities[index] = _activities[index].copyWith(
        isCompleted: isCompleted,
        isSkipped: false,
      );
      _saveActivities();
      _syncTodayHistory();
      if (isCompleted) {
        notificationService?.cancelActivityReminders(id);
        _timerControllers[id]?.finish();
      } else {
        _timerControllers[id]?.reset();
      }
      _saveTimerStates();
    }
  }

  @override
  void setActivitySkipped(String id, {required bool isSkipped}) {
    final index = _activities.indexWhere((activity) => activity.id == id);
    if (index != -1) {
      _activities[index] = _activities[index].copyWith(
        isSkipped: isSkipped,
        isCompleted: false,
      );
      _saveActivities();
      _syncTodayHistory();
      if (isSkipped) {
        notificationService?.cancelActivityReminders(id);
        _timerControllers[id]?.reset();
      }
      _saveTimerStates();
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
    if (activity.isEnabled) {
      _enabledOrder.remove(activity.id);
      _enabledOrder.add(activity.id);
    } else {
      _enabledOrder.remove(activity.id);
    }
    _sortActivitiesByOrder();
    _saveEnabledOrder();
    _saveActivities();
    _syncTodayHistory();
  }

  @override
  void updateActivity(Activity activity) {
    final index = _activities.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      final oldActivity = _activities[index];
      _activities[index] = activity;

      if (!oldActivity.isEnabled && activity.isEnabled) {
        _enabledOrder.remove(activity.id);
        _enabledOrder.add(activity.id);
      } else if (oldActivity.isEnabled && !activity.isEnabled) {
        _enabledOrder.remove(activity.id);
      }
      _sortActivitiesByOrder();
      _saveEnabledOrder();

      // If timer is unstarted (initial), update duration immediately.
      // If timer is running or paused, leave the current session untouched.
      final controller = _timerControllers[activity.id];
      if (controller != null && controller.isInitial) {
        controller.updateDurationIfInitial(activity.defaultDuration);
        _saveTimerStates();
      }

      _saveActivities();
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
    if (activityId == 'guitar' && !isEnabled) {
      return false;
    }
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
      _enabledOrder.remove(activityId);
      notificationService?.cancelActivityReminders(activityId);
    } else {
      _enabledOrder.remove(activityId);
      _enabledOrder.add(activityId);
      final config = getReminderConfig(activityId);
      if (config.hasAnyReminder && !updated.isCompleted && !updated.isSkipped) {
        notificationService?.scheduleActivityReminders(
          config,
          isCompletedToday: updated.isCompleted,
          isSkippedToday: updated.isSkipped,
        );
      }
    }

    _sortActivitiesByOrder();
    _saveEnabledOrder();
    _saveActivities();
    _syncTodayHistory();
    return true;
  }

  @override
  bool deleteActivity(String activityId) {
    if (activityId == 'guitar') return false;
    final activity = getActivityById(activityId);
    if (activity == null) return false;
    if (isActivityInProgress(activityId)) return false;

    _activities.removeWhere((a) => a.id == activityId);
    _enabledOrder.remove(activityId);
    _reminderConfigs.remove(activityId);
    _timerControllers.remove(activityId);
    notificationService?.cancelActivityReminders(activityId);

    _sortActivitiesByOrder();
    _saveActivities();
    _saveEnabledOrder();
    _saveReminderConfigs();
    _saveTimerStates();
    _syncTodayHistory();
    return true;
  }

  @override
  Future<void> flush() async {
    await _saveActivities();
    await _saveEnabledOrder();
    await _saveHistory();
    await _saveReminderConfigs();
    await _saveTimerStates();
  }

  @override
  List<String> getEnabledActivityOrder() {
    return List.unmodifiable(_enabledOrder);
  }

  @override
  void reorderEnabledActivities(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _enabledOrder.length) return;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (newIndex < 0 || newIndex >= _enabledOrder.length) return;
    if (oldIndex == newIndex) return;

    final id = _enabledOrder.removeAt(oldIndex);
    _enabledOrder.insert(newIndex, id);
    _sortActivitiesByOrder();
    _saveEnabledOrder();
    _saveActivities();
  }

  @override
  void updateEnabledActivityOrder(List<String> orderedIds) {
    final validEnabled = _activities.where((a) => a.isEnabled).map((a) => a.id).toSet();
    final newOrder = <String>[];
    for (final id in orderedIds) {
      if (validEnabled.contains(id) && !newOrder.contains(id)) {
        newOrder.add(id);
      }
    }
    for (final act in _activities) {
      if (act.isEnabled && !newOrder.contains(act.id)) {
        newOrder.add(act.id);
      }
    }
    _enabledOrder.clear();
    _enabledOrder.addAll(newOrder);
    _sortActivitiesByOrder();
    _saveEnabledOrder();
    _saveActivities();
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
    _saveReminderConfigs();
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
    if (!_timerControllers.containsKey(activityId)) {
      final activity = getActivityById(activityId);
      final duration = defaultDuration ?? activity?.defaultDuration ?? const Duration(minutes: 10);
      final isDone = activity?.isCompleted ?? false;
      final controller = RoutineTimerController(
        totalDuration: duration,
        initialState: isDone ? TimerState.completed : TimerState.initial,
        initialRemaining: isDone ? Duration.zero : duration,
        now: now ?? _clock,
      );
      _timerControllers[activityId] = controller;
      _attachTimerListener(activityId, controller);
    }
    return _timerControllers[activityId]!;
  }

  @override
  void resetTimer(String activityId) {
    final activity = getActivityById(activityId);
    final duration = activity?.defaultDuration ?? const Duration(minutes: 10);
    final isDone = activity?.isCompleted ?? false;
    final controller = RoutineTimerController(
      totalDuration: duration,
      initialState: isDone ? TimerState.completed : TimerState.initial,
      initialRemaining: isDone ? Duration.zero : duration,
      now: _clock,
    );
    _timerControllers[activityId] = controller;
    _attachTimerListener(activityId, controller);
    _saveTimerStates();
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

  /// Exposed for testing date rollover behavior.
  @visibleForTesting
  Future<void> simulateDateRollover(DateTime newDate) async {
    await checkDateRollover(now: newDate);
    await flush();
  }
}
