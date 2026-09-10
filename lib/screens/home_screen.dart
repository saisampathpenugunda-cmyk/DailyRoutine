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
import 'create_activity_screen.dart';
import 'manage_activities_screen.dart';
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late List<Activity> _activities;
  int _currentTabIndex = 0;
  Key _historyKey = UniqueKey();
  Key _progressKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activities = widget.repository.getActivities();
    _checkRolloverAndRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await _checkRolloverAndRefresh();
    }
  }

  Future<void> _checkRolloverAndRefresh() async {
    final rolledOver = await widget.repository.checkDateRollover();
    if (!mounted) return;
    setState(() {
      if (rolledOver) {
        _historyKey = UniqueKey();
        _progressKey = UniqueKey();
      }
      _activities = widget.repository.getActivities();
    });
  }

  void _loadActivities() {
    setState(() {
      _activities = widget.repository.getActivities();
    });
  }

  Future<void> _onTabSelected(int index) async {
    final rolledOver = await widget.repository.checkDateRollover();
    if (!mounted) return;
    setState(() {
      _currentTabIndex = index;
      if (index == 1 || rolledOver) {
        _historyKey = UniqueKey();
      }
      if (index == 2 || rolledOver) {
        _progressKey = UniqueKey();
      }
      if (index == 0 || rolledOver) {
        _activities = widget.repository.getActivities();
      }
    });
  }

  void _toggleActivityCompletion(String id) {
    widget.repository.toggleActivityCompletion(id);
    _loadActivities();
  }

  void _toggleActivityEnabled(String id, bool enabled) {
    final success = widget.repository.setActivityEnabled(id, enabled);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot disable an activity with an active or paused session. Please finish or reset the session first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
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
          builder: (context) => ActivityDetailScreen(
            activity: activity,
            repository: widget.repository,
          ),
        ),
      );
    }
    // Reload so the Home screen reflects any completion changes made downstream or date rollover.
    await _checkRolloverAndRefresh();
  }

  Future<void> _openCreateActivityScreen() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CreateActivityScreen(
          repository: widget.repository,
        ),
      ),
    );
    if (created == true || mounted) {
      _loadActivities();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final themeController = ThemeScope.of(context);
    final isDark = themeController.isDarkMode;

    final enabledActivities = _activities.where((a) => a.isEnabled).toList();
    final disabledActivities = _activities.where((a) => !a.isEnabled).toList();
    final completedCount = enabledActivities.where((a) => a.isCompleted).length;
    final totalCount = enabledActivities.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
    final isAllDone = progress == 1.0 && totalCount > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentTabIndex == 0
              ? 'Daily Routine'
              : _currentTabIndex == 1
                  ? 'History'
                  : 'Progress',
          style: TextStyle(
            color: colors.textMain,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        centerTitle: false,
        actions: [
          // ── Theme Mode Toggle ─────────────────────────────────────────────
          IconButton(
            key: const Key('theme_mode_toggle_button'),
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: colors.textMain,
            ),
            tooltip: isDark ? 'Switch to Urban Zen (Light)' : 'Switch to Cyber Noir (Dark)',
            onPressed: () {
              themeController.toggleTheme();
            },
          ),
          if (_currentTabIndex == 0) ...[
            IconButton(
              key: const Key('manage_activities_button'),
              icon: Icon(
                Icons.tune_rounded,
                color: colors.textMain,
              ),
              tooltip: 'Manage Activities',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => ManageActivitiesScreen(
                      repository: widget.repository,
                      notificationService: widget.notificationService,
                    ),
                  ),
                );
                await _checkRolloverAndRefresh();
              },
            ),
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: colors.textMain,
              ),
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
          ],
        ],
      ),
      body: _currentTabIndex == 0
          ? ListView(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              children: [
                // ── Greeting Header (matching reference image) ─────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning,',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colors.textMain,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _getFormattedDate(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Today's Plan Hero Card with Circular Completion Ring ───────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      border: Border.all(
                        color: isAllDone
                            ? colors.completed.withValues(alpha: 0.35)
                            : colors.border,
                        width: AppTheme.borderWidth,
                      ),
                      boxShadow: isDark ? null : AppTheme.lightCardShadow,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Plan",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: colors.textMain,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$completedCount of $totalCount activities completed',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: (isAllDone ? colors.completed : colors.primary)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                  border: Border.all(
                                    color: (isAllDone ? colors.completed : colors.primary)
                                        .withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  isAllDone ? '100% Done' : '${(progress * 100).toInt()}% Done',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isAllDone ? colors.completed : colors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Circular progress ring matching reference with safe text containment
                        SizedBox(
                          width: 66,
                          height: 66,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox.expand(
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 5.0,
                                  backgroundColor: colors.barBackground,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isAllDone ? colors.completed : colors.primary,
                                  ),
                                ),
                              ),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${(progress * 100).toInt()}%',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: colors.textMain,
                                            letterSpacing: -0.3,
                                            height: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 1.5),
                                        Text(
                                          'Complete',
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w600,
                                            color: colors.textSecondary,
                                            letterSpacing: 0.1,
                                            height: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 4.0),
                  child: Text(
                    'Your Activities',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textMain,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (_activities.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        border: Border.all(color: colors.border, width: AppTheme.borderWidth),
                        boxShadow: isDark ? null : AppTheme.lightCardShadow,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.playlist_add_rounded,
                            size: 40,
                            color: colors.secondary,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No activities yet',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.textMain,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap the + button below to create your first activity',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (enabledActivities.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        border: Border.all(color: colors.border, width: AppTheme.borderWidth),
                        boxShadow: isDark ? null : AppTheme.lightCardShadow,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.pause_circle_outline_rounded,
                            size: 40,
                            color: colors.secondary,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'All activities are disabled',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.textMain,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enable an activity below to include it in Today\'s Plan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...enabledActivities.map(
                    (activity) => ActivityCard(
                      key: ValueKey(activity.id),
                      activity: activity,
                      progress: widget.repository.getActivityProgress(activity),
                      onTap: () => _navigateToDetail(activity),
                      onToggleCompletion: (_) => _toggleActivityCompletion(activity.id),
                      onToggleEnabled: (enabled) => _toggleActivityEnabled(activity.id, enabled),
                    ),
                  ),
                if (disabledActivities.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 4.0),
                    child: Row(
                      children: [
                        Text(
                          'Disabled Activities',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textSecondary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${disabledActivities.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...disabledActivities.map(
                    (activity) => ActivityCard(
                      key: ValueKey(activity.id),
                      activity: activity,
                      progress: 0.0,
                      onTap: () => _navigateToDetail(activity),
                      onToggleEnabled: (enabled) => _toggleActivityEnabled(activity.id, enabled),
                    ),
                  ),
                ],
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
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(color: colors.border, width: AppTheme.borderWidth),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: _onTabSelected,
          backgroundColor: colors.surface,
          elevation: 0,
          selectedItemColor: colors.primary,
          unselectedItemColor: colors.secondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
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
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
              key: const Key('add_activity_fab'),
              onPressed: _openCreateActivityScreen,
              backgroundColor: colors.primary,
              foregroundColor: isDark ? colors.background : Colors.white,
              elevation: 2,
              shape: const CircleBorder(),
              tooltip: 'Add Activity',
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekDays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}
