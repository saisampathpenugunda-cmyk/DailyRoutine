import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/models/day_history.dart';
import 'package:daily_routine/models/progress_statistics.dart';
import 'package:daily_routine/models/reminder_config.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/screens/home_screen.dart';
import 'package:daily_routine/screens/meditation_screen.dart';
import 'package:daily_routine/services/notification_service.dart';
import 'package:daily_routine/services/progress_calculator.dart';
import 'package:daily_routine/theme/app_theme.dart';
import 'package:daily_routine/widgets/activity_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('1. Activity Model & Serialization', () {
    test('Default isEnabled is true for newly created activity', () {
      const activity = Activity(
        id: 'test_act',
        name: 'Test Activity',
        activityType: ActivityType.timer,
        defaultDuration: Duration(minutes: 10),
      );
      expect(activity.isEnabled, isTrue);
    });

    test('JSON serialization and deserialization preserves isEnabled', () {
      const activity = Activity(
        id: 'test_act',
        name: 'Test Activity',
        activityType: ActivityType.timer,
        defaultDuration: Duration(minutes: 10),
        isEnabled: false,
      );

      final json = activity.toJson();
      expect(json['isEnabled'], isFalse);

      final restored = Activity.fromJson(json);
      expect(restored.isEnabled, isFalse);
    });

    test('Old JSON missing isEnabled defaults to true (backward compatibility)', () {
      final oldJson = {
        'id': 'meditation',
        'name': 'Meditation',
        'activityType': 'meditation',
        'defaultDurationMinutes': 10,
        'isCompleted': false,
      };

      final restored = Activity.fromJson(oldJson);
      expect(restored.isEnabled, isTrue);
    });
  });

  group('2. Progress Calculations & DayHistory', () {
    test('Progress metrics consider only enabled activities', () {
      final activities = [
        const Activity(
          id: 'meditation',
          name: 'Meditation',
          activityType: ActivityType.meditation,
          defaultDuration: Duration(minutes: 10),
          isEnabled: true,
          isCompleted: true,
        ),
        const Activity(
          id: 'walking',
          name: 'Walking',
          activityType: ActivityType.walking,
          defaultDuration: Duration(minutes: 15),
          isEnabled: true,
          isCompleted: false,
        ),
        const Activity(
          id: 'dumbbells',
          name: 'Dumbbells',
          activityType: ActivityType.dumbbells,
          defaultDuration: Duration(minutes: 20),
          isEnabled: false, // Disabled!
          isCompleted: false,
        ),
      ];

      final day = DayHistory(
        dateKey: '2026-09-10',
        activities: activities,
        recordedAt: DateTime(2026, 9, 10),
      );

      // 2 enabled, 1 completed -> 50%
      expect(day.enabledActivities.length, 2);
      expect(day.totalCount, 2);
      expect(day.completedCount, 1);
      expect(day.completionRate, 0.5);
    });

    test('Ratio tests: 3 enabled / 1 completed = 33%, 2 completed = 67%, 3 completed = 100%', () {
      // 3 enabled, 1 completed
      final day1 = DayHistory(
        dateKey: '2026-09-10',
        activities: [
          const Activity(id: 'a', name: 'A', activityType: ActivityType.timer, defaultDuration: Duration(minutes: 5), isEnabled: true, isCompleted: true),
          const Activity(id: 'b', name: 'B', activityType: ActivityType.timer, defaultDuration: Duration(minutes: 5), isEnabled: true, isCompleted: false),
          const Activity(id: 'c', name: 'C', activityType: ActivityType.timer, defaultDuration: Duration(minutes: 5), isEnabled: true, isCompleted: false),
        ],
        recordedAt: DateTime(2026, 9, 10),
      );
      expect((day1.completionRate * 100).round(), 33);

      // 3 enabled, 2 completed
      final day2 = DayHistory(
        dateKey: '2026-09-10',
        activities: [
          const Activity(id: 'a', name: 'A', activityType: ActivityType.timer, defaultDuration: Duration(minutes: 5), isEnabled: true, isCompleted: true),
          const Activity(id: 'b', name: 'B', activityType: ActivityType.timer, defaultDuration: Duration(minutes: 5), isEnabled: true, isCompleted: true),
          const Activity(id: 'c', name: 'C', activityType: ActivityType.timer, defaultDuration: Duration(minutes: 5), isEnabled: true, isCompleted: false),
        ],
        recordedAt: DateTime(2026, 9, 10),
      );
      expect((day2.completionRate * 100).round(), 67);

      // 3 enabled, 3 completed
      final day3 = DayHistory(
        dateKey: '2026-09-10',
        activities: [
          const Activity(id: 'a', name: 'A', activityType: ActivityType.timer, defaultDuration: Duration(minutes: 5), isEnabled: true, isCompleted: true),
          const Activity(id: 'b', name: 'B', activityType: ActivityType.timer, defaultDuration: Duration(minutes: 5), isEnabled: true, isCompleted: true),
          const Activity(id: 'c', name: 'C', activityType: ActivityType.timer, defaultDuration: Duration(minutes: 5), isEnabled: true, isCompleted: true),
        ],
        recordedAt: DateTime(2026, 9, 10),
      );
      expect((day3.completionRate * 100).round(), 100);
    });

    test('All activities disabled produces 0% without divide-by-zero error', () {
      final day = DayHistory(
        dateKey: '2026-09-10',
        activities: [
          const Activity(id: 'a', name: 'A', activityType: ActivityType.timer, defaultDuration: Duration(minutes: 5), isEnabled: false),
          const Activity(id: 'b', name: 'B', activityType: ActivityType.timer, defaultDuration: Duration(minutes: 5), isEnabled: false),
        ],
        recordedAt: DateTime(2026, 9, 10),
      );

      expect(day.totalCount, 0);
      expect(day.completedCount, 0);
      expect(day.completionRate, 0.0);
      expect(day.isAllCompleted, isFalse);

      final stats = ProgressCalculator.calculate(
        history: [day],
        todayActivities: day.activities,
        period: ProgressPeriod.day,
        now: DateTime(2026, 9, 10),
      );
      expect(stats.totalActivities, 0);
      expect(stats.completedCount, 0);
      expect(stats.skippedCount, 0);
      expect(stats.missedCount, 0);
    });

    test('Disabled activities are excluded from skipped and missed counts in ProgressCalculator', () {
      final day = DayHistory(
        dateKey: '2026-09-10',
        activities: [
          const Activity(id: 'a', name: 'A', activityType: ActivityType.timer, defaultDuration: Duration(minutes: 5), isEnabled: true, isCompleted: false, isSkipped: true),
          const Activity(id: 'b', name: 'B', activityType: ActivityType.timer, defaultDuration: Duration(minutes: 5), isEnabled: false, isCompleted: false, isSkipped: true), // disabled & skipped
          const Activity(id: 'c', name: 'C', activityType: ActivityType.timer, defaultDuration: Duration(minutes: 5), isEnabled: false, isCompleted: false), // disabled & missed
        ],
        recordedAt: DateTime(2026, 9, 10),
      );

      final stats = ProgressCalculator.calculate(
        history: [day],
        todayActivities: day.activities,
        period: ProgressPeriod.day,
        now: DateTime(2026, 9, 10),
      );

      // Only 'a' should be counted in skipped
      expect(stats.totalActivities, 1);
      expect(stats.skippedCount, 1);
      expect(stats.missedCount, 0);
    });

    test('Historical records remain immutable when enabling/disabling today', () {
      final pastDay = DayHistory(
        dateKey: '2026-09-09',
        activities: [
          const Activity(id: 'meditation', name: 'Meditation', activityType: ActivityType.meditation, defaultDuration: Duration(minutes: 10), isEnabled: true, isCompleted: true),
          const Activity(id: 'walking', name: 'Walking', activityType: ActivityType.walking, defaultDuration: Duration(minutes: 15), isEnabled: true, isCompleted: true),
        ],
        recordedAt: DateTime(2026, 9, 9),
      );

      final repo = InMemoryActivityRepository(
        initialHistory: [pastDay],
        now: () => DateTime(2026, 9, 10),
      );

      // Disable meditation today
      repo.setActivityEnabled('meditation', false);

      // Verify past history was NOT changed
      final history = repo.getHistory();
      final recordedPastDay = history.firstWhere((h) => h.dateKey == '2026-09-09');
      expect(recordedPastDay.activities.firstWhere((a) => a.id == 'meditation').isEnabled, isTrue);
      expect(recordedPastDay.completionRate, 1.0);
    });
  });

  group('3. Active Session Safety & Notifications', () {
    test('Cannot disable an activity with a running timer session', () {
      final repo = InMemoryActivityRepository();
      final timer = repo.getTimerController('meditation');
      timer.start();

      expect(repo.isActivityInProgress('meditation'), isTrue);

      final success = repo.setActivityEnabled('meditation', false);
      expect(success, isFalse);

      // Session must remain intact and running
      expect(repo.getActivityById('meditation')?.isEnabled, isTrue);
      expect(timer.isRunning, isTrue);
    });

    test('Cannot disable an activity with a paused timer session', () {
      final repo = InMemoryActivityRepository();
      final timer = repo.getTimerController('meditation');
      timer.start();
      timer.pause();

      expect(repo.isActivityInProgress('meditation'), isTrue);

      final success = repo.setActivityEnabled('meditation', false);
      expect(success, isFalse);

      expect(repo.getActivityById('meditation')?.isEnabled, isTrue);
      expect(timer.isPaused, isTrue);
    });

    test('Cannot disable a workout with sets recorded in progress', () {
      final repo = InMemoryActivityRepository();
      final act = repo.getActivityById('dumbbells')!;
      repo.updateActivity(act.copyWith(completedSetsReps: [10]));

      expect(repo.isActivityInProgress('dumbbells'), isTrue);

      final success = repo.setActivityEnabled('dumbbells', false);
      expect(success, isFalse);
      expect(repo.getActivityById('dumbbells')?.isEnabled, isTrue);
    });

    test('Can disable when session is unstarted or fully completed', () {
      final repo = InMemoryActivityRepository();
      expect(repo.isActivityInProgress('meditation'), isFalse);

      final success = repo.setActivityEnabled('meditation', false);
      expect(success, isTrue);
      expect(repo.getActivityById('meditation')?.isEnabled, isFalse);

      // Re-enable
      final reEnabled = repo.setActivityEnabled('meditation', true);
      expect(reEnabled, isTrue);
      expect(repo.getActivityById('meditation')?.isEnabled, isTrue);
    });

    test('Disabling activity cancels reminders and re-enabling restores reminders', () {
      final notifService = InMemoryNotificationService();
      final repo = InMemoryActivityRepository(
        notificationService: notifService,
      );

      // Configure reminder for meditation
      repo.updateReminderConfig(const ReminderConfig(
        activityId: 'meditation',
        isMainEnabled: true,
        mainHour: 8,
        mainMinute: 0,
        isBackupEnabled: false,
        backupHour: 8,
        backupMinute: 30,
      ));

      expect(notifService.scheduledNotifications.values.any((n) => n.activityId == 'meditation'), isTrue);

      // Disable meditation
      repo.setActivityEnabled('meditation', false);
      expect(notifService.scheduledNotifications.values.any((n) => n.activityId == 'meditation'), isFalse);

      // Re-enable meditation
      repo.setActivityEnabled('meditation', true);
      expect(notifService.scheduledNotifications.values.any((n) => n.activityId == 'meditation'), isTrue);
    });
  });

  group('4. UI & Widget Tests', () {
    testWidgets('ActivityCard displays Disabled badge and switch in OFF position when disabled', (tester) async {
      bool? toggledVal;
      const act = Activity(
        id: 'meditation',
        name: 'Meditation',
        activityType: ActivityType.meditation,
        defaultDuration: Duration(minutes: 10),
        isEnabled: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activity: act,
              onTap: () {},
              onToggleEnabled: (val) => toggledVal = val,
            ),
          ),
        ),
      );

      expect(find.text('Disabled'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);

      final switchWidget = tester.widget<Switch>(find.byKey(const ValueKey('toggle_enabled_meditation')));
      expect(switchWidget.value, isFalse);

      await tester.tap(find.byKey(const ValueKey('toggle_enabled_meditation')));
      expect(toggledVal, isTrue);
    });

    testWidgets('HomeScreen does not render disabled activities on Home', (tester) async {
      final repo = InMemoryActivityRepository();
      repo.setActivityEnabled('meditation', false);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Disabled Activities'), findsNothing);
      expect(find.text('Meditation'), findsNothing);
      expect(find.text('Walking'), findsOneWidget);
      expect(find.text('Dumbbells'), findsOneWidget);

      // Re-enabling meditation brings it back to Home
      repo.setActivityEnabled('meditation', true);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Meditation'), findsOneWidget);
      expect(find.text('Disabled Activities'), findsNothing);
    });

    testWidgets('HomeScreen shows clean empty state when all activities are disabled', (tester) async {
      final repo = InMemoryActivityRepository();
      repo.setActivityEnabled('meditation', false);
      repo.setActivityEnabled('walking', false);
      repo.setActivityEnabled('dumbbells', false);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All activities are disabled'), findsOneWidget);
      expect(find.text('0 of 0 activities completed'), findsOneWidget);
      expect(find.text('0% Done'), findsOneWidget);
      expect(find.text('Disabled Activities'), findsNothing);
    });

    testWidgets('Detail screens display Enable/Disable switch in AppBar', (tester) async {
      final repo = InMemoryActivityRepository();
      final act = repo.getActivityById('meditation')!;

      await tester.pumpWidget(
        MaterialApp(
          home: MeditationScreen(
            activity: act,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('detail_enable_switch')), findsOneWidget);
      expect(find.text('Enabled'), findsOneWidget);

      // Toggle off in AppBar
      await tester.tap(find.byKey(const Key('detail_enable_switch')));
      await tester.pumpAndSettle();

      expect(find.text('Disabled'), findsOneWidget);
      expect(repo.getActivityById('meditation')?.isEnabled, isFalse);
    });

    testWidgets('Detail screen blocks disable and shows snackbar when timer is active', (tester) async {
      final repo = InMemoryActivityRepository();
      final act = repo.getActivityById('meditation')!;

      await tester.pumpWidget(
        MaterialApp(
          home: MeditationScreen(
            activity: act,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start timer
      await tester.tap(find.byKey(const Key('start_button')));
      await tester.pump();

      // Try to toggle off
      await tester.tap(find.byKey(const Key('detail_enable_switch')));
      await tester.pump();

      expect(find.text('Cannot disable an activity with an active or paused session. Please finish or reset the session first.'), findsOneWidget);
      expect(repo.getActivityById('meditation')?.isEnabled, isTrue);
    });

    testWidgets('Home page ActivityCard switch styling in Light and Dark themes', (tester) async {
      const enabledAct = Activity(
        id: 'meditation',
        name: 'Meditation',
        activityType: ActivityType.meditation,
        defaultDuration: Duration(minutes: 10),
        isEnabled: true,
      );
      const disabledAct = Activity(
        id: 'walking',
        name: 'Walking',
        activityType: ActivityType.walking,
        defaultDuration: Duration(minutes: 15),
        isEnabled: false,
      );

      // 1. Light Theme
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

      final lightTheme = Theme.of(tester.element(find.byKey(const ValueKey('toggle_enabled_meditation'))));
      // Enabled switch: transparent track, primary purple thumb, primary purple outline
      expect(lightTheme.switchTheme.trackColor?.resolve({WidgetState.selected}), equals(Colors.transparent));
      expect(lightTheme.switchTheme.thumbColor?.resolve({WidgetState.selected}), equals(AppTheme.lightSwitchThumbOn));
      expect(lightTheme.switchTheme.trackOutlineColor?.resolve({WidgetState.selected}), equals(AppTheme.lightSwitchTrackOutlineOn));
      expect(lightTheme.switchTheme.trackOutlineWidth?.resolve({WidgetState.selected}), equals(2.0));

      // Disabled switch: transparent track, secondary purple thumb, muted outline
      expect(lightTheme.switchTheme.trackColor?.resolve({}), equals(Colors.transparent));
      expect(lightTheme.switchTheme.thumbColor?.resolve({}), equals(AppTheme.lightSwitchThumbOff));
      expect(lightTheme.switchTheme.trackOutlineColor?.resolve({}), equals(AppTheme.lightSwitchTrackOutlineOff));
      expect(lightTheme.switchTheme.trackOutlineWidth?.resolve({}), equals(1.4));

      // Ensure compact switch size inside card
      final switchContainer = tester.getSize(
        find.ancestor(
          of: find.byKey(const ValueKey('toggle_enabled_meditation')),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(switchContainer.height, lessThanOrEqualTo(30.0));
      expect(switchContainer.width, lessThanOrEqualTo(40.0));

      // 2. Dark Theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Column(
              children: [
                ActivityCard(
                  activity: enabledAct,
                  onTap: () {},
                  onToggleEnabled: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final darkTheme = Theme.of(tester.element(find.byKey(const ValueKey('toggle_enabled_meditation'))));
      expect(darkTheme.switchTheme.trackColor?.resolve({WidgetState.selected}), equals(Colors.transparent));
      expect(darkTheme.switchTheme.thumbColor?.resolve({WidgetState.selected}), equals(AppTheme.cyberNoirSwitchThumbOn));
      expect(darkTheme.switchTheme.trackOutlineColor?.resolve({WidgetState.selected}), equals(AppTheme.cyberNoirSwitchTrackOutlineOn));
      expect(darkTheme.switchTheme.trackOutlineWidth?.resolve({WidgetState.selected}), equals(2.0));
      expect(darkTheme.switchTheme.thumbColor?.resolve({}), equals(AppTheme.cyberNoirSwitchThumbOff));
      expect(darkTheme.switchTheme.trackOutlineColor?.resolve({}), equals(AppTheme.cyberNoirSwitchTrackOutlineOff));
      expect(darkTheme.switchTheme.trackOutlineWidth?.resolve({}), equals(1.4));
    });
  });
}

