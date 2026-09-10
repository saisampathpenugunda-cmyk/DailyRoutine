import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../theme/app_theme.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;
  final ValueChanged<bool?>? onToggleCompletion;
  final ValueChanged<bool>? onToggleEnabled;
  final double progress;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
    this.onToggleCompletion,
    this.onToggleEnabled,
    this.progress = 0.0,
  });

  IconData _getIconForType(ActivityType type) => type.icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isEnabled = activity.isEnabled;
    final bool isCompleted = isEnabled && (activity.isCompleted || progress >= 1.0);
    final bool isSkipped = isEnabled && activity.isSkipped && !isCompleted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3.5),
      decoration: BoxDecoration(
        color: isEnabled ? colors.card : colors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: !isEnabled
              ? colors.border.withValues(alpha: 0.6)
              : isCompleted
                  ? colors.completed.withValues(alpha: 0.35)
                  : isSkipped
                      ? colors.skipped.withValues(alpha: 0.35)
                      : colors.border,
          width: AppTheme.borderWidth,
        ),
        boxShadow: isDark || !isEnabled ? null : AppTheme.lightCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 9.0),
            child: Column(
              children: [
                Row(
                  children: [
                    // Circular icon container
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.highlight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted
                              ? colors.completed.withValues(alpha: 0.25)
                              : colors.border,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _getIconForType(activity.activityType),
                        color: !isEnabled
                            ? colors.secondary
                            : isCompleted
                                ? colors.completed
                                : isSkipped
                                    ? colors.skipped
                                    : colors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  activity.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: !isEnabled
                                        ? colors.textSecondary
                                        : isCompleted
                                            ? colors.completed
                                            : isSkipped
                                                ? colors.textSecondary
                                                : colors.textMain,
                                  ),
                                ),
                              ),
                              if (!isEnabled) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.secondary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                    border: Border.all(
                                      color: colors.secondary.withValues(alpha: 0.35),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Disabled',
                                    style: TextStyle(
                                      color: colors.secondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ] else if (isCompleted) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.check_circle,
                                  size: 15,
                                  color: colors.completed,
                                ),
                              ] else if (isSkipped) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.skipped.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                    border: Border.all(
                                      color: colors.skipped.withValues(alpha: 0.35),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Skipped',
                                    style: TextStyle(
                                      color: colors.skipped,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 13,
                                color: colors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                activity.formattedDuration,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isEnabled)
                      SizedBox(
                        height: 30,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Switch(
                            key: ValueKey('toggle_enabled_${activity.id}'),
                            value: false,
                            onChanged: onToggleEnabled,
                          ),
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onToggleEnabled != null) ...[
                            Tooltip(
                              message: 'Disable activity',
                              child: SizedBox(
                                height: 30,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Switch(
                                    key: ValueKey('toggle_enabled_${activity.id}'),
                                    value: true,
                                    onChanged: onToggleEnabled,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Checkbox(
                            value: isCompleted,
                            activeColor: colors.completed,
                            checkColor: Colors.white,
                            side: BorderSide(
                              color: colors.secondary,
                              width: AppTheme.borderWidth,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: onToggleCompletion,
                          ),
                        ],
                      ),
                  ],
                ),
                if (isEnabled) ...[
                  const SizedBox(height: 10),
                  // Horizontal progress track
                  () {
                    final double effectiveProgress = isCompleted
                        ? 1.0
                        : (isSkipped ? 0.0 : progress.clamp(0.0, 1.0));
                    final int percentInt = isCompleted
                        ? 100
                        : (effectiveProgress > 0 ? (effectiveProgress * 100).round().clamp(1, 99) : 0);

                    return Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: effectiveProgress,
                              minHeight: 5,
                              backgroundColor: colors.barBackground,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCompleted ? colors.completed : colors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$percentInt%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCompleted
                                ? colors.completed
                                : (percentInt > 0 ? colors.primary : colors.textSecondary),
                          ),
                        ),
                      ],
                    );
                  }(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
