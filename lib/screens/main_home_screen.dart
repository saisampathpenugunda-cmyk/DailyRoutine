import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/streak_controller.dart';
import '../controllers/user_profile_controller.dart';
import '../money/repositories/money_repository.dart';
import '../money/screens/money_dashboard_screen.dart';
import '../money/services/money_calculator.dart';
import '../money/theme/money_theme.dart';
import '../money/utils/money_formatter.dart';
import '../repositories/activity_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

/// App-level entry point providing high-level navigation to Activities and Money modules.
class MainHomeScreen extends StatefulWidget {
  final ActivityRepository activityRepository;
  final MoneyRepository moneyRepository;
  final NotificationService? notificationService;
  final UserProfileController? userProfileController;
  final StreakController? streakController;
  final ThemeController? themeController;
  final DateTime? currentTime;

  const MainHomeScreen({
    super.key,
    required this.activityRepository,
    required this.moneyRepository,
    this.notificationService,
    this.userProfileController,
    this.streakController,
    this.themeController,
    this.currentTime,
  });

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> with WidgetsBindingObserver {
  late UserProfileController _userProfileController;
  late StreakController _streakController;
  Timer? _greetingTimer;

  int _activitiesCompletedCount = 0;
  int _activitiesEnabledCount = 0;
  double _moneyBalance = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userProfileController = widget.userProfileController ?? UserProfileController();
    _userProfileController.addListener(_onStateUpdated);

    _streakController = widget.streakController ??
        StreakController(repository: widget.activityRepository);
    _streakController.addListener(_onStateUpdated);
    _streakController.recalculate();

    _startGreetingTimer();
    _loadSummaries();
  }

  void _onStateUpdated() {
    if (mounted) {
      _loadSummaries();
    }
  }

  void _startGreetingTimer() {
    _greetingTimer?.cancel();
    _greetingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _greetingTimer?.cancel();
    if (widget.userProfileController == null) {
      _userProfileController.dispose();
    }
    if (widget.streakController == null) {
      _streakController.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.activityRepository.checkDateRollover();
      _streakController.recalculate();
      _loadSummaries();
    }
  }

  Future<void> _loadSummaries() async {
    final activities = widget.activityRepository.getActivities();
    final enabled = activities.where((a) => a.isEnabled).toList();
    final completed = enabled.where((a) => a.isCompleted).length;

    final transactions = await widget.moneyRepository.getTransactions();
    final balance = MoneyCalculator.calculateBalance(transactions);

    if (!mounted) return;
    setState(() {
      _activitiesEnabledCount = enabled.length;
      _activitiesCompletedCount = completed;
      _moneyBalance = balance;
      _isLoading = false;
    });
  }

  Future<void> _openActivities() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          repository: widget.activityRepository,
          notificationService: widget.notificationService,
          userProfileController: _userProfileController,
          streakController: _streakController,
        ),
      ),
    );
    _loadSummaries();
  }

  Future<void> _openMoney() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MoneyDashboardScreen(
          repository: widget.moneyRepository,
          activityRepository: widget.activityRepository,
          notificationService: widget.notificationService,
          userProfileController: _userProfileController,
        ),
      ),
    );
    _loadSummaries();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          userProfileController: _userProfileController,
          repository: widget.activityRepository,
          notificationService: widget.notificationService,
        ),
      ),
    );
    _loadSummaries();
  }

  String _formatDate() {
    final now = widget.currentTime ?? DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _formatCurrency(double amount) {
    return MoneyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.appColors;
    final moneyColors = MoneyTheme.of(context);

    final String greeting = HomeScreen.getTimeBasedGreeting(
      _userProfileController.userName,
      time: widget.currentTime,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DailyRoutine',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            key: const Key('main_home_settings_button'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSummaries,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GREETING & DATE
                    Text(
                      greeting,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textMain,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 28),

                    // SECTION: YOUR DAY
                    Text(
                      'Your Day',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: colors.textMain,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildModuleCard(
                      title: 'Activities',
                      subtitle: '$_activitiesCompletedCount of $_activitiesEnabledCount completed',
                      icon: Icons.checklist_rounded,
                      iconColor: isDark ? colors.primary : const Color(0xFF6750A4),
                      accentText: _activitiesEnabledCount > 0
                          ? '${((_activitiesCompletedCount / _activitiesEnabledCount) * 100).toInt()}% Done'
                          : '0% Done',
                      onTap: _openActivities,
                    ),
                    const SizedBox(height: 24),

                    // SECTION: YOUR MONEY
                    Text(
                      'Your Money',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: colors.textMain,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildModuleCard(
                      title: 'Money',
                      subtitle: 'Current Balance: ${_formatCurrency(_moneyBalance)}',
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: moneyColors.primaryAccent,
                      accentText: 'Dashboard',
                      onTap: _openMoney,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String accentText,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    final cardColor = colors.card;

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      accentText,
                      style: TextStyle(
                        color: iconColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 12, color: iconColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
