import 'dart:async';
import 'package:flutter/material.dart';
import '../models/text_note.dart';
import '../repositories/notes_repository.dart';
import '../utils/uuid.dart';
import '../theme/notes_theme.dart';
import '../../theme/app_theme.dart';

/// Screen for creating or editing a [TextNote].
///
/// Features:
/// - Auto-saves with a 500ms debounce
/// - Safe flush on exit, disposal, and app lifecycle pause
/// - Preserves stable UUID and createdAt timestamp
/// - Pin/unpin and delete with confirmation dialog
class TextNoteEditorScreen extends StatefulWidget {
  final TextNote? note;
  final NotesRepository repository;

  const TextNoteEditorScreen({
    super.key,
    this.note,
    required this.repository,
  });

  @override
  State<TextNoteEditorScreen> createState() => _TextNoteEditorScreenState();
}

class _TextNoteEditorScreenState extends State<TextNoteEditorScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final FocusNode _titleFocusNode;
  late final FocusNode _contentFocusNode;

  late final String _noteId;
  late final DateTime _createdAt;
  TextNote? _currentNote;
  late bool _isPersisted;
  late bool _isPinned;

  Timer? _debounceTimer;
  bool _isDeleting = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final initial = widget.note;
    _currentNote = initial;
    _isPersisted = initial != null;
    _noteId = initial?.id ?? Uuid.v4();
    _createdAt = initial?.createdAt ?? DateTime.now();
    _isPinned = initial?.isPinned ?? false;

    _titleController = TextEditingController(text: initial?.title ?? '');
    _contentController = TextEditingController(text: initial?.content ?? '');
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.removeListener(_onTextChanged);
    _contentController.removeListener(_onTextChanged);

    if (!_isDeleting) {
      _flushSync();
    }

    _debounceTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
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

  void _onTextChanged() {
    if (_isDeleting) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _save();
    });
  }

  Future<void> _save() async {
    if (_isDeleting || _isSaving) return;

    final title = _titleController.text;
    final content = _contentController.text;

    // Do not create empty records if user hasn't typed anything yet
    if (!_isPersisted && title.trim().isEmpty && content.trim().isEmpty) {
      return;
    }

    _isSaving = true;
    try {
      if (!_isPersisted) {
        final newNote = TextNote(
          id: _noteId,
          title: title,
          content: content,
          isPinned: _isPinned,
          createdAt: _createdAt,
        );
        final saved = await widget.repository.addTextNote(newNote);
        _currentNote = saved;
        _isPersisted = true;
        if (mounted) setState(() {});
      } else {
        final existing = _currentNote ?? widget.note!;
        final updated = existing.copyWith(
          title: title,
          content: content,
          isPinned: _isPinned,
          createdAt: _createdAt,
        );
        final saved = await widget.repository.updateTextNote(updated);
        _currentNote = saved;
      }
    } finally {
      _isSaving = false;
    }
  }

  Future<void> _flush() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    await _save();
  }

  void _flushSync() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
      _debounceTimer = null;
      _save();
    }
  }

  Future<void> _togglePin() async {
    setState(() {
      _isPinned = !_isPinned;
    });
    await _save();
  }

  Future<void> _confirmDelete() async {
    final titleText = _titleController.text.trim();
    final displayName = titleText.isNotEmpty ? titleText : 'this note';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final colors = NotesTheme.of(dialogCtx);
        return AlertDialog(
          backgroundColor: colors.card,
          title: Text(
            'Delete Note?',
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
              key: const Key('confirm_delete_note_button'),
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
        await widget.repository.deleteTextNote(_noteId);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = NotesTheme.of(context);

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
            _isPersisted ? 'Edit Note' : 'New Note',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.textMain,
            ),
          ),
          actions: [
            IconButton(
              key: const Key('note_pin_button'),
              icon: Icon(
                _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: _isPinned ? colors.primary : colors.textSecondary,
              ),
              tooltip: _isPinned ? 'Unpin note' : 'Pin note',
              onPressed: _togglePin,
            ),
            if (_isPersisted)
              IconButton(
                key: const Key('note_delete_button'),
                icon: Icon(
                  Icons.delete_outline,
                  color: colors.textSecondary,
                ),
                tooltip: 'Delete note',
                onPressed: _confirmDelete,
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('text_note_title_field'),
                controller: _titleController,
                focusNode: _titleFocusNode,
                textInputAction: TextInputAction.next,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.textMain,
                ),
                decoration: InputDecoration(
                  hintText: 'Title',
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
              Divider(
                color: colors.border,
                height: 1,
                thickness: AppTheme.borderWidth,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('text_note_content_field'),
                controller: _contentController,
                focusNode: _contentFocusNode,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: colors.textMain,
                ),
                decoration: InputDecoration(
                  hintText: 'Note...',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: colors.textSecondary.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
