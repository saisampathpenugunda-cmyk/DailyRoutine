import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/routine_timer_controller.dart';
import '../models/activity.dart';
import '../repositories/activity_repository.dart';

class MeditationScreen extends StatefulWidget {
  final Activity activity;
  final ActivityRepository repository;

  const MeditationScreen({
    super.key,
    required this.activity,
    required this.repository,
  });

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  late final RoutineTimerController _timer;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _timer = RoutineTimerController(
      totalDuration: widget.activity.defaultDuration,
    );
    _timer.addListener(_onTimerChange);
  }

  void _onTimerChange() {
    if (mounted) setState(() {});
  }

  // Starts the periodic 1-second ticker that drives the UI.
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final completed = _timer.tick();
      if (completed) {
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

  void _handleSkip() {
    _ticker?.cancel();
    widget.repository.setActivitySkipped(
      widget.activity.id,
      isSkipped: true,
    );
    Navigator.of(context).pop();
  }

  void _markCompleted() {
    widget.repository.setActivityCompletion(
      widget.activity.id,
      isCompleted: true,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _timer.removeListener(_onTimerChange);
    _timer.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.name),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Top card: activity info ──────────────────────────────
              _ActivityInfoCard(
                activity: widget.activity,
                colorScheme: colorScheme,
                theme: theme,
              ),

              // ── Timer display ────────────────────────────────────────
              _TimerDisplay(
                timer: _timer,
                colorScheme: colorScheme,
                theme: theme,
              ),

              // ── Controls ─────────────────────────────────────────────
              _Controls(
                timerState: _timer.state,
                onStart: _handleStart,
                onPause: _handlePause,
                onResume: _handleResume,
                onFinish: _handleFinish,
                onDone: () => Navigator.of(context).pop(),
                onSkip: _handleSkip,
                colorScheme: colorScheme,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ActivityInfoCard extends StatelessWidget {
  final Activity activity;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _ActivityInfoCard({
    required this.activity,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.self_improvement,
                size: 28,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 15, color: colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      'Default: ${activity.formattedDuration}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
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
}

class _TimerDisplay extends StatelessWidget {
  final RoutineTimerController timer;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _TimerDisplay({
    required this.timer,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = timer.isCompleted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular progress ring
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: isCompleted ? 0.0 : timer.progress,
                  strokeWidth: 10,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.green : colorScheme.primary,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCompleted)
                    Icon(Icons.check_circle, size: 48, color: Colors.green)
                  else
                    Text(
                      timer.formattedTime,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: colorScheme.onSurface,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted ? 'Completed!' : _stateLabel(timer.state),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isCompleted ? Colors.green : colorScheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
}

class _Controls extends StatelessWidget {
  final TimerState timerState;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;
  final VoidCallback onDone;
  final VoidCallback onSkip;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _Controls({
    required this.timerState,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
    required this.onDone,
    required this.onSkip,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    Widget mainControls;
    switch (timerState) {
      case TimerState.initial:
        mainControls = _bigButton(
          key: const Key('start_button'),
          label: 'Start',
          icon: Icons.play_arrow_rounded,
          onPressed: onStart,
          color: colorScheme.primary,
          foreground: colorScheme.onPrimary,
        );
        break;

      case TimerState.running:
        mainControls = Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('pause_button'),
                onPressed: onPause,
                icon: const Icon(Icons.pause_rounded),
                label: const Text('Pause'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                key: const Key('finish_button'),
                onPressed: onFinish,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Finish'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        );
        break;

      case TimerState.paused:
        mainControls = Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const Key('resume_button'),
                onPressed: onResume,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Resume'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('finish_early_button'),
                onPressed: onFinish,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Finish'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        );
        break;

      case TimerState.completed:
        mainControls = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.green, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Meditation completed for today!',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _bigButton(
              key: const Key('done_button'),
              label: 'Done',
              icon: Icons.arrow_back_rounded,
              onPressed: onDone,
              color: colorScheme.primary,
              foreground: colorScheme.onPrimary,
            ),
          ],
        );
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mainControls,
        if (timerState != TimerState.completed) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                "Can't do today",
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _bigButton({
    required Key key,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required Color foreground,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: key,
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
