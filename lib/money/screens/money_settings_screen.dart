import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../repositories/money_repository.dart';
import '../theme/money_theme.dart';
import 'budgets_screen.dart';
import 'categories_screen.dart';
import 'monthly_view_screen.dart';
import 'recurring_transactions_screen.dart';
import 'statistics_screen.dart';
import 'transactions_screen.dart';

/// Dedicated Money Settings screen providing access to Money features,
/// app-wide theme customization, and future money-specific preferences.
class MoneySettingsScreen extends StatelessWidget {
  final MoneyRepository repository;

  const MoneySettingsScreen({
    super.key,
    required this.repository,
  });

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
                        builder: (_) => TransactionsScreen(repository: repository),
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
                        builder: (_) => CategoriesScreen(repository: repository),
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
                        builder: (_) => StatisticsScreen(repository: repository),
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
                        builder: (_) => MonthlyViewScreen(repository: repository),
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
                        builder: (_) => BudgetsScreen(repository: repository),
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
                        builder: (_) => StatisticsScreen(repository: repository),
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
                        builder: (_) => RecurringTransactionsScreen(repository: repository),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Section 3: Money Preferences ─────────────────────────────────
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
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
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
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryAccent : colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colors.primaryAccent : colors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : colors.textPrimary,
              ),
            ),
          ],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        Icons.chevron_right_rounded,
        color: colors.textSecondary,
        size: 20,
      ),
    );
  }
}
