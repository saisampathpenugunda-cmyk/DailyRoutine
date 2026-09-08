import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/screens/reminder_settings_screen.dart';
import 'package:daily_routine/services/notification_service.dart';

void main() {
  group('ReminderSettingsScreen Widget Tests', () {
    testWidgets('Renders all 3 activity reminder cards with main and backup switches', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final notificationService = InMemoryNotificationService();
      final repo = InMemoryActivityRepository(notificationService: notificationService);

      await tester.pumpWidget(
        MaterialApp(
          home: ReminderSettingsScreen(
            repository: repo,
            notificationService: notificationService,
          ),
        ),
      );

      // Verify Screen Title
      expect(find.text('Reminders'), findsOneWidget);

      // Verify 3 Activities rendered
      expect(find.text('Meditation'), findsOneWidget);
      expect(find.text('Walking'), findsOneWidget);
      expect(find.text('Dumbbells'), findsOneWidget);

      // Verify Main Reminder Times
      expect(find.text('8:00 AM'), findsOneWidget); // Meditation default
      expect(find.text('5:00 PM'), findsOneWidget); // Walking default
      expect(find.text('7:00 PM'), findsOneWidget); // Dumbbells default

      // Verify Main and Backup labels
      expect(find.text('Main Reminder'), findsNWidgets(3));
      expect(find.text('Backup Reminder'), findsNWidgets(3));
    });

    testWidgets('Toggling backup reminder enables backup time chip', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final notificationService = InMemoryNotificationService();
      final repo = InMemoryActivityRepository(notificationService: notificationService);

      await tester.pumpWidget(
        MaterialApp(
          home: ReminderSettingsScreen(
            repository: repo,
            notificationService: notificationService,
          ),
        ),
      );

      // Initially backup is disabled for meditation, so 8:30 AM is not visible
      expect(find.text('8:30 AM'), findsNothing);

      // Find backup switches (there are 3 backup switches, meditation is the second switch in the card)
      // The switches alternate: [Main, Backup, Main, Backup, Main, Backup]
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(6));

      // Tap meditation backup switch (index 1)
      await tester.tap(switches.at(1));
      await tester.pumpAndSettle();

      // Now backup time chip is displayed
      expect(find.text('8:30 AM'), findsOneWidget);

      // Verify repository updated
      final config = repo.getReminderConfig('meditation');
      expect(config.isBackupEnabled, isTrue);
    });

    testWidgets('Shows cancelled badge when activity is already completed', (
      WidgetTester tester,
    ) async {
      final notificationService = InMemoryNotificationService();
      final repo = InMemoryActivityRepository(notificationService: notificationService);
      repo.setActivityCompletion('meditation', isCompleted: true);

      await tester.pumpWidget(
        MaterialApp(
          home: ReminderSettingsScreen(
            repository: repo,
            notificationService: notificationService,
          ),
        ),
      );

      expect(find.text("Today's alerts cancelled (completed)"), findsOneWidget);
    });

    testWidgets('Shows cancelled badge when activity is skipped', (
      WidgetTester tester,
    ) async {
      final notificationService = InMemoryNotificationService();
      final repo = InMemoryActivityRepository(notificationService: notificationService);
      repo.setActivitySkipped('walking', isSkipped: true);

      await tester.pumpWidget(
        MaterialApp(
          home: ReminderSettingsScreen(
            repository: repo,
            notificationService: notificationService,
          ),
        ),
      );

      expect(find.text("Today's alerts cancelled (skipped)"), findsOneWidget);
    });
  });
}
