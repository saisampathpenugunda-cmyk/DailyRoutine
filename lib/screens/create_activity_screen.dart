import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../models/reminder_config.dart';
import '../repositories/activity_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/duration_control.dart';

class CreateActivityScreen extends StatefulWidget {
  final ActivityRepository repository;

  const CreateActivityScreen({
    super.key,
    required this.repository,
  });

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();

  int _durationSeconds = 0;
  ActivityType _selectedType = ActivityType.timer;
  TimeOfDay? _mainReminderTime;
  TimeOfDay? _backupReminderTime;

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
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

  Future<void> _openDurationPicker() async {
    final currentMinutes = int.tryParse(_durationController.text.trim()) ?? 15;
    final picked = await showModalBottomSheet<Duration>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DurationPickerSheet(
        initialDuration: Duration(
          minutes: currentMinutes.clamp(1, 180),
          seconds: _durationSeconds,
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _durationController.text = '${picked.inMinutes}';
        _durationSeconds = picked.inSeconds % 60;
      });
    }
  }

  void _handleCreate() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final durationMinutes = int.parse(_durationController.text.trim());
    final totalDuration = Duration(minutes: durationMinutes, seconds: _durationSeconds);
    final id = 'activity_${DateTime.now().millisecondsSinceEpoch}';

    final newActivity = Activity(
      id: id,
      name: name,
      activityType: _selectedType,
      defaultDuration: totalDuration,
      isCompleted: false,
      isSkipped: false,
    );

    widget.repository.addActivity(newActivity);

    // If either reminder is selected, configure and update reminders.
    // If no reminder is selected, create without scheduling notifications.
    if (_mainReminderTime != null || _backupReminderTime != null) {
      final config = ReminderConfig(
        activityId: id,
        isMainEnabled: _mainReminderTime != null,
        mainHour: _mainReminderTime?.hour ?? 9,
        mainMinute: _mainReminderTime?.minute ?? 0,
        isBackupEnabled: _backupReminderTime != null,
        backupHour: _backupReminderTime?.hour ?? 9,
        backupMinute: _backupReminderTime?.minute ?? 30,
      );
      widget.repository.updateReminderConfig(config);
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Activity',
          style: TextStyle(
            color: colors.textMain,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textMain),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // ── Activity Name ─────────────────────────────────────────
              _SectionLabel(title: 'Activity Name', colors: colors),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('activity_name_input'),
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
                      key: const Key('activity_type_timer'),
                      title: 'Timer',
                      subtitle: 'Timed sessions with countdown (e.g. Meditation, Study)',
                      icon: Icons.timer_outlined,
                      isSelected: _selectedType == ActivityType.timer,
                      colors: colors,
                      onTap: () => setState(() => _selectedType = ActivityType.timer),
                    ),
                    Divider(color: colors.border, height: 1),
                    _ActivityTypeTile(
                      key: const Key('activity_type_workout'),
                      title: 'Workout',
                      subtitle: 'Sets and reps tracking (e.g. Dumbbells, Calisthenics)',
                      icon: Icons.fitness_center,
                      isSelected: _selectedType == ActivityType.workout,
                      colors: colors,
                      onTap: () => setState(() => _selectedType = ActivityType.workout),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Duration ──────────────────────────────────────────────
              _SectionLabel(title: 'Duration', colors: colors),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('activity_duration_input'),
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: colors.textMain, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'e.g. 15',
                        hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.7)),
                        suffixText: 'minutes',
                        suffixStyle: TextStyle(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
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
                          return 'Duration is required';
                        }
                        final parsed = int.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Please enter a valid duration in minutes';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: IconButton.filledTonal(
                      key: const Key('duration_stepper_picker_button'),
                      icon: const Icon(Icons.schedule_rounded),
                      tooltip: 'Pick Minutes & Seconds',
                      style: IconButton.styleFrom(
                        backgroundColor: colors.card,
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.border, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        padding: const EdgeInsets.all(14),
                      ),
                      onPressed: _openDurationPicker,
                    ),
                  ),
                ],
              ),
              if (_durationSeconds > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    'Extra: +$_durationSeconds seconds',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 28),

              // ── Main Reminder — Optional ──────────────────────────────
              _ReminderPickerTile(
                key: const Key('main_reminder_tile'),
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
              const SizedBox(height: 16),

              // ── Backup Reminder — Optional ────────────────────────────
              _ReminderPickerTile(
                key: const Key('backup_reminder_tile'),
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
              const SizedBox(height: 36),

              // ── Action Buttons ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('cancel_button'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: colors.border, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: FilledButton(
                      key: const Key('create_button'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: isDark ? colors.background : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      onPressed: _handleCreate,
                      child: const Text(
                        'Create',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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

  const _SectionLabel({
    required this.title,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: colors.textMain,
        letterSpacing: -0.2,
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

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedTime != null;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isSelected ? colors.primary.withValues(alpha: 0.5) : colors.border,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.highlight,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border, width: 1),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? colors.primary : colors.secondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSelected
                          ? ReminderConfig.formatTime(selectedTime!.hour, selectedTime!.minute)
                          : 'Tap to select time (Optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? colors.primary : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: colors.textSecondary),
                  tooltip: 'Clear',
                  onPressed: onClear,
                )
              else
                Icon(Icons.chevron_right, size: 20, color: colors.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTypeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final AppThemeColors colors;
  final VoidCallback onTap;

  const _ActivityTypeTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Radio circle indicator
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
            // Leading icon container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.highlight,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border, width: 1),
              ),
              child: Icon(icon, size: 20, color: colors.primary),
            ),
            const SizedBox(width: 14),
            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

