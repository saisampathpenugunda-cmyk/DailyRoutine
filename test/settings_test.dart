import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_routine/controllers/user_profile_controller.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/screens/home_screen.dart';
import 'package:daily_routine/screens/settings_screen.dart';
import 'package:daily_routine/screens/manage_activities_screen.dart';
import 'package:daily_routine/screens/reminder_settings_screen.dart';
import 'package:daily_routine/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserProfileController Unit Tests', () {
    test('defaults to Sampath when SharedPreferences is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = await UserProfileController.init();
      expect(controller.userName, 'Sampath');
    });

    test('loads saved name from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        UserProfileController.prefsKey: 'Alexander',
      });
      final controller = await UserProfileController.init();
      expect(controller.userName, 'Alexander');
    });

    test('updates name, notifies listeners, and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = await UserProfileController.init(prefs);

      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.setUserName('Samantha');

      expect(controller.userName, 'Samantha');
      expect(notifyCount, 1);
      expect(prefs.getString(UserProfileController.prefsKey), 'Samantha');
    });

    test('ignores empty or whitespace-only name updates', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = await UserProfileController.init();

      await controller.setUserName('   ');
      expect(controller.userName, 'Sampath');

      await controller.setUserName('');
      expect(controller.userName, 'Sampath');
    });
  });

  group('ThemeController System Mode Support', () {
    test('ThemeController supports and persists ThemeMode.system', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = await ThemeController.init(prefs);

      expect(controller.value, ThemeMode.light);

      controller.setThemeMode(ThemeMode.system);
      expect(controller.value, ThemeMode.system);
      expect(prefs.getString(ThemeController.themeModeKey), 'system');

      controller.setThemeMode(ThemeMode.dark);
      expect(controller.value, ThemeMode.dark);
      expect(prefs.getString(ThemeController.themeModeKey), 'dark');

      final reloadedController = await ThemeController.init(prefs);
      expect(reloadedController.value, ThemeMode.dark);

      reloadedController.setThemeMode(ThemeMode.system);
      final restoredSystemController = await ThemeController.init(prefs);
      expect(restoredSystemController.value, ThemeMode.system);
    });
  });

  group('SettingsScreen & HomeScreen Integration Tests', () {
    late InMemoryActivityRepository repository;
    late ThemeController themeController;
    late UserProfileController userProfileController;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repository = InMemoryActivityRepository();
      themeController = ThemeController(ThemeMode.light);
      userProfileController = UserProfileController('Sampath');
    });

    Widget buildTestApp({Widget? home}) {
      return ThemeScope(
        controller: themeController,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.value,
          home: home ??
              HomeScreen(
                repository: repository,
                userProfileController: userProfileController,
                currentTime: DateTime(2026, 9, 11, 8, 0),
              ),
        ),
      );
    }

    testWidgets('Home screen displays default greeting with Sampath', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Good Morning, Sampath!'), findsOneWidget);
      expect(find.byKey(const Key('settings_button')), findsOneWidget);
    });

    testWidgets('Home greeting updates automatically when UserProfileController changes', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Good Morning, Sampath!'), findsOneWidget);

      await userProfileController.setUserName('Sai');
      await tester.pump();

      expect(find.text('Good Morning, Sai!'), findsOneWidget);
      expect(find.text('Good Morning, Sampath!'), findsNothing);
    });

    testWidgets('Tapping Settings button on Home navigates to SettingsScreen', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('SettingsScreen displays Profile section and allows editing name', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      userProfileController = UserProfileController('Sampath', prefs);

      await tester.pumpWidget(
        buildTestApp(
          home: SettingsScreen(
            repository: repository,
            userProfileController: userProfileController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Profile card content
      expect(find.text('PROFILE'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.byKey(const Key('profile_user_name')), findsOneWidget);
      expect(find.text('Sampath'), findsOneWidget);

      // Tap Edit Name button
      await tester.tap(find.byKey(const Key('edit_name_button')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile Name'), findsOneWidget);
      expect(find.byKey(const Key('name_text_field')), findsOneWidget);

      // Change name to "Vikram"
      await tester.enterText(find.byKey(const Key('name_text_field')), 'Vikram');
      await tester.tap(find.byKey(const Key('save_name_button')));
      await tester.pumpAndSettle();

      // Verify updated in UI and in persistence
      expect(find.text('Vikram'), findsOneWidget);
      expect(userProfileController.userName, 'Vikram');
      expect(prefs.getString(UserProfileController.prefsKey), 'Vikram');
    });

    testWidgets('Cancel button in edit name dialog does not update name', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          home: SettingsScreen(
            repository: repository,
            userProfileController: userProfileController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit_name_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('name_text_field')), 'Discarded');
      await tester.tap(find.byKey(const Key('cancel_name_button')));
      await tester.pumpAndSettle();

      expect(find.text('Sampath'), findsOneWidget);
      expect(find.text('Discarded'), findsNothing);
      expect(userProfileController.userName, 'Sampath');
    });

    testWidgets('Appearance section allows selecting Light, Dark, and System modes', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      themeController = ThemeController(ThemeMode.light, prefs);

      await tester.pumpWidget(
        ThemeScope(
          controller: themeController,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.value,
            home: SettingsScreen(
              repository: repository,
              userProfileController: userProfileController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.byKey(const Key('theme_option_light')), findsOneWidget);
      expect(find.byKey(const Key('theme_option_dark')), findsOneWidget);
      expect(find.byKey(const Key('theme_option_system')), findsOneWidget);

      // Select Dark mode
      await tester.tap(find.byKey(const Key('theme_option_dark')));
      await tester.pumpAndSettle();
      expect(themeController.value, ThemeMode.dark);
      expect(prefs.getString(ThemeController.themeModeKey), 'dark');

      // Select System mode
      await tester.tap(find.byKey(const Key('theme_option_system')));
      await tester.pumpAndSettle();
      expect(themeController.value, ThemeMode.system);
      expect(prefs.getString(ThemeController.themeModeKey), 'system');

      // Select Light mode
      await tester.tap(find.byKey(const Key('theme_option_light')));
      await tester.pumpAndSettle();
      expect(themeController.value, ThemeMode.light);
      expect(prefs.getString(ThemeController.themeModeKey), 'light');
    });

    testWidgets('Manage Activities button opens existing ManageActivitiesScreen', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          home: SettingsScreen(
            repository: repository,
            userProfileController: userProfileController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_manage_activities_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ManageActivitiesScreen), findsOneWidget);
      expect(find.text('Manage Activities'), findsWidgets);
    });

    testWidgets('Notifications button opens existing ReminderSettingsScreen', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          home: SettingsScreen(
            repository: repository,
            userProfileController: userProfileController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_notifications_button')),
        50.0,
      );
      await tester.tap(find.byKey(const Key('settings_notifications_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ReminderSettingsScreen), findsOneWidget);
      expect(find.text('Reminders'), findsWidgets);
    });

    testWidgets('About section displays app name, version 1.2.0, and description', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          home: SettingsScreen(
            repository: repository,
            userProfileController: userProfileController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('about_app_name')),
        50.0,
      );

      expect(find.text('ABOUT'), findsOneWidget);
      expect(find.byKey(const Key('about_app_name')), findsOneWidget);
      expect(find.text('DailyRoutine'), findsOneWidget);

      expect(find.byKey(const Key('about_version')), findsOneWidget);
      expect(find.text('Version 1.2.0'), findsOneWidget);

      expect(find.byKey(const Key('about_description')), findsOneWidget);
      expect(find.text('A simple daily routine tracker.'), findsOneWidget);
    });

    testWidgets('Settings back button pops back to previous screen', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Navigate to Settings
      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Tap back button
      await tester.tap(find.byKey(const Key('settings_back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Change name persists across simulated app restart', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      userProfileController = UserProfileController('Sampath', prefs);

      // 1. Launch app on Home screen
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.text('Good Morning, Sampath!'), findsOneWidget);

      // 2. Open Settings
      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();

      // 3. Edit name to 'Sampath Kumar'
      await tester.tap(find.byKey(const Key('edit_name_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('name_text_field')), 'Sampath Kumar');
      await tester.tap(find.byKey(const Key('save_name_button')));
      await tester.pumpAndSettle();

      expect(find.text('Sampath Kumar'), findsOneWidget);

      // 4. Return to Home and verify dynamic update
      await tester.tap(find.byKey(const Key('settings_back_button')));
      await tester.pumpAndSettle();
      expect(find.text('Good Morning, Sampath Kumar!'), findsOneWidget);

      // 5. Simulate cold app restart: re-initialize UserProfileController from prefs
      final restartedProfileController = await UserProfileController.init(prefs);
      expect(restartedProfileController.userName, 'Sampath Kumar');

      // 6. Launch fresh app widget with restarted controller
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            repository: repository,
            userProfileController: restartedProfileController,
            currentTime: DateTime(2026, 9, 11, 8, 0),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Good Morning, Sampath Kumar!'), findsOneWidget);
    });

    testWidgets('Change appearance persists across simulated app restart', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      themeController = ThemeController(ThemeMode.light, prefs);

      // 1. Launch app with Settings screen
      await tester.pumpWidget(
        ThemeScope(
          controller: themeController,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.value,
            home: SettingsScreen(
              repository: repository,
              userProfileController: userProfileController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2. Select System theme
      await tester.tap(find.byKey(const Key('theme_option_system')));
      await tester.pumpAndSettle();
      expect(themeController.value, ThemeMode.system);

      // 3. Simulate cold app restart: re-initialize ThemeController from prefs
      final restartedThemeController = await ThemeController.init(prefs);
      expect(restartedThemeController.value, ThemeMode.system);

      // 4. Change to Dark theme
      themeController.setThemeMode(ThemeMode.dark);
      final restartedDarkController = await ThemeController.init(prefs);
      expect(restartedDarkController.value, ThemeMode.dark);
    });
  });
}
