# Testing Strategy

## Overview
The project maintains a high standard of automated testing. All major components must have tests verifying their behavior.

## Current Coverage
- **Models**: `activity_model_test.dart`, `day_history_test.dart`, and `reminder_config_test.dart` verify data integrity, copy operations, serialization, duration precision, and boundary values.
- **Repositories**: `shared_preferences_activity_repository_test.dart` ensures atomic writes, corruption backups, date rollover archival, and reminder persistence.
- **Controllers**: `timer_controller_test.dart` fully covers timestamp calculations, Start, Pause, Resume, and Finish behaviors, and tick completions without background timer drift.
- **Notifications & Scheduling**: `notification_scheduler_test.dart` validates in-memory alarm scheduling, main vs backup alerts, next-day scheduling on rollover/past time, and automated reminder cancellations upon activity completion or skip.
- **Analytics & Progress**: `progress_calculator_test.dart` covers Day, Week, and Month analytics, empty history handling, unrecorded day safety, dumbbell volume summation, and month boundary calculations.
- **Widgets**: `widget_test.dart`, `history_screen_test.dart`, `reminder_settings_screen_test.dart`, `progress_screen_test.dart`, and activity screens (`meditation_screen_test.dart`, `walking_screen_test.dart`, `dumbbells_screen_test.dart`) test all navigation flows, 3-tab switching, period selectors, button transitions, time pickers, toggle switches, and real-time badge updates. Total suite: 102 automated tests.

## Testing Guidelines
- **No Background Loops**: Unit tests for time-dependent code should manipulate timestamps or use fake clocks rather than relying on `Future.delayed`.
- **Widget Pumping**: When testing widget animations or timers, use `tester.pumpAndSettle()` carefully or explicitly pump specific durations `tester.pump(const Duration(seconds: 1))` to advance timers.
- **Mocking**: Not currently in use, as `InMemoryActivityRepository` serves as a sufficient fake for UI tests.
