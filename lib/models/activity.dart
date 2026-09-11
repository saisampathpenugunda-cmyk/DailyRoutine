import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum ActivityType {
  meditation,
  walking,
  dumbbells,
  study,
  guitar,
  reading,
  general,
  timer,
  workout;

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
      case ActivityType.timer:
        return 'Timer';
      case ActivityType.workout:
        return 'Workout';
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityType.meditation:
        return Icons.self_improvement;
      case ActivityType.walking:
        return Icons.directions_walk;
      case ActivityType.dumbbells:
        return Icons.fitness_center;
      case ActivityType.study:
        return Icons.school;
      case ActivityType.guitar:
        return Icons.music_note;
      case ActivityType.reading:
        return Icons.menu_book;
      case ActivityType.general:
        return Icons.star_outline;
      case ActivityType.timer:
        return Icons.timer_outlined;
      case ActivityType.workout:
        return Icons.fitness_center;
    }
  }
}

enum ActivityRecordStatus {
  completed,
  partial,
  skipped,
  missed,
  pending,
  disabled;

  String get displayName {
    switch (this) {
      case ActivityRecordStatus.completed:
        return 'Completed';
      case ActivityRecordStatus.partial:
        return 'Partial';
      case ActivityRecordStatus.skipped:
        return 'Skipped';
      case ActivityRecordStatus.missed:
        return 'Missed';
      case ActivityRecordStatus.pending:
        return 'Pending';
      case ActivityRecordStatus.disabled:
        return 'Disabled';
    }
  }
}

class Activity {
  final String id;
  final String name;
  final ActivityType activityType;
  final Duration defaultDuration;
  final Duration actualDuration;
  final bool isEnabled;
  final bool isCompleted;
  final bool isSkipped;
  final List<int> completedSetsReps;

  const Activity({
    required this.id,
    required this.name,
    required this.activityType,
    required this.defaultDuration,
    this.actualDuration = Duration.zero,
    this.isEnabled = true,
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

  String get formattedActualDuration {
    if (actualDuration == Duration.zero) return '0 min';
    final minutes = actualDuration.inMinutes;
    final seconds = actualDuration.inSeconds % 60;
    if (minutes > 0 && seconds == 0) {
      return '$minutes min';
    }
    if (minutes == 0) {
      return '$seconds sec';
    }
    return '$minutes min $seconds sec';
  }

  ActivityRecordStatus get status {
    if (!isEnabled) return ActivityRecordStatus.disabled;
    if (isCompleted) return ActivityRecordStatus.completed;
    if (isSkipped) return ActivityRecordStatus.skipped;
    if (actualDuration > Duration.zero) return ActivityRecordStatus.partial;
    return ActivityRecordStatus.pending;
  }

  bool get isBuiltIn =>
      id == 'meditation' ||
      id == 'walking' ||
      id == 'dumbbells' ||
      id == 'guitar';

  bool get isWorkout => activityType == ActivityType.workout || activityType == ActivityType.dumbbells;

  String get typeLabel => isWorkout ? 'Workout' : 'Timer';

  Activity copyWith({
    String? id,
    String? name,
    ActivityType? activityType,
    Duration? defaultDuration,
    Duration? actualDuration,
    bool? isEnabled,
    bool? isCompleted,
    bool? isSkipped,
    List<int>? completedSetsReps,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      activityType: activityType ?? this.activityType,
      defaultDuration: defaultDuration ?? this.defaultDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      isEnabled: isEnabled ?? this.isEnabled,
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
      'actualDurationSeconds': actualDuration.inSeconds,
      'isEnabled': isEnabled,
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

    final actualSec = (json['actualDurationSeconds'] as num?)?.toInt() ?? 0;
    final actualDuration = Duration(seconds: actualSec < 0 ? 0 : actualSec);
    final isEnabled = json['isEnabled'] != false;

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
      actualDuration: actualDuration,
      isEnabled: isEnabled,
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
        other.actualDuration == actualDuration &&
        other.isEnabled == isEnabled &&
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
        actualDuration,
        isEnabled,
        isCompleted,
        isSkipped,
        Object.hashAll(completedSetsReps),
      );
}
