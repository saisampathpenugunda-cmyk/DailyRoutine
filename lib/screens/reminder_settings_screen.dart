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
    final theme = Theme.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
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
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reminders',
          style: TextStyle(
            color: colors.textMain,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: colors.border,
                width: AppTheme.borderWidth,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: colors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reminders trigger even when the app is closed. Completing or skipping an activity automatically cancels today’s remaining alerts.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
    final colors = context.appColors;
    final isCompleted = activity?.isCompleted ?? false;
    final isSkipped = activity?.isSkipped ?? false;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: colors.border,
          width: AppTheme.borderWidth,
        ),
        boxShadow: isDark ? null : AppTheme.lightCardShadow,
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.highlight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.border,
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: colors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _buildStatusHint(colors, isCompleted, isSkipped),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: 10),

            // Main Reminder Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.alarm, size: 17, color: colors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Main Reminder',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textMain,
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
                          color: config.isMainEnabled ? colors.barBackground : colors.card,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          border: Border.all(
                            color: colors.border,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          config.formattedMainTime,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: config.isMainEnabled ? colors.textMain : colors.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: config.isMainEnabled,
                      onChanged: onToggleMain,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Backup Reminder Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_alert_outlined, size: 17, color: colors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Backup Reminder',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textMain,
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
                            color: colors.barBackground,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                              color: colors.border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            config.formattedBackupTime,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.textMain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Switch(
                      value: config.isBackupEnabled,
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

  Widget _buildStatusHint(AppThemeColors colors, bool isCompleted, bool isSkipped) {
    if (activity != null && !activity!.isEnabled) {
      return Text(
        "Activity disabled (reminders inactive)",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.secondary,
        ),
      );
    }
    if (isCompleted) {
      return Text(
        "Today's alerts cancelled (completed)",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.completed,
        ),
      );
    }
    if (isSkipped) {
      return Text(
        "Today's alerts cancelled (skipped)",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.skipped,
        ),
      );
    }
    if (!config.isMainEnabled && !config.isBackupEnabled) {
      return Text(
        'Reminders disabled',
        style: TextStyle(fontSize: 12, color: colors.secondary),
      );
    }
    return Text(
      'Next alert: Today at ${config.formattedMainTime}',
      style: TextStyle(fontSize: 12, color: colors.textSecondary),
    );
  }
}
