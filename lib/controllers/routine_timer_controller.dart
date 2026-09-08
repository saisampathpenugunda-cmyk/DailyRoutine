// Timer states for the meditation countdown timer.
enum TimerState { initial, running, paused, completed }

/// A timestamp-based countdown timer that remains accurate even if the app
/// loses focus. It does NOT use a drift-prone frame-by-frame accumulator;
/// instead it records the wall-clock end time and computes remaining duration
/// on every tick.
class RoutineTimerController {
  final Duration totalDuration;

  TimerState _state = TimerState.initial;
  Duration _remaining;

  /// Wall-clock moment when the timer should reach zero (set on start/resume).
  DateTime? _endTime;

  /// Listeners to notify on every state / tick change.
  final List<void Function()> _listeners = [];

  RoutineTimerController({required this.totalDuration})
      : _remaining = totalDuration;

  // ── Getters ──────────────────────────────────────────────────────────────

  TimerState get state => _state;
  Duration get remaining => _remaining;
  bool get isInitial => _state == TimerState.initial;
  bool get isRunning => _state == TimerState.running;
  bool get isPaused => _state == TimerState.paused;
  bool get isCompleted => _state == TimerState.completed;

  /// Formatted remaining time as `MM:SS`.
  String get formattedTime {
    final totalSeconds = (_remaining.inMilliseconds / 1000).ceil();
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Progress from 1.0 (full) to 0.0 (empty).
  double get progress {
    if (totalDuration == Duration.zero || totalDuration.inMilliseconds == 0) return 0;
    return _remaining.inMilliseconds / totalDuration.inMilliseconds;
  }

  // ── Listener management ──────────────────────────────────────────────────

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);

  void _notify() {
    for (final l in List<void Function()>.from(_listeners)) {
      l();
    }
  }

  /// Disposes controller resources and clears all registered listeners.
  void dispose() {
    _listeners.clear();
  }

  // ── Timer controls ───────────────────────────────────────────────────────

  /// Starts the countdown from `totalDuration`.
  void start() {
    if (_state != TimerState.initial) return;
    _endTime = DateTime.now().add(_remaining);
    _state = TimerState.running;
    _notify();
  }

  /// Pauses the running timer, recording how much time remains.
  void pause() {
    if (_state != TimerState.running) return;
    _remaining = _computeRemaining();
    _endTime = null;
    _state = TimerState.paused;
    _notify();
  }

  /// Resumes a paused timer.
  void resume() {
    if (_state != TimerState.paused) return;
    _endTime = DateTime.now().add(_remaining);
    _state = TimerState.running;
    _notify();
  }

  /// Immediately finishes the timer (early-finish or auto-complete path).
  void finish() {
    if (_state == TimerState.completed) return;
    _remaining = Duration.zero;
    _endTime = null;
    _state = TimerState.completed;
    _notify();
  }

  /// Called on every periodic UI tick (e.g., every second from a widget).
  /// Returns `true` when the timer just reached zero so the caller can
  /// trigger completion logic.
  bool tick() {
    if (_state != TimerState.running) return false;

    _remaining = _computeRemaining();

    if (_remaining <= Duration.zero) {
      _remaining = Duration.zero;
      _endTime = null;
      _state = TimerState.completed;
      _notify();
      return true; // auto-completed
    }

    _notify();
    return false;
  }

  /// Resets to initial state. Useful for testing.
  void reset() {
    _state = TimerState.initial;
    _remaining = totalDuration;
    _endTime = null;
    _notify();
  }

  // ── Internal helpers ─────────────────────────────────────────────────────

  Duration _computeRemaining() {
    if (_endTime == null) return _remaining;
    final r = _endTime!.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }
}
