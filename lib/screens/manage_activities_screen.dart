import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../repositories/activity_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'create_activity_screen.dart';
import 'edit_activity_screen.dart';

class ManageActivitiesScreen extends StatefulWidget {
  final ActivityRepository repository;
  final NotificationService? notificationService;

  const ManageActivitiesScreen({
    super.key,
    required this.repository,
    this.notificationService,
  });

  @override
  State<ManageActivitiesScreen> createState() => _ManageActivitiesScreenState();
}

class _ManageActivitiesScreenState extends State<ManageActivitiesScreen> {
  late List<Activity> _activities;

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

  Future<void> _openCreateActivity() async {
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

  Future<void> _openEditActivity(Activity activity) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => EditActivityScreen(
          activity: activity,
          repository: widget.repository,
          notificationService: widget.notificationService,
        ),
      ),
    );
    if (updated == true || mounted) {
      _loadActivities();
    }
  }

  void _toggleActivityEnabled(Activity activity, bool enabled) {
    final success = widget.repository.setActivityEnabled(activity.id, enabled);
    if (!success) {
      ScaffoldMessenger.of(context).clearSnackBars();
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

  Future<void> _confirmDeleteActivity(Activity activity) async {
    if (widget.repository.isActivityInProgress(activity.id)) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete an activity with an active or paused session. Please finish or reset the session first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.appColors;
        final errorColor = Theme.of(dialogContext).colorScheme.error;
        return AlertDialog(
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            side: BorderSide(color: colors.border, width: 1),
          ),
          title: Text(
            'Delete Activity?',
            style: TextStyle(
              color: colors.textMain,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete ${activity.name}?',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              key: const Key('dialog_cancel_button'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            FilledButton(
              key: const Key('dialog_confirm_delete_button'),
              style: FilledButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final success = widget.repository.deleteActivity(activity.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${activity.name} deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadActivities();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Activities',
          style: TextStyle(
            color: colors.textMain,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          key: const Key('manage_activities_back_button'),
          icon: Icon(Icons.arrow_back, color: colors.textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            // ── Prominent "+ Add Activity" Action ───────────────────────────
            FilledButton.icon(
              key: const Key('manage_add_activity_button'),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Add Activity',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: isDark ? colors.background : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              onPressed: _openCreateActivity,
            ),
            const SizedBox(height: 20),

            // ── Section Header ──────────────────────────────────────────────
            Row(
              children: [
                Text(
                  'ALL ACTIVITIES (${_activities.length})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Activities List ─────────────────────────────────────────────
            for (final activity in _activities) ...[
              _ManageActivityCard(
                key: Key('manage_activity_card_${activity.id}'),
                activity: activity,
                colors: colors,
                isDark: isDark,
                onToggleEnabled: (val) => _toggleActivityEnabled(activity, val),
                onEdit: () => _openEditActivity(activity),
                onDelete: () => _confirmDeleteActivity(activity),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _ManageActivityCard extends StatelessWidget {
  final Activity activity;
  final AppThemeColors colors;
  final bool isDark;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _ManageActivityCard({
    super.key,
    required this.activity,
    required this.colors,
    required this.isDark,
    required this.onToggleEnabled,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = isDark ? const Color(0xFF20282C) : colors.primary.withValues(alpha: 0.12);
    final iconColor = isDark ? const Color(0xFF8BCFD1) : colors.primary;
    final errorColor = Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: activity.isEnabled
            ? colors.card
            : (isDark ? colors.card.withValues(alpha: 0.5) : colors.card.withValues(alpha: 0.65)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isDark ? const Color(0xFF2B363C) : colors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon Container
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2B363C) : colors.border.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Icon(
                  activity.activityType.icon,
                  size: 22,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 14),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: activity.isEnabled
                            ? colors.textMain
                            : colors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${activity.typeLabel} • ${activity.formattedDuration}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Enabled/Disabled Switch with Label
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    activity.isEnabled ? 'Enabled' : 'Disabled',
                    key: Key('manage_status_label_${activity.id}'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: activity.isEnabled
                          ? colors.primary
                          : colors.textSecondary,
                    ),
                  ),
                  SizedBox(
                    height: 30,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Switch(
                        key: Key('manage_toggle_switch_${activity.id}'),
                        value: activity.isEnabled,
                        onChanged: onToggleEnabled,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: colors.border.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 10),

          // Action Buttons: Edit, and Delete (if custom)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                key: Key('edit_activity_button_${activity.id}'),
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textMain,
                  side: BorderSide(color: colors.border, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(0, 34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onEdit,
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  key: Key('delete_activity_button_${activity.id}'),
                  icon: Icon(Icons.delete_outline, size: 15, color: errorColor),
                  label: Text('Delete', style: TextStyle(color: errorColor)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: errorColor,
                    side: BorderSide(color: errorColor.withValues(alpha: 0.5), width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: const Size(0, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onDelete,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
