import 'package:flutter/foundation.dart';

enum ActivityType {
  meditation,
  walking,
  dumbbells,
  study,
  guitar,
  reading,
  general;

  String get displayName {
    switch (this) {
      case ActivityType.meditation:
        return 'Meditation';
      case ActivityType.walking:
        return 'Walking';
      case ActivityType.dumbbells:
        return 'Dumbbells';
      case ActivityType.study:
        return 'Study';
      case ActivityType.guitar:
        return 'Guitar';
      case ActivityType.reading:
        return 'Reading';
      case ActivityType.general:
        return 'General';
    }
  }
}

class Activity {
  final String id;
  final String name;
  final ActivityType activityType;
  final Duration defaultDuration;
  final bool isCompleted;
  final bool isSkipped;
  final List<int> completedSetsReps;

  const Activity({
    required this.id,
    required this.name,
    required this.activityType,
    required this.defaultDuration,
    this.isCompleted = false,
    this.isSkipped = false,
    this.completedSetsReps = const [],
  });

  String get formattedDuration {
    final minutes = defaultDuration.inMinutes;
    if (minutes > 0 && defaultDuration.inSeconds % 60 == 0) {
      return '$minutes min';
    }
    final seconds = defaultDuration.inSeconds;
    if (seconds < 60) {
      return '$seconds sec';
    }
    final remSeconds = seconds % 60;
    return '$minutes min $remSeconds sec';
  }

  Activity copyWith({
    String? id,
    String? name,
    ActivityType? activityType,
    Duration? defaultDuration,
    bool? isCompleted,
    bool? isSkipped,
    List<int>? completedSetsReps,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      activityType: activityType ?? this.activityType,
      defaultDuration: defaultDuration ?? this.defaultDuration,
      isCompleted: isCompleted ?? this.isCompleted,
      isSkipped: isSkipped ?? this.isSkipped,
      completedSetsReps: completedSetsReps ?? this.completedSetsReps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'activityType': activityType.name,
      'defaultDurationSeconds': defaultDuration.inSeconds,
      'defaultDurationMinutes': defaultDuration.inMinutes,
      'isCompleted': isCompleted,
      'isSkipped': isSkipped,
      'completedSetsReps': completedSetsReps,
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    Duration duration;
    if (json.containsKey('defaultDurationSeconds')) {
      final seconds = (json['defaultDurationSeconds'] as num?)?.toInt() ?? 0;
      duration = Duration(seconds: seconds < 0 ? 0 : seconds);
    } else {
      final minutes = (json['defaultDurationMinutes'] as num?)?.toInt() ?? 0;
      duration = Duration(minutes: minutes < 0 ? 0 : minutes);
    }

    final rawReps = json['completedSetsReps'];
    final List<int> parsedReps = [];
    if (rawReps is Iterable) {
      for (final item in rawReps) {
        if (item is num) {
          final val = item.toInt();
          if (val > 0) parsedReps.add(val);
        }
      }
    }

    return Activity(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      activityType: ActivityType.values.firstWhere(
        (type) => type.name == json['activityType'],
        orElse: () => ActivityType.general,
      ),
      defaultDuration: duration,
      isCompleted: json['isCompleted'] == true,
      isSkipped: json['isSkipped'] == true,
      completedSetsReps: parsedReps,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Activity &&
        other.id == id &&
        other.name == name &&
        other.activityType == activityType &&
        other.defaultDuration == defaultDuration &&
        other.isCompleted == isCompleted &&
        other.isSkipped == isSkipped &&
        listEquals(other.completedSetsReps, completedSetsReps);
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        activityType,
        defaultDuration,
        isCompleted,
        isSkipped,
        Object.hashAll(completedSetsReps),
      );
}
