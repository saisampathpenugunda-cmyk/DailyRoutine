import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/notes/models/timetable_data.dart';
import 'package:daily_routine/notes/services/timetable_service.dart';

void main() {
  group('Timetable Data Source of Truth Tests', () {
    test('Monday has exactly 5 sessions with exact courses, times, and rooms', () {
      final monday = TimetableData.getSessionsForDay(1);
      expect(monday.length, 5);

      expect(monday[0].startTime, '08:00');
      expect(monday[0].endTime, '08:50');
      expect(monday[0].courseCode, '24CSEN1011');
      expect(monday[0].courseTitle, 'Object Oriented Programming');
      expect(monday[0].room, 'ICT / 505');

      expect(monday[1].startTime, '09:00');
      expect(monday[1].endTime, '09:50');
      expect(monday[1].courseCode, '24CSEN2021');
      expect(monday[1].courseTitle, 'Computer Organization and Architecture');
      expect(monday[1].room, 'ICT / 505');

      expect(monday[2].startTime, '10:00');
      expect(monday[2].endTime, '10:50');
      expect(monday[2].courseCode, 'MATH2561');
      expect(monday[2].courseTitle, 'Probability and Statistics For Engineering');
      expect(monday[2].room, 'ICT / 218');

      expect(monday[3].startTime, '11:00');
      expect(monday[3].endTime, '11:50');
      expect(monday[3].courseCode, '24CSEN2001');
      expect(monday[3].courseTitle, 'Data Structures');
      expect(monday[3].room, 'ICT / 617');

      expect(monday[4].startTime, '13:00');
      expect(monday[4].endTime, '13:50');
      expect(monday[4].courseCode, 'EECE2191');
      expect(monday[4].courseTitle, 'Fundamentals of Autonomous Vehicles');
      expect(monday[4].room, 'ICT / 424');
    });

    test('Tuesday has exactly 5 sessions with exact courses, times, and rooms', () {
      final tuesday = TimetableData.getSessionsForDay(2);
      expect(tuesday.length, 5);

      expect(tuesday[0].startTime, '08:00');
      expect(tuesday[0].endTime, '08:50');
      expect(tuesday[0].courseCode, '24CSEN1011P');
      expect(tuesday[0].courseTitle, 'Object Oriented Programming Lab');
      expect(tuesday[0].room, 'ICT / 209');

      expect(tuesday[1].startTime, '09:00');
      expect(tuesday[1].endTime, '09:50');
      expect(tuesday[1].courseCode, '24CSEN1011P');
      expect(tuesday[1].courseTitle, 'Object Oriented Programming Lab');
      expect(tuesday[1].room, 'ICT / 209');

      expect(tuesday[2].startTime, '10:00');
      expect(tuesday[2].endTime, '10:50');
      expect(tuesday[2].courseCode, '24CSEN2021');
      expect(tuesday[2].courseTitle, 'Computer Organization and Architecture');
      expect(tuesday[2].room, 'ICT / 505');

      expect(tuesday[3].startTime, '11:00');
      expect(tuesday[3].endTime, '11:50');
      expect(tuesday[3].courseCode, 'MATH2561');
      expect(tuesday[3].courseTitle, 'Probability and Statistics For Engineering');
      expect(tuesday[3].room, 'ICT / 6032');

      expect(tuesday[4].startTime, '13:00');
      expect(tuesday[4].endTime, '13:50');
      expect(tuesday[4].courseCode, 'EECE2191');
      expect(tuesday[4].courseTitle, 'Fundamentals of Autonomous Vehicles');
      expect(tuesday[4].room, 'ICT / 424');
    });

    test('Wednesday has exactly 5 sessions with exact courses, times, and rooms', () {
      final wednesday = TimetableData.getSessionsForDay(3);
      expect(wednesday.length, 5);

      expect(wednesday[0].startTime, '08:00');
      expect(wednesday[0].endTime, '08:50');
      expect(wednesday[0].courseCode, '24CSEN2001');
      expect(wednesday[0].courseTitle, 'Data Structures');
      expect(wednesday[0].room, 'ICT / 617');

      expect(wednesday[1].startTime, '09:00');
      expect(wednesday[1].endTime, '09:50');
      expect(wednesday[1].courseCode, '24CSEN1011');
      expect(wednesday[1].courseTitle, 'Object Oriented Programming');
      expect(wednesday[1].room, 'ICT / 505');

      expect(wednesday[2].startTime, '10:00');
      expect(wednesday[2].endTime, '10:50');
      expect(wednesday[2].courseCode, 'MATH2561');
      expect(wednesday[2].courseTitle, 'Probability and Statistics For Engineering');
      expect(wednesday[2].room, 'ICT / 218');

      expect(wednesday[3].startTime, '11:00');
      expect(wednesday[3].endTime, '11:50');
      expect(wednesday[3].courseCode, '24CSEN2021');
      expect(wednesday[3].courseTitle, 'Computer Organization and Architecture');
      expect(wednesday[3].room, 'ICT / 505');

      expect(wednesday[4].startTime, '13:00');
      expect(wednesday[4].endTime, '13:50');
      expect(wednesday[4].courseCode, 'EECE2191');
      expect(wednesday[4].courseTitle, 'Fundamentals of Autonomous Vehicles');
      expect(wednesday[4].room, 'ICT / 424');
    });

    test('Thursday has exactly 5 sessions with exact courses, times, and rooms', () {
      final thursday = TimetableData.getSessionsForDay(4);
      expect(thursday.length, 5);

      expect(thursday[0].startTime, '08:00');
      expect(thursday[0].endTime, '08:50');
      expect(thursday[0].courseCode, '24CSEN2001P');
      expect(thursday[0].courseTitle, 'Data Structures Lab');
      expect(thursday[0].room, 'ICT / 220');

      expect(thursday[1].startTime, '09:00');
      expect(thursday[1].endTime, '09:50');
      expect(thursday[1].courseCode, '24CSEN2001P');
      expect(thursday[1].courseTitle, 'Data Structures Lab');
      expect(thursday[1].room, 'ICT / 220');

      expect(thursday[2].startTime, '10:00');
      expect(thursday[2].endTime, '10:50');
      expect(thursday[2].courseCode, 'GCGC1001');
      expect(thursday[2].courseTitle, 'Aptitude and Self-Management Skills');
      expect(thursday[2].room, 'ICT / 617');

      expect(thursday[3].startTime, '11:00');
      expect(thursday[3].endTime, '11:50');
      expect(thursday[3].courseCode, 'GCGC1001');
      expect(thursday[3].courseTitle, 'Aptitude and Self-Management Skills');
      expect(thursday[3].room, 'ICT / 617');

      expect(thursday[4].startTime, '14:00');
      expect(thursday[4].endTime, '14:50');
      expect(thursday[4].courseCode, '24CSEN2021');
      expect(thursday[4].courseTitle, 'Computer Organization and Architecture');
      expect(thursday[4].room, 'ICT / 505');
    });

    test('Friday has exactly 3 sessions with exact courses, times, and rooms', () {
      final friday = TimetableData.getSessionsForDay(5);
      expect(friday.length, 3);

      expect(friday[0].startTime, '09:00');
      expect(friday[0].endTime, '09:50');
      expect(friday[0].courseCode, 'MATH2561');
      expect(friday[0].courseTitle, 'Probability and Statistics For Engineering');
      expect(friday[0].room, 'ICT / 6032');

      expect(friday[1].startTime, '10:00');
      expect(friday[1].endTime, '10:50');
      expect(friday[1].courseCode, '24CSEN2001');
      expect(friday[1].courseTitle, 'Data Structures');
      expect(friday[1].room, 'ICT / 617');

      expect(friday[2].startTime, '11:00');
      expect(friday[2].endTime, '11:50');
      expect(friday[2].courseCode, '24CSEN1011');
      expect(friday[2].courseTitle, 'Object Oriented Programming');
      expect(friday[2].room, 'ICT / 505');
    });

    test('Saturday has no classes scheduled', () {
      final saturday = TimetableData.getSessionsForDay(6);
      expect(saturday, isEmpty);
    });

    test('MATH2561 room varies correctly across days', () {
      final monMath = TimetableData.getSessionsForDay(1).firstWhere((s) => s.courseCode == 'MATH2561');
      final tueMath = TimetableData.getSessionsForDay(2).firstWhere((s) => s.courseCode == 'MATH2561');
      final wedMath = TimetableData.getSessionsForDay(3).firstWhere((s) => s.courseCode == 'MATH2561');
      final friMath = TimetableData.getSessionsForDay(5).firstWhere((s) => s.courseCode == 'MATH2561');

      expect(monMath.room, 'ICT / 218');
      expect(tueMath.room, 'ICT / 6032');
      expect(wedMath.room, 'ICT / 218');
      expect(friMath.room, 'ICT / 6032');
    });
  });

  group('Now/Next Calculation Tests with Injectable Clock', () {
    // 2026-09-21 is a Monday (weekday = 1)
    final monday = DateTime(2026, 9, 21);

    test('before first class on class day returns NEXT with first class', () {
      // Monday at 07:30
      final service = TimetableService(
        clock: () => DateTime(monday.year, monday.month, monday.day, 7, 30),
      );
      final result = service.getNowNext();

      expect(result.status, NowNextStatus.next);
      expect(result.statusHeader, 'NEXT CLASS');
      expect(result.currentSession, isNull);
      expect(result.nextSession, isNotNull);
      expect(result.nextSession!.courseTitle, 'Object Oriented Programming');
      expect(result.nextSession!.startTime, '08:00');
      expect(result.nextSession!.room, 'ICT / 505');
      expect(result.nextTransitionTime, DateTime(monday.year, monday.month, monday.day, 8, 0));
    });

    test('during class returns NOW with current class and upcoming next class', () {
      // Monday at 08:20
      final service = TimetableService(
        clock: () => DateTime(monday.year, monday.month, monday.day, 8, 20),
      );
      final result = service.getNowNext();

      expect(result.status, NowNextStatus.now);
      expect(result.statusHeader, 'NOW');
      expect(result.currentSession, isNotNull);
      expect(result.currentSession!.courseTitle, 'Object Oriented Programming');
      expect(result.currentSession!.courseCode, '24CSEN1011');
      expect(result.currentSession!.room, 'ICT / 505');

      expect(result.nextSession, isNotNull);
      expect(result.nextSession!.courseTitle, 'Computer Organization and Architecture');
      expect(result.nextSession!.startTime, '09:00');

      // Next transition is class end time: 08:50
      expect(result.nextTransitionTime, DateTime(monday.year, monday.month, monday.day, 8, 50));
    });

    test('exactly at class end time (08:50), class is finished and status is NEXT', () {
      // Monday at 08:50:00
      final service = TimetableService(
        clock: () => DateTime(monday.year, monday.month, monday.day, 8, 50),
      );
      final result = service.getNowNext();

      expect(result.status, NowNextStatus.next);
      expect(result.statusHeader, 'NEXT CLASS');
      expect(result.currentSession, isNull);
      expect(result.nextSession!.startTime, '09:00');
      expect(result.nextSession!.courseTitle, 'Computer Organization and Architecture');
      expect(result.nextTransitionTime, DateTime(monday.year, monday.month, monday.day, 9, 0));
    });

    test('exactly at next class start time (09:00), class becomes CURRENT', () {
      // Monday at 09:00:00
      final service = TimetableService(
        clock: () => DateTime(monday.year, monday.month, monday.day, 9, 0),
      );
      final result = service.getNowNext();

      expect(result.status, NowNextStatus.now);
      expect(result.statusHeader, 'NOW');
      expect(result.currentSession!.courseTitle, 'Computer Organization and Architecture');
      expect(result.currentSession!.startTime, '09:00');
      expect(result.nextTransitionTime, DateTime(monday.year, monday.month, monday.day, 9, 50));
    });

    test('between classes during lunch (12:15) returns NEXT at 13:00', () {
      // Monday at 12:15
      final service = TimetableService(
        clock: () => DateTime(monday.year, monday.month, monday.day, 12, 15),
      );
      final result = service.getNowNext();

      expect(result.status, NowNextStatus.next);
      expect(result.nextSession!.startTime, '13:00');
      expect(result.nextSession!.courseTitle, 'Fundamentals of Autonomous Vehicles');
      expect(result.nextSession!.room, 'ICT / 424');
      expect(result.nextTransitionTime, DateTime(monday.year, monday.month, monday.day, 13, 0));
    });

    test('after final class on Monday (14:30) returns CLASSES FINISHED with Tuesday first class', () {
      // Monday at 14:30
      final service = TimetableService(
        clock: () => DateTime(monday.year, monday.month, monday.day, 14, 30),
      );
      final result = service.getNowNext();

      expect(result.status, NowNextStatus.classesFinishedToday);
      expect(result.statusHeader, "TODAY'S CLASSES FINISHED");
      expect(result.currentSession, isNull);
      expect(result.nextSession, isNotNull);
      expect(result.nextSession!.courseCode, '24CSEN1011P');
      expect(result.nextSession!.courseTitle, 'Object Oriented Programming Lab');
      expect(result.nextSessionDayName, 'Tuesday');
    });

    test('on Saturday returns NO CLASSES TODAY with Monday first class', () {
      // 2026-09-26 is a Saturday (weekday = 6)
      final saturday = DateTime(2026, 9, 26, 11, 0);
      final service = TimetableService(clock: () => saturday);
      final result = service.getNowNext();

      expect(result.status, NowNextStatus.noClassesToday);
      expect(result.statusHeader, 'NO CLASSES TODAY');
      expect(result.nextSession, isNotNull);
      expect(result.nextSession!.courseTitle, 'Object Oriented Programming');
      expect(result.nextSessionDayName, 'Monday');
      expect(result.nextSession!.room, 'ICT / 505');
    });

    test('on Sunday returns NO CLASSES TODAY with Monday first class', () {
      // 2026-09-27 is a Sunday (weekday = 7)
      final sunday = DateTime(2026, 9, 27, 18, 0);
      final service = TimetableService(clock: () => sunday);
      final result = service.getNowNext();

      expect(result.status, NowNextStatus.noClassesToday);
      expect(result.statusHeader, 'NO CLASSES TODAY');
      expect(result.nextSession!.courseTitle, 'Object Oriented Programming');
      expect(result.nextSessionDayName, 'Monday');
    });
  });
}
