import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../repositories/money_repository.dart';
import '../services/savings_notification_helper.dart';
import '../theme/money_theme.dart';
import 'budgets_screen.dart';
import 'categories_screen.dart';
import 'monthly_view_screen.dart';
import 'recurring_transactions_screen.dart';
import 'savings_screen.dart';
import 'statistics_screen.dart';
import 'transactions_screen.dart';

/// Dedicated Money Settings screen providing access to Money features,
/// savings allocations, notifications, app-wide theme customization,
/// and money-specific preferences.
class MoneySettingsScreen extends StatefulWidget {
  final MoneyRepository repository;
  final NotificationService? notificationService;

  const MoneySettingsScreen({
    super.key,
    required this.repository,
    this.notificationService,
  });

  @override
  State<MoneySettingsScreen> createState() => _MoneySettingsScreenState();
}

class _MoneySettingsScreenState extends State<MoneySettingsScreen> {
  bool _savingsReminderEnabled = true;
  int _savingsReminderHour = SavingsNotificationHelper.defaultHour;
  int _savingsReminderMinute = SavingsNotificationHelper.defaultMinute;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _savingsReminderEnabled =
          prefs.getBool(SavingsNotificationHelper.prefEnabledKey) ?? true;
      _savingsReminderHour =
          prefs.getInt(SavingsNotificationHelper.prefHourKey) ??
              SavingsNotificationHelper.defaultHour;
      _savingsReminderMinute =
          prefs.getInt(SavingsNotificationHelper.prefMinuteKey) ??
              SavingsNotificationHelper.defaultMinute;
    });
  }

  Future<void> _updateSavingsReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        SavingsNotificationHelper.prefEnabledKey, _savingsReminderEnabled);
    await prefs.setInt(
        SavingsNotificationHelper.prefHourKey, _savingsReminderHour);
    await prefs.setInt(
        SavingsNotificationHelper.prefMinuteKey, _savingsReminderMinute);

    await SavingsNotificationHelper.syncSavingsReminder(
      repository: widget.repository,
      notificationService: widget.notificationService,
    );
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _savingsReminderHour,
        minute: _savingsReminderMinute,
      ),
    );

    if (picked != null) {
      setState(() {
        _savingsReminderHour = picked.hour;
        _savingsReminderMinute = picked.minute;
      });
      await _updateSavingsReminder();
    }
  }

  String _formatTimeOfDay(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final colors = MoneyTheme.of(context);
    final themeController = ThemeScope.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Money Settings',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          key: const Key('money_settings_back_button'),
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            // ── Section 1: Appearance ────────────────────────────────────────
            _buildSectionHeader('APPEARANCE', colors),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme / Appearance',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeController,
                    builder: (context, currentMode, _) {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildThemeOption(
                              key: const Key('money_settings_theme_option_dark'),
                              label: 'Dark',
                              icon: Icons.dark_mode_outlined,
                              isSelected: currentMode == ThemeMode.dark,
                              colors: colors,
                              onTap: () => themeController.setThemeMode(ThemeMode.dark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildThemeOption(
                              key: const Key('money_settings_theme_option_light'),
                              label: 'Light',
                              icon: Icons.light_mode_outlined,
                              isSelected: currentMode == ThemeMode.light,
                              colors: colors,
                              onTap: () => themeController.setThemeMode(ThemeMode.light),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildThemeOption(
                              key: const Key('money_settings_theme_option_system'),
                              label: 'System',
                              icon: Icons.brightness_auto_outlined,
                              isSelected: currentMode == ThemeMode.system,
                              colors: colors,
                              onTap: () => themeController.setThemeMode(ThemeMode.system),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Section 2: Money ─────────────────────────────────────────────
            _buildSectionHeader('MONEY', colors),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  _buildNavTile(
                    key: const Key('money_settings_transactions_tile'),
                    icon: Icons.receipt_long_outlined,
                    title: 'Transactions',
                    subtitle: 'Manage your transactions',
                    colors: colors,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TransactionsScreen(repository: widget.repository),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: colors.border),
                  _buildNavTile(
                    key: const Key('money_settings_savings_tile'),
                    icon: Icons.savings_outlined,
                    title: 'Savings',
                    subtitle: '5% automatic savings on income',
                    colors: colors,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SavingsScreen(
                          repository: widget.repository,
                          notificationService: widget.notificationService,
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: colors.border),
                  _buildNavTile(
                    key: const Key('money_settings_categories_tile'),
                    icon: Icons.category_outlined,
                    title: 'Categories',
                    subtitle: 'Manage income and expense categories',
                    colors: colors,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CategoriesScreen(repository: widget.repository),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: colors.border),
                  _buildNavTile(
                    key: const Key('money_settings_statistics_tile'),
                    icon: Icons.bar_chart_rounded,
                    title: 'Statistics',
                    subtitle: 'View spending and income statistics',
                    colors: colors,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StatisticsScreen(repository: widget.repository),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: colors.border),
                  _buildNavTile(
                    key: const Key('money_settings_monthly_view_tile'),
                    icon: Icons.calendar_month_outlined,
                    title: 'Monthly View',
                    subtitle: 'Review monthly financial activity',
                    colors: colors,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MonthlyViewScreen(repository: widget.repository),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: colors.border),
                  _buildNavTile(
                    key: const Key('money_settings_budgets_tile'),
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Budgets',
                    subtitle: 'Manage monthly budgets',
                    colors: colors,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BudgetsScreen(repository: widget.repository),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: colors.border),
                  _buildNavTile(
                    key: const Key('money_settings_budget_insights_tile'),
                    icon: Icons.insights_outlined,
                    title: 'Budget Insights',
                    subtitle: 'Compare budgets with actual spending',
                    colors: colors,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StatisticsScreen(repository: widget.repository),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: colors.border),
                  _buildNavTile(
                    key: const Key('money_settings_recurring_tile'),
                    icon: Icons.autorenew_rounded,
                    title: 'Recurring Transactions',
                    subtitle: 'Manage recurring income and expenses',
                    colors: colors,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecurringTransactionsScreen(repository: widget.repository),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Section 3: Savings Notifications ─────────────────────────────
            _buildSectionHeader('SAVINGS NOTIFICATIONS', colors),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    key: const Key('money_settings_savings_notification_toggle'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    secondary: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: colors.primaryAccent,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Daily Savings Reminder',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Notify daily with your total accumulated savings',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    value: _savingsReminderEnabled,
                    activeThumbColor: colors.primaryAccent,
                    onChanged: (val) async {
                      setState(() => _savingsReminderEnabled = val);
                      await _updateSavingsReminder();
                    },
                  ),
                  if (_savingsReminderEnabled) ...[
                    Divider(height: 1, color: colors.border),
                    InkWell(
                      key: const Key('money_settings_savings_notification_time_tile'),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      onTap: _pickReminderTime,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: colors.border),
                              ),
                              child: Icon(
                                Icons.access_time_rounded,
                                color: colors.primaryAccent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reminder Time',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatTimeOfDay(_savingsReminderHour, _savingsReminderMinute),
                                    key: const Key('money_settings_savings_notification_time_text'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: colors.primaryAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: colors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Section 4: Money Preferences ─────────────────────────────────
            _buildSectionHeader('MONEY PREFERENCES', colors),
            const SizedBox(height: 10),
            Container(
              key: const Key('money_settings_preferences_tile'),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: colors.primaryAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Money Preferences',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Future money-specific settings',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      'Coming Soon',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, MoneyColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: colors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
    required MoneyColors colors,
    required VoidCallback onTap,
  }) {
    return ListTile(
      key: key,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Icon(icon, color: colors.primaryAccent, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: colors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: colors.textSecondary,
      ),
    );
  }

  Widget _buildThemeOption({
    required Key key,
    required String label,
    required IconData icon,
    required bool isSelected,
    required MoneyColors colors,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected ? colors.primaryAccent : colors.border;
    final bgColor = isSelected ? colors.primaryAccent.withValues(alpha: 0.12) : colors.surface;
    final textColor = isSelected ? colors.primaryAccent : colors.textPrimary;

    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.0),
        ),
        child: Column(
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
