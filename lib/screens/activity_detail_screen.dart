import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/routine_timer_controller.dart';
import '../models/activity.dart';
import '../repositories/activity_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/duration_control.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Activity activity;
  final ActivityRepository repository;
  final RoutineTimerController? timer;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
    required this.repository,
    this.timer,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late Activity _currentActivity;
  late final RoutineTimerController _timer;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _currentActivity = widget.activity;
    _timer = widget.timer ??
        widget.repository.getTimerController(
          widget.activity.id,
          defaultDuration: widget.activity.defaultDuration,
        );
    _timer.addListener(_onTimerChange);

    if (_timer.isRunning) {
      final completed = _timer.tick();
      if (completed) {
        _markCompleted();
      } else {
        _startTicker();
      }
    }
  }

  void _onTimerChange() {
    if (mounted) setState(() {});
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final completed = _timer.tick();
      if (completed || _timer.isCompleted) {
        _markCompleted();
        _ticker?.cancel();
      }
    });
  }

  void _handleStart() {
    _timer.start();
    _startTicker();
  }

  void _handlePause() {
    _ticker?.cancel();
    _timer.pause();
  }

  void _handleResume() {
    _timer.resume();
    _startTicker();
  }

  void _handleFinish() {
    _ticker?.cancel();
    _timer.finish();
    _markCompleted();
  }

  void _markCompleted() {
    widget.repository.setActivityCompletion(
      _currentActivity.id,
      isCompleted: true,
    );
    if (mounted) {
      setState(() {
        _currentActivity = _currentActivity.copyWith(isCompleted: true);
      });
    }
  }

  void _onDurationChanged(Duration newDuration) {
    final updated = _currentActivity.copyWith(defaultDuration: newDuration);
    widget.repository.updateActivity(updated);
    if (mounted) {
      setState(() {
        _currentActivity = updated;
      });
    }
  }

  void _handleToggleEnabled(bool enabled) {
    final success = widget.repository.setActivityEnabled(_currentActivity.id, enabled);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot disable an activity with an active or paused session. Please finish or reset the session first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (mounted) {
      setState(() {
        _currentActivity = _currentActivity.copyWith(isEnabled: enabled);
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _timer.removeListener(_onTimerChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = context.appColors;
    final isCompleted = _timer.isCompleted || _currentActivity.isCompleted;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentActivity.name,
          style: TextStyle(
            color: colors.textMain,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        backgroundColor: colors.background,
        iconTheme: IconThemeData(color: colors.textMain),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentActivity.isEnabled ? 'Enabled' : 'Disabled',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _currentActivity.isEnabled ? colorScheme.primary : colors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 30,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Switch(
                    key: const Key('detail_enable_switch'),
                    value: _currentActivity.isEnabled,
                    onChanged: _handleToggleEnabled,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Activity Info Header ──────────────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCompleted
                        ? colors.completed.withValues(alpha: 0.3)
                        : colors.border,
                    width: AppTheme.borderWidth,
                  ),
                ),
                child: Icon(
                  _currentActivity.activityType.icon,
                  size: 36,
                  color: isCompleted ? colors.completed : colors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _currentActivity.name,
                key: const Key('activity_detail_name'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textMain,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _currentActivity.activityType.displayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // ── Countdown Timer Display (MM:SS) ───────────────────────────
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: isCompleted ? 1.0 : _timer.progress,
                        strokeWidth: 10,
                        backgroundColor: colors.barBackground,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted ? colors.completed : colors.primary,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCompleted)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 52,
                            color: colors.completed,
                          )
                        else
                          Text(
                            _timer.formattedTime,
                            key: const Key('timer_countdown_text'),
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: colors.textMain,
                              fontSize: 44,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          isCompleted ? 'Completed!' : _stateLabel(_timer.state),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isCompleted ? colors.completed : colors.textSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Directly BELOW the timer: Duration Control ────────────────
              DurationControl(
                duration: _currentActivity.defaultDuration,
                onDurationChanged: _onDurationChanged,
              ),
              const SizedBox(height: 36),

              // ── Timer Controls (Start, Pause/Resume, Finish) ───────────────
              _buildTimerControls(colorScheme, colors),
            ],
          ),
        ),
      ),
    );
  }

  String _stateLabel(TimerState state) {
    switch (state) {
      case TimerState.initial:
        return 'Ready';
      case TimerState.running:
        return 'Running';
      case TimerState.paused:
        return 'Paused';
      case TimerState.completed:
        return 'Completed!';
    }
  }

  Widget _buildTimerControls(ColorScheme colorScheme, AppThemeColors colors) {
    if (_timer.isCompleted || _currentActivity.isCompleted) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          key: const Key('done_button'),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Done'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.completed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    switch (_timer.state) {
      case TimerState.initial:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const Key('start_button'),
            onPressed: _handleStart,
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: const Text(
              'Start',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.background,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );

      case TimerState.running:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('pause_button'),
                onPressed: _handlePause,
                icon: const Icon(Icons.pause_rounded),
                label: const Text('Pause'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: colors.border),
                  foregroundColor: colors.textMain,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton.icon(
                key: const Key('finish_button'),
                onPressed: _handleFinish,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Finish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.completed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        );

      case TimerState.paused:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                key: const Key('resume_button'),
                onPressed: _handleResume,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Resume'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton.icon(
                key: const Key('finish_button'),
                onPressed: _handleFinish,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Finish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.completed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        );

      case TimerState.completed:
        return const SizedBox.shrink();
    }
  }
}
