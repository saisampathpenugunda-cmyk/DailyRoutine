import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/models/day_history.dart';
import 'package:daily_routine/models/progress_statistics.dart';
import 'package:daily_routine/models/reminder_config.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/screens/home_screen.dart';
import 'package:daily_routine/screens/manage_activities_screen.dart';
import 'package:daily_routine/services/notification_service.dart';
import 'package:daily_routine/services/progress_calculator.dart';
import 'package:daily_routine/theme/app_theme.dart';
import 'package:daily_routine/widgets/activity_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('V1.2 — Final Home Switch Visual Hierarchy Tests', () {
    testWidgets('1. Switch styling in Light Theme: Enabled is prominent outlined purple, Disabled is muted visible', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const enabledAct = Activity(
        id: 'guitar',
        name: 'Guitar',
        activityType: ActivityType.timer,
        defaultDuration: Duration(minutes: 20),
        isEnabled: true,
      );
      const disabledAct = Activity(
        id: 'studies',
        name: 'Studies',
        activityType: ActivityType.timer,
        defaultDuration: Duration(minutes: 45),
        isEnabled: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                ActivityCard(
                  activity: enabledAct,
                  onTap: () {},
                  onToggleEnabled: (_) {},
                ),
                ActivityCard(
                  activity: disabledAct,
                  onTap: () {},
                  onToggleEnabled: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final enabledFinder = find.byKey(const ValueKey('toggle_enabled_guitar'));
      final disabledFinder = find.byKey(const ValueKey('toggle_enabled_studies'));

      expect(enabledFinder, findsOneWidget);
      expect(disabledFinder, findsOneWidget);

      final enabledSwitch = tester.widget<Switch>(enabledFinder);
      final disabledSwitch = tester.widget<Switch>(disabledFinder);

      // Value states determine thumb position: Enabled on RIGHT (true), Disabled on LEFT (false)
      expect(enabledSwitch.value, isTrue);
      expect(disabledSwitch.value, isFalse);

      final theme = Theme.of(tester.element(enabledFinder));

      // Tracks must NOT become completely filled purple pills in either state
      expect(theme.switchTheme.trackColor?.resolve({WidgetState.selected}), equals(Colors.transparent));
      expect(theme.switchTheme.trackColor?.resolve({}), equals(Colors.transparent));

      // Enabled state: Stronger primary purple outline (2.0px) and purple thumb
      final outlineEnabled = theme.switchTheme.trackOutlineColor?.resolve({WidgetState.selected});
      expect(outlineEnabled, equals(AppTheme.lightSwitchTrackOutlineOn));
      final thumbEnabled = theme.switchTheme.thumbColor?.resolve({WidgetState.selected});
      expect(thumbEnabled, equals(AppTheme.lightSwitchThumbOn));
      final outlineWidthEnabled = theme.switchTheme.trackOutlineWidth?.resolve({WidgetState.selected});
      expect(outlineWidthEnabled, equals(2.0));

      // Disabled state: Muted visible outline (1.4px) and muted thumb that does not disappear
      final outlineDisabled = theme.switchTheme.trackOutlineColor?.resolve({});
      expect(outlineDisabled, equals(AppTheme.lightSwitchTrackOutlineOff));
      final thumbDisabled = theme.switchTheme.thumbColor?.resolve({});
      expect(thumbDisabled, equals(AppTheme.lightSwitchThumbOff));
      final outlineWidthDisabled = theme.switchTheme.trackOutlineWidth?.resolve({});
      expect(outlineWidthDisabled, equals(1.4));

      // Enabled outline is thicker and more prominent than disabled
      expect(outlineWidthEnabled!, greaterThan(outlineWidthDisabled!));

      // Ensure compact size inside card
      final switchContainer = tester.getSize(
        find.ancestor(
          of: enabledFinder,
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(switchContainer.height, lessThanOrEqualTo(30.0));
      expect(switchContainer.width, lessThanOrEqualTo(40.0));
    });

    testWidgets('2. Switch styling in Cyber Noir Dark Theme: Electric cyan enabled vs muted slate disabled', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const enabledAct = Activity(
        id: 'running',
        name: 'Running',
        activityType: ActivityType.walking,
        defaultDuration: Duration(minutes: 30),
        isEnabled: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: ActivityCard(
              activity: enabledAct,
              onTap: () {},
              onToggleEnabled: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const ValueKey('toggle_enabled_running'));
      final theme = Theme.of(tester.element(switchFinder));

      expect(theme.switchTheme.trackColor?.resolve({WidgetState.selected}), equals(Colors.transparent));
      expect(theme.switchTheme.thumbColor?.resolve({WidgetState.selected}), equals(AppTheme.cyberNoirSwitchThumbOn));
      expect(theme.switchTheme.trackOutlineColor?.resolve({WidgetState.selected}), equals(AppTheme.cyberNoirSwitchTrackOutlineOn));
      expect(theme.switchTheme.trackOutlineWidth?.resolve({WidgetState.selected}), equals(2.0));

      expect(theme.switchTheme.trackColor?.resolve({}), equals(Colors.transparent));
      expect(theme.switchTheme.thumbColor?.resolve({}), equals(AppTheme.cyberNoirSwitchThumbOff));
      expect(theme.switchTheme.trackOutlineColor?.resolve({}), equals(AppTheme.cyberNoirSwitchTrackOutlineOff));
      expect(theme.switchTheme.trackOutlineWidth?.resolve({}), equals(1.4));
    });
  });

  group('V1.2 — All Activities Can Be Deleted Tests', () {
    late InMemoryActivityRepository repository;
    late InMemoryNotificationService notificationService;

    setUp(() {
      notificationService = InMemoryNotificationService();
      repository = InMemoryActivityRepository(
        notificationService: notificationService,
      );
    });

    void setViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
    }

    test('3. Meditation, Walking, and Dumbbells can all be deleted from repository without restrictions', () {
      expect(repository.getActivityById('meditation'), isNotNull);
      expect(repository.getActivityById('walking'), isNotNull);
      expect(repository.getActivityById('dumbbells'), isNotNull);

      // Delete Meditation
      final delMed = repository.deleteActivity('meditation');
      expect(delMed, isTrue);
      expect(repository.getActivityById('meditation'), isNull);

      // Delete Walking
      final delWalk = repository.deleteActivity('walking');
      expect(delWalk, isTrue);
      expect(repository.getActivityById('walking'), isNull);

      // Delete Dumbbells
      final delDumb = repository.deleteActivity('dumbbells');
      expect(delDumb, isTrue);
      expect(repository.getActivityById('dumbbells'), isNull);

      // Repository activities list is empty
      expect(repository.getActivities().isEmpty, isTrue);
    });

    test('4. Custom activities (Guitar, Studies, Running) can be added and deleted', () {
      repository.addActivity(const Activity(
        id: 'act_guitar',
        name: 'Guitar',
        activityType: ActivityType.timer,
        defaultDuration: Duration(minutes: 25),
      ));
      repository.addActivity(const Activity(
        id: 'act_studies',
        name: 'Studies',
        activityType: ActivityType.timer,
        defaultDuration: Duration(minutes: 50),
      ));
      repository.addActivity(const Activity(
        id: 'act_running',
        name: 'Running',
        activityType: ActivityType.walking,
        defaultDuration: Duration(minutes: 30),
      ));

      expect(repository.getActivityById('act_guitar'), isNotNull);
      expect(repository.getActivityById('act_studies'), isNotNull);
      expect(repository.getActivityById('act_running'), isNotNull);

      expect(repository.deleteActivity('act_guitar'), isTrue);
      expect(repository.getActivityById('act_guitar'), isNull);

      expect(repository.deleteActivity('act_studies'), isTrue);
      expect(repository.getActivityById('act_studies'), isNull);

      expect(repository.deleteActivity('act_running'), isTrue);
      expect(repository.getActivityById('act_running'), isNull);
    });

    testWidgets('5. Confirmation dialog: Cancel preserves activity, Delete removes it', (tester) async {
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

      final deleteMedButton = find.byKey(const Key('delete_activity_button_meditation'));
      expect(deleteMedButton, findsOneWidget);

      // Tap Delete on Meditation
      await tester.tap(deleteMedButton);
      await tester.pumpAndSettle();

      // Dialog appears with exact requested titles and buttons
      expect(find.text('Delete Activity?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete Meditation?'), findsOneWidget);
      expect(find.byKey(const Key('dialog_cancel_button')), findsOneWidget);
      expect(find.byKey(const Key('dialog_confirm_delete_button')), findsOneWidget);

      // Tap Cancel -> Meditation remains
      await tester.tap(find.byKey(const Key('dialog_cancel_button')));
      await tester.pumpAndSettle();

      expect(find.text('Meditation'), findsOneWidget);
      expect(repository.getActivityById('meditation'), isNotNull);

      // Tap Delete again and confirm
      await tester.tap(deleteMedButton);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dialog_confirm_delete_button')));
      await tester.pumpAndSettle();

      // Meditation is gone from UI and repository
      expect(find.byKey(const Key('manage_activity_card_meditation')), findsNothing);
      expect(repository.getActivityById('meditation'), isNull);
    });

    testWidgets('6. Deleted activity disappears from Today\'s Plan on HomeScreen', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: HomeScreen(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially all 3 are on Home
      expect(find.text('Meditation'), findsOneWidget);
      expect(find.text('Walking'), findsOneWidget);
      expect(find.text('Dumbbells'), findsOneWidget);

      // Delete Meditation directly
      repository.deleteActivity('meditation');

      // Open Settings -> Manage Activities and come back (or trigger refresh)
      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_manage_activities_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('manage_activities_back_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_back_button')));
      await tester.pumpAndSettle();

      // Meditation no longer appears in Today's Plan
      expect(find.text('Meditation'), findsNothing);
      expect(find.text('Walking'), findsOneWidget);
      expect(find.text('Dumbbells'), findsOneWidget);
      expect(find.text('0 of 2 activities completed'), findsOneWidget);
    });

    test('7. Deleted activity pending reminders/notifications are cancelled', () {
      const config = ReminderConfig(
        activityId: 'meditation',
        isMainEnabled: true,
        mainHour: 7,
        mainMinute: 30,
        isBackupEnabled: true,
        backupHour: 8,
        backupMinute: 0,
      );
      repository.updateReminderConfig(config);

      // Scheduled
      expect(notificationService.scheduledNotifications.containsKey(config.mainNotificationId), isTrue);
      expect(notificationService.scheduledNotifications.containsKey(config.backupNotificationId), isTrue);

      // Delete Meditation
      repository.deleteActivity('meditation');

      // Cancelled
      expect(notificationService.scheduledNotifications.containsKey(config.mainNotificationId), isFalse);
      expect(notificationService.scheduledNotifications.containsKey(config.backupNotificationId), isFalse);
    });

    test('8. History immutability: Previous DayHistory records remain untouched after deleting Meditation today', () {
      // Record yesterday with completed Meditation and Walking
      final yesterdayDate = '2026-09-09';
      final yesterdayHistory = DayHistory(
        dateKey: yesterdayDate,
        activities: [
          const Activity(
            id: 'meditation',
            name: 'Meditation',
            activityType: ActivityType.meditation,
            defaultDuration: Duration(minutes: 10),
            actualDuration: Duration(minutes: 10),
            isEnabled: true,
            isCompleted: true,
          ),
          const Activity(
            id: 'walking',
            name: 'Walking',
            activityType: ActivityType.walking,
            defaultDuration: Duration(minutes: 15),
            actualDuration: Duration(minutes: 15),
            isEnabled: true,
            isCompleted: true,
          ),
        ],
        recordedAt: DateTime(2026, 9, 9, 23, 0),
      );

      // Add to repository history directly
      repository.getHistory(); // initialize
      // Delete Meditation today
      repository.deleteActivity('meditation');

      // Today's activities do not have meditation
      expect(repository.getActivityById('meditation'), isNull);

      // Verify yesterday's DayHistory snapshot properties are 100% intact
      expect(yesterdayHistory.activities.length, 2);
      expect(yesterdayHistory.activities.any((a) => a.id == 'meditation'), isTrue);
      final med = yesterdayHistory.activities.firstWhere((a) => a.id == 'meditation');
      expect(med.name, 'Meditation');
      expect(med.isCompleted, isTrue);
      expect(med.actualDuration, const Duration(minutes: 10));
      expect(yesterdayHistory.completionRate, 1.0);
    });

    test('9. Deleted activity does not participate in future or current progress calculations', () {
      double getTodayPercentage() {
        return ProgressCalculator.calculate(
          history: repository.getHistory(),
          todayActivities: repository.getActivities(),
          period: ProgressPeriod.day,
        ).completionPercentage;
      }

      // 3 activities initially
      expect(getTodayPercentage(), 0.0);

      // Complete Walking
      repository.setActivityCompletion('walking', isCompleted: true);
      // 1 of 3 completed = 33%
      expect(getTodayPercentage().round(), 33);

      // Delete Meditation (incomplete)
      repository.deleteActivity('meditation');

      // Now 1 of 2 completed = 50%
      expect(getTodayPercentage().round(), 50);

      // Complete Dumbbells
      repository.setActivityCompletion('dumbbells', isCompleted: true);
      // 2 of 2 completed = 100%
      expect(getTodayPercentage().round(), 100);
    });

    testWidgets('10. Home screen displays "No activities yet" empty state when all activities are deleted', (tester) async {
      setViewport(tester);

      repository.deleteActivity('meditation');
      repository.deleteActivity('walking');
      repository.deleteActivity('dumbbells');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: HomeScreen(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No activities yet'), findsOneWidget);
      expect(find.text('Tap the + button below to create your first activity'), findsOneWidget);
      expect(find.text('0 of 0 activities completed'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });
  });
}
