import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/repositories/shared_preferences_activity_repository.dart';
import 'package:daily_routine/screens/home_screen.dart';
import 'package:daily_routine/screens/manage_activities_screen.dart';
import 'package:daily_routine/screens/edit_activity_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Guitar Built-in Status & Repository Protection', () {
    test('Activity.isBuiltIn is true for id == guitar or ActivityType.guitar', () {
      final guitarActivity = Activity(
        id: 'guitar',
        name: 'Guitar',
        activityType: ActivityType.guitar,
        defaultDuration: const Duration(minutes: 15),
      );
      expect(guitarActivity.isBuiltIn, isTrue);

      final customActivity = Activity(
        id: 'custom-1',
        name: 'Violin',
        activityType: ActivityType.general,
        defaultDuration: const Duration(minutes: 15),
      );
      expect(customActivity.isBuiltIn, isFalse);
    });

    test('InMemoryActivityRepository blocks deleting and disabling guitar', () {
      final repo = InMemoryActivityRepository(
        initialActivities: [
          const Activity(
            id: 'meditation',
            name: 'Meditation',
            activityType: ActivityType.meditation,
            defaultDuration: Duration(minutes: 10),
          ),
          const Activity(
            id: 'guitar',
            name: 'Guitar',
            activityType: ActivityType.guitar,
            defaultDuration: Duration(minutes: 15),
            isEnabled: true,
          ),
        ],
      );
      expect(repo.getActivityById('guitar'), isNotNull);
      expect(repo.getActivityById('guitar')!.isEnabled, isTrue);

      // Attempt to disable
      final disableResult = repo.setActivityEnabled('guitar', false);
      expect(disableResult, isFalse);
      expect(repo.getActivityById('guitar')!.isEnabled, isTrue);

      // Attempt to delete
      final deleteResult = repo.deleteActivity('guitar');
      expect(deleteResult, isFalse);
      expect(repo.getActivityById('guitar'), isNotNull);
    });

    test('SharedPreferencesActivityRepository guarantees guitar presence, enabled state, and blocks removal', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPreferencesActivityRepository(prefs);

      final guitar = repo.getActivityById('guitar');
      expect(guitar, isNotNull);
      expect(guitar!.isEnabled, isTrue);
      expect(guitar.activityType, ActivityType.guitar);

      // Attempt to disable
      final disableResult = repo.setActivityEnabled('guitar', false);
      expect(disableResult, isFalse);
      expect(repo.getActivityById('guitar')!.isEnabled, isTrue);

      // Attempt to delete
      final deleteResult = repo.deleteActivity('guitar');
      expect(deleteResult, isFalse);
      expect(repo.getActivityById('guitar'), isNotNull);
    });
  });

  group('Guitar Protection across UI screens', () {
    late InMemoryActivityRepository repository;

    setUp(() {
      repository = InMemoryActivityRepository(
        initialActivities: [
          const Activity(
            id: 'meditation',
            name: 'Meditation',
            activityType: ActivityType.meditation,
            defaultDuration: Duration(minutes: 10),
          ),
          const Activity(
            id: 'guitar',
            name: 'Guitar',
            activityType: ActivityType.guitar,
            defaultDuration: Duration(minutes: 15),
            isEnabled: true,
          ),
        ],
      );
    });

    testWidgets('HomeScreen: toggling guitar switch shows SnackBar and prevents disable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      final guitarCard = find.byKey(const Key('activity_card_guitar'));
      expect(guitarCard, findsOneWidget);

      final guitarSwitch = find.descendant(
        of: guitarCard,
        matching: find.byType(Switch),
      );
      expect(guitarSwitch, findsOneWidget);

      // Tap the switch to try to disable guitar
      await tester.tap(guitarSwitch);
      await tester.pumpAndSettle();

      expect(
        find.text('Guitar is a permanent built-in activity and cannot be disabled.'),
        findsOneWidget,
      );
      expect(repository.getActivityById('guitar')!.isEnabled, isTrue);
    });

    testWidgets('ManageActivitiesScreen: guitar delete button is hidden and disable is blocked', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ManageActivitiesScreen(repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      // Custom activities have delete button, but guitar must NOT have delete button
      final guitarItem = find.byKey(const Key('manage_activity_card_guitar'));
      expect(guitarItem, findsOneWidget);

      final guitarDeleteBtn = find.descendant(
        of: guitarItem,
        matching: find.byKey(const Key('delete_activity_button_guitar')),
      );
      expect(guitarDeleteBtn, findsNothing);

      // Toggling switch on guitar item shows warning SnackBar
      final guitarSwitch = find.descendant(
        of: guitarItem,
        matching: find.byKey(const Key('manage_toggle_switch_guitar')),
      );
      expect(guitarSwitch, findsOneWidget);

      await tester.tap(guitarSwitch);
      await tester.pumpAndSettle();

      expect(
        find.text('Guitar is a permanent built-in activity and cannot be disabled.'),
        findsOneWidget,
      );
      expect(repository.getActivityById('guitar')!.isEnabled, isTrue);
    });

    testWidgets('EditActivityScreen: guitar delete button is hidden and save preserves guitar properties', (tester) async {
      final guitar = repository.getActivityById('guitar')!;
      await tester.pumpWidget(
        MaterialApp(
          home: EditActivityScreen(
            activity: guitar,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Delete button must NOT be rendered for guitar
      expect(find.byKey(const Key('edit_delete_button')), findsNothing);

      // Save preserves guitar type and isEnabled: true
      await tester.tap(find.byKey(const Key('edit_save_button')));
      await tester.pumpAndSettle();

      final updatedGuitar = repository.getActivityById('guitar')!;
      expect(updatedGuitar.isEnabled, isTrue);
      expect(updatedGuitar.activityType, ActivityType.guitar);
    });
  });
}
