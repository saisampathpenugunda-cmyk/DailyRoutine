import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/repositories/shared_preferences_activity_repository.dart';
import 'package:daily_routine/screens/home_screen.dart';
import 'package:daily_routine/screens/meditation_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Activity Ordering — Repository Unit Tests', () {
    test('1. Default order is Meditation, Walking, Dumbbells', () {
      final repo = InMemoryActivityRepository();
      final order = repo.getEnabledActivityOrder();
      expect(order, ['meditation', 'walking', 'dumbbells']);

      final activities = repo.getActivities().where((a) => a.isEnabled).toList();
      expect(activities.map((a) => a.id).toList(), ['meditation', 'walking', 'dumbbells']);
    });

    test('2. Reordering enabled activities updates order correctly', () {
      final repo = InMemoryActivityRepository();
      // Move Dumbbells (index 2) to top (index 0)
      repo.reorderEnabledActivities(2, 0);

      expect(repo.getEnabledActivityOrder(), ['dumbbells', 'meditation', 'walking']);
      final activities = repo.getActivities().where((a) => a.isEnabled).toList();
      expect(activities.map((a) => a.id).toList(), ['dumbbells', 'meditation', 'walking']);

      // Move Dumbbells (index 0) to bottom (index 3 in Flutter callback terms)
      repo.reorderEnabledActivities(0, 3);
      expect(repo.getEnabledActivityOrder(), ['meditation', 'walking', 'dumbbells']);
    });

    test('3 & 4. Persists reordered activity order to SharedPreferences and restores on reload', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final repo1 = SharedPreferencesActivityRepository(prefs);
      expect(repo1.getEnabledActivityOrder(), ['meditation', 'walking', 'dumbbells', 'guitar']);

      // Reorder: Walking (1) to top (0)
      repo1.reorderEnabledActivities(1, 0);
      expect(repo1.getEnabledActivityOrder(), ['walking', 'meditation', 'dumbbells', 'guitar']);

      // Reload fresh repository instance from the same SharedPreferences
      final repo2 = SharedPreferencesActivityRepository(prefs);
      expect(repo2.getEnabledActivityOrder(), ['walking', 'meditation', 'dumbbells', 'guitar']);
      final activities = repo2.getActivities().where((a) => a.isEnabled).toList();
      expect(activities.map((a) => a.id).toList(), ['walking', 'meditation', 'dumbbells', 'guitar']);
    });

    test('5. Disabling an activity removes it from enabled ordering', () {
      final repo = InMemoryActivityRepository();
      repo.setActivityEnabled('walking', false);

      expect(repo.getEnabledActivityOrder(), ['meditation', 'dumbbells']);
      final enabled = repo.getActivities().where((a) => a.isEnabled).toList();
      expect(enabled.map((a) => a.id).toList(), ['meditation', 'dumbbells']);
    });

    test('6. Re-enabling a disabled activity ALWAYS appends it to the LAST position', () {
      final repo = InMemoryActivityRepository();
      // Reorder first so Dumbbells is at top: [dumbbells, meditation, walking]
      repo.reorderEnabledActivities(2, 0);
      expect(repo.getEnabledActivityOrder(), ['dumbbells', 'meditation', 'walking']);

      // Disable meditation (was in middle)
      repo.setActivityEnabled('meditation', false);
      expect(repo.getEnabledActivityOrder(), ['dumbbells', 'walking']);

      // Re-enable meditation: MUST append to the LAST position!
      repo.setActivityEnabled('meditation', true);
      expect(repo.getEnabledActivityOrder(), ['dumbbells', 'walking', 'meditation']);
    });

    test('7. Re-enabling an activity and then reordering works properly', () {
      final repo = InMemoryActivityRepository();
      repo.setActivityEnabled('meditation', false);
      expect(repo.getEnabledActivityOrder(), ['walking', 'dumbbells']);

      repo.setActivityEnabled('meditation', true);
      expect(repo.getEnabledActivityOrder(), ['walking', 'dumbbells', 'meditation']);

      // Reorder re-enabled meditation (index 2) to top (index 0)
      repo.reorderEnabledActivities(2, 0);
      expect(repo.getEnabledActivityOrder(), ['meditation', 'walking', 'dumbbells']);
    });

    test('8. Creating a new activity appends it to the LAST position', () {
      final repo = InMemoryActivityRepository();
      const newAct = Activity(
        id: 'reading',
        name: 'Reading',
        activityType: ActivityType.meditation,
        defaultDuration: Duration(minutes: 15),
      );

      repo.addActivity(newAct);
      expect(repo.getEnabledActivityOrder(), ['meditation', 'walking', 'dumbbells', 'reading']);
      final enabled = repo.getActivities().where((a) => a.isEnabled).toList();
      expect(enabled.map((a) => a.id).toList(), ['meditation', 'walking', 'dumbbells', 'reading']);
    });

    test('9. Deleting an activity removes it completely from ordering without stale entries', () {
      final repo = InMemoryActivityRepository();
      expect(repo.getEnabledActivityOrder(), ['meditation', 'walking', 'dumbbells']);

      repo.deleteActivity('walking');
      expect(repo.getEnabledActivityOrder(), ['meditation', 'dumbbells']);
      expect(repo.getActivityById('walking'), isNull);

      final enabled = repo.getActivities().where((a) => a.isEnabled).toList();
      expect(enabled.map((a) => a.id).toList(), ['meditation', 'dumbbells']);
    });

    test('10. Repeated disable/enable operations maintain clean ordering without duplicates', () {
      final repo = InMemoryActivityRepository();
      for (int i = 0; i < 5; i++) {
        repo.setActivityEnabled('meditation', false);
        repo.setActivityEnabled('meditation', true);
      }
      expect(repo.getEnabledActivityOrder(), ['walking', 'dumbbells', 'meditation']);
      expect(repo.getEnabledActivityOrder().toSet().length, repo.getEnabledActivityOrder().length);
    });

    test('11. Repeated reordering does not produce duplicate activities or lose items', () {
      final repo = InMemoryActivityRepository();
      for (int i = 0; i < 10; i++) {
        repo.reorderEnabledActivities(0, 3); // rotate first to end
      }
      expect(repo.getEnabledActivityOrder().length, 3);
      expect(repo.getEnabledActivityOrder().toSet(), {'meditation', 'walking', 'dumbbells'});
    });

    test('12. Progress calculations remain 100% identical before and after reordering', () {
      final repo = InMemoryActivityRepository();
      repo.toggleActivityCompletion('meditation');

      final enabledBefore = repo.getActivities().where((a) => a.isEnabled).toList();
      final completedBefore = enabledBefore.where((a) => a.isCompleted).length;
      final progressBefore = completedBefore / enabledBefore.length;

      // Reorder activities
      repo.reorderEnabledActivities(2, 0);

      final enabledAfter = repo.getActivities().where((a) => a.isEnabled).toList();
      final completedAfter = enabledAfter.where((a) => a.isCompleted).length;
      final progressAfter = completedAfter / enabledAfter.length;

      expect(progressBefore, progressAfter);
      expect(progressAfter, 1 / 3);
    });

    test('13. Historical records remain 100% untouched before and after reordering', () {
      final repo = InMemoryActivityRepository();
      repo.toggleActivityCompletion('walking');

      final historyBefore = repo.getHistory();
      expect(historyBefore.isNotEmpty, isTrue);
      final todaySnapshotBefore = historyBefore.first;
      final walkingBefore = todaySnapshotBefore.activities.firstWhere((a) => a.id == 'walking');
      expect(walkingBefore.isCompleted, isTrue);

      // Reorder activities
      repo.reorderEnabledActivities(1, 0);

      final historyAfter = repo.getHistory();
      final todaySnapshotAfter = historyAfter.first;
      final walkingAfter = todaySnapshotAfter.activities.firstWhere((a) => a.id == 'walking');
      expect(walkingAfter.isCompleted, isTrue);
    });
  });

  group('Activity Ordering — Home Screen Widget & Drag-and-Drop Tests', () {
    testWidgets('Home screen displays enabled activities in saved order', (tester) async {
      final repo = InMemoryActivityRepository();
      repo.reorderEnabledActivities(2, 0); // Dumbbells, Meditation, Walking

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      final meditationFinder = find.text('Meditation');
      final walkingFinder = find.text('Walking');
      final dumbbellsFinder = find.text('Dumbbells');

      expect(meditationFinder, findsOneWidget);
      expect(walkingFinder, findsOneWidget);
      expect(dumbbellsFinder, findsOneWidget);

      final dTop = tester.getTopLeft(dumbbellsFinder).dy;
      final mTop = tester.getTopLeft(meditationFinder).dy;
      final wTop = tester.getTopLeft(walkingFinder).dy;

      // Dumbbells should be above Meditation, which is above Walking
      expect(dTop < mTop, isTrue);
      expect(mTop < wTop, isTrue);
    });

    testWidgets('Disabled activities do not appear on Home screen', (tester) async {
      final repo = InMemoryActivityRepository();
      repo.setActivityEnabled('meditation', false);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Meditation'), findsNothing);
      expect(find.text('Disabled Activities'), findsNothing);
      expect(find.text('Walking'), findsOneWidget);
      expect(find.text('Dumbbells'), findsOneWidget);
    });

    testWidgets('Dragging card via long-press on HomeScreen updates order', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = InMemoryActivityRepository();
      expect(repo.getEnabledActivityOrder(), ['meditation', 'walking', 'dumbbells']);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      final firstCard = find.byKey(const ValueKey('activity_card_meditation'));
      final thirdCard = find.byKey(const ValueKey('activity_card_dumbbells'));
      expect(firstCard, findsOneWidget);
      expect(thirdCard, findsOneWidget);

      final thirdCenter = tester.getCenter(thirdCard);
      final firstCenter = tester.getCenter(firstCard);

      // Long-press on Dumbbells card to initiate drag
      final gesture = await tester.startGesture(thirdCenter);
      await tester.pump(const Duration(milliseconds: 650));

      // Drag well above the first card position
      final firstTopLeft = tester.getTopLeft(firstCard);
      await gesture.moveTo(Offset(firstCenter.dx, firstTopLeft.dy - 60));
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.up();
      await tester.pumpAndSettle();

      // Order in repository should now have dumbbells at the top
      expect(repo.getEnabledActivityOrder(), ['dumbbells', 'meditation', 'walking']);
    });

    testWidgets('Tapping card opens detail screen while long-press drags', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = InMemoryActivityRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Normal tap opens Meditation screen
      await tester.tap(find.text('Meditation'));
      await tester.pumpAndSettle();

      expect(find.byType(MeditationScreen), findsOneWidget);
    });

    testWidgets('Tapping checkbox on card still toggles completion', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = InMemoryActivityRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.getActivityById('meditation')!.isCompleted, isFalse);
      final meditationCard = find.byKey(const ValueKey('activity_card_meditation'));
      final checkbox = find.descendant(of: meditationCard, matching: find.byType(Checkbox));
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      expect(repo.getActivityById('meditation')!.isCompleted, isTrue);
    });

    testWidgets('Zero enabled activities renders clean empty state without crash', (tester) async {
      final repo = InMemoryActivityRepository();
      repo.setActivityEnabled('meditation', false);
      repo.setActivityEnabled('walking', false);
      repo.setActivityEnabled('dumbbells', false);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All activities are disabled'), findsOneWidget);
      expect(find.byType(ReorderableListView), findsNothing);
    });

    testWidgets('One enabled activity renders cleanly and cannot drag out of bounds', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = InMemoryActivityRepository();
      repo.setActivityEnabled('walking', false);
      repo.setActivityEnabled('dumbbells', false);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Meditation'), findsOneWidget);
      expect(find.byType(ReorderableListView), findsOneWidget);

      final medCenter = tester.getCenter(find.text('Meditation'));
      final gesture = await tester.startGesture(medCenter);
      await tester.pump(const Duration(milliseconds: 650));
      await gesture.moveTo(Offset(medCenter.dx, medCenter.dy + 100));
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(repo.getEnabledActivityOrder(), ['meditation']);
    });
  });
}
