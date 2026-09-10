import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../models/reminder_config.dart';
import '../repositories/activity_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/duration_control.dart';

class EditActivityScreen extends StatefulWidget {
  final Activity activity;
  final ActivityRepository repository;
  final NotificationService? notificationService;

  const EditActivityScreen({
    super.key,
    required this.activity,
    required this.repository,
    this.notificationService,
  });

  @override
  State<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends State<EditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late ActivityType _selectedType;
  late Duration _duration;
  late bool _isEnabled;
  TimeOfDay? _mainReminderTime;
  TimeOfDay? _backupReminderTime;
  late bool _inProgress;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.activity.name);
    _selectedType = widget.activity.isWorkout ? ActivityType.workout : ActivityType.timer;
    _duration = widget.activity.defaultDuration;
    _isEnabled = widget.activity.isEnabled;
    _inProgress = widget.repository.isActivityInProgress(widget.activity.id);

    final config = widget.repository.getReminderConfig(widget.activity.id);
    if (config.isMainEnabled) {
      _mainReminderTime = TimeOfDay(hour: config.mainHour, minute: config.mainMinute);
    }
    if (config.isBackupEnabled) {
      _backupReminderTime = TimeOfDay(hour: config.backupHour, minute: config.backupMinute);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({
    required TimeOfDay? current,
    required ValueChanged<TimeOfDay?> onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_duration <= Duration.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Duration must be greater than 0 seconds.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Preserve underlying specific built-in engine type if built-in
    ActivityType finalType;
    if (widget.activity.isBuiltIn) {
      if (_selectedType == ActivityType.workout) {
        finalType = ActivityType.dumbbells;
      } else {
        finalType = widget.activity.activityType == ActivityType.walking
            ? ActivityType.walking
            : ActivityType.meditation;
      }
    } else {
      finalType = _selectedType;
    }

    final updatedActivity = widget.activity.copyWith(
      name: _nameController.text.trim(),
      activityType: finalType,
      defaultDuration: _duration,
      isEnabled: _isEnabled,
    );

    widget.repository.updateActivity(updatedActivity);

    // Save reminder settings
    final newConfig = ReminderConfig(
      activityId: widget.activity.id,
      isMainEnabled: _mainReminderTime != null,
      mainHour: _mainReminderTime?.hour ?? 9,
      mainMinute: _mainReminderTime?.minute ?? 0,
      isBackupEnabled: _backupReminderTime != null,
      backupHour: _backupReminderTime?.hour ?? 9,
      backupMinute: _backupReminderTime?.minute ?? 30,
    );
    widget.repository.updateReminderConfig(newConfig);

    Navigator.of(context).pop(true);
  }

  Future<void> _handleDelete() async {
    if (widget.repository.isActivityInProgress(widget.activity.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete an activity with an active or paused session. Please finish or reset the session first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.appColors;
        final errorColor = Theme.of(dialogContext).colorScheme.error;
        return AlertDialog(
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            side: BorderSide(color: colors.border, width: 1),
          ),
          title: Text(
            'Delete Activity?',
            style: TextStyle(
              color: colors.textMain,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete ${widget.activity.name}?',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              key: const Key('dialog_cancel_button'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            FilledButton(
              key: const Key('dialog_confirm_delete_button'),
              style: FilledButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final success = widget.repository.deleteActivity(widget.activity.id);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor = Theme.of(context).colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Activity',
          style: TextStyle(
            color: colors.textMain,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          key: const Key('edit_activity_back_button'),
          icon: Icon(Icons.arrow_back, color: colors.textMain),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          TextButton(
            key: const Key('edit_activity_save_button'),
            onPressed: _handleSave,
            child: Text(
              'Save',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Active Session Safety Warning Banner ───────────────────
                if (_inProgress) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C00).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(
                        color: const Color(0xFFFF8C00).withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFFF8C00),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This activity currently has an active or paused session. Type and status are locked. Duration edits will apply to future sessions.',
                            style: TextStyle(
                              color: colors.textMain,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Activity Name ─────────────────────────────────────────
                _SectionLabel(title: 'Activity Name', colors: colors),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('edit_activity_name_input'),
                  controller: _nameController,
                  style: TextStyle(color: colors.textMain, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'e.g. Yoga, Reading, Guitar',
                    hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.7)),
                    filled: true,
                    fillColor: colors.card,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: BorderSide(color: colors.border, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: BorderSide(color: colors.border, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: BorderSide(color: colors.primary, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an activity name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // ── Activity Type ─────────────────────────────────────────
                _SectionLabel(title: 'Activity Type', colors: colors),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: colors.border, width: 1),
                  ),
                  child: Column(
                    children: [
                      _ActivityTypeTile(
                        key: const Key('edit_type_timer'),
                        title: 'Timer',
                        subtitle: 'Timed sessions with countdown',
                        icon: Icons.timer_outlined,
                        isSelected: _selectedType == ActivityType.timer,
                        colors: colors,
                        enabled: !_inProgress,
                        onTap: () {
                          if (_inProgress) return;
                          setState(() => _selectedType = ActivityType.timer);
                        },
                      ),
                      Divider(color: colors.border, height: 1),
                      _ActivityTypeTile(
                        key: const Key('edit_type_workout'),
                        title: 'Workout',
                        subtitle: 'Sets and reps tracking',
                        icon: Icons.fitness_center,
                        isSelected: _selectedType == ActivityType.workout,
                        colors: colors,
                        enabled: !_inProgress,
                        onTap: () {
                          if (_inProgress) return;
                          setState(() => _selectedType = ActivityType.workout);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Duration ──────────────────────────────────────────────
                _SectionLabel(title: 'Duration', colors: colors),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: colors.border, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Duration',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DurationControl.formatDuration(_duration),
                            key: const Key('edit_duration_text'),
                            style: TextStyle(
                              color: colors.textMain,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        key: const Key('edit_duration_button'),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Change'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.primary,
                          side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final picked = await showModalBottomSheet<Duration>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => DurationPickerSheet(
                              initialDuration: _duration,
                            ),
                          );
                          if (picked != null) {
                            setState(() => _duration = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Enabled / Disabled Switch ─────────────────────────────
                _SectionLabel(title: 'Status', colors: colors),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: colors.border, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEnabled ? 'Enabled' : 'Disabled',
                            key: const Key('edit_enabled_label'),
                            style: TextStyle(
                              color: _isEnabled ? colors.textMain : colors.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isEnabled
                                ? 'Appears in Today’s Plan & schedules reminders'
                                : 'Hidden from Today’s Plan & reminders inactive',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 30,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Switch(
                            key: const Key('edit_enabled_switch'),
                            value: _isEnabled,
                            onChanged: _inProgress
                                ? null
                                : (val) {
                                    setState(() => _isEnabled = val);
                                  },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Main Reminder — Optional ──────────────────────────────
                _ReminderPickerTile(
                  key: const Key('edit_main_reminder_tile'),
                  title: 'Main Reminder — Optional',
                  selectedTime: _mainReminderTime,
                  icon: Icons.notifications_active_outlined,
                  colors: colors,
                  onTap: () => _pickTime(
                    current: _mainReminderTime,
                    onPicked: (t) => setState(() => _mainReminderTime = t),
                  ),
                  onClear: () => setState(() => _mainReminderTime = null),
                ),
                const SizedBox(height: 14),

                // ── Backup Reminder — Optional ────────────────────────────
                _ReminderPickerTile(
                  key: const Key('edit_backup_reminder_tile'),
                  title: 'Backup Reminder — Optional',
                  selectedTime: _backupReminderTime,
                  icon: Icons.add_alarm_outlined,
                  colors: colors,
                  onTap: () => _pickTime(
                    current: _backupReminderTime,
                    onPicked: (t) => setState(() => _backupReminderTime = t),
                  ),
                  onClear: () => setState(() => _backupReminderTime = null),
                ),
                const SizedBox(height: 32),

                // ── Save Button ───────────────────────────────────────────
                FilledButton(
                  key: const Key('edit_save_button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: isDark ? colors.background : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  onPressed: _handleSave,
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),

                // ── Delete Button ──────────────────────────────────────────
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const Key('edit_delete_button'),
                  icon: Icon(Icons.delete_outline, color: errorColor, size: 20),
                  label: Text(
                    'Delete Activity',
                    style: TextStyle(
                      color: errorColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: errorColor.withValues(alpha: 0.5), width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  onPressed: _handleDelete,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final AppThemeColors colors;

  const _SectionLabel({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _ActivityTypeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final bool enabled;
  final AppThemeColors colors;
  final VoidCallback onTap;

  const _ActivityTypeTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    this.enabled = true,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.border,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary.withValues(alpha: 0.15)
                      : colors.border.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? colors.primary : colors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? colors.primary : colors.textMain,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderPickerTile extends StatelessWidget {
  final String title;
  final TimeOfDay? selectedTime;
  final IconData icon;
  final AppThemeColors colors;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _ReminderPickerTile({
    super.key,
    required this.title,
    required this.selectedTime,
    required this.icon,
    required this.colors,
    required this.onTap,
    required this.onClear,
  });

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: selectedTime != null
                ? colors.primary.withValues(alpha: 0.15)
                : colors.border.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: selectedTime != null ? colors.primary : colors.textSecondary,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textMain,
          ),
        ),
        subtitle: Text(
          selectedTime != null
              ? _formatTime(selectedTime!)
              : 'No reminder set (tap to add)',
          style: TextStyle(
            fontSize: 13,
            color: selectedTime != null ? colors.primary : colors.textSecondary,
            fontWeight: selectedTime != null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: selectedTime != null
            ? IconButton(
                icon: Icon(Icons.close, color: colors.textSecondary, size: 20),
                tooltip: 'Remove reminder',
                onPressed: onClear,
              )
            : Icon(Icons.chevron_right, color: colors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
