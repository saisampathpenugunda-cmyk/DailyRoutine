import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/main.dart';
import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/screens/create_activity_screen.dart';
import 'package:daily_routine/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CreateActivityScreen & Add Activity From Home Tests', () {
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

    testWidgets('Home page displays "+" FAB at bottom right corner and opens CreateActivityScreen', (
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

      // Find the "+" FAB
      final fabFinder = find.byKey(const Key('add_activity_fab'));
      expect(fabFinder, findsOneWidget);

      final fabWidget = tester.widget<FloatingActionButton>(fabFinder);
      expect(fabWidget.shape, isA<CircleBorder>());
      expect(find.descendant(of: fabFinder, matching: find.byIcon(Icons.add)), findsOneWidget);

      // Tap the FAB to open CreateActivityScreen
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      expect(find.byType(CreateActivityScreen), findsOneWidget);
      expect(find.text('Create Activity'), findsOneWidget);
    });

    testWidgets('CreateActivityScreen renders all required labels, fields, and action buttons', (
      WidgetTester tester,
    ) async {
      setViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: CreateActivityScreen(repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      // Labels
      expect(find.text('Activity Name'), findsOneWidget);
      expect(find.text('Activity Type'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('Main Reminder — Optional'), findsOneWidget);
      expect(find.text('Backup Reminder — Optional'), findsOneWidget);

      // Verify "Optional" is explicitly visible
      expect(find.textContaining('Optional'), findsWidgets);

      // Activity types
      expect(find.text('Timer'), findsOneWidget);
      expect(find.text('Workout'), findsOneWidget);

      // Input fields
      expect(find.byKey(const Key('activity_name_input')), findsOneWidget);
      expect(find.byKey(const Key('activity_duration_input')), findsOneWidget);

      // Reminder tiles
      expect(find.byKey(const Key('main_reminder_tile')), findsOneWidget);
      expect(find.byKey(const Key('backup_reminder_tile')), findsOneWidget);

      // Action buttons
      expect(find.byKey(const Key('cancel_button')), findsOneWidget);
      expect(find.byKey(const Key('create_button')), findsOneWidget);
    });

    testWidgets('Validates required fields: empty name and invalid duration produce errors', (
      WidgetTester tester,
    ) async {
      setViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: CreateActivityScreen(repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Create with empty fields
      await tester.ensureVisible(find.byKey(const Key('create_button')));
      await tester.tap(find.byKey(const Key('create_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter an activity name'), findsOneWidget);
      expect(find.text('Duration is required'), findsOneWidget);

      // Enter valid name, but invalid duration "0"
      await tester.enterText(find.byKey(const Key('activity_name_input')), 'Yoga');
      await tester.enterText(find.byKey(const Key('activity_duration_input')), '0');
      await tester.ensureVisible(find.byKey(const Key('create_button')));
      await tester.tap(find.byKey(const Key('create_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter an activity name'), findsNothing);
      expect(find.text('Please enter a valid duration in minutes'), findsOneWidget);

      // Enter negative duration
      await tester.enterText(find.byKey(const Key('activity_duration_input')), '-10');
      await tester.ensureVisible(find.byKey(const Key('create_button')));
      await tester.tap(find.byKey(const Key('create_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid duration in minutes'), findsOneWidget);
    });

    testWidgets('Cancel button dismisses screen without adding any activity', (
      WidgetTester tester,
    ) async {
      setViewport(tester);
      final initialCount = repository.getActivities().length;

      await tester.pumpWidget(
        DailyRoutineApp(
          repository: repository,
          notificationService: notificationService,
        ),
      );
      await tester.pumpAndSettle();

      // Open CreateActivityScreen
      await tester.tap(find.byKey(const Key('add_activity_fab')));
      await tester.pumpAndSettle();

      // Type some data
      await tester.enterText(find.byKey(const Key('activity_name_input')), 'Reading');
      await tester.enterText(find.byKey(const Key('activity_duration_input')), '20');

      // Tap Cancel
      await tester.ensureVisible(find.byKey(const Key('cancel_button')));
      await tester.tap(find.byKey(const Key('cancel_button')));
      await tester.pumpAndSettle();

      // Back on Home page, count unchanged
      expect(find.byType(CreateActivityScreen), findsNothing);
      expect(repository.getActivities().length, initialCount);
      expect(find.text('Reading'), findsNothing);
    });

    testWidgets('Creating a Timer activity adds it to repository and immediately displays on Home page', (
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

      // Initially 3 activities
      expect(repository.getActivities().length, 3);
      expect(find.text('4 of 4 activities completed'), findsNothing);

      // Tap "+" FAB
      await tester.tap(find.byKey(const Key('add_activity_fab')));
      await tester.pumpAndSettle();

      // Enter details for a Timer activity
      await tester.enterText(find.byKey(const Key('activity_name_input')), 'Study Flutter');
      await tester.tap(find.byKey(const Key('activity_type_timer')));
      await tester.enterText(find.byKey(const Key('activity_duration_input')), '45');

      // Tap Create
      await tester.ensureVisible(find.byKey(const Key('create_button')));
      await tester.tap(find.byKey(const Key('create_button')));
      await tester.pumpAndSettle();

      // Screen dismissed and back on Home page
      expect(find.byType(CreateActivityScreen), findsNothing);

      // Newly created activity immediately appears on Home page
      expect(find.text('Study Flutter'), findsOneWidget);
      expect(find.text('45 min'), findsOneWidget);

      // Verify in repository
      final activities = repository.getActivities();
      expect(activities.length, 4);
      final created = activities.firstWhere((a) => a.name == 'Study Flutter');
      expect(created.activityType, ActivityType.timer);
      expect(created.defaultDuration, const Duration(minutes: 45));
      expect(created.isCompleted, isFalse);

      // No notifications were scheduled since no reminder was selected
      expect(notificationService.scheduledNotifications.containsKey(created.id.hashCode), isFalse);
    });

    testWidgets('Creating a Workout activity adds it to repository and immediately displays on Home page', (
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

      // Tap "+" FAB
      await tester.tap(find.byKey(const Key('add_activity_fab')));
      await tester.pumpAndSettle();

      // Enter details for a Workout activity
      await tester.enterText(find.byKey(const Key('activity_name_input')), 'Calisthenics');
      await tester.tap(find.byKey(const Key('activity_type_workout')));
      await tester.enterText(find.byKey(const Key('activity_duration_input')), '25');

      // Tap Create
      await tester.ensureVisible(find.byKey(const Key('create_button')));
      await tester.tap(find.byKey(const Key('create_button')));
      await tester.pumpAndSettle();

      // Newly created workout appears on Home page
      expect(find.text('Calisthenics'), findsOneWidget);
      expect(find.text('25 min'), findsOneWidget);

      final activities = repository.getActivities();
      final workout = activities.firstWhere((a) => a.name == 'Calisthenics');
      expect(workout.activityType, ActivityType.workout);
      expect(workout.defaultDuration, const Duration(minutes: 25));
    });

    testWidgets('Creating activity with reminders schedules notifications appropriately', (
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

      // Tap "+" FAB
      await tester.tap(find.byKey(const Key('add_activity_fab')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('activity_name_input')), 'Guitar Practice');
      await tester.enterText(find.byKey(const Key('activity_duration_input')), '30');

      // Tap Main Reminder tile to open time picker
      await tester.ensureVisible(find.byKey(const Key('main_reminder_tile')));
      await tester.tap(find.byKey(const Key('main_reminder_tile')));
      await tester.pumpAndSettle();

      // Confirm time in TimePicker dialog
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Verify selected time is shown
      expect(find.textContaining('AM'), findsOneWidget);

      // Tap Create
      await tester.ensureVisible(find.byKey(const Key('create_button')));
      await tester.tap(find.byKey(const Key('create_button')));
      await tester.pumpAndSettle();

      // Verify activity created
      final activities = repository.getActivities();
      final created = activities.firstWhere((a) => a.name == 'Guitar Practice');

      // Verify reminder config was created and scheduled
      final cfg = repository.getReminderConfig(created.id);
      expect(cfg.isMainEnabled, isTrue);
      expect(notificationService.scheduledNotifications.containsKey(cfg.mainNotificationId), isTrue);
    });
  });
}
