import 'package:flutter/material.dart';
import 'repositories/activity_repository.dart';
import 'screens/home_screen.dart';
import 'repositories/shared_preferences_activity_repository.dart';

import 'theme/app_theme.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = LocalNotificationService();
  await notificationService.init();

  final activityRepository = await SharedPreferencesActivityRepository.init(
    notificationService: notificationService,
  );
  runApp(DailyRoutineApp(
    repository: activityRepository,
    notificationService: notificationService,
  ));
}

class DailyRoutineApp extends StatefulWidget {
  final ActivityRepository repository;
  final NotificationService? notificationService;

  const DailyRoutineApp({
    super.key,
    required this.repository,
    this.notificationService,
  });

  @override
  State<DailyRoutineApp> createState() => _DailyRoutineAppState();
}

class _DailyRoutineAppState extends State<DailyRoutineApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      widget.repository.flush();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Routine',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: HomeScreen(
        repository: widget.repository,
        notificationService: widget.notificationService,
      ),
    );
  }
}
