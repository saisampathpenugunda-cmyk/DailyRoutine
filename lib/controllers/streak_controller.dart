import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/day_history.dart';
import '../repositories/activity_repository.dart';

/// Immutable model holding the calculated current and all-time best streaks.
class StreakInfo {
  final int currentStreak;
  final int bestStreak;

  const StreakInfo({
    required this.currentStreak,
    required this.bestStreak,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakInfo &&
          runtimeType == other.runtimeType &&
          currentStreak == other.currentStreak &&
          bestStreak == other.bestStreak;

  @override
  int get hashCode => currentStreak.hashCode ^ bestStreak.hashCode;

  @override
  String toString() => 'StreakInfo(current: $currentStreak, best: $bestStreak)';
}

/// Controller responsible for calculating, managing, and persisting routine streaks.
///
/// Rules:
/// - A day counts toward the streak only when ALL activities enabled on that day
///   are fully completed (`dayHistory.isAllCompleted == true`).
/// - Partial, skipped, missed, or 0-enabled-activity days do not count.
/// - Calendar dates are used strictly for consecutive day calculations.
/// - Best streak is monotonically non-decreasing and never decreases upon reset.
/// - History data in [ActivityRepository] is the primary source of truth.
class StreakController extends ValueNotifier<StreakInfo> {
  static const String currentStreakKey = 'streak_current';
  static const String bestStreakKey = 'streak_best';

  final ActivityRepository repository;
  final SharedPreferences? _prefs;
  final DateTime Function() _clock;

  StreakController({
    required this.repository,
    SharedPreferences? prefs,
    DateTime Function()? now,
    StreakInfo initial = const StreakInfo(currentStreak: 0, bestStreak: 0),
  })  : _prefs = prefs,
        _clock = now ?? DateTime.now,
        super(initial);

  int get currentStreak => value.currentStreak;
  int get bestStreak => value.bestStreak;

  /// Asynchronously initializes [StreakController], restoring saved streaks
  /// from [SharedPreferences] and performing an initial calculation.
  static Future<StreakController> init({
    required ActivityRepository repository,
    SharedPreferences? prefs,
    DateTime Function()? now,
  }) async {
    final preferences = prefs ?? await SharedPreferences.getInstance();
    final savedCurrent = preferences.getInt(currentStreakKey) ?? 0;
    final savedBest = preferences.getInt(bestStreakKey) ?? 0;

    final controller = StreakController(
      repository: repository,
      prefs: preferences,
      now: now,
      initial: StreakInfo(currentStreak: savedCurrent, bestStreak: savedBest),
    );
    controller.recalculate();
    return controller;
  }

  /// Recalculates current and best streaks against repository history and current day state.
  void recalculate({DateTime? now}) {
    final current = now ?? _clock();
    final activities = repository.getActivities();
    final enabledActivities = activities.where((a) => a.isEnabled).toList();

    final bool hasZeroEnabledToday = enabledActivities.isEmpty;
    final bool isTodayAllCompleted =
        !hasZeroEnabledToday && enabledActivities.every((a) => a.isCompleted);
    final bool isTodaySkipped = enabledActivities.any((a) => a.isSkipped);

    final history = repository.getHistory();
    final Map<String, DayHistory> historyMap = {
      for (final h in history) h.dateKey: h,
    };

    String formatDateKey(DateTime dt) {
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }

    bool isDaySuccessful(String dateKey) {
      final h = historyMap[dateKey];
      if (h == null) return false;
      return h.isAllCompleted;
    }

    // ── 1. Calculate Current Streak ──────────────────────────────────────────
    int currentStreak = 0;

    if (hasZeroEnabledToday) {
      currentStreak = 0;
    } else if (isTodayAllCompleted) {
      currentStreak = 1;
      DateTime cursor = DateTime(current.year, current.month, current.day - 1);
      while (true) {
        final key = formatDateKey(cursor);
        if (isDaySuccessful(key)) {
          currentStreak++;
          cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
        } else {
          break;
        }
      }
    } else if (isTodaySkipped) {
      currentStreak = 0;
    } else {
      // Today is in-progress (not all completed, not skipped).
      // Active streak is the consecutive completed run ending yesterday.
      DateTime cursor = DateTime(current.year, current.month, current.day - 1);
      while (true) {
        final key = formatDateKey(cursor);
        if (isDaySuccessful(key)) {
          currentStreak++;
          cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
        } else {
          break;
        }
      }
    }

    // ── 2. Calculate Historical Best Streak ──────────────────────────────────
    final successfulDateKeys = <String>{};
    for (final h in history) {
      if (h.isAllCompleted) {
        successfulDateKeys.add(h.dateKey);
      }
    }

    final todayKey = formatDateKey(current);
    if (isTodayAllCompleted) {
      successfulDateKeys.add(todayKey);
    } else {
      successfulDateKeys.remove(todayKey);
    }

    int maxHistoryStreak = 0;
    if (successfulDateKeys.isNotEmpty) {
      final sortedDates = successfulDateKeys.map((k) {
        final parts = k.split('-');
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }).toList()
        ..sort((a, b) => a.compareTo(b));

      int run = 1;
      maxHistoryStreak = 1;
      for (int i = 1; i < sortedDates.length; i++) {
        final prev = sortedDates[i - 1];
        final curr = sortedDates[i];
        final expected = DateTime(prev.year, prev.month, prev.day + 1);
        if (curr.year == expected.year &&
            curr.month == expected.month &&
            curr.day == expected.day) {
          run++;
          if (run > maxHistoryStreak) {
            maxHistoryStreak = run;
          }
        } else {
          run = 1;
        }
      }
    }

    // ── 3. Guarantee Best Streak Never Decreases ─────────────────────────────
    int calculatedBest = value.bestStreak;
    if (_prefs != null) {
      final savedBest = _prefs.getInt(bestStreakKey) ?? 0;
      calculatedBest = math.max(calculatedBest, savedBest);
    }
    calculatedBest = math.max(calculatedBest, currentStreak);
    calculatedBest = math.max(calculatedBest, maxHistoryStreak);

    final newInfo = StreakInfo(
      currentStreak: currentStreak,
      bestStreak: calculatedBest,
    );

    if (value != newInfo) {
      value = newInfo;
    }

    // ── 4. Persist to SharedPreferences ─────────────────────────────────────
    if (_prefs != null) {
      _prefs.setInt(currentStreakKey, currentStreak);
      _prefs.setInt(bestStreakKey, calculatedBest);
    }
  }
}
