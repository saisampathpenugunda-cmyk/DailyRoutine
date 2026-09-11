import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/routine_timer_controller.dart';
import '../controllers/guitar_songs_controller.dart';
import '../models/activity.dart';
import '../repositories/activity_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/duration_control.dart';
import 'songs_screen.dart';

class GuitarScreen extends StatefulWidget {
  final Activity activity;
  final ActivityRepository repository;
  final RoutineTimerController? timer;
  final GuitarSongsController? songsController;

  const GuitarScreen({
    super.key,
    required this.activity,
    required this.repository,
    this.timer,
    this.songsController,
  });

  @override
  State<GuitarScreen> createState() => _GuitarScreenState();
}

class _GuitarScreenState extends State<GuitarScreen> {
  late Activity _activity;
  late final RoutineTimerController _timer;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _activity = widget.activity;
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
      _activity.id,
      isCompleted: true,
    );
    if (mounted) {
      setState(() {
        _activity = _activity.copyWith(isCompleted: true);
      });
    }
  }

  void _onDurationChanged(Duration newDuration) {
    final updated = _activity.copyWith(defaultDuration: newDuration);
    widget.repository.updateActivity(updated);
    _timer.updateDurationIfInitial(newDuration);
    if (mounted) {
      setState(() {
        _activity = updated;
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
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = _activity.isCompleted || _timer.isCompleted;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Guitar',
          style: TextStyle(
            color: colors.textMain,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: colors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textMain),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── 1. Practice Countdown Timer ──────────────────────────────
              const SizedBox(height: 12),
              SizedBox(
                width: 210,
                height: 210,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: isCompleted ? 1.0 : _timer.progress,
                        strokeWidth: 9,
                        backgroundColor: colors.barBackground,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted ? colors.completed : colors.primary,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCompleted) ...[
                          Icon(
                            Icons.check_circle_rounded,
                            size: 46,
                            color: colors.completed,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.completed,
                            ),
                          ),
                        ] else ...[
                          Text(
                            _timer.formattedTime,
                            key: const Key('guitar_timer_text'),
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              color: colors.textMain,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            _timer.isRunning
                                ? 'Practicing'
                                : _timer.isPaused
                                    ? 'Paused'
                                    : 'Practice Time',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 2. Customizable Duration Control ─────────────────────────
              if (_timer.isInitial && !isCompleted) ...[
                DurationControl(
                  duration: _activity.defaultDuration,
                  onDurationChanged: _onDurationChanged,
                ),
                const SizedBox(height: 20),
              ],

              // ── 3. Timer Control Buttons ─────────────────────────────────
              _buildTimerActions(colors),
              const SizedBox(height: 32),

              // ── 4. Songs Section (Directly below timer) ───────────────────
              InkWell(
                key: const Key('guitar_songs_button'),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => SongsScreen(
                        controller: widget.songsController,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18.0,
                    vertical: 16.0,
                  ),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: colors.border,
                      width: AppTheme.borderWidth,
                    ),
                    boxShadow: isDark ? null : AppTheme.lightCardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.highlight,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Icon(
                          Icons.queue_music_rounded,
                          size: 24,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Songs',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colors.textMain,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Saved practice songs & video lessons',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerActions(AppThemeColors colors) {
    if (_activity.isCompleted || _timer.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: colors.completed.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: colors.completed.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, color: colors.completed, size: 20),
            const SizedBox(width: 8),
            Text(
              'Practice Session Done',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.completed,
              ),
            ),
          ],
        ),
      );
    }

    if (_timer.isInitial) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          key: const Key('guitar_start_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            elevation: 0,
          ),
          onPressed: _handleStart,
          icon: const Icon(Icons.play_arrow_rounded, size: 24),
          label: const Text(
            'Start Practice',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    if (_timer.isRunning) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                key: const Key('guitar_pause_button'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.border, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                onPressed: _handlePause,
                icon: Icon(Icons.pause_rounded, color: colors.textMain),
                label: Text(
                  'Pause',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textMain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                key: const Key('guitar_finish_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.completed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  elevation: 0,
                ),
                onPressed: _handleFinish,
                icon: const Icon(Icons.check_rounded),
                label: const Text(
                  'Finish',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Paused state
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              key: const Key('guitar_resume_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                elevation: 0,
              ),
              onPressed: _handleResume,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'Resume',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              key: const Key('guitar_finish_button'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.completed, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              onPressed: _handleFinish,
              icon: Icon(Icons.check_rounded, color: colors.completed),
              label: Text(
                'Finish',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.completed,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
