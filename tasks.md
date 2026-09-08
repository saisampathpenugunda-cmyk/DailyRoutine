# Tasks

## Completed
- [x] Implement `WalkingScreen` for the Walking activity.
- [x] Implement `DumbbellsScreen` for the Dumbbells activity with rep entry.
- [x] Implement Local Storage (`SharedPreferencesActivityRepository`) to persist routines and completion states.
- [x] Harden storage against silent wipes upon JSON corruption (`activities_corrupted_backup`).
- [x] Migrate `Activity` serialization to `defaultDurationSeconds` with legacy minutes backward compatibility.
- [x] Fix `TextEditingController` dialog memory leak in `DumbbellsScreen`.
- [x] Add rep bounds validation (1-999) to `DumbbellsScreen`.
- [x] Fix set progression desynchronization when resuming `DumbbellsScreen`.
- [x] Fix `RoutineTimerController` listener mutation concurrency issue and add `dispose()`.
- [x] Clean up scratch scripts to achieve 0 `flutter analyze` linter issues.
- [x] Implement `DayHistory` model with date partitioning, completion rates, and JSON serialization.
- [x] Implement multi-day historical persistence in `SharedPreferencesActivityRepository` (`activity_history`).
- [x] Implement automatic date rollover: archives previous day's completed/skipped activities and sets/reps into history while resetting daily status without wiping routines.
- [x] Implement `WidgetsBindingObserver` in `main.dart` to flush repository writes immediately on app pause/detach.
- [x] Create static color palette and subtle sharp geometry design tokens in `AppTheme` (`lib/theme/app_theme.dart`).
- [x] Implement dual-tab bottom navigation (`Today` / `History`) on `HomeScreen`.
- [x] Implement `HistoryScreen` with chronological day cards, accomplishment badges, and activity details.
- [x] Apply subtle sharp borders and static semantic colors to `ActivityCard` and dashboard containers.
- [x] Implement Scheduled Local Notifications & Reminders with main + optional backup alerts per activity.
- [x] Configure Android 13+ `POST_NOTIFICATIONS` runtime permission and reboot receivers (`RECEIVE_BOOT_COMPLETED`).
- [x] Implement `ReminderSettingsScreen` with time picker dials and live alert cancellation status tags.
- [x] Implement automatic cancellation of scheduled reminders when activities are completed or skipped.
- [x] Implement Progress Screen with Day, Week, and Month time-period selection.
- [x] Implement `ProgressCalculator` computing completion %, completed/skipped/missed counts, duration, and dumbbell volume.
- [x] Implement native sharp progress visualizations (segmented distribution, 7-day comparison, monthly day-by-day).
- [x] Implement Monthly Final Accuracy percentage card based on recorded days.
- [x] Expand `HomeScreen` bottom navigation to 3 tabs (`Today`, `History`, `Progress`).

## Current Backlog
- [ ] Add the ability for users to create custom activities from the UI.
- [ ] Implement Android app backup configuration (`android:allowBackup="false"` or custom backup rules).

## Ongoing
- Monitor Windows Gradle intermediate file locks during builds. Ensure clean processes are run when necessary.

