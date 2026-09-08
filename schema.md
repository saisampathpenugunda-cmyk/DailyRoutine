# Data Schema

## Activity Model
The core entity in the system is the `Activity`. 

```dart
class Activity {
  final String id;
  final String name;
  final ActivityType activityType;
  final Duration defaultDuration;
  final bool isCompleted;
  final bool isSkipped;
  final List<int> completedSetsReps;
}
```

### Fields
- `id`: Unique identifier for the activity (String).
- `name`: Display name (String).
- `activityType`: Enum categorizing the activity (`meditation`, `walking`, `dumbbells`, `study`, `guitar`, `reading`, `general`).
- `defaultDuration`: Baseline expected duration required to complete the activity (Duration, serialized as seconds).
- `isCompleted`: Boolean flag indicating if the activity has been finished for the day.
- `isSkipped`: Boolean flag indicating if the activity was skipped for today ("Can't do today").
- `completedSetsReps`: List of completed reps per set (e.g., `[12, 10, 8]` for dumbbell exercises).

### JSON Serialization Contract
```json
{
  "id": "meditation",
  "name": "Meditation",
  "activityType": "meditation",
  "defaultDurationSeconds": 600,
  "defaultDurationMinutes": 10,
  "isCompleted": false,
  "isSkipped": false,
  "completedSetsReps": []
}
```
> **Note on Compatibility**: `defaultDurationSeconds` provides second-level duration precision. `fromJson()` retains backward compatibility by reading `defaultDurationSeconds` first and falling back to legacy `defaultDurationMinutes` if absent.

## ActivityRepository
The contract for fetching, storing, and updating routines.
- `getActivities()`: Returns an unmodifiable list of activities.
- `getActivityById(String id)`: Retrieves an activity or null.
- `toggleActivityCompletion(String id)`: Toggles completion state and resets skipped status.
- `setActivityCompletion(String id, {required bool isCompleted})`: Explicitly sets completion state.
- `setActivitySkipped(String id, {required bool isSkipped})`: Marks activity as skipped and clears completion.
- `addActivity(Activity activity)`: Adds a new activity or updates an existing activity by ID (deduplicating keys).
- `updateActivity(Activity activity)`: Updates an existing activity.
- `getHistory()`: Returns an unmodifiable chronological list of archived `DayHistory` records.
- `flush()`: Awaits and persists all in-flight changes to underlying storage.

## DayHistory Model
Represents an archived snapshot of an entire day's routine accomplishments.

```dart
class DayHistory {
  final String dateKey; // Format: 'YYYY-MM-DD'
  final DateTime recordedAt;
  final List<Activity> activities;

  int get totalCount;
  int get completedCount;
  double get completionRate;
  bool get isAllCompleted;
  String get displayTitle; // 'Today', 'Yesterday', or 'Mon, Sep 7'
}
```

### JSON Serialization Contract
```json
{
  "dateKey": "2026-09-06",
  "recordedAt": "2026-09-06T23:59:59.000Z",
  "activities": [
    {
      "id": "meditation",
      "name": "Meditation",
      "activityType": "meditation",
      "defaultDurationSeconds": 600,
      "isCompleted": true,
      "isSkipped": false,
      "completedSetsReps": []
    }
  ]
}
```

## ReminderConfig Model
Manages main and backup schedule configuration for an activity.

```dart
class ReminderConfig {
  final String activityId;
  final bool isMainEnabled;
  final int mainHour;
  final int mainMinute;
  final bool isBackupEnabled;
  final int backupHour;
  final int backupMinute;

  int get mainNotificationId;
  int get backupNotificationId;
  String get formattedMainTime;
  String get formattedBackupTime;
}
```

### Default Schedules & Notification IDs
| Activity | Main Time | Backup Time | Main ID | Backup ID |
|---|---|---|---|---|
| Meditation | 08:00 AM (Enabled) | 08:30 AM (Disabled) | 101 | 102 |
| Walking | 05:00 PM (Enabled) | 05:30 PM (Disabled) | 201 | 202 |
| Dumbbells | 07:00 PM (Enabled) | 07:30 PM (Disabled) | 301 | 302 |

### JSON Serialization Contract
```json
{
  "activityId": "meditation",
  "isMainEnabled": true,
  "mainHour": 8,
  "mainMinute": 0,
  "isBackupEnabled": false,
  "backupHour": 8,
  "backupMinute": 30
}
```

## Persistent Storage Keys (SharedPreferences)
- `activities`: JSON string of current day's `List<Activity>`.
- `activity_history`: JSON string of all past days `List<DayHistory>`.
- `activity_reminders`: JSON string of reminder configs `List<ReminderConfig>`.
- `last_active_date`: Date key string (`'YYYY-MM-DD'`) of the last recorded interaction session.
- `activities_corrupted_backup`: Preserved raw JSON payload when corrupted data is encountered to prevent silent data wipe.

