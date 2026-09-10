import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../repositories/activity_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/duration_control.dart';

class DumbbellsScreen extends StatefulWidget {
  final Activity activity;
  final ActivityRepository repository;

  const DumbbellsScreen({
    super.key,
    required this.activity,
    required this.repository,
  });

  @override
  State<DumbbellsScreen> createState() => _DumbbellsScreenState();
}

class _DumbbellsScreenState extends State<DumbbellsScreen> {
  late Activity _activity;
  final int _totalSets = 3;
  int _currentSet = 1;

  @override
  void initState() {
    super.initState();
    _activity = widget.activity;
    _currentSet = (_activity.completedSetsReps.length + 1).clamp(1, _totalSets);
  }

  Future<void> _completeSet() async {
    final reps = await _showRepsDialog();
    if (reps != null) {
      final updatedReps = List<int>.from(_activity.completedSetsReps)..add(reps);
      final updatedActivity = _activity.copyWith(completedSetsReps: updatedReps);
      
      if (_currentSet < _totalSets) {
        widget.repository.updateActivity(updatedActivity);
        setState(() {
          _activity = updatedActivity;
          _currentSet++;
        });
      } else if (_currentSet == _totalSets) {
        // Final set completed
        final finalActivity = updatedActivity.copyWith(isCompleted: true, isSkipped: false);
        widget.repository.updateActivity(finalActivity);
        setState(() {
          _activity = finalActivity;
        });
      }
    }
  }

  Future<int?> _showRepsDialog() {
    return showDialog<int>(
      context: context,
      builder: (context) => _RepsDialog(currentSet: _currentSet),
    );
  }

  void _onDurationChanged(Duration newDuration) {
    final updated = _activity.copyWith(defaultDuration: newDuration);
    widget.repository.updateActivity(updated);
    if (mounted) {
      setState(() {
        _activity = updated;
      });
    }
  }

  void _skipActivity() {
    widget.repository.setActivitySkipped(_activity.id, isSkipped: true);
    setState(() {
      _activity = _activity.copyWith(isSkipped: true, isCompleted: false);
    });
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleToggleEnabled(bool enabled) {
    final success = widget.repository.setActivityEnabled(_activity.id, enabled);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot disable an activity with an active or paused session. Please finish or reset the session first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (mounted) {
      setState(() {
        _activity = _activity.copyWith(isEnabled: enabled);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDone = _activity.isCompleted;

    return Scaffold(
      appBar: AppBar(
        title: Text(_activity.name),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _activity.isEnabled ? 'Enabled' : 'Disabled',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _activity.isEnabled ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 30,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Switch(
                    key: const Key('detail_enable_switch'),
                    value: _activity.isEnabled,
                    onChanged: _handleToggleEnabled,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24.0,
                ),
                child: IntrinsicHeight(
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
              if (isDone) ...[
                Icon(
                  Icons.check_circle_outline,
                  size: 100,
                  color: context.appColors.completed,
                ),
                const SizedBox(height: 24),
                Text(
                  'Great job!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.appColors.completed,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All $_totalSets sets completed.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 1,
                    ),
                    boxShadow: Theme.of(context).brightness == Brightness.light
                        ? const [
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Circular progress ring enclosing dumbbell icon
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: (_currentSet - 1) / _totalSets,
                                strokeWidth: 8,
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 32,
                                  color: context.appColors.primary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Workout Session',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  _activity.formattedDuration,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '$_currentSet/$_totalSets',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sets',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 30,
                              width: 1,
                              color: colorScheme.outlineVariant,
                            ),
                            Column(
                              children: [
                                Text(
                                  '10-15',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Target Reps',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                DurationControl(
                  duration: _activity.defaultDuration,
                  onDurationChanged: _onDurationChanged,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _completeSet,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _currentSet == _totalSets ? 'Complete Final Set' : 'Complete Set $_currentSet',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _skipActivity,
                  icon: const Icon(Icons.close),
                  label: const Text("Can't do today"),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                ),
              ],
              const Spacer(),
            ],
          ),
          ),
        ),
      ),
    );
  },
),
),
);
  }
}

class _RepsDialog extends StatefulWidget {
  final int currentSet;

  const _RepsDialog({required this.currentSet});

  @override
  State<_RepsDialog> createState() => _RepsDialogState();
}

class _RepsDialogState extends State<_RepsDialog> {
  late final TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final reps = int.tryParse(_controller.text.trim());
    if (reps == null || reps <= 0 || reps > 999) {
      setState(() {
        _errorMessage = 'Please enter valid reps (1-999)';
      });
      return;
    }
    Navigator.of(context).pop(reps);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Set ${widget.currentSet} Completed'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Reps completed',
              hintText: 'e.g., 12',
              errorText: _errorMessage,
            ),
            autofocus: true,
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
