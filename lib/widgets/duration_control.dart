import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Interactive duration control widget displaying:
/// Duration
/// [ 15 min 00 sec ]   ✎
///
/// Tapping it opens an attractive bottom sheet with Minutes and Seconds steppers.
class DurationControl extends StatelessWidget {
  final Duration duration;
  final ValueChanged<Duration> onDurationChanged;
  final bool enabled;

  const DurationControl({
    super.key,
    required this.duration,
    required this.onDurationChanged,
    this.enabled = true,
  });

  static String formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes min ${seconds.toString().padLeft(2, '0')} sec';
  }

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) return;

    final result = await showModalBottomSheet<Duration>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DurationPickerSheet(initialDuration: duration),
    );

    if (result != null && result != duration) {
      onDurationChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Duration',
          style: textTheme.labelMedium?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          key: const Key('duration_control_button'),
          onTap: enabled ? () => _openPicker(context) : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colors.border,
                width: AppTheme.borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  formatDuration(duration),
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textMain,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: colors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Attractive bottom sheet picker for Minutes and Seconds with steppers.
class DurationPickerSheet extends StatefulWidget {
  final Duration initialDuration;

  const DurationPickerSheet({
    super.key,
    required this.initialDuration,
  });

  @override
  State<DurationPickerSheet> createState() => _DurationPickerSheetState();
}

class _DurationPickerSheetState extends State<DurationPickerSheet> {
  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialDuration.inMinutes.clamp(0, 180);
    _seconds = (widget.initialDuration.inSeconds % 60).clamp(0, 59);
    if (_minutes == 0 && _seconds == 0) {
      _minutes = 1;
    }
  }

  void _save() {
    final totalSeconds = _minutes * 60 + _seconds;
    if (totalSeconds <= 0) return;
    Navigator.of(context).pop(Duration(minutes: _minutes, seconds: _seconds));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final isValid = (_minutes * 60 + _seconds) > 0;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: colors.border, width: AppTheme.borderWidth),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Set Duration',
            style: textTheme.titleMedium?.copyWith(
              color: colors.textMain,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Adjust target duration for this activity',
            style: textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          // Stepper columns: Minutes and Seconds
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStepperColumn(
                label: 'Minutes',
                value: _minutes,
                onDecrement: _minutes > 0 ? () => setState(() => _minutes--) : null,
                onIncrement: _minutes < 180 ? () => setState(() => _minutes++) : null,
                decKey: 'decrement_minutes_button',
                incKey: 'increment_minutes_button',
                valKey: 'minutes_value_text',
              ),
              Container(
                height: 60,
                width: 1,
                color: colors.border,
              ),
              _buildStepperColumn(
                label: 'Seconds',
                value: _seconds,
                isTwoDigits: true,
                onDecrement: _seconds > 0 ? () => setState(() => _seconds--) : null,
                onIncrement: _seconds < 59 ? () => setState(() => _seconds++) : null,
                decKey: 'decrement_seconds_button',
                incKey: 'increment_seconds_button',
                valKey: 'seconds_value_text',
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Action buttons: Cancel and Save
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('duration_picker_cancel_button'),
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  key: const Key('duration_picker_save_button'),
                  onPressed: isValid ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isValid ? colors.background : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperColumn({
    required String label,
    required int value,
    required VoidCallback? onDecrement,
    required VoidCallback? onIncrement,
    required String decKey,
    required String incKey,
    required String valKey,
    bool isTwoDigits = false,
  }) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStepperButton(
              key: Key(decKey),
              icon: Icons.remove_rounded,
              onPressed: onDecrement,
            ),
            Container(
              width: 56,
              alignment: Alignment.center,
              child: Text(
                isTwoDigits ? value.toString().padLeft(2, '0') : value.toString(),
                key: Key(valKey),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textMain,
                ),
              ),
            ),
            _buildStepperButton(
              key: Key(incKey),
              icon: Icons.add_rounded,
              onPressed: onIncrement,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepperButton({
    required Key key,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final colors = context.appColors;
    final isEnabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isEnabled ? colors.card : colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isEnabled ? colors.border : colors.border.withValues(alpha: 0.4),
              width: AppTheme.borderWidth,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isEnabled ? colors.textMain : colors.textSecondary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
