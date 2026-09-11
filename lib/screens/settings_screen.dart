import 'package:flutter/material.dart';
import '../controllers/user_profile_controller.dart';
import '../repositories/activity_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'manage_activities_screen.dart';
import 'reminder_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ActivityRepository repository;
  final NotificationService? notificationService;
  final UserProfileController userProfileController;

  const SettingsScreen({
    super.key,
    required this.repository,
    this.notificationService,
    required this.userProfileController,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _showEditNameDialog() async {
    final colors = context.appColors;
    final textController = TextEditingController(
      text: widget.userProfileController.userName,
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            side: BorderSide(color: colors.border, width: AppTheme.borderWidth),
          ),
          title: Text(
            'Edit Profile Name',
            style: TextStyle(
              color: colors.textMain,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your name to personalize your daily routine greeting.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('name_text_field'),
                controller: textController,
                autofocus: true,
                style: TextStyle(
                  color: colors.textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  filled: true,
                  fillColor: colors.highlight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide(color: colors.primary, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              key: const Key('cancel_name_button'),
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            FilledButton(
              key: const Key('save_name_button'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
              ),
              onPressed: () {
                final trimmed = textController.text.trim();
                if (trimmed.isNotEmpty) {
                  Navigator.of(dialogContext).pop(trimmed);
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && mounted) {
      await widget.userProfileController.setUserName(newName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeController = ThemeScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: colors.textMain,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          key: const Key('settings_back_button'),
          icon: Icon(Icons.arrow_back, color: colors.textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            // ── Section 1: Profile ──────────────────────────────────────────
            _buildSectionHeader('PROFILE', colors),
            const SizedBox(height: 8),
            ValueListenableBuilder<String>(
              valueListenable: widget.userProfileController,
              builder: (context, userName, _) {
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(color: colors.border, width: AppTheme.borderWidth),
                    boxShadow: isDark ? null : AppTheme.lightCardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary.withValues(alpha: 0.15),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: colors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Name',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userName,
                              key: const Key('profile_user_name'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('edit_name_button'),
                        icon: Icon(Icons.edit_outlined, color: colors.primary),
                        tooltip: 'Edit Name',
                        onPressed: _showEditNameDialog,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Section 2: Appearance ───────────────────────────────────────
            _buildSectionHeader('APPEARANCE', colors),
            const SizedBox(height: 8),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeController,
              builder: (context, currentMode, _) {
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(color: colors.border, width: AppTheme.borderWidth),
                    boxShadow: isDark ? null : AppTheme.lightCardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme Mode',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textMain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildThemeOption(
                              context: context,
                              key: const Key('theme_option_light'),
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
                              context: context,
                              key: const Key('theme_option_dark'),
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
                              context: context,
                              key: const Key('theme_option_system'),
                              label: 'System',
                              icon: Icons.brightness_auto_outlined,
                              isSelected: currentMode == ThemeMode.system,
                              colors: colors,
                              onTap: () => themeController.setThemeMode(ThemeMode.system),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Section 3: Activities & Routine ─────────────────────────────
            _buildSectionHeader('ACTIVITIES & ROUTINE', colors),
            const SizedBox(height: 8),
            _buildActionTile(
              key: const Key('settings_manage_activities_button'),
              icon: Icons.tune_rounded,
              title: 'Manage Activities',
              subtitle: 'Enable, disable, edit, and create activities',
              colors: colors,
              isDark: isDark,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => ManageActivitiesScreen(
                      repository: widget.repository,
                      notificationService: widget.notificationService,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Section 4: Notifications ────────────────────────────────────
            _buildSectionHeader('NOTIFICATIONS', colors),
            const SizedBox(height: 8),
            _buildActionTile(
              key: const Key('settings_notifications_button'),
              icon: Icons.notifications_outlined,
              title: 'Reminders & Notifications',
              subtitle: 'Configure daily routine alerts and reminders',
              colors: colors,
              isDark: isDark,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => ReminderSettingsScreen(
                      repository: widget.repository,
                      notificationService: widget.notificationService,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Section 5: About ────────────────────────────────────────────
            _buildSectionHeader('ABOUT', colors),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(color: colors.border, width: AppTheme.borderWidth),
                boxShadow: isDark ? null : AppTheme.lightCardShadow,
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      color: colors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'DailyRoutine',
                    key: const Key('about_app_name'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.textMain,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Version 1.2.0',
                      key: const Key('about_version'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A simple daily routine tracker.',
                    key: const Key('about_description'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required Key key,
    required String label,
    required IconData icon,
    required bool isSelected,
    required AppThemeColors colors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.18)
                : colors.highlight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: isSelected ? colors.primary : colors.border,
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? colors.primary : colors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? colors.primary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
    required AppThemeColors colors,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: colors.border, width: AppTheme.borderWidth),
            boxShadow: isDark ? null : AppTheme.lightCardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(icon, color: colors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
