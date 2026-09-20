import 'package:flutter/material.dart';
import '../models/study_task.dart';
import '../models/text_note.dart';
import '../repositories/notes_repository.dart';
import '../services/notes_service.dart';
import '../theme/notes_theme.dart';
import 'study_task_editor_screen.dart';
import 'text_note_editor_screen.dart';
import 'timetable_screen.dart';

/// Main screen for browsing V3 Study Tasks and Notes with top tabs: Study Tasks | Notes.
class NotesScreen extends StatefulWidget {
  final NotesRepository repository;

  const NotesScreen({
    super.key,
    required this.repository,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<StudyTask> _studyTasks = [];
  List<TextNote> _textNotes = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final tasks = await widget.repository.getStudyTasks();
    final textNotes = await widget.repository.getTextNotes();

    if (!mounted) return;
    setState(() {
      _studyTasks = tasks;
      _textNotes = textNotes;
      _isLoading = false;
    });
  }

  Future<void> _toggleStudyTaskCompleted(StudyTask task) async {
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
    );
    await widget.repository.updateStudyTask(updated);
    await _loadData();
  }

  Future<void> _toggleStudyTaskPin(StudyTask task) async {
    final updated = task.copyWith(
      isPinned: !task.isPinned,
      updatedAt: DateTime.now(),
    );
    await widget.repository.updateStudyTask(updated);
    await _loadData();
  }

