import 'package:flutter/material.dart';
import '../models/activity.dart';

import '../theme/app_theme.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;
  final ValueChanged<bool?>? onToggleCompletion;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
    this.onToggleCompletion,
  });

  IconData _getIconForType(ActivityType type) {
    switch (type) {
      case ActivityType.meditation:
        return Icons.self_improvement;
      case ActivityType.walking:
        return Icons.directions_walk;
      case ActivityType.dumbbells:
        return Icons.fitness_center;
      case ActivityType.study:
        return Icons.school;
      case ActivityType.guitar:
        return Icons.music_note;
      case ActivityType.reading:
        return Icons.menu_book;
      case ActivityType.general:
        return Icons.task_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = activity.isCompleted;
    final bool isSkipped = activity.isSkipped;

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: isCompleted
              ? AppTheme.emeraldGreen.withValues(alpha: 0.6)
              : isSkipped
                  ? AppTheme.crimsonRed.withValues(alpha: 0.4)
                  : AppTheme.slate200,
          width: AppTheme.borderWidth,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.emeraldGreen.withValues(alpha: 0.1)
                      : isSkipped
                          ? AppTheme.crimsonRed.withValues(alpha: 0.1)
                          : AppTheme.slate100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: isCompleted
                        ? AppTheme.emeraldGreen.withValues(alpha: 0.25)
                        : isSkipped
                            ? AppTheme.crimsonRed.withValues(alpha: 0.25)
                            : AppTheme.slate200,
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getIconForType(activity.activityType),
                  color: isCompleted
                      ? AppTheme.emeraldGreen
                      : isSkipped
                          ? AppTheme.crimsonRed
                          : AppTheme.cobaltBlue,
                  size: 24,
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
                              fontWeight: FontWeight.w600,
                              decoration: isCompleted || isSkipped
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted || isSkipped
                                  ? AppTheme.slate400
                                  : AppTheme.slate900,
                            ),
                          ),
                        ),
                        if (isSkipped) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.crimsonRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              border: Border.all(
                                color: AppTheme.crimsonRed.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'Skipped',
                              style: TextStyle(
                                color: AppTheme.crimsonRed,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppTheme.slate400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activity.formattedDuration,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.slate500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: activity.isCompleted,
                activeColor: AppTheme.emeraldGreen,
                side: const BorderSide(
                  color: AppTheme.slate400,
                  width: AppTheme.borderWidth,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                onChanged: onToggleCompletion,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
