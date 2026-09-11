import 'dart:async';
import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../repositories/activity_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_card.dart';
import 'activity_detail_screen.dart';
import 'meditation_screen.dart';
import 'walking_screen.dart';
import 'dumbbells_screen.dart';
import 'guitar_screen.dart';
import 'history_screen.dart';
import 'progress_screen.dart';
import 'reminder_settings_screen.dart';
import 'create_activity_screen.dart';
import 'manage_activities_screen.dart';
import 'settings_screen.dart';
import '../services/notification_service.dart';
import '../controllers/user_profile_controller.dart';
import '../controllers/streak_controller.dart';

class HomeScreen extends StatefulWidget {
  final ActivityRepository repository;
  final NotificationService? notificationService;
  final UserProfileController? userProfileController;
  final StreakController? streakController;
  final DateTime? currentTime;

  const HomeScreen({
    super.key,
    required this.repository,
    this.notificationService,
    this.userProfileController,
    this.streakController,
    this.currentTime,
  });

  static String getTimeBasedGreeting(String name, {DateTime? time}) {
    final now = time ?? DateTime.now();
    final hour = now.hour;
    final String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      greeting = 'Good Evening';
    } else {
      greeting = 'Good Night';
    }
    return '$greeting, $name!';
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late List<Activity> _activities;
  late UserProfileController _userProfileController;
  late StreakController _streakController;
  int _currentTabIndex = 0;
  Key _historyKey = UniqueKey();
  Key _progressKey = UniqueKey();
  Timer? _greetingRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userProfileController = widget.userProfileController ?? UserProfileController();
    _userProfileController.addListener(_onUserProfileChanged);
    _streakController = widget.streakController ??
        StreakController(repository: widget.repository);
    _streakController.addListener(_onStreakChanged);
    _streakController.recalculate();
    _activities = widget.repository.getActivities();
    _checkRolloverAndRefresh();
    _startGreetingTimer();
  }

  void _startGreetingTimer() {
    _greetingRefreshTimer?.cancel();
    _greetingRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _onUserProfileChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onStreakChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userProfileController != widget.userProfileController) {
      _userProfileController.removeListener(_onUserProfileChanged);
      _userProfileController = widget.userProfileController ?? UserProfileController();
      _userProfileController.addListener(_onUserProfileChanged);
    }
    if (oldWidget.streakController != widget.streakController) {
      _streakController.removeListener(_onStreakChanged);
      _streakController = widget.streakController ??
          StreakController(repository: widget.repository);
      _streakController.addListener(_onStreakChanged);
    }
    _streakController.recalculate();
    _activities = widget.repository.getActivities();
  }

  @override
  void dispose() {
    _greetingRefreshTimer?.cancel();
    _userProfileController.removeListener(_onUserProfileChanged);
    _streakController.removeListener(_onStreakChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      _startGreetingTimer();
      await _checkRolloverAndRefresh();
      if (mounted) {
        setState(() {});
      }
    } else if (state == AppLifecycleState.paused) {
      _greetingRefreshTimer?.cancel();
    }
  }

  Future<void> _checkRolloverAndRefresh() async {
    final rolledOver = await widget.repository.checkDateRollover();
    _streakController.recalculate();
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
    _streakController.recalculate();
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
    if (id == 'guitar' && !enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guitar is a permanent built-in activity and cannot be disabled.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
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
    } else if (activity.activityType == ActivityType.guitar ||
        activity.id == 'guitar' ||
        activity.name.trim().toLowerCase() == 'guitar') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => GuitarScreen(
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
            IconButton(
              key: const Key('settings_button'),
              icon: Icon(
                Icons.settings_outlined,
                color: colors.textMain,
              ),
              tooltip: 'Settings',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => SettingsScreen(
                      repository: widget.repository,
                      notificationService: widget.notificationService,
                      userProfileController: _userProfileController,
                    ),
                  ),
                );
                await _checkRolloverAndRefresh();
              },
            ),
          ],
        ],
      ),
      body: _currentTabIndex == 0
          ? (enabledActivities.isEmpty
              ? ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  children: [
                    _buildHomeHero(context, colors, isDark, completedCount, totalCount, progress, isAllDone),
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
                              _activities.isEmpty
                                  ? Icons.playlist_add_rounded
                                  : Icons.pause_circle_outline_rounded,
                              size: 40,
                              color: colors.secondary,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _activities.isEmpty
                                  ? 'No activities yet'
                                  : 'All activities are disabled',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colors.textMain,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _activities.isEmpty
                                  ? 'Tap the + button below to create your first activity'
                                  : 'Enable an activity in Manage Activities to include it in Today\'s Plan',
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
                    ),
                  ],
                )
              : ReorderableListView(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  onReorder: (oldIndex, newIndex) {
                    widget.repository.reorderEnabledActivities(oldIndex, newIndex);
                    _loadActivities();
                  },
                  proxyDecorator: (Widget child, int index, Animation<double> animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (BuildContext context, Widget? animChild) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.25),
                                blurRadius: 18 * animation.value,
                                spreadRadius: 2 * animation.value,
                                offset: Offset(0, 6 * animation.value),
                              ),
                            ],
                          ),
                          child: animChild,
                        );
                      },
                      child: child,
                    );
                  },
                  header: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHomeHero(context, colors, isDark, completedCount, totalCount, progress, isAllDone),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 2.0),
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
                    ],
                  ),
                  children: [
                    for (int i = 0; i < enabledActivities.length; i++)
                      ReorderableDelayedDragStartListener(
                        key: ValueKey(enabledActivities[i].id),
                        index: i,
                        child: ActivityCard(
                          key: ValueKey('activity_card_${enabledActivities[i].id}'),
                          activity: enabledActivities[i],
                          progress: widget.repository.getActivityProgress(enabledActivities[i]),
                          onTap: () => _navigateToDetail(enabledActivities[i]),
                          onToggleCompletion: (_) => _toggleActivityCompletion(enabledActivities[i].id),
                          onToggleEnabled: (enabled) => _toggleActivityEnabled(enabledActivities[i].id, enabled),
                        ),
                      ),
                  ],
                ))
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

  Widget _buildHomeHero(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
    int completedCount,
    int totalCount,
    double progress,
    bool isAllDone,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Greeting Header (matching reference image) ─────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 2.0, 20.0, 2.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                HomeScreen.getTimeBasedGreeting(
                  _userProfileController.userName,
                  time: widget.currentTime,
                ),
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
        // ── Compact Streak Card ─────────────────────────────────────────
        _buildStreakCard(context, colors, isDark),
        // ── Today's Plan Hero Card with Circular Completion Ring ───────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
      ],
    );
  }

  Widget _buildStreakCard(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
  ) {
    final currentStreak = _streakController.currentStreak;
    final bestStreak = _streakController.bestStreak;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      child: Container(
        key: const Key('streak_card'),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: colors.border, width: AppTheme.borderWidth),
          boxShadow: isDark ? null : AppTheme.lightCardShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🔥 $currentStreak Day Streak',
                    key: const Key('current_streak_text'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textMain,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Best: $bestStreak ${bestStreak == 1 ? 'day' : 'days'}',
                    key: const Key('best_streak_text'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
