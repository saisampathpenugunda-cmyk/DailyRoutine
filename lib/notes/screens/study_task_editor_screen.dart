import 'dart:async';
import 'package:flutter/material.dart';

import '../models/study_task.dart';
import '../repositories/notes_repository.dart';
import '../theme/notes_theme.dart';

/// Full editor screen for creating and editing a [StudyTask].
class StudyTaskEditorScreen extends StatefulWidget {
  final NotesRepository repository;
  final String? initialTaskId;

  const StudyTaskEditorScreen({
    super.key,
    required this.repository,
    this.initialTaskId,
  }) : assert(initialTaskId != '', 'initialTaskId cannot be empty string');

  @override
  State<StudyTaskEditorScreen> createState() => _StudyTaskEditorScreenState();
}

class _StudyTaskEditorScreenState extends State<StudyTaskEditorScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  StudyTask? _task;
  bool _isLoading = true;
  bool _isPinned = false;
  bool _isCompleted = false;
  DateTime? _createdAt;
  Timer? _debounceTimer;

  bool get _isCreateMode => widget.initialTaskId == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    _titleController.addListener(_onTextChanged);
    _descriptionController.addListener(_onTextChanged);

    _initTask();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _flushPendingChangesSync();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _flushPendingChangesSync();
    }
  }

  Future<void> _initTask() async {
    if (_isCreateMode) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final task = await widget.repository.getStudyTaskById(widget.initialTaskId!);
    if (!mounted) return;

    if (task != null) {
      _task = task;
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _isPinned = task.isPinned;
      _isCompleted = task.isCompleted;
      _createdAt = task.createdAt;
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _onTextChanged() {
    if (_isLoading) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _saveTaskSilently();
    });
  }

  void _flushPendingChangesSync() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _saveTaskSilently();
  }

  Future<void> _saveTaskSilently() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    // Do not save blank tasks
    if (title.isEmpty) {
      return;
    }

    if (_task == null) {
      final newTask = StudyTask(
        title: title,
        description: description,
        isCompleted: _isCompleted,
        isPinned: _isPinned,
      );
      _task = newTask;
      _createdAt = newTask.createdAt;
      await widget.repository.addStudyTask(newTask);
    } else {
      final updated = _task!.copyWith(
        title: title,
        description: description,
        isCompleted: _isCompleted,
        isPinned: _isPinned,
        createdAt: _createdAt,
        updatedAt: DateTime.now(),
      );
      _task = updated;
      await widget.repository.updateStudyTask(updated);
    }
  }

  Future<void> _togglePin() async {
    setState(() {
      _isPinned = !_isPinned;
    });

    if (_task != null) {
      final updated = _task!.copyWith(
        isPinned: _isPinned,
        updatedAt: DateTime.now(),
      );
      _task = updated;
      await widget.repository.updateStudyTask(updated);
    } else {
      _saveTaskSilently();
    }
  }

  Future<void> _deleteTask() async {
    if (_task == null) {
      Navigator.of(context).pop();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final colors = NotesTheme.of(dialogCtx);
        return AlertDialog(
          backgroundColor: colors.card,
          title: Text(
            'Delete Study Task?',
            style: TextStyle(
              color: colors.textMain,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently delete this task? This cannot be undone.',
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              key: const Key('cancel_delete_task_button'),
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            TextButton(
              key: const Key('confirm_delete_task_button'),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(
                'Delete',
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      _debounceTimer?.cancel();
      _debounceTimer = null;
      await widget.repository.deleteStudyTask(_task!.id);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _saveAndExit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      // If task name is required, show validation error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task Name is required')),
      );
      return;
    }
    await _saveTaskSilently();
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = NotesTheme.of(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _flushPendingChangesSync();
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          leading: BackButton(
            key: const Key('study_task_editor_back_button'),
            color: colors.textMain,
            onPressed: () {
              _flushPendingChangesSync();
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            _isCreateMode ? 'New Study Task' : 'Edit Study Task',
            style: TextStyle(
              color: colors.textMain,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              key: const Key('study_task_pin_button'),
              icon: Icon(
                _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: _isPinned ? colors.primary : colors.textSecondary,
              ),
              tooltip: _isPinned ? 'Unpin Task' : 'Pin Task',
              onPressed: _togglePin,
            ),
            if (!_isCreateMode)
              IconButton(
                key: const Key('study_task_delete_button'),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Delete Task',
                onPressed: _deleteTask,
              ),
            IconButton(
              key: const Key('study_task_save_button'),
              icon: Icon(Icons.check, color: colors.primary),
              tooltip: 'Save Task',
              onPressed: _saveAndExit,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TASK NAME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('study_task_title_input'),
                      controller: _titleController,
                      autofocus: _isCreateMode,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.textMain,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Revise Java OOP',
                        hintStyle: TextStyle(
                          color: colors.textSecondary.withValues(alpha: 0.6),
                        ),
                        filled: true,
                        fillColor: colors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'DESCRIPTION (OPTIONAL)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('study_task_description_input'),
                      controller: _descriptionController,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.textMain,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Review inheritance and polymorphism.',
                        hintStyle: TextStyle(
                          color: colors.textSecondary.withValues(alpha: 0.6),
                        ),
                        filled: true,
                        fillColor: colors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
