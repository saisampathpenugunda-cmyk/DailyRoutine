import 'dart:async';
import 'package:flutter/material.dart';
import '../models/checklist.dart';
import '../models/checklist_item.dart';
import '../repositories/notes_repository.dart';
import '../utils/uuid.dart';
import '../theme/notes_theme.dart';
import '../../theme/app_theme.dart';

/// Screen for creating or editing a [Checklist].
///
/// Features:
/// - Auto-saves title and item texts with 500ms debounce
/// - Immediate persistence for structural changes (add, delete, check, reorder, pin)
/// - Drag-and-drop item reordering preserving item UUIDs
/// - Progress indicator showing completed / total items count
/// - Safe flush on exit, disposal, and app lifecycle backgrounding
class ChecklistEditorScreen extends StatefulWidget {
  final Checklist? checklist;
  final NotesRepository repository;

  const ChecklistEditorScreen({
    super.key,
    this.checklist,
    required this.repository,
  });

  @override
  State<ChecklistEditorScreen> createState() => _ChecklistEditorScreenState();
}

class _ChecklistEditorScreenState extends State<ChecklistEditorScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _titleController;
  late final FocusNode _titleFocusNode;

  late final String _checklistId;
  late final DateTime _createdAt;
  Checklist? _currentChecklist;
  late bool _isPersisted;
  late bool _isPinned;

  final List<ChecklistItem> _items = [];
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  Timer? _debounceTimer;
  bool _isDeleting = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final initial = widget.checklist;
    _currentChecklist = initial;
    _isPersisted = initial != null;
    _checklistId = initial?.id ?? Uuid.v4();
    _createdAt = initial?.createdAt ?? DateTime.now();
    _isPinned = initial?.isPinned ?? false;

    _titleController = TextEditingController(text: initial?.title ?? '');
    _titleFocusNode = FocusNode();
    _titleController.addListener(_onTextChanged);

    if (initial != null) {
      final sortedItems = List<ChecklistItem>.from(initial.items)
        ..sort((a, b) => a.order.compareTo(b.order));
      for (final item in sortedItems) {
        _items.add(item);
        _getControllerFor(item);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.removeListener(_onTextChanged);

    if (!_isDeleting) {
      _flushSync();
    }

    _debounceTimer?.cancel();
    _titleController.dispose();
    _titleFocusNode.dispose();

    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _flush();
    }
  }

  TextEditingController _getControllerFor(ChecklistItem item) {
    if (!_controllers.containsKey(item.id)) {
      final controller = TextEditingController(text: item.text);
      controller.addListener(_onTextChanged);
      _controllers[item.id] = controller;
    }
    return _controllers[item.id]!;
  }

  FocusNode _getFocusNodeFor(ChecklistItem item) {
    if (!_focusNodes.containsKey(item.id)) {
      _focusNodes[item.id] = FocusNode();
    }
    return _focusNodes[item.id]!;
  }

  void _onTextChanged() {
    if (_isDeleting) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _save();
    });
  }

  Future<void> _save({bool immediate = false}) async {
    if (_isDeleting || _isSaving) return;

    // Synchronize item texts from active controllers
    for (int i = 0; i < _items.length; i++) {
      final id = _items[i].id;
      if (_controllers.containsKey(id)) {
        _items[i] = _items[i].copyWith(text: _controllers[id]!.text);
      }
    }

    final title = _titleController.text;

    // Do not create empty records if user hasn't added anything yet
    if (!_isPersisted && title.trim().isEmpty && _items.isEmpty) {
      return;
    }

    _isSaving = true;
    try {
      if (!_isPersisted) {
        final newChecklist = Checklist(
          id: _checklistId,
          title: title,
          items: List.unmodifiable(_items),
          isPinned: _isPinned,
          createdAt: _createdAt,
        );
        final saved = await widget.repository.addChecklist(newChecklist);
        _currentChecklist = saved;
        _isPersisted = true;
        if (mounted) setState(() {});
      } else {
        final existing = _currentChecklist ?? widget.checklist!;
        final updated = existing.copyWith(
          title: title,
          items: List.unmodifiable(_items),
          isPinned: _isPinned,
          createdAt: _createdAt,
        );
        final saved = await widget.repository.updateChecklist(updated);
        _currentChecklist = saved;
      }
    } finally {
      _isSaving = false;
    }
  }

  Future<void> _flush() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    await _save(immediate: true);
  }

  void _flushSync() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
      _debounceTimer = null;
      _save(immediate: true);
    }
  }

  Future<void> _addItem() async {
    final newItemId = Uuid.v4();
    final newItem = ChecklistItem(
      id: newItemId,
      text: '',
      isCompleted: false,
      order: _items.length,
    );

    setState(() {
      _items.add(newItem);
    });

    final focusNode = _getFocusNodeFor(newItem);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        focusNode.requestFocus();
      }
    });

    await _save(immediate: true);
  }

  Future<void> _toggleItemCompletion(int index) async {
    setState(() {
      _items[index] = _items[index].copyWith(
        isCompleted: !_items[index].isCompleted,
      );
    });
    await _save(immediate: true);
  }

  Future<void> _deleteItem(int index) async {
    final removed = _items.removeAt(index);
    final controller = _controllers.remove(removed.id);
    controller?.dispose();
    final focus = _focusNodes.remove(removed.id);
    focus?.dispose();

    // Re-index remaining items
    for (int i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(order: i);
    }

    setState(() {});
    await _save(immediate: true);
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);

      // Re-index item orders while keeping their stable UUIDs
      for (int i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(order: i);
      }
    });
    await _save(immediate: true);
  }

  Future<void> _togglePin() async {
    setState(() {
      _isPinned = !_isPinned;
    });
    await _save(immediate: true);
  }

  Future<void> _confirmDelete() async {
    final titleText = _titleController.text.trim();
    final displayName = titleText.isNotEmpty ? titleText : 'this checklist';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final colors = NotesTheme.of(dialogCtx);
        return AlertDialog(
          backgroundColor: colors.card,
          title: Text(
            'Delete Checklist?',
            style: TextStyle(color: colors.textMain, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to permanently delete "$displayName"? This cannot be undone.',
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: colors.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _isDeleting = true;
      _debounceTimer?.cancel();
      _debounceTimer = null;

      if (_isPersisted) {
        await widget.repository.deleteChecklist(_checklistId);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = NotesTheme.of(context);
    final totalItems = _items.length;
    final completedItems = _items.where((i) => i.isCompleted).length;
    final progress = totalItems > 0 ? (completedItems / totalItems) : 0.0;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!_isDeleting) {
          await _flush();
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          iconTheme: IconThemeData(color: colors.textMain),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textMain),
            tooltip: 'Back',
            onPressed: () async {
              await _flush();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            _isPersisted ? 'Edit Checklist' : 'New Checklist',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.textMain,
            ),
          ),
          actions: [
            IconButton(
              key: const Key('checklist_pin_button'),
              icon: Icon(
                _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: _isPinned ? colors.primary : colors.textSecondary,
              ),
              tooltip: _isPinned ? 'Unpin checklist' : 'Pin checklist',
              onPressed: _togglePin,
            ),
            if (_isPersisted)
              IconButton(
                key: const Key('checklist_delete_button'),
                icon: Icon(
                  Icons.delete_outline,
                  color: colors.textSecondary,
                ),
                tooltip: 'Delete checklist',
                onPressed: _confirmDelete,
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            key: const Key('checklist_title_field'),
                            controller: _titleController,
                            focusNode: _titleFocusNode,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colors.textMain,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Checklist Title',
                              hintStyle: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: colors.textSecondary.withValues(alpha: 0.6),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (totalItems > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$completedItems of $totalItems completed',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: progress == 1.0
                                        ? colors.completed
                                        : colors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: colors.barBackground,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress == 1.0
                                      ? colors.completed
                                      : colors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Divider(
                            color: colors.border,
                            height: 1,
                            thickness: AppTheme.borderWidth,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverReorderableList(
                    itemCount: _items.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ReorderableDelayedDragStartListener(
                        key: ValueKey(item.id),
                        index: index,
                        child: Container(
                          color: colors.background,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 2.0,
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                key: Key('checklist_item_checkbox_${item.id}'),
                                value: item.isCompleted,
                                activeColor: colors.completed,
                                onChanged: (_) => _toggleItemCompletion(index),
                              ),
                              Expanded(
                                child: TextField(
                                  key: Key('checklist_item_field_${item.id}'),
                                  controller: _getControllerFor(item),
                                  focusNode: _getFocusNodeFor(item),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: item.isCompleted
                                        ? colors.textSecondary
                                        : colors.textMain,
                                    decoration: item.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Item description',
                                    hintStyle: TextStyle(
                                      color: colors.textSecondary
                                          .withValues(alpha: 0.5),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                              IconButton(
                                key: Key('checklist_item_delete_${item.id}'),
                                icon: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: colors.textSecondary,
                                ),
                                tooltip: 'Delete item',
                                onPressed: () => _deleteItem(index),
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Icon(
                                    Icons.drag_handle,
                                    size: 20,
                                    color: colors.textSecondary
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: const Key('add_checklist_item_button'),
                          icon: Icon(Icons.add, color: colors.primary),
                          label: Text(
                            'Add item',
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: _addItem,
                        ),
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
