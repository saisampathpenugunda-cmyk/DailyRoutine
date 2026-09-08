import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../repositories/activity_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_card.dart';
import 'activity_detail_screen.dart';
import 'meditation_screen.dart';
import 'walking_screen.dart';
import 'dumbbells_screen.dart';
import 'history_screen.dart';
import 'progress_screen.dart';
import 'reminder_settings_screen.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  final ActivityRepository repository;
  final NotificationService? notificationService;

  const HomeScreen({
    super.key,
    required this.repository,
    this.notificationService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Activity> _activities;
  int _currentTabIndex = 0;
  Key _historyKey = UniqueKey();
  Key _progressKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  void _loadActivities() {
    setState(() {
      _activities = widget.repository.getActivities();
    });
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentTabIndex = index;
      if (index == 1) {
        _historyKey = UniqueKey();
      } else if (index == 2) {
        _progressKey = UniqueKey();
      }
    });
    if (index == 0) {
      _loadActivities();
    }
  }

  void _toggleActivityCompletion(String id) {
    widget.repository.toggleActivityCompletion(id);
    _loadActivities();
  }

  Future<void> _navigateToDetail(Activity activity) async {
    if (activity.activityType == ActivityType.meditation) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => MeditationScreen(
            activity: activity,
            repository: widget.repository,
          ),
        ),
      );
    } else if (activity.activityType == ActivityType.walking) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => WalkingScreen(
            activity: activity,
            repository: widget.repository,
          ),
        ),
      );
    } else if (activity.activityType == ActivityType.dumbbells) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => DumbbellsScreen(
            activity: activity,
            repository: widget.repository,
          ),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ActivityDetailScreen(activity: activity),
        ),
      );
    }
    // Reload so the Home screen reflects any completion changes made downstream.
    _loadActivities();
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _activities.where((a) => a.isCompleted).length;
    final totalCount = _activities.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentTabIndex == 0
              ? 'Daily Routine'
              : _currentTabIndex == 1
                  ? 'History'
                  : 'Progress',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        centerTitle: false,
        actions: _currentTabIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Reminders',
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => ReminderSettingsScreen(
                          repository: widget.repository,
                          notificationService: widget.notificationService,
                        ),
                      ),
                    );
                    _loadActivities();
                  },
                ),
              ]
            : null,
      ),
      body: _currentTabIndex == 0
          ? ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(
                        color: AppTheme.slate200,
                        width: AppTheme.borderWidth,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.cobaltBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              ),
                              child: const Icon(
                                Icons.calendar_today,
                                color: AppTheme.cobaltBlue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Today's Plan",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: AppTheme.slate900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$completedCount of $totalCount activities completed',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.slate500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (progress == 1.0 ? AppTheme.emeraldGreen : AppTheme.cobaltBlue)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                border: Border.all(
                                  color: (progress == 1.0 ? AppTheme.emeraldGreen : AppTheme.cobaltBlue)
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: progress == 1.0 ? AppTheme.emeraldGreen : AppTheme.cobaltBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: AppTheme.slate100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress == 1.0 ? AppTheme.emeraldGreen : AppTheme.cobaltBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Text(
                    'ACTIVITIES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slate500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ..._activities.map(
                  (activity) => ActivityCard(
                    key: ValueKey(activity.id),
                    activity: activity,
                    onTap: () => _navigateToDetail(activity),
                    onToggleCompletion: (_) => _toggleActivityCompletion(activity.id),
                  ),
                ),
              ],
            )
          : _currentTabIndex == 1
              ? HistoryScreen(
                  key: _historyKey,
                  repository: widget.repository,
                )
              : ProgressScreen(
                  key: _progressKey,
                  repository: widget.repository,
                ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppTheme.slate200, width: AppTheme.borderWidth),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: _onTabSelected,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppTheme.cobaltBlue,
          unselectedItemColor: AppTheme.slate400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.today_outlined),
              activeIcon: Icon(Icons.today),
              label: 'Today',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_outlined),
              activeIcon: Icon(Icons.insights),
              label: 'Progress',
            ),
          ],
        ),
      ),
    );
  }
}
