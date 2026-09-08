import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';
import '../models/day_history.dart';
import '../models/reminder_config.dart';
import '../services/notification_service.dart';
import 'activity_repository.dart';

class SharedPreferencesActivityRepository implements ActivityRepository {
  static const String _storageKey = 'activities';
  static const String _historyKey = 'activity_history';
  static const String _lastDateKey = 'last_active_date';
  static const String _corruptedBackupKey = 'activities_corrupted_backup';
  static const String _remindersKey = 'activity_reminders';
  
  final SharedPreferences _prefs;
  final NotificationService? notificationService;
  final List<Activity> _activities = [];
  final List<DayHistory> _history = [];
  final Map<String, ReminderConfig> _reminderConfigs = {};

  SharedPreferencesActivityRepository(
    this._prefs, {
    this.notificationService,
  }) {
    _loadAll();
  }

  static Future<SharedPreferencesActivityRepository> init({
    NotificationService? notificationService,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return SharedPreferencesActivityRepository(
      prefs,
      notificationService: notificationService,
    );
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
    _loadReminderConfigs();
    _checkDateRollover();
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
    for (final id in ['meditation', 'walking', 'dumbbells']) {
      _reminderConfigs.putIfAbsent(id, () => ReminderConfig.defaultFor(id));
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
          if (loadedActivities.isNotEmpty) {
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

  void _checkDateRollover({DateTime? overrideNow}) {
    final now = overrideNow ?? DateTime.now();
    final todayKey = _formatDateKey(now);
    final lastActiveDate = _prefs.getString(_lastDateKey);

    if (lastActiveDate != null && lastActiveDate != todayKey) {
      // Prior day completed or passed — archive prior day into history
      _archiveDay(lastActiveDate);

      // Start fresh for today: retain routine definitions, reset status
      for (int i = 0; i < _activities.length; i++) {
        _activities[i] = _activities[i].copyWith(
          isCompleted: false,
          isSkipped: false,
          completedSetsReps: const [],
        );
      }
      _prefs.setString(_lastDateKey, todayKey);
      _saveActivities(currentDate: now);
      notificationService?.rescheduleAll(getReminderConfigs(), _activities, testNow: now);
    } else if (lastActiveDate == null) {
      _prefs.setString(_lastDateKey, todayKey);
    }
  }

  void _archiveDay(String dateKey, {DateTime? recordedAt}) {
    if (_activities.isEmpty) return;

    // Check if already archived
    final existingIndex = _history.indexWhere((h) => h.dateKey == dateKey);
    final snapshot = DayHistory(
      dateKey: dateKey,
      activities: List.of(_activities),
      recordedAt: recordedAt ?? DateTime.now(),
    );

    if (existingIndex != -1) {
      _history[existingIndex] = snapshot;
    } else {
      _history.insert(0, snapshot);
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
    ]);
    _saveActivities();
  }

  Future<void> _saveActivities({DateTime? currentDate}) async {
    try {
      final String encodedList = jsonEncode(
        _activities.map((activity) => activity.toJson()).toList(),
      );
      await _prefs.setString(_storageKey, encodedList);

      final todayKey = _formatDateKey(currentDate ?? DateTime.now());
      await _prefs.setString(_lastDateKey, todayKey);
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
      if (willBeCompleted) {
        notificationService?.cancelActivityReminders(id);
      }
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
      if (isCompleted) {
        notificationService?.cancelActivityReminders(id);
      }
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
      if (isSkipped) {
        notificationService?.cancelActivityReminders(id);
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
    _saveActivities();
  }

  @override
  void updateActivity(Activity activity) {
    final index = _activities.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      _activities[index] = activity;
      _saveActivities();
      if (activity.isCompleted || activity.isSkipped) {
        notificationService?.cancelActivityReminders(activity.id);
      }
    }
  }

  @override
  Future<void> flush() async {
    await _saveActivities();
    await _saveHistory();
    await _saveReminderConfigs();
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
    notificationService?.scheduleActivityReminders(
      config,
      isCompletedToday: activity?.isCompleted ?? false,
      isSkippedToday: activity?.isSkipped ?? false,
    );
  }

  /// Exposed for testing date rollover behavior.
  @visibleForTesting
  Future<void> simulateDateRollover(DateTime newDate) async {
    _checkDateRollover(overrideNow: newDate);
    await flush();
  }
}
