import 'package:flutter/material.dart';
import '../models/activity.dart';

class ActivityDetailScreen extends StatelessWidget {
  final Activity activity;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(activity.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                _getIconForType(activity.activityType),
                size: 48,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              activity.name,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Chip(
              avatar: const Icon(Icons.schedule, size: 18),
              label: Text(
                'Duration: ${activity.formattedDuration}',
                style: theme.textTheme.labelLarge,
              ),
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Activity Type',
                      value: activity.activityType.displayName,
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      label: 'Planned Duration',
                      value: activity.formattedDuration,
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      label: 'Status',
                      value: activity.isCompleted ? 'Completed' : 'Pending',
                      valueColor: activity.isCompleted
                          ? Colors.green
                          : colorScheme.outline,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dedicated activity controls (timer, tracking, reminders) will be connected here.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
