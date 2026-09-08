# Bugs & Known Issues

## 1. Resolved Issues

### State Loss on App Restart
- **Issue**: Previously, the app used an `InMemoryActivityRepository`, resetting all statuses on restart.
- **Resolution**: Implemented and hardened `SharedPreferencesActivityRepository` with persistent JSON serialization.
- **Status**: **Resolved**.

### Activity Duration Truncation (Sub-Minute Data Loss)
- **Issue**: Serialization saved `defaultDurationMinutes`, dropping seconds and truncating sub-minute durations (e.g. 45 seconds) to 0 minutes.
- **Resolution**: Migrated serialization to `defaultDurationSeconds` with backward-compatible deserialization for legacy minutes.
- **Status**: **Resolved**.

### TextEditingController Memory Leak in Dialog
- **Issue**: `_showRepsDialog` allocated a `TextEditingController` on every set completion without disposing it.
- **Resolution**: Encapsulated dialog into a dedicated `_RepsDialog` StatefulWidget with automatic controller disposal on route teardown.
- **Status**: **Resolved**.

### Dumbbells Reps Input Validation
- **Issue**: Users could submit negative numbers or invalid values for dumbbell reps.
- **Resolution**: Implemented form validation ensuring entered reps are positive integers between 1 and 999.
- **Status**: **Resolved**.

### Dumbbells Set Count Desynchronization
- **Issue**: `_currentSet` defaulted to 1 upon opening `DumbbellsScreen`, ignoring sets already recorded.
- **Resolution**: Dynamically calculated `_currentSet` from `completedSetsReps.length + 1`.
- **Status**: **Resolved**.

### RoutineTimerController Listener Concurrent Modification Risk
- **Issue**: Direct iteration over `_listeners` threw `ConcurrentModificationError` when a listener unsubscribed inside its callback.
- **Resolution**: Iterated over a defensive copy `List.from(_listeners)` and added `dispose()`.
- **Status**: **Resolved**.

### Silent Data Wipe on Corrupt Storage
- **Issue**: Any parse exception in `SharedPreferencesActivityRepository` triggered `_initializeDefaults()`, immediately overwriting and destroying all user routine data.
- **Resolution**: Added safe corrupted data preservation into `activities_corrupted_backup` before loading defaults.
- **Status**: **Resolved**.

---

## 2. Monitored Build Issues (Windows)

### Gradle Intermediates Locking (Windows)
- **Issue**: The `build/app/intermediates` directory frequently locks on Windows/OneDrive during the build process, preventing subsequent builds from succeeding.
- **Workaround**: Run `gradlew --stop` followed by an explicit `Remove-Item -Recurse -Force "build\app\intermediates"` before building.
- **Status**: Monitored. Ensure clean builds when transitioning branches or modifying Gradle settings.

### Gradle and AGP Version Conflict
- **Issue**: AGP 8.11.1 requires Gradle 9.5.1 (or compatible) for Java 25 support. Newer versions of Gradle (9.7+) break AGP 8.x compatibility due to internal API removals.
- **Workaround**: The project uses the Gradle Wrapper locked to `9.5.1` in `gradle-wrapper.properties`.
- **Status**: Resolved, but upgrading Gradle requires careful AGP matching.

