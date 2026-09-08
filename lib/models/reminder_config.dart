class ReminderConfig {
  final String activityId;
  final bool isMainEnabled;
  final int mainHour;
  final int mainMinute;
  final bool isBackupEnabled;
  final int backupHour;
  final int backupMinute;

  const ReminderConfig({
    required this.activityId,
    this.isMainEnabled = true,
    required this.mainHour,
    required this.mainMinute,
    this.isBackupEnabled = false,
    required this.backupHour,
    required this.backupMinute,
  });

  /// Factory producing default reminder configurations per activity.
  factory ReminderConfig.defaultFor(String activityId) {
    switch (activityId) {
      case 'meditation':
        return const ReminderConfig(
          activityId: 'meditation',
          isMainEnabled: true,
          mainHour: 8,
          mainMinute: 0,
          isBackupEnabled: false,
          backupHour: 8,
          backupMinute: 30,
        );
      case 'walking':
        return const ReminderConfig(
          activityId: 'walking',
          isMainEnabled: true,
          mainHour: 17,
          mainMinute: 0,
          isBackupEnabled: false,
          backupHour: 17,
          backupMinute: 30,
        );
      case 'dumbbells':
        return const ReminderConfig(
          activityId: 'dumbbells',
          isMainEnabled: true,
          mainHour: 19,
          mainMinute: 0,
          isBackupEnabled: false,
          backupHour: 19,
          backupMinute: 30,
        );
      default:
        return ReminderConfig(
          activityId: activityId,
          isMainEnabled: true,
          mainHour: 9,
          mainMinute: 0,
          isBackupEnabled: false,
          backupHour: 9,
          backupMinute: 30,
        );
    }
  }

  int get mainNotificationId {
    switch (activityId) {
      case 'meditation':
        return 101;
      case 'walking':
        return 201;
      case 'dumbbells':
        return 301;
      default:
        return 401;
    }
  }

  int get backupNotificationId {
    switch (activityId) {
      case 'meditation':
        return 102;
      case 'walking':
        return 202;
      case 'dumbbells':
        return 302;
      default:
        return 402;
    }
  }

  static String formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  String get formattedMainTime => formatTime(mainHour, mainMinute);
  String get formattedBackupTime => formatTime(backupHour, backupMinute);

  ReminderConfig copyWith({
    String? activityId,
    bool? isMainEnabled,
    int? mainHour,
    int? mainMinute,
    bool? isBackupEnabled,
    int? backupHour,
    int? backupMinute,
  }) {
    return ReminderConfig(
      activityId: activityId ?? this.activityId,
      isMainEnabled: isMainEnabled ?? this.isMainEnabled,
      mainHour: mainHour ?? this.mainHour,
      mainMinute: mainMinute ?? this.mainMinute,
      isBackupEnabled: isBackupEnabled ?? this.isBackupEnabled,
      backupHour: backupHour ?? this.backupHour,
      backupMinute: backupMinute ?? this.backupMinute,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activityId': activityId,
      'isMainEnabled': isMainEnabled,
      'mainHour': mainHour,
      'mainMinute': mainMinute,
      'isBackupEnabled': isBackupEnabled,
      'backupHour': backupHour,
      'backupMinute': backupMinute,
    };
  }

  factory ReminderConfig.fromJson(Map<String, dynamic> json) {
    final activityId = json['activityId'] as String? ?? 'general';
    final defaults = ReminderConfig.defaultFor(activityId);

    return ReminderConfig(
      activityId: activityId,
      isMainEnabled: json['isMainEnabled'] as bool? ?? defaults.isMainEnabled,
      mainHour: json['mainHour'] as int? ?? defaults.mainHour,
      mainMinute: json['mainMinute'] as int? ?? defaults.mainMinute,
      isBackupEnabled: json['isBackupEnabled'] as bool? ?? defaults.isBackupEnabled,
      backupHour: json['backupHour'] as int? ?? defaults.backupHour,
      backupMinute: json['backupMinute'] as int? ?? defaults.backupMinute,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderConfig &&
          runtimeType == other.runtimeType &&
          activityId == other.activityId &&
          isMainEnabled == other.isMainEnabled &&
          mainHour == other.mainHour &&
          mainMinute == other.mainMinute &&
          isBackupEnabled == other.isBackupEnabled &&
          backupHour == other.backupHour &&
          backupMinute == other.backupMinute;

  @override
  int get hashCode =>
      activityId.hashCode ^
      isMainEnabled.hashCode ^
      mainHour.hashCode ^
      mainMinute.hashCode ^
      isBackupEnabled.hashCode ^
      backupHour.hashCode ^
      backupMinute.hashCode;
}
