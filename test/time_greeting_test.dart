import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/controllers/user_profile_controller.dart';
import 'package:daily_routine/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeScreen.getTimeBasedGreeting pure logic & boundaries', () {
    test('5:00 AM to 11:59 AM returns Good Morning, [name]!', () {
      // 5:00 AM
      expect(
        HomeScreen.getTimeBasedGreeting('Sampath', time: DateTime(2026, 9, 11, 5, 0)),
        'Good Morning, Sampath!',
      );
      // 8:30 AM
      expect(
        HomeScreen.getTimeBasedGreeting('Sai', time: DateTime(2026, 9, 11, 8, 30)),
        'Good Morning, Sai!',
      );
      // 11:59 AM
      expect(
        HomeScreen.getTimeBasedGreeting('Alex', time: DateTime(2026, 9, 11, 11, 59, 59)),
        'Good Morning, Alex!',
      );
    });

    test('12:00 PM to 4:59 PM returns Good Afternoon, [name]!', () {
      // 12:00 PM
      expect(
        HomeScreen.getTimeBasedGreeting('Sampath', time: DateTime(2026, 9, 11, 12, 0)),
        'Good Afternoon, Sampath!',
      );
      // 2:30 PM
      expect(
        HomeScreen.getTimeBasedGreeting('Sai', time: DateTime(2026, 9, 11, 14, 30)),
        'Good Afternoon, Sai!',
      );
      // 4:59 PM
      expect(
        HomeScreen.getTimeBasedGreeting('Alex', time: DateTime(2026, 9, 11, 16, 59, 59)),
        'Good Afternoon, Alex!',
      );
    });

    test('5:00 PM to 8:59 PM returns Good Evening, [name]!', () {
      // 5:00 PM
      expect(
        HomeScreen.getTimeBasedGreeting('Sampath', time: DateTime(2026, 9, 11, 17, 0)),
        'Good Evening, Sampath!',
      );
      // 7:00 PM
      expect(
        HomeScreen.getTimeBasedGreeting('Sai', time: DateTime(2026, 9, 11, 19, 0)),
        'Good Evening, Sai!',
      );
      // 8:59 PM
      expect(
        HomeScreen.getTimeBasedGreeting('Alex', time: DateTime(2026, 9, 11, 20, 59, 59)),
        'Good Evening, Alex!',
      );
    });

    test('9:00 PM to 4:59 AM returns Good Night, [name]!', () {
      // 9:00 PM
      expect(
        HomeScreen.getTimeBasedGreeting('Sampath', time: DateTime(2026, 9, 11, 21, 0)),
        'Good Night, Sampath!',
      );
      // 11:30 PM
      expect(
        HomeScreen.getTimeBasedGreeting('Sai', time: DateTime(2026, 9, 11, 23, 30)),
        'Good Night, Sai!',
      );
      // Midnight (12:00 AM)
      expect(
        HomeScreen.getTimeBasedGreeting('Alex', time: DateTime(2026, 9, 11, 0, 0)),
        'Good Night, Alex!',
      );
      // 3:15 AM
      expect(
        HomeScreen.getTimeBasedGreeting('Chris', time: DateTime(2026, 9, 11, 3, 15)),
        'Good Night, Chris!',
      );
      // 4:59 AM
      expect(
        HomeScreen.getTimeBasedGreeting('Dana', time: DateTime(2026, 9, 11, 4, 59, 59)),
        'Good Night, Dana!',
      );
    });

    test('boundary test: 4:59:59 AM (Night) vs 5:00:00 AM (Morning)', () {
      final night = DateTime(2026, 9, 11, 4, 59, 59);
      final morning = DateTime(2026, 9, 11, 5, 0, 0);

      expect(HomeScreen.getTimeBasedGreeting('User', time: night), 'Good Night, User!');
      expect(HomeScreen.getTimeBasedGreeting('User', time: morning), 'Good Morning, User!');
    });

    test('boundary test: 11:59:59 AM (Morning) vs 12:00:00 PM (Afternoon)', () {
      final morning = DateTime(2026, 9, 11, 11, 59, 59);
      final afternoon = DateTime(2026, 9, 11, 12, 0, 0);

      expect(HomeScreen.getTimeBasedGreeting('User', time: morning), 'Good Morning, User!');
      expect(HomeScreen.getTimeBasedGreeting('User', time: afternoon), 'Good Afternoon, User!');
    });

    test('boundary test: 4:59:59 PM (Afternoon) vs 5:00:00 PM (Evening)', () {
      final afternoon = DateTime(2026, 9, 11, 16, 59, 59);
      final evening = DateTime(2026, 9, 11, 17, 0, 0);

      expect(HomeScreen.getTimeBasedGreeting('User', time: afternoon), 'Good Afternoon, User!');
      expect(HomeScreen.getTimeBasedGreeting('User', time: evening), 'Good Evening, User!');
    });

    test('boundary test: 8:59:59 PM (Evening) vs 9:00:00 PM (Night)', () {
      final evening = DateTime(2026, 9, 11, 20, 59, 59);
      final night = DateTime(2026, 9, 11, 21, 0, 0);

      expect(HomeScreen.getTimeBasedGreeting('User', time: evening), 'Good Evening, User!');
      expect(HomeScreen.getTimeBasedGreeting('User', time: night), 'Good Night, User!');
    });
  });

  group('HomeScreen Greeting Widget rendering & dynamic updates', () {
    late InMemoryActivityRepository repository;
    late UserProfileController profileController;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      profileController = UserProfileController('Sampath', prefs);
      repository = InMemoryActivityRepository();
    });

    testWidgets('renders Morning greeting in the morning', (tester) async {
      final morningTime = DateTime(2026, 9, 11, 9, 0);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            repository: repository,
            userProfileController: profileController,
            currentTime: morningTime,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good Morning, Sampath!'), findsOneWidget);
    });

    testWidgets('renders Afternoon greeting in the afternoon', (tester) async {
      final afternoonTime = DateTime(2026, 9, 11, 14, 0);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            repository: repository,
            userProfileController: profileController,
            currentTime: afternoonTime,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good Afternoon, Sampath!'), findsOneWidget);
    });

    testWidgets('renders Evening greeting in the evening', (tester) async {
      final eveningTime = DateTime(2026, 9, 11, 19, 0);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            repository: repository,
            userProfileController: profileController,
            currentTime: eveningTime,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good Evening, Sampath!'), findsOneWidget);
    });

    testWidgets('renders Night greeting at night', (tester) async {
      final nightTime = DateTime(2026, 9, 11, 22, 0);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            repository: repository,
            userProfileController: profileController,
            currentTime: nightTime,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good Night, Sampath!'), findsOneWidget);
    });

    testWidgets('greeting updates dynamically when user profile name changes', (tester) async {
      final morningTime = DateTime(2026, 9, 11, 9, 0);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            repository: repository,
            userProfileController: profileController,
            currentTime: morningTime,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good Morning, Sampath!'), findsOneWidget);

      await profileController.setUserName('Sampath Kumar');
      await tester.pump();

      expect(find.text('Good Morning, Sampath Kumar!'), findsOneWidget);
      expect(find.text('Good Morning, Sampath!'), findsNothing);
    });

    testWidgets('changing name inside SettingsScreen dynamically updates greeting upon return to HomeScreen', (tester) async {
      final morningTime = DateTime(2026, 9, 11, 10, 0);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            repository: repository,
            userProfileController: profileController,
            currentTime: morningTime,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good Morning, Sampath!'), findsOneWidget);

      // Open Settings
      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();

      // Edit name to John
      await tester.tap(find.byKey(const Key('edit_name_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('name_text_field')), 'John');
      await tester.tap(find.byKey(const Key('save_name_button')));
      await tester.pumpAndSettle();

      expect(find.text('John'), findsOneWidget);

      // Return to Home
      await tester.tap(find.byKey(const Key('settings_back_button')));
      await tester.pumpAndSettle();

      // Verify Home greeting now displays John
      expect(find.text('Good Morning, John!'), findsOneWidget);
      expect(find.text('Good Morning, Sampath!'), findsNothing);
    });
  });
}
