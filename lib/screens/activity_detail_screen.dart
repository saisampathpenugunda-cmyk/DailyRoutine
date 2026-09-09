import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../theme/app_theme.dart';

class ActivityDetailScreen extends StatelessWidget {
  final Activity activity;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = context.appColors;

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
                color: colors.highlight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: activity.isCompleted
                      ? colors.completed.withValues(alpha: 0.25)
                      : colors.border,
                  width: 1,
                ),
              ),
              child: Icon(
                activity.activityType.icon,
                size: 48,
                color: activity.isCompleted
                    ? colors.completed
                    : colors.primary,
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
                          ? context.appColors.completed
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
