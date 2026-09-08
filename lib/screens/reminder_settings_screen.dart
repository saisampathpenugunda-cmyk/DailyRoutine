import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../models/reminder_config.dart';
import '../repositories/activity_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class ReminderSettingsScreen extends StatefulWidget {
  final ActivityRepository repository;
  final NotificationService? notificationService;

  const ReminderSettingsScreen({
    super.key,
    required this.repository,
    this.notificationService,
  });

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  late List<ReminderConfig> _configs;
  late List<Activity> _activities;

  @override
  void initState() {
    super.initState();
    _loadData();
    _requestPermissionsIfNeeded();
  }

  void _loadData() {
    setState(() {
      _activities = widget.repository.getActivities();
      _configs = widget.repository.getReminderConfigs();
    });
  }

  Future<void> _requestPermissionsIfNeeded() async {
    await widget.notificationService?.requestPermissions();
  }

  Future<void> _pickTime({
    required BuildContext context,
    required int initialHour,
    required int initialMinute,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme.copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      onPicked(picked);
    }
  }

  void _updateConfig(ReminderConfig config) {
    widget.repository.updateReminderConfig(config);
    _loadData();
  }

  IconData _getIconForActivity(String activityId) {
    switch (activityId) {
      case 'meditation':
        return Icons.self_improvement;
      case 'walking':
        return Icons.directions_walk;
      case 'dumbbells':
        return Icons.fitness_center;
      default:
        return Icons.task_alt;
    }
  }

  String _getDisplayName(String activityId) {
    switch (activityId) {
      case 'meditation':
        return 'Meditation';
      case 'walking':
        return 'Walking';
      case 'dumbbells':
        return 'Dumbbells';
      default:
        return activityId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reminders',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: AppTheme.cobaltBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppTheme.cobaltBlue.withValues(alpha: 0.25),
                width: AppTheme.borderWidth,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: AppTheme.cobaltBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Reminders trigger even when the app is closed. Completing or skipping an activity automatically cancels today’s remaining alerts.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.slate700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._configs.map((config) {
            final activity = _activities.cast<Activity?>().firstWhere(
                  (a) => a?.id == config.activityId,
                  orElse: () => null,
                );

            return _ReminderCard(
              config: config,
              activity: activity,
              icon: _getIconForActivity(config.activityId),
              displayName: _getDisplayName(config.activityId),
              onPickMainTime: () => _pickTime(
                context: context,
                initialHour: config.mainHour,
                initialMinute: config.mainMinute,
                onPicked: (picked) {
                  _updateConfig(
                    config.copyWith(
                      mainHour: picked.hour,
                      mainMinute: picked.minute,
                    ),
                  );
                },
              ),
              onToggleMain: (enabled) {
                _updateConfig(config.copyWith(isMainEnabled: enabled));
              },
              onPickBackupTime: () => _pickTime(
                context: context,
                initialHour: config.backupHour,
                initialMinute: config.backupMinute,
                onPicked: (picked) {
                  _updateConfig(
                    config.copyWith(
                      backupHour: picked.hour,
                      backupMinute: picked.minute,
                    ),
                  );
                },
              ),
              onToggleBackup: (enabled) {
                _updateConfig(config.copyWith(isBackupEnabled: enabled));
              },
            );
          }),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderConfig config;
  final Activity? activity;
  final IconData icon;
  final String displayName;
  final VoidCallback onPickMainTime;
  final ValueChanged<bool> onToggleMain;
  final VoidCallback onPickBackupTime;
  final ValueChanged<bool> onToggleBackup;

  const _ReminderCard({
    required this.config,
    required this.activity,
    required this.icon,
    required this.displayName,
    required this.onPickMainTime,
    required this.onToggleMain,
    required this.onPickBackupTime,
    required this.onToggleBackup,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = activity?.isCompleted ?? false;
    final isSkipped = activity?.isSkipped ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.slate200,
          width: AppTheme.borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.cobaltBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: AppTheme.cobaltBlue.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: AppTheme.cobaltBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.slate900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _buildStatusHint(isCompleted, isSkipped),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppTheme.slate200, height: 1),
            const SizedBox(height: 12),

            // Main Reminder Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.alarm, size: 18, color: AppTheme.slate700),
                    const SizedBox(width: 8),
                    const Text(
                      'Main Reminder',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.slate900,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      onTap: config.isMainEnabled ? onPickMainTime : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: config.isMainEnabled ? AppTheme.slate100 : AppTheme.slate50,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          border: Border.all(
                            color: config.isMainEnabled ? AppTheme.slate300 : AppTheme.slate200,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          config.formattedMainTime,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: config.isMainEnabled ? AppTheme.slate900 : AppTheme.slate400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: config.isMainEnabled,
                      activeThumbColor: AppTheme.cobaltBlue,
                      onChanged: onToggleMain,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Backup Reminder Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_alert_outlined, size: 18, color: AppTheme.slate700),
                    const SizedBox(width: 8),
                    const Text(
                      'Backup Reminder',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.slate900,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (config.isBackupEnabled) ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        onTap: onPickBackupTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.slate100,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                              color: AppTheme.slate300,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            config.formattedBackupTime,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.slate900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Switch(
                      value: config.isBackupEnabled,
                      activeThumbColor: AppTheme.cobaltBlue,
                      onChanged: onToggleBackup,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHint(bool isCompleted, bool isSkipped) {
    if (isCompleted) {
      return const Text(
        "Today's alerts cancelled (completed)",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.emeraldGreen,
        ),
      );
    }
    if (isSkipped) {
      return const Text(
        "Today's alerts cancelled (skipped)",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.crimsonRed,
        ),
      );
    }
    if (!config.isMainEnabled && !config.isBackupEnabled) {
      return const Text(
        'Reminders disabled',
        style: TextStyle(fontSize: 12, color: AppTheme.slate400),
      );
    }
    return Text(
      'Next alert: Today at ${config.formattedMainTime}',
      style: const TextStyle(fontSize: 12, color: AppTheme.slate500),
    );
  }
}
