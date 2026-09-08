# Architecture

## Overview
The Daily Routine app is built using Flutter and follows a lightweight Model-View-Presenter (MVP-lite) / Repository pattern with dependency injection.

## State Management & Controller Lifecycle
- **UI State**: The application uses localized state management within StatefulWidgets (`HomeScreen`, `MeditationScreen`, `WalkingScreen`, `DumbbellsScreen`).
- **Controllers**: Complex business logic, such as countdown timers, is encapsulated in dedicated controller classes (`RoutineTimerController`). These controllers manage wall-clock timestamp calculations, prevent timer drift during app backgrounding, dispatch updates via defensive listener snapshots, and provide explicit `dispose()` cleanup.
- **Dialogs & Inputs**: Isolated modal interactions (such as rep tracking in `DumbbellsScreen`) utilize dedicated stateful dialog widgets (`_RepsDialog`) to manage and safely dispose `TextEditingController` instances without leaking resources across route animations.

## Directory Structure
- `lib/models/`: Contains data models and JSON serialization logic (`Activity`, `ActivityType`).
- `lib/repositories/`: Contains data access interfaces and implementations (`ActivityRepository`, `InMemoryActivityRepository`, `SharedPreferencesActivityRepository`).
- `lib/controllers/`: Contains standalone business logic components (`RoutineTimerController`).
- `lib/screens/`: Contains top-level UI views (`HomeScreen`, `MeditationScreen`, `WalkingScreen`, `DumbbellsScreen`, `ActivityDetailScreen`).
- `lib/widgets/`: Contains reusable UI components (`ActivityCard`).

## Design Patterns & Reliability
- **Repository Pattern**: Abstracts data persistence. `SharedPreferencesActivityRepository` persists activities as JSON. It includes data corruption safeguards, preserving invalid payloads into `activities_corrupted_backup` rather than silently erasing user history.
- **Dependency Injection**: Repositories are passed down via constructors (`DailyRoutineApp(repository: ...)`), enabling simple mocking and unit testing without global state.
- **Durability & Compatibility**: Serialization uses `defaultDurationSeconds` for second-level accuracy while transparently supporting legacy `defaultDurationMinutes` payloads.
- **Historical Logging & Date Rollover**: The storage layer partitions state into today's active routine (`activities`) and multi-day historical snapshots (`activity_history`). Upon detecting a date rollover, yesterday's state is archived into `DayHistory`, and today's status flags are cleanly reset while preserving user routines.
- **Lifecycle-Aware Storage Flushing**: `DailyRoutineApp` implements `WidgetsBindingObserver` to monitor `AppLifecycleState`. When an app is paused, minimized, or detached, `repository.flush()` is invoked to guarantee all pending asynchronous writes are committed to disk before OS process termination.

## Design System & Theming (`AppTheme`)
- **Static Semantic Palette**: Uses high-contrast, deterministic colors (Cobalt Blue `#2563EB`, Emerald Green `#059669`, Amber Warning `#D97706`, Crimson Red `#E11D48`, and Slate neutrals `#0F172A` to `#F8FAFC`) rather than dynamic Material 3 tinting.
- **Subtle Sharp Geometry**: Standardized container borders (`1.2px` width) and restrained corner radii (`radiusSmall = 6.0`, `radiusMedium = 10.0`, `radiusLarge = 14.0`) provide a clean, modern, sharp aesthetic while avoiding harsh brutalism.
- **Three-Tab Architecture**: `HomeScreen` hosts a bottom navigation bar switching reactively between `Today` (live checklist), `History` (chronological daily archives), and `Progress` (analytics and trend graphs).

## Progress & Analytics Architecture
- **Pure Functional Calculation Engine**: `ProgressCalculator` in `lib/services/progress_calculator.dart` computes period statistics (`ProgressStatistics`) across `Day`, `Week`, and `Month` windows without any UI coupling or platform dependencies.
- **Single Source of Truth**: Evaluates live routines from `repository.getActivities()` alongside persisted history from `repository.getHistory()`. Unrecorded days are handled gracefully without being treated as missed activities.
- **Workout & Volume Tracking**: Aggregates total workout duration from completed activities, plus exact dumbbell sets (`completedSetsReps.length`) and reps (`completedSetsReps` summation).
- **Native Sharp Charts**: Employs pure Flutter layout components (`DayActivityBreakdownBar`, `WeekProgressBarChart`, `MonthDayProgressBarChart`) styled with `AppTheme` sharp borders and static semantic colors, eliminating external chart library overhead.
- **Monthly Final Accuracy**: Calculates overall completion percentage across available recorded days in the current month.

## Notifications & Reminder Architecture
- **Service Abstraction**: `NotificationService` interface decouples scheduled alarms from the UI and repository. `LocalNotificationService` wraps `flutter_local_notifications` and `timezone` for production on Android, while `InMemoryNotificationService` supports headless test execution.
- **Scheduled Alarms Without Exact Alarm Bloat**: Uses `AndroidScheduleMode.inexactAllowWhileIdle` to deliver alerts reliably during device sleep or app termination without requesting invasive permissions (`SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM`).
- **Main & Backup Hierarchy**: Each routine supports an independent Main reminder and an optional Backup reminder (e.g. 30 minutes later). Deterministic ID mapping (Meditation: `101`/`102`, Walking: `201`/`202`, Dumbbells: `301`/`302`) eliminates duplicate alerts and collisions.
- **Auto-Cancellation on Action**: Marking an activity completed or skipped immediately cancels remaining scheduled alarms for that activity today via `cancelActivityReminders(id)`.
- **Reboot Resilience**: Android manifest registers `RECEIVE_BOOT_COMPLETED` alongside `ScheduledNotificationBootReceiver` and `ScheduledNotificationReceiver` to restore scheduled alarms automatically after device restart.
- **Time Rollover**: On midnight date rollover, pending activity reminders automatically reschedule for the new day upon app launch or repository synchronization.

