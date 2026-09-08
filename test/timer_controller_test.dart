import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/controllers/routine_timer_controller.dart';

void main() {
  group('RoutineTimerController', () {
    late RoutineTimerController controller;

    setUp(() {
      controller = RoutineTimerController(
        totalDuration: const Duration(minutes: 10),
      );
    });

    test('initial state is correct', () {
      expect(controller.state, TimerState.initial);
      expect(controller.remaining, const Duration(minutes: 10));
      expect(controller.formattedTime, '10:00');
      expect(controller.progress, 1.0);
      expect(controller.isInitial, true);
      expect(controller.isRunning, false);
      expect(controller.isCompleted, false);
    });

    test('start() transitions to running state', () {
      controller.start();
      expect(controller.state, TimerState.running);
      expect(controller.isRunning, true);
    });

    test('start() does nothing if already running', () {
      controller.start();
      controller.start(); // second call should be a no-op
      expect(controller.state, TimerState.running);
    });

    test('pause() transitions from running to paused', () {
      controller.start();
      controller.pause();
      expect(controller.state, TimerState.paused);
      expect(controller.isPaused, true);
    });

    test('pause() does nothing when not running', () {
      controller.pause();
      expect(controller.state, TimerState.initial);
    });

    test('resume() transitions from paused to running', () {
      controller.start();
      controller.pause();
      controller.resume();
      expect(controller.state, TimerState.running);
      expect(controller.isRunning, true);
    });

    test('resume() does nothing when not paused', () {
      controller.resume();
      expect(controller.state, TimerState.initial);
    });

    test('finish() transitions immediately to completed with 00:00', () {
      controller.start();
      controller.finish();
      expect(controller.state, TimerState.completed);
      expect(controller.remaining, Duration.zero);
      expect(controller.formattedTime, '00:00');
      expect(controller.isCompleted, true);
    });

    test('finish() from paused state also completes', () {
      controller.start();
      controller.pause();
      controller.finish();
      expect(controller.state, TimerState.completed);
    });

    test('finish() is idempotent when already completed', () {
      controller.finish();
      controller.finish(); // should not throw
      expect(controller.state, TimerState.completed);
    });

    test('tick() returns false when not running', () {
      final completed = controller.tick();
      expect(completed, false);
      expect(controller.state, TimerState.initial);
    });

    test('tick() returns false while time remains', () {
      controller.start();
      // tick immediately — the remaining should still be ~10 min
      final completed = controller.tick();
      expect(completed, false);
      expect(controller.state, TimerState.running);
    });

    test('tick() auto-completes and clamps to 00:00 when endTime is in the past',
        () {
      // Use a 1-second total, then manually wind the clock by setting
      // _endTime to the past via a subclass with a fake clock.
      final tiny = RoutineTimerController(
        totalDuration: const Duration(seconds: 1),
      );
      tiny.start();

      // Advance internal state by simulating the end time being in the past:
      // We can't directly mutate _endTime, but tick() calls _computeRemaining()
      // which subtracts DateTime.now() from _endTime. If we wait 1 tick on a
      // 0-duration controller, remaining becomes 0 immediately.
      final zeroController = RoutineTimerController(
        totalDuration: Duration.zero,
      );
      zeroController.start();
      final completed = zeroController.tick();
      expect(completed, true);
      expect(zeroController.state, TimerState.completed);
      expect(zeroController.remaining, Duration.zero);
    });

    test('progress returns 0.0 when remaining is 0', () {
      controller.finish();
      expect(controller.progress, 0.0);
    });

    test('formattedTime pads single-digit minutes and seconds', () {
      final c = RoutineTimerController(
        totalDuration: const Duration(minutes: 1, seconds: 5),
      );
      expect(c.formattedTime, '01:05');
    });

    test('reset() restores initial state', () {
      controller.start();
      controller.reset();
      expect(controller.state, TimerState.initial);
      expect(controller.remaining, const Duration(minutes: 10));
    });

    test('listeners are called on state changes', () {
      var callCount = 0;
      controller.addListener(() => callCount++);

      controller.start();
      expect(callCount, 1);

      controller.pause();
      expect(callCount, 2);

      controller.resume();
      expect(callCount, 3);

      controller.finish();
      expect(callCount, 4);
    });

    test('removeListener stops notifications', () {
      var callCount = 0;
      void listener() => callCount++;
      controller.addListener(listener);
      controller.start();
      expect(callCount, 1);

      controller.removeListener(listener);
      controller.pause();
      expect(callCount, 1); // not incremented after removal
    });

    test('re-entrant listener removal during notification does not throw ConcurrentModificationError', () {
      late void Function() selfRemovingListener;
      var invoked = false;

      selfRemovingListener = () {
        invoked = true;
        controller.removeListener(selfRemovingListener);
      };

      controller.addListener(selfRemovingListener);
      // Calling start triggers _notify() which iterates listeners
      expect(() => controller.start(), returnsNormally);
      expect(invoked, isTrue);
    });

    test('dispose clears all registered listeners', () {
      var callCount = 0;
      controller.addListener(() => callCount++);
      controller.dispose();

      controller.start();
      expect(callCount, 0);
    });
  });
}
