import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../repositories/activity_repository.dart';

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

  void _skipActivity() {
    widget.repository.setActivitySkipped(_activity.id, isSkipped: true);
    setState(() {
      _activity = _activity.copyWith(isSkipped: true, isCompleted: false);
    });
    if (mounted) {
      Navigator.of(context).pop();
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Great job!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
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
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Set',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$_currentSet/$_totalSets',
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 64,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Aim for 10-15 reps',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 64,
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
