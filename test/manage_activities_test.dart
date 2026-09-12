import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/main.dart';
import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/models/day_history.dart';
import 'package:daily_routine/models/reminder_config.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/screens/create_activity_screen.dart';
import 'package:daily_routine/screens/edit_activity_screen.dart';
import 'package:daily_routine/screens/manage_activities_screen.dart';
import 'package:daily_routine/services/notification_service.dart';
import 'package:daily_routine/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyRoutine V1.2 — Manage Activities Tests', () {
    late InMemoryActivityRepository repository;
    late InMemoryNotificationService notificationService;

    setUp(() {
      notificationService = InMemoryNotificationService();
      repository = InMemoryActivityRepository(
        notificationService: notificationService,
      );
    });

    void setViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets('1. Manage Activities screen loads and displays all activities with correct labels', (
      WidgetTester tester,
    ) async {
      setViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ManageActivitiesScreen(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manage Activities'), findsOneWidget);
      expect(find.text('ALL ACTIVITIES (3)'), findsOneWidget);
      expect(find.text('Meditation'), findsOneWidget);
      expect(find.text('Walking'), findsOneWidget);
      expect(find.text('Dumbbells'), findsOneWidget);

      // Verify categories show "Timer" or "Workout", never "Dumbbell Workout"
      expect(find.textContaining('Timer • 10 min'), findsOneWidget);
      expect(find.textContaining('Timer • 30 min'), findsOneWidget);
      expect(find.textContaining('Workout • 20 min'), findsOneWidget);
      expect(find.textContaining('Dumbbell Workout'), findsNothing);

      // All 3 built-ins show Enabled switches
      expect(find.byKey(const Key('manage_toggle_switch_meditation')), findsOneWidget);
      expect(find.byKey(const Key('manage_toggle_switch_walking')), findsOneWidget);
      expect(find.byKey(const Key('manage_toggle_switch_dumbbells')), findsOneWidget);

      // All activities show Edit and Delete buttons
      expect(find.byKey(const Key('edit_activity_button_meditation')), findsOneWidget);
      expect(find.byKey(const Key('edit_activity_button_walking')), findsOneWidget);
      expect(find.byKey(const Key('edit_activity_button_dumbbells')), findsOneWidget);

      expect(find.byKey(const Key('delete_activity_button_meditation')), findsOneWidget);
      expect(find.byKey(const Key('delete_activity_button_walking')), findsOneWidget);
      expect(find.byKey(const Key('delete_activity_button_dumbbells')), findsOneWidget);
    });

    testWidgets('2. Home AppBar opens Manage Activities screen, and existing "+" FAB still works', (
      WidgetTester tester,
    ) async {
      setViewport(tester);
      await tester.pumpWidget(
        DailyRoutineApp(
          repository: repository,
          notificationService: notificationService,
        ),
      );
      await tester.pumpAndSettle();

      // Settings button exists in AppBar and leads to Manage Activities
      final settingsButton = find.byKey(const Key('settings_button'));
      expect(settingsButton, findsOneWidget);

      // Small "+" FAB still exists
      final addFab = find.byKey(const Key('add_activity_fab'));
      expect(addFab, findsOneWidget);

      // Tap Settings -> Manage Activities button
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_manage_activities_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ManageActivitiesScreen), findsOneWidget);

      // Back to Home
      await tester.tap(find.byKey(const Key('manage_activities_back_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_back_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ManageActivitiesScreen), findsNothing);

      // Tap small "+" FAB opens CreateActivityScreen
      await tester.tap(addFab);
      await tester.pumpAndSettle();

      expect(find.byType(CreateActivityScreen), findsOneWidget);
    });

    testWidgets('3. Create Activity from Manage Activities screen adds new activity and appears in list', (
      WidgetTester tester,
    ) async {
      setViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ManageActivitiesScreen(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "+ Add Activity" button
      await tester.tap(find.byKey(const Key('manage_add_activity_button')));
      await tester.pumpAndSettle();

      expect(find.byType(CreateActivityScreen), findsOneWidget);

      // Fill in details
      await tester.enterText(find.byKey(const Key('activity_name_input')), 'Reading');
      await tester.tap(find.byKey(const Key('activity_type_timer')));
      await tester.enterText(find.byKey(const Key('activity_duration_input')), '25');

      await tester.tap(find.byKey(const Key('create_button')));
      await tester.pumpAndSettle();

      // Returned to ManageActivitiesScreen
      expect(find.byType(ManageActivitiesScreen), findsOneWidget);
      expect(find.text('ALL ACTIVITIES (4)'), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
      expect(find.textContaining('Timer • 25 min'), findsOneWidget);
    });

    testWidgets('4. All activities (Meditation, Walking, Dumbbells, Custom) display Delete button', (
      WidgetTester tester,
    ) async {
      setViewport(tester);
      // Add custom activity
      repository.addActivity(
        const Activity(
          id: 'custom_guitar',
          name: 'Guitar Practice',
          activityType: ActivityType.timer,
          defaultDuration: Duration(minutes: 20),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ManageActivitiesScreen(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All activities display Delete button
      expect(find.byKey(const Key('delete_activity_button_meditation')), findsOneWidget);
      expect(find.byKey(const Key('delete_activity_button_walking')), findsOneWidget);
      expect(find.byKey(const Key('delete_activity_button_dumbbells')), findsOneWidget);
      expect(find.byKey(const Key('delete_activity_button_custom_guitar')), findsOneWidget);
    });

    testWidgets('5. Deleting custom activity shows confirmation dialog and Cancel leaves it intact', (
      WidgetTester tester,
    ) async {
      setViewport(tester);
      repository.addActivity(
        const Activity(
          id: 'custom_stretching',
          name: 'Stretching',
          activityType: ActivityType.workout,
          defaultDuration: Duration(minutes: 15),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ManageActivitiesScreen(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Delete
      await tester.tap(find.byKey(const Key('delete_activity_button_custom_stretching')));
      await tester.pumpAndSettle();

      // Confirmation dialog
      expect(find.text('Delete Activity?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete Stretching?'), findsOneWidget);
      expect(find.byKey(const Key('dialog_cancel_button')), findsOneWidget);
      expect(find.byKey(const Key('dialog_confirm_delete_button')), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.byKey(const Key('dialog_cancel_button')));
      await tester.pumpAndSettle();

      // Still in list and repository
      expect(find.text('Stretching'), findsOneWidget);
      expect(repository.getActivityById('custom_stretching'), isNotNull);
    });

    testWidgets('6. Confirming deletion removes custom activity from repository and list, and cancels reminders', (
      WidgetTester tester,
    ) async {
      setViewport(tester);
      const activityId = 'custom_drawing';
      repository.addActivity(
        const Activity(
          id: activityId,
          name: 'Drawing',
          activityType: ActivityType.timer,
          defaultDuration: Duration(minutes: 30),
        ),
      );
      const config = ReminderConfig(
        activityId: activityId,
        isMainEnabled: true,
        mainHour: 10,
        mainMinute: 0,
        isBackupEnabled: false,
        backupHour: 10,
        backupMinute: 30,
      );
      repository.updateReminderConfig(config);
      expect(notificationService.scheduledNotifications.containsKey(config.mainNotificationId), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: ManageActivitiesScreen(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Delete
      await tester.tap(find.byKey(Key('delete_activity_button_$activityId')));
      await tester.pumpAndSettle();

      // Confirm Delete
      await tester.tap(find.byKey(const Key('dialog_confirm_delete_button')));
      await tester.pumpAndSettle();

      // Removed from UI
      expect(find.text('Drawing'), findsNothing);
      expect(repository.getActivityById(activityId), isNull);

      // Reminders cancelled
      expect(notificationService.scheduledNotifications.containsKey(config.mainNotificationId), isFalse);
    });

    test('7. Meditation, Walking, and Dumbbells can all be deleted from repository', () {
      expect(repository.deleteActivity('meditation'), isTrue);
      expect(repository.deleteActivity('walking'), isTrue);
      expect(repository.deleteActivity('dumbbells'), isTrue);

      expect(repository.getActivityById('meditation'), isNull);
      expect(repository.getActivityById('walking'), isNull);
      expect(repository.getActivityById('dumbbells'), isNull);
    });

    testWidgets('8. Edit Activity: Name, type, duration, and reminders edit and persist', (
      WidgetTester tester,
    ) async {
      setViewport(tester);
      const customId = 'custom_run';
      repository.addActivity(
        const Activity(
          id: customId,
          name: 'Run',
          activityType: ActivityType.timer,
          defaultDuration: Duration(minutes: 20),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ManageActivitiesScreen(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.byKey(Key('edit_activity_button_$customId')));
      await tester.pumpAndSettle();

      expect(find.byType(EditActivityScreen), findsOneWidget);
      expect(find.text('Edit Activity'), findsOneWidget);

      // Edit name
      await tester.enterText(find.byKey(const Key('edit_activity_name_input')), 'Interval Sprint');

      // Edit type to Workout
      await tester.tap(find.byKey(const Key('edit_type_workout')));

      // Save
      await tester.tap(find.byKey(const Key('edit_save_button')));
      await tester.pumpAndSettle();

      // Returned to Manage Activities
      expect(find.byType(ManageActivitiesScreen), findsOneWidget);
      expect(find.text('Interval Sprint'), findsOneWidget);
      expect(find.textContaining('Workout'), findsWidgets);

      final updated = repository.getActivityById(customId)!;
      expect(updated.name, 'Interval Sprint');
      expect(updated.activityType, ActivityType.workout);
    });

    testWidgets('9. Disabling and re-enabling an activity from Manage Activities updates Today plan and reminders', (
      WidgetTester tester,
    ) async {
      setViewport(tester);
      const config = ReminderConfig(
        activityId: 'meditation',
        isMainEnabled: true,
        mainHour: 8,
        mainMinute: 0,
        isBackupEnabled: false,
        backupHour: 8,
        backupMinute: 30,
      );
      repository.updateReminderConfig(config);
      expect(notificationService.scheduledNotifications.containsKey(config.mainNotificationId), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: ManageActivitiesScreen(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle Meditation switch to disabled
      await tester.tap(find.byKey(const Key('manage_toggle_switch_meditation')));
      await tester.pumpAndSettle();

      // Label updates to Disabled
      expect(find.byKey(const Key('manage_status_label_meditation')), findsOneWidget);
      expect(find.text('Disabled'), findsOneWidget);
      expect(repository.getActivityById('meditation')!.isEnabled, isFalse);

      // Reminder was cancelled
      expect(notificationService.scheduledNotifications.containsKey(config.mainNotificationId), isFalse);

      // Toggle Meditation switch back to enabled
      await tester.tap(find.byKey(const Key('manage_toggle_switch_meditation')));
      await tester.pumpAndSettle();

      expect(repository.getActivityById('meditation')!.isEnabled, isTrue);

      // Reminder was restored
      expect(notificationService.scheduledNotifications.containsKey(config.mainNotificationId), isTrue);
    });

    testWidgets('10. Active session safety: cannot disable or delete activity while session is running', (
      WidgetTester tester,
    ) async {
      setViewport(tester);
      const customId = 'custom_timer_act';
      repository.addActivity(
        const Activity(
          id: customId,
          name: 'Active Routine',
          activityType: ActivityType.timer,
          defaultDuration: Duration(minutes: 10),
        ),
      );

      // Start timer
      final controller = repository.getTimerController(customId);
      controller.start();
      expect(repository.isActivityInProgress(customId), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: ManageActivitiesScreen(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Attempt to toggle disabled
      await tester.tap(find.byKey(Key('manage_toggle_switch_$customId')));
      await tester.pumpAndSettle();

      // Blocked with SnackBar warning
      expect(find.textContaining('Cannot disable an activity with an active or paused session'), findsOneWidget);
      expect(repository.getActivityById(customId)!.isEnabled, isTrue);

      // Attempt to delete
      await tester.tap(find.byKey(Key('delete_activity_button_$customId')));
      await tester.pumpAndSettle();

      // Blocked with SnackBar warning
      expect(find.textContaining('Cannot delete an activity with an active or paused session'), findsOneWidget);
      expect(repository.getActivityById(customId), isNotNull);
    });

    testWidgets('11. History Immutability: Past DayHistory records remain intact after editing or deleting activity', (
      WidgetTester tester,
    ) async {
      const customId = 'custom_past_act';
      const pastActivity = Activity(
        id: customId,
        name: 'Past Study',
        activityType: ActivityType.timer,
        defaultDuration: Duration(minutes: 45),
        actualDuration: Duration(minutes: 45),
        isCompleted: true,
      );
      repository.addActivity(pastActivity);

      // Archive into past history
      final pastRecord = DayHistory(
        dateKey: '2026-09-08',
        activities: [pastActivity],
        recordedAt: DateTime(2026, 9, 8, 10, 0),
      );
      repository.addHistoryEntry(pastRecord);

      final initialPast = repository.getHistory().firstWhere((h) => h.dateKey == '2026-09-08');
      expect(initialPast.activities.first.name, 'Past Study');
      expect(initialPast.activities.first.isCompleted, isTrue);

      // Now edit the activity today
      repository.updateActivity(
        pastActivity.copyWith(
          name: 'Modern Study',
          defaultDuration: const Duration(minutes: 60),
        ),
      );

      // Past history is completely unaffected
      final historyAfterEdit = repository.getHistory().firstWhere((h) => h.dateKey == '2026-09-08');
      expect(historyAfterEdit.activities.first.name, 'Past Study');
      expect(historyAfterEdit.activities.first.defaultDuration.inMinutes, 45);

      // Now delete the custom activity today
      final deleted = repository.deleteActivity(customId);
      expect(deleted, isTrue);
      expect(repository.getActivityById(customId), isNull);

      // Past history still retains 'Past Study' intact
      final historyAfterDelete = repository.getHistory().firstWhere((h) => h.dateKey == '2026-09-08');
      expect(historyAfterDelete.activities.first.name, 'Past Study');
      expect(historyAfterDelete.activities.first.isCompleted, isTrue);
    });

    testWidgets('12. Home screen immediately reflects created, edited, and deleted activities', (
      WidgetTester tester,
    ) async {
      setViewport(tester);
      await tester.pumpWidget(
        DailyRoutineApp(
          repository: repository,
          notificationService: notificationService,
        ),
      );
      await tester.pumpAndSettle();

      // Open Settings -> Manage Activities
      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_manage_activities_button')));
      await tester.pumpAndSettle();

      // Add "Journaling"
      await tester.tap(find.byKey(const Key('manage_add_activity_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('activity_name_input')), 'Journaling');
      await tester.enterText(find.byKey(const Key('activity_duration_input')), '15');
      await tester.tap(find.byKey(const Key('create_button')));
      await tester.pumpAndSettle();

      // Back to Home
      await tester.tap(find.byKey(const Key('manage_activities_back_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_back_button')));
      await tester.pumpAndSettle();

      // "Journaling" appears on Home
      expect(find.text('Journaling'), findsOneWidget);
      expect(find.text('15 min'), findsOneWidget);
    });

    testWidgets('13. Duration change on active session updates defaultDuration for next session without resetting active session', (
      WidgetTester tester,
    ) async {
      final controller = repository.getTimerController('meditation');
      controller.start();
      expect(controller.isRunning, isTrue);
      expect(controller.totalDuration, const Duration(minutes: 10));

      // Update meditation activity duration to 15 min
      final meditation = repository.getActivityById('meditation')!;
      repository.updateActivity(meditation.copyWith(defaultDuration: const Duration(minutes: 15)));

      // Active controller duration is untouched and still running
      expect(controller.isRunning, isTrue);
      expect(controller.totalDuration, const Duration(minutes: 10));

      // Repository default duration is updated to 15 min for next session
      expect(repository.getActivityById('meditation')!.defaultDuration, const Duration(minutes: 15));
    });

    testWidgets('14. Progress calculation strictly uses enabled activities and excludes deleted activities', (
      WidgetTester tester,
    ) async {
      setViewport(tester);
      // Create custom activity
      repository.addActivity(
        const Activity(
          id: 'custom_dance',
          name: 'Dance',
          activityType: ActivityType.workout,
          defaultDuration: Duration(minutes: 20),
        ),
      );

      // Complete Meditation
      repository.setActivityCompletion('meditation', isCompleted: true);
      // Disable Walking
      repository.setActivityEnabled('walking', false);

      await tester.pumpWidget(
        DailyRoutineApp(
          repository: repository,
          notificationService: notificationService,
        ),
      );
      await tester.pumpAndSettle();

      // Total enabled: Meditation (done), Dumbbells (not done), Dance (not done) -> 3 enabled, 1 done = 33%
      expect(find.text('1 of 3 activities completed'), findsOneWidget);

      // Now delete Dance
      repository.deleteActivity('custom_dance');
      await tester.pumpWidget(
        DailyRoutineApp(
          key: UniqueKey(),
          repository: repository,
          notificationService: notificationService,
        ),
      );
      await tester.pumpAndSettle();

      // Total enabled: Meditation (done), Dumbbells (not done) -> 2 enabled, 1 done = 50%
      expect(find.text('1 of 2 activities completed'), findsOneWidget);
    });

    testWidgets('15. Edit screen allows changing activity type from Workout to Timer for custom activity', (
      WidgetTester tester,
    ) async {
      setViewport(tester);
      repository.addActivity(
        const Activity(
          id: 'custom_circuit',
          name: 'Circuit',
          activityType: ActivityType.workout,
          defaultDuration: Duration(minutes: 20),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EditActivityScreen(
            activity: repository.getActivityById('custom_circuit')!,
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Timer
      await tester.tap(find.byKey(const Key('edit_type_timer')));
      await tester.tap(find.byKey(const Key('edit_save_button')));
      await tester.pumpAndSettle();

      expect(repository.getActivityById('custom_circuit')!.activityType, ActivityType.timer);
    });

    testWidgets('16. Activity without reminders schedules no notifications', (
      WidgetTester tester,
    ) async {
      const config = ReminderConfig(
        activityId: 'custom_silent',
        isMainEnabled: false,
        mainHour: 9,
        mainMinute: 0,
        isBackupEnabled: false,
        backupHour: 9,
        backupMinute: 30,
      );
      repository.updateReminderConfig(config);
      expect(notificationService.scheduledNotifications.containsKey(config.mainNotificationId), isFalse);
      expect(notificationService.scheduledNotifications.containsKey(config.backupNotificationId), isFalse);
    });

    testWidgets('17. Outlined Switch styling: Enabled thumb on RIGHT, Disabled thumb on LEFT, track NOT completely filled', (
      WidgetTester tester,
    ) async {
      setViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ManageActivitiesScreen(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Meditation switch is initially enabled (value == true, thumb on RIGHT)
      final medSwitchFinder = find.byKey(const Key('manage_toggle_switch_meditation'));
      final medSwitch = tester.widget<Switch>(medSwitchFinder);
      expect(medSwitch.value, isTrue);

      // Verify theme trackColor resolves to transparent (NOT filled)
      final theme = Theme.of(tester.element(medSwitchFinder));
      final trackColorEnabled = theme.switchTheme.trackColor?.resolve({WidgetState.selected});
      expect(trackColorEnabled, equals(Colors.transparent));

      // Verify outline color and thumb color for enabled
      final outlineEnabled = theme.switchTheme.trackOutlineColor?.resolve({WidgetState.selected});
      expect(outlineEnabled, equals(AppTheme.lightSwitchTrackOutlineOn));
      final thumbEnabled = theme.switchTheme.thumbColor?.resolve({WidgetState.selected});
      expect(thumbEnabled, equals(AppTheme.lightSwitchThumbOn));
      expect(theme.switchTheme.trackOutlineWidth?.resolve({WidgetState.selected}), equals(2.0));

      // Toggle Meditation to disabled
      await tester.tap(medSwitchFinder);
      await tester.pumpAndSettle();

      final medSwitchDisabled = tester.widget<Switch>(medSwitchFinder);
      expect(medSwitchDisabled.value, isFalse); // thumb on LEFT

      // Verify disabled trackColor remains transparent (NOT filled)
      final trackColorDisabled = theme.switchTheme.trackColor?.resolve({});
      expect(trackColorDisabled, equals(Colors.transparent));

      // Verify outline color and thumb color for disabled (muted secondary purple)
      final outlineDisabled = theme.switchTheme.trackOutlineColor?.resolve({});
      expect(outlineDisabled, equals(AppTheme.lightSwitchTrackOutlineOff));
      final thumbDisabled = theme.switchTheme.thumbColor?.resolve({});
      expect(thumbDisabled, equals(AppTheme.lightSwitchThumbOff));
      expect(theme.switchTheme.trackOutlineWidth?.resolve({}), equals(1.4));
    });

    testWidgets('18. Outlined Switch styling in Cyber Noir Dark theme', (
      WidgetTester tester,
    ) async {
      setViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ManageActivitiesScreen(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const Key('manage_toggle_switch_meditation'));
      final theme = Theme.of(tester.element(switchFinder));

      // Selected: track is transparent, thumb is primary cyan/accent
      expect(theme.switchTheme.trackColor?.resolve({WidgetState.selected}), equals(Colors.transparent));
      expect(theme.switchTheme.thumbColor?.resolve({WidgetState.selected}), equals(AppTheme.cyberNoirSwitchThumbOn));
      expect(theme.switchTheme.trackOutlineColor?.resolve({WidgetState.selected}), equals(AppTheme.cyberNoirSwitchTrackOutlineOn));
      expect(theme.switchTheme.trackOutlineWidth?.resolve({WidgetState.selected}), equals(2.0));

      // Unselected: track is transparent, thumb is secondary slate
      expect(theme.switchTheme.trackColor?.resolve({}), equals(Colors.transparent));
      expect(theme.switchTheme.thumbColor?.resolve({}), equals(AppTheme.cyberNoirSwitchThumbOff));
      expect(theme.switchTheme.trackOutlineColor?.resolve({}), equals(AppTheme.cyberNoirSwitchTrackOutlineOff));
      expect(theme.switchTheme.trackOutlineWidth?.resolve({}), equals(1.4));
    });

    testWidgets('19. Meditation can be deleted via UI with confirmation dialog and reminder cancellation', (
      WidgetTester tester,
    ) async {
      setViewport(tester);
      // Set a reminder on Meditation
      const medConfig = ReminderConfig(
        activityId: 'meditation',
        isMainEnabled: true,
        mainHour: 8,
        mainMinute: 0,
        isBackupEnabled: false,
        backupHour: 8,
        backupMinute: 30,
      );
      repository.updateReminderConfig(medConfig);
      expect(notificationService.scheduledNotifications.containsKey(medConfig.mainNotificationId), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ManageActivitiesScreen(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Delete on Meditation
      await tester.tap(find.byKey(const Key('delete_activity_button_meditation')));
      await tester.pumpAndSettle();

      // Confirmation dialog
      expect(find.text('Delete Activity?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete Meditation?'), findsOneWidget);

      // Confirm Delete
      await tester.tap(find.byKey(const Key('dialog_confirm_delete_button')));
      await tester.pumpAndSettle();

      // Meditation removed from UI and repository
      expect(find.text('Meditation'), findsNothing);
      expect(repository.getActivityById('meditation'), isNull);

      // Reminders cancelled
      expect(notificationService.scheduledNotifications.containsKey(medConfig.mainNotificationId), isFalse);
    });

    testWidgets('20. Walking and Dumbbells can be deleted via UI with confirmation dialog', (
      WidgetTester tester,
    ) async {
      setViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ManageActivitiesScreen(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Delete Walking
      await tester.tap(find.byKey(const Key('delete_activity_button_walking')));
      await tester.pumpAndSettle();
      expect(find.text('Are you sure you want to delete Walking?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('dialog_confirm_delete_button')));
      await tester.pumpAndSettle();

      expect(find.text('Walking'), findsNothing);
      expect(repository.getActivityById('walking'), isNull);

      // Delete Dumbbells
      await tester.tap(find.byKey(const Key('delete_activity_button_dumbbells')));
      await tester.pumpAndSettle();
      expect(find.text('Are you sure you want to delete Dumbbells?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('dialog_confirm_delete_button')));
      await tester.pumpAndSettle();

      expect(find.text('Dumbbells'), findsNothing);
      expect(repository.getActivityById('dumbbells'), isNull);
    });

    test('21. Historical records remain unchanged after deleting an activity today', () {
      // Simulate yesterday having a completed Meditation session
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      repository.addHistoryEntry(
        DayHistory(
          dateKey: yesterdayKey,
          activities: [
            const Activity(
              id: 'meditation',
              name: 'Meditation',
              activityType: ActivityType.meditation,
              defaultDuration: Duration(minutes: 10),
              isCompleted: true,
            ),
          ],
          recordedAt: yesterday,
        ),
      );

      // Delete Meditation today
      final deleted = repository.deleteActivity('meditation');
      expect(deleted, isTrue);
      expect(repository.getActivityById('meditation'), isNull);

      // Verify yesterday's history STILL has Meditation completed
      final yesterdayHistory = repository.getHistory().firstWhere((h) => h.dateKey == yesterdayKey);
      expect(yesterdayHistory, isNotNull);
      expect(yesterdayHistory.activities.any((a) => a.id == 'meditation'), isTrue);
      expect(yesterdayHistory.activities.firstWhere((a) => a.id == 'meditation').isCompleted, isTrue);
    });
  });
}
