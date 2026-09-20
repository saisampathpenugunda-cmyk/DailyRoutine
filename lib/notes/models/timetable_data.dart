import 'timetable_session.dart';

/// Centralized immutable source of truth for the college weekly timetable.
class TimetableData {
  TimetableData._();

  static const List<TimetableSession> weeklySchedule = [
    // ── MONDAY (Day 1) ──────────────────────────────────────────────────────
    TimetableSession(
      day: 1,
      startTime: '08:00',
      endTime: '08:50',
      courseCode: '24CSEN1011',
      courseTitle: 'Object Oriented Programming',
      room: 'ICT / 505',
    ),
    TimetableSession(
      day: 1,
      startTime: '09:00',
      endTime: '09:50',
      courseCode: '24CSEN2021',
      courseTitle: 'Computer Organization and Architecture',
      room: 'ICT / 505',
    ),
    TimetableSession(
      day: 1,
      startTime: '10:00',
      endTime: '10:50',
      courseCode: 'MATH2561',
      courseTitle: 'Probability and Statistics For Engineering',
      room: 'ICT / 218',
    ),
    TimetableSession(
      day: 1,
      startTime: '11:00',
      endTime: '11:50',
      courseCode: '24CSEN2001',
      courseTitle: 'Data Structures',
      room: 'ICT / 617',
    ),
    TimetableSession(
      day: 1,
      startTime: '13:00',
      endTime: '13:50',
      courseCode: 'EECE2191',
      courseTitle: 'Fundamentals of Autonomous Vehicles',
      room: 'ICT / 424',
    ),

    // ── TUESDAY (Day 2) ─────────────────────────────────────────────────────
    TimetableSession(
      day: 2,
      startTime: '08:00',
      endTime: '08:50',
      courseCode: '24CSEN1011P',
      courseTitle: 'Object Oriented Programming Lab',
      room: 'ICT / 209',
    ),
    TimetableSession(
      day: 2,
      startTime: '09:00',
      endTime: '09:50',
      courseCode: '24CSEN1011P',
      courseTitle: 'Object Oriented Programming Lab',
      room: 'ICT / 209',
    ),
    TimetableSession(
      day: 2,
      startTime: '10:00',
      endTime: '10:50',
      courseCode: '24CSEN2021',
      courseTitle: 'Computer Organization and Architecture',
      room: 'ICT / 505',
    ),
    TimetableSession(
      day: 2,
      startTime: '11:00',
      endTime: '11:50',
      courseCode: 'MATH2561',
      courseTitle: 'Probability and Statistics For Engineering',
      room: 'ICT / 6032',
    ),
    TimetableSession(
      day: 2,
      startTime: '13:00',
      endTime: '13:50',
      courseCode: 'EECE2191',
      courseTitle: 'Fundamentals of Autonomous Vehicles',
      room: 'ICT / 424',
    ),

    // ── WEDNESDAY (Day 3) ───────────────────────────────────────────────────
    TimetableSession(
      day: 3,
      startTime: '08:00',
      endTime: '08:50',
      courseCode: '24CSEN2001',
      courseTitle: 'Data Structures',
      room: 'ICT / 617',
    ),
    TimetableSession(
      day: 3,
      startTime: '09:00',
      endTime: '09:50',
      courseCode: '24CSEN1011',
      courseTitle: 'Object Oriented Programming',
      room: 'ICT / 505',
    ),
    TimetableSession(
      day: 3,
      startTime: '10:00',
      endTime: '10:50',
      courseCode: 'MATH2561',
      courseTitle: 'Probability and Statistics For Engineering',
      room: 'ICT / 218',
    ),
    TimetableSession(
      day: 3,
      startTime: '11:00',
      endTime: '11:50',
      courseCode: '24CSEN2021',
      courseTitle: 'Computer Organization and Architecture',
      room: 'ICT / 505',
    ),
    TimetableSession(
      day: 3,
      startTime: '13:00',
      endTime: '13:50',
      courseCode: 'EECE2191',
      courseTitle: 'Fundamentals of Autonomous Vehicles',
      room: 'ICT / 424',
    ),

    // ── THURSDAY (Day 4) ────────────────────────────────────────────────────
    TimetableSession(
      day: 4,
      startTime: '08:00',
      endTime: '08:50',
      courseCode: '24CSEN2001P',
      courseTitle: 'Data Structures Lab',
      room: 'ICT / 220',
    ),
    TimetableSession(
      day: 4,
      startTime: '09:00',
      endTime: '09:50',
      courseCode: '24CSEN2001P',
      courseTitle: 'Data Structures Lab',
      room: 'ICT / 220',
    ),
    TimetableSession(
      day: 4,
      startTime: '10:00',
      endTime: '10:50',
      courseCode: 'GCGC1001',
      courseTitle: 'Aptitude and Self-Management Skills',
      room: 'ICT / 617',
    ),
    TimetableSession(
      day: 4,
      startTime: '11:00',
      endTime: '11:50',
      courseCode: 'GCGC1001',
      courseTitle: 'Aptitude and Self-Management Skills',
      room: 'ICT / 617',
    ),
    TimetableSession(
      day: 4,
      startTime: '14:00',
      endTime: '14:50',
      courseCode: '24CSEN2021',
      courseTitle: 'Computer Organization and Architecture',
      room: 'ICT / 505',
    ),

    // ── FRIDAY (Day 5) ──────────────────────────────────────────────────────
    TimetableSession(
      day: 5,
      startTime: '09:00',
      endTime: '09:50',
      courseCode: 'MATH2561',
      courseTitle: 'Probability and Statistics For Engineering',
      room: 'ICT / 6032',
    ),
    TimetableSession(
      day: 5,
      startTime: '10:00',
      endTime: '10:50',
      courseCode: '24CSEN2001',
      courseTitle: 'Data Structures',
      room: 'ICT / 617',
    ),
    TimetableSession(
      day: 5,
      startTime: '11:00',
      endTime: '11:50',
      courseCode: '24CSEN1011',
      courseTitle: 'Object Oriented Programming',
      room: 'ICT / 505',
    ),

    // ── SATURDAY (Day 6) & SUNDAY (Day 7) ──────────────────────────────────
    // No classes
  ];

  /// Returns all sessions scheduled for [day] (1=Monday ... 7=Sunday), sorted by startTime.
  static List<TimetableSession> getSessionsForDay(int day) {
    final sessions = weeklySchedule.where((s) => s.day == day).toList();
    sessions.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return List.unmodifiable(sessions);
  }
}
