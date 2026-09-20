import '../models/timetable_data.dart';
import '../models/timetable_session.dart';

enum NowNextStatus {
  now,
  next,
  classesFinishedToday,
  noClassesToday,
}

class NowNextResult {
  final NowNextStatus status;
  final TimetableSession? currentSession;
  final TimetableSession? nextSession;
  final String? nextSessionDayName;
  final DateTime nextTransitionTime;

  const NowNextResult({
    required this.status,
    this.currentSession,
    this.nextSession,
    this.nextSessionDayName,
    required this.nextTransitionTime,
  });

  /// User-facing badge header: "NOW", "NEXT CLASS", "TODAY'S CLASSES FINISHED", "NO CLASSES TODAY"
  String get statusHeader {
    switch (status) {
      case NowNextStatus.now:
        return 'NOW';
      case NowNextStatus.next:
        return 'NEXT CLASS';
      case NowNextStatus.classesFinishedToday:
        return "TODAY'S CLASSES FINISHED";
      case NowNextStatus.noClassesToday:
        return 'NO CLASSES TODAY';
    }
  }

  @override
  String toString() =>
      'NowNextResult(status: $status, current: ${currentSession?.courseTitle}, next: ${nextSession?.courseTitle})';
}

/// Service providing pure Now/Next calculation with an injectable clock provider.
class TimetableService {
  final DateTime Function() _clock;

  TimetableService({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  /// Calculates the current Now/Next status for the given [targetTime] or current clock time.
  NowNextResult getNowNext({DateTime? targetTime}) {
    final now = targetTime ?? _clock();
    final currentDay = now.weekday; // 1 = Monday, ..., 7 = Sunday
    final currentMinutes = now.hour * 60 + now.minute;

    final todaySessions = TimetableData.getSessionsForDay(currentDay);

    // 1. Day has no classes scheduled (e.g. Saturday, Sunday)
    if (todaySessions.isEmpty) {
      final upcoming = _findNextUpcomingClassAfter(currentDay, now);
      final nextDayMidnight = DateTime(now.year, now.month, now.day + 1);
      return NowNextResult(
        status: NowNextStatus.noClassesToday,
        nextSession: upcoming?.session,
        nextSessionDayName: upcoming?.dayName,
        nextTransitionTime: nextDayMidnight,
      );
    }

    // 2. Check if a class is currently running: currentTime >= start && currentTime < end
    for (int i = 0; i < todaySessions.length; i++) {
      final s = todaySessions[i];
      if (currentMinutes >= s.startMinutes && currentMinutes < s.endMinutes) {
        // Current class running
        final nextToday = (i + 1 < todaySessions.length) ? todaySessions[i + 1] : null;
        final nextUpcoming = nextToday != null
            ? _Upcoming(session: nextToday, dayName: 'Today')
            : _findNextUpcomingClassAfter(currentDay, now);

        final endHour = s.endMinutes ~/ 60;
        final endMinute = s.endMinutes % 60;
        final transition = DateTime(now.year, now.month, now.day, endHour, endMinute);

        return NowNextResult(
          status: NowNextStatus.now,
          currentSession: s,
          nextSession: nextUpcoming?.session,
          nextSessionDayName: nextUpcoming?.dayName,
          nextTransitionTime: transition,
        );
      }
    }

    // 3. Check if upcoming class today exists (before first class or between classes)
    for (int i = 0; i < todaySessions.length; i++) {
      final s = todaySessions[i];
      if (currentMinutes < s.startMinutes) {
        // First session whose start is after current time
        final startHour = s.startMinutes ~/ 60;
        final startMinute = s.startMinutes % 60;
        final transition = DateTime(now.year, now.month, now.day, startHour, startMinute);

        return NowNextResult(
          status: NowNextStatus.next,
          nextSession: s,
          nextSessionDayName: 'Today',
          nextTransitionTime: transition,
        );
      }
    }

    // 4. All classes today have finished
    final upcoming = _findNextUpcomingClassAfter(currentDay, now);
    final tomorrowMidnight = DateTime(now.year, now.month, now.day + 1);

    return NowNextResult(
      status: NowNextStatus.classesFinishedToday,
      nextSession: upcoming?.session,
      nextSessionDayName: upcoming?.dayName,
      nextTransitionTime: tomorrowMidnight,
    );
  }

  /// Finds the next upcoming class across subsequent days (1 to 7 cycle).
  _Upcoming? _findNextUpcomingClassAfter(int currentDay, DateTime now) {
    for (int offset = 1; offset <= 7; offset++) {
      int nextDay = ((currentDay - 1 + offset) % 7) + 1;
      final sessions = TimetableData.getSessionsForDay(nextDay);
      if (sessions.isNotEmpty) {
        final firstSession = sessions.first;
        return _Upcoming(
          session: firstSession,
          dayName: firstSession.dayName,
        );
      }
    }
    return null;
  }
}

class _Upcoming {
  final TimetableSession session;
  final String dayName;

  const _Upcoming({required this.session, required this.dayName});
}