  Future<void> _deleteStudyTask(StudyTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final colors = NotesTheme.of(dialogCtx);
        return AlertDialog(
          backgroundColor: colors.card,
          title: Text(
            'Delete Study Task?',
            style: TextStyle(color: colors.textMain, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to permanently delete "${task.title}"? This cannot be undone.',
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
      await widget.repository.deleteStudyTask(task.id);
      await _loadData();
    }
  }

  Future<void> _onReorderStudyTasks(
    int oldIndex,
    int newIndex,
    List<StudyTask> currentList,
  ) async {
    final list = List<StudyTask>.from(currentList);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    await widget.repository.reorderStudyTasks(list.map((t) => t.id).toList());
    await _loadData();
  }

  Future<void> _toggleTextNotePin(TextNote note) async {
    final updated = note.copyWith(isPinned: !note.isPinned);
    await widget.repository.updateTextNote(updated);
    await _loadData();
  }

  Future<void> _deleteTextNote(TextNote note) async {
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
            'Are you sure you want to permanently delete "${note.title}"? This cannot be undone.',
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
      await widget.repository.deleteTextNote(note.id);
      await _loadData();
    }
  }

  void _onFabPressed() async {
    if (_tabController.index == 0) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StudyTaskEditorScreen(repository: widget.repository),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TextNoteEditorScreen(repository: widget.repository),
        ),
      );
    }
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final colors = NotesTheme.of(context);

    final filteredTasks =
        NotesService.searchStudyTasks(_studyTasks, _searchQuery);
    final sortedTasks = NotesService.sortStudyTasks(filteredTasks);

    final filteredNotes =
        NotesService.searchTextNotes(_textNotes, _searchQuery);
    final sortedNotes = NotesService.sortTextNotes(filteredNotes);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textMain),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: colors.textMain,
          fontSize: 20,
        ),
        title: _isSearching
            ? TextField(
                key: const Key('notes_search_field'),
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search tasks and notes...',
                  hintStyle: TextStyle(color: colors.textSecondary),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: colors.textMain),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : Text(
                'Study & Notes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.textMain,
                ),
              ),
        actions: [
          IconButton(
            key: const Key('notes_timetable_button'),
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Timetable',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TimetableScreen()),
              );
            },
          ),
          IconButton(
            key: const Key('notes_search_button'),
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Close Search' : 'Search',
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.primary,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          tabs: const [
            Tab(text: 'Study Tasks'),
            Tab(text: 'Notes'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStudyTasksTab(sortedTasks, colors),
                _buildNotesTab(sortedNotes, colors),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('notes_fab'),
        onPressed: _onFabPressed,
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        label: Text(_tabController.index == 0 ? '+ Study Task' : '+ Note'),
      ),
    );
  }

  Widget _buildStudyTasksTab(List<StudyTask> tasks, NotesColors colors) {
    if (_studyTasks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.task_alt_rounded,
        title: 'No study tasks yet',
        subtitle: 'Tap + Study Task to create your first task.',
        colors: colors,
      );
    }

    if (tasks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matching tasks',
        subtitle: 'Try searching with different keywords.',
        colors: colors,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ReorderableListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: tasks.length,
        onReorder: (oldIndex, newIndex) =>
            _onReorderStudyTasks(oldIndex, newIndex, tasks),
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Container(
            key: ValueKey(task.id),
            margin: const EdgeInsets.only(bottom: 12),
            child: _buildStudyTaskCard(task, colors),
          );
        },
      ),
    );
  }

  Widget _buildStudyTaskCard(StudyTask task, NotesColors colors) {
    return Card(
      elevation: 0,
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: task.isPinned
              ? colors.primary.withValues(alpha: 0.5)
              : colors.border,
          width: task.isPinned ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StudyTaskEditorScreen(
                repository: widget.repository,
                initialTaskId: task.id,
              ),
            ),
          );
          _loadData();
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Direct Checkbox ─────────────────────────────────────────
              IconButton(
                key: Key('study_task_checkbox_${task.id}'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  task.isCompleted
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: task.isCompleted ? colors.completed : colors.primary,
                  size: 26,
                ),
                onPressed: () => _toggleStudyTaskCompleted(task),
              ),
              const SizedBox(width: 8),

              // ── Task Title & Description ────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (task.isPinned) ...[
                          Icon(
                            Icons.push_pin,
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: task.isCompleted
                                  ? colors.textSecondary
                                  : colors.textMain,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: task.isCompleted
                              ? colors.textSecondary.withValues(alpha: 0.6)
                              : colors.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // ── Pin & Delete Actions ────────────────────────────────────
              IconButton(
                key: Key('study_task_pin_${task.id}'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  task.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 20,
                  color: task.isPinned ? colors.primary : colors.textSecondary,
                ),
                tooltip: task.isPinned ? 'Unpin' : 'Pin',
                onPressed: () => _toggleStudyTaskPin(task),
              ),
              IconButton(
                key: Key('study_task_delete_${task.id}'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: colors.textSecondary,
                ),
                tooltip: 'Delete',
                onPressed: () => _deleteStudyTask(task),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesTab(List<TextNote> notes, NotesColors colors) {
    if (_textNotes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.description_outlined,
        title: 'No notes yet',
        subtitle: 'Tap + Note to create your first note.',
        colors: colors,
      );
    }

    if (notes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matching notes',
        subtitle: 'Try searching with different keywords.',
        colors: colors,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: notes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final note = notes[index];
          return _buildTextNoteCard(note, colors);
        },
      ),
    );
  }

  Widget _buildTextNoteCard(TextNote note, NotesColors colors) {
    return Card(
      elevation: 0,
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: note.isPinned
              ? colors.primary.withValues(alpha: 0.5)
              : colors.border,
          width: note.isPinned ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TextNoteEditorScreen(
                note: note,
                repository: widget.repository,
              ),
            ),
          );
          _loadData();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note.isPinned) ...[
                    Icon(
                      Icons.push_pin,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? 'Untitled Note' : note.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: colors.textMain,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      note.isPinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      color: note.isPinned
                          ? colors.primary
                          : colors.textSecondary,
                    ),
                    tooltip: note.isPinned ? 'Unpin' : 'Pin',
                    onPressed: () => _toggleTextNotePin(note),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: colors.textSecondary,
                    ),
                    tooltip: 'Delete',
                    onPressed: () => _deleteTextNote(note),
                  ),
                ],
              ),
              if (note.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required NotesColors colors,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 56,
              color: colors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textMain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
