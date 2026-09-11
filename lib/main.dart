import 'package:flutter/material.dart';
import 'repositories/activity_repository.dart';
import 'screens/home_screen.dart';
import 'repositories/shared_preferences_activity_repository.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'controllers/user_profile_controller.dart';
import 'controllers/streak_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = LocalNotificationService();
  await notificationService.init();

  final activityRepository = await SharedPreferencesActivityRepository.init(
    notificationService: notificationService,
  );
  final themeController = await ThemeController.init();
  final userProfileController = await UserProfileController.init();
  final streakController = await StreakController.init(repository: activityRepository);

  runApp(DailyRoutineApp(
    repository: activityRepository,
    notificationService: notificationService,
    themeController: themeController,
    userProfileController: userProfileController,
    streakController: streakController,
  ));
}

class DailyRoutineApp extends StatefulWidget {
  final ActivityRepository repository;
  final NotificationService? notificationService;
  final ThemeController? themeController;
  final UserProfileController? userProfileController;
  final StreakController? streakController;

  const DailyRoutineApp({
    super.key,
    required this.repository,
    this.notificationService,
    this.themeController,
    this.userProfileController,
    this.streakController,
  });

  @override
  State<DailyRoutineApp> createState() => _DailyRoutineAppState();
}

class _DailyRoutineAppState extends State<DailyRoutineApp> with WidgetsBindingObserver {
  late final ThemeController _themeController;
  late final UserProfileController _userProfileController;
  late final StreakController _streakController;

  @override
  void initState() {
    super.initState();
    _themeController = widget.themeController ?? ThemeController(ThemeMode.light);
    _userProfileController = widget.userProfileController ?? UserProfileController();
    _streakController = widget.streakController ??
        StreakController(repository: widget.repository);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.themeController == null) {
      _themeController.dispose();
    }
    if (widget.userProfileController == null) {
      _userProfileController.dispose();
    }
    if (widget.streakController == null) {
      _streakController.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await widget.repository.checkDateRollover();
      _streakController.recalculate();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      await widget.repository.checkDateRollover();
      _streakController.recalculate();
      await widget.repository.flush();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: _themeController,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeController,
        builder: (context, currentMode, _) {
          return MaterialApp(
            title: 'Daily Routine',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: currentMode,
            home: HomeScreen(
              repository: widget.repository,
              notificationService: widget.notificationService,
              userProfileController: _userProfileController,
              streakController: _streakController,
            ),
          );
        },
      ),
    );
  }
}
