import '../exceptions/notes_exception.dart';
import '../models/checklist.dart';
import '../models/study_task.dart';
import '../models/text_note.dart';
import 'notes_repository.dart';

/// Hermetic in-memory implementation of [NotesRepository], ideal for unit tests.
class InMemoryNotesRepository implements NotesRepository {
  final List<TextNote> _textNotes = [];
  final List<Checklist> _checklists = [];
  final List<StudyTask> _studyTasks = [];

  InMemoryNotesRepository({
    List<TextNote>? initialTextNotes,
    List<Checklist>? initialChecklists,
    List<StudyTask>? initialStudyTasks,
  }) {
    if (initialTextNotes != null) {
      _textNotes.addAll(initialTextNotes);
    }
    if (initialChecklists != null) {
      _checklists.addAll(initialChecklists);
    }
    if (initialStudyTasks != null) {
      _studyTasks.addAll(initialStudyTasks);
    }
  }

  // ── Text Notes ──────────────────────────────────────────────────────────

  @override
  Future<List<TextNote>> getTextNotes() async {
    return List.unmodifiable(_textNotes);
  }

  @override
  Future<TextNote?> getTextNoteById(String id) async {
    try {
      return _textNotes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TextNote> addTextNote(TextNote note) async {
    if (_textNotes.any((n) => n.id == note.id)) {
      throw NotesException('TextNote with ID "${note.id}" already exists');
    }
    _textNotes.add(note);
    return note;
  }

  @override
  Future<TextNote> updateTextNote(TextNote note) async {
    final index = _textNotes.indexWhere((n) => n.id == note.id);
    if (index == -1) {
      throw NotesException('TextNote with ID "${note.id}" not found');
    }

    final existing = _textNotes[index];
    final updated = note.copyWith(
      createdAt: existing.createdAt,
      updatedAt: note.updatedAt.isAfter(existing.updatedAt)
          ? note.updatedAt
          : DateTime.now(),
    );

    _textNotes[index] = updated;
    return updated;
  }

  @override
  Future<bool> deleteTextNote(String id) async {
    final index = _textNotes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _textNotes.removeAt(index);
      return true;
    }
    return false;
  }

  // ── Study Tasks ─────────────────────────────────────────────────────────

  @override
  Future<List<StudyTask>> getStudyTasks() async {
    return List.unmodifiable(_studyTasks);
  }

  @override
  Future<StudyTask?> getStudyTaskById(String id) async {
    try {
      return _studyTasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<StudyTask> addStudyTask(StudyTask task) async {
    if (_studyTasks.any((t) => t.id == task.id)) {
      throw NotesException('StudyTask with ID "${task.id}" already exists');
    }
    _studyTasks.add(task);
    return task;
  }

  @override
  Future<StudyTask> updateStudyTask(StudyTask task) async {
    final index = _studyTasks.indexWhere((t) => t.id == task.id);
    if (index == -1) {
      throw NotesException('StudyTask with ID "${task.id}" not found');
    }

    final existing = _studyTasks[index];
    final updated = task.copyWith(
      createdAt: existing.createdAt,
      updatedAt: task.updatedAt.isAfter(existing.updatedAt)
          ? task.updatedAt
          : DateTime.now(),
    );

    _studyTasks[index] = updated;
    return updated;
  }

  @override
  Future<bool> deleteStudyTask(String id) async {
    final index = _studyTasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _studyTasks.removeAt(index);
      return true;
    }
    return false;
  }

  @override
  Future<void> reorderStudyTasks(List<String> orderedIds) async {
    final Map<String, StudyTask> map = {for (final t in _studyTasks) t.id: t};
    _studyTasks.clear();
    for (final id in orderedIds) {
      final task = map[id];
      if (task != null) {
        _studyTasks.add(task);
      }
    }
    // Add any missing tasks
    for (final entry in map.entries) {
      if (!_studyTasks.any((t) => t.id == entry.key)) {
        _studyTasks.add(entry.value);
      }
    }
  }

  // ── Checklists ──────────────────────────────────────────────────────────

  @override
  Future<List<Checklist>> getChecklists() async {
    return List.unmodifiable(_checklists);
  }

  @override
  Future<Checklist?> getChecklistById(String id) async {
    try {
      return _checklists.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Checklist> addChecklist(Checklist checklist) async {
    if (_checklists.any((c) => c.id == checklist.id)) {
      throw NotesException('Checklist with ID "${checklist.id}" already exists');
    }
    _checklists.add(checklist);
    return checklist;
  }

  @override
  Future<Checklist> updateChecklist(Checklist checklist) async {
    final index = _checklists.indexWhere((c) => c.id == checklist.id);
    if (index == -1) {
      throw NotesException('Checklist with ID "${checklist.id}" not found');
    }

    final existing = _checklists[index];
    final updated = checklist.copyWith(
      createdAt: existing.createdAt,
      updatedAt: checklist.updatedAt.isAfter(existing.updatedAt)
          ? checklist.updatedAt
          : DateTime.now(),
    );

    _checklists[index] = updated;
    return updated;
  }

  @override
  Future<bool> deleteChecklist(String id) async {
    final index = _checklists.indexWhere((c) => c.id == id);
    if (index != -1) {
      _checklists.removeAt(index);
      return true;
    }
    return false;
  }
}
