/// Represents a single scheduled class session in the timetable.
class TimetableSession {
  final int day; // 1 = Monday, 2 = Tuesday, ..., 6 = Saturday, 7 = Sunday
  final String startTime; // "HH:mm" e.g. "08:00"
  final String endTime; // "HH:mm" e.g. "08:50"
  final String courseCode; // e.g. "24CSEN1011"
  final String courseTitle; // e.g. "Object Oriented Programming"
  final String room; // e.g. "ICT / 505"

  const TimetableSession({
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.courseCode,
    required this.courseTitle,
    required this.room,
  });

  /// Minutes from midnight for start time (e.g. 08:00 -> 480).
  int get startMinutes => _toMinutes(startTime);

  /// Minutes from midnight for end time (e.g. 08:50 -> 530).
  int get endMinutes => _toMinutes(endTime);

  static int _toMinutes(String timeStr) {
    final parts = timeStr.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return h * 60 + m;
  }

  /// Formatted day name (e.g. "Monday").
  String get dayName {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  /// Formatted short day name (e.g. "Mon").
  String get shortDayName {
    switch (day) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
        'courseCode': courseCode,
        'courseTitle': courseTitle,
        'room': room,
      };

  factory TimetableSession.fromJson(Map<String, dynamic> json) {
    return TimetableSession(
      day: json['day'] is int
          ? json['day']
          : (int.tryParse(json['day']?.toString() ?? '') ?? 1),
      startTime: json['startTime']?.toString() ?? '08:00',
      endTime: json['endTime']?.toString() ?? '08:50',
      courseCode: json['courseCode']?.toString() ?? '',
      courseTitle: json['courseTitle']?.toString() ?? '',
      room: json['room']?.toString() ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableSession &&
          runtimeType == other.runtimeType &&
          day == other.day &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          courseCode == other.courseCode &&
          courseTitle == other.courseTitle &&
          room == other.room;

  @override
  int get hashCode =>
      day.hashCode ^
      startTime.hashCode ^
      endTime.hashCode ^
      courseCode.hashCode ^
      courseTitle.hashCode ^
      room.hashCode;

  @override
  String toString() =>
      '$dayName $startTime-$endTime | $courseCode $courseTitle | $room';
}
