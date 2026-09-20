import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../exceptions/notes_exception.dart';
import '../models/checklist.dart';
import '../models/study_task.dart';
import '../models/text_note.dart';
import '../repositories/notes_repository.dart';

/// Persistent SharedPreferences-backed implementation of [NotesRepository].
///
/// Ensures strict separation of Text Notes, Study Tasks, and Checklists by utilizing
/// isolated preference keys [textNotesKey], [studyTasksKey], and [checklistsKey].
class SharedPreferencesNotesRepository implements NotesRepository {
  static const String textNotesKey = 'notes_text_notes_key';
  static const String studyTasksKey = 'notes_study_tasks_key';
  static const String checklistsKey = 'notes_checklists_key';

  final SharedPreferences _prefs;
  final List<TextNote> _textNotes = [];
  final List<StudyTask> _studyTasks = [];
  final List<Checklist> _checklists = [];

  SharedPreferencesNotesRepository(this._prefs) {
    _loadFromPrefs();
  }

  /// Factory helper to initialize repository asynchronously with SharedPreferences.
  static Future<SharedPreferencesNotesRepository> create({
    SharedPreferences? prefs,
  }) async {
    final preferences = prefs ?? await SharedPreferences.getInstance();
    return SharedPreferencesNotesRepository(preferences);
  }

  void _loadFromPrefs() {
    _loadTextNotes();
    _loadStudyTasks();
    _loadChecklists();
  }

  void _loadTextNotes() {
    _textNotes.clear();
    final raw = _prefs.getString(textNotesKey);
    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            try {
              final note = TextNote.fromJson(Map<String, dynamic>.from(item));
              if (note.id.isNotEmpty) {
                _textNotes.add(note);
              }
            } catch (_) {
              // Ignore individual malformed note defensively
            }
          }
        }
      }
    } catch (_) {
      // Corrupted JSON storage fallback without crashing
      _textNotes.clear();
    }
  }

  Future<void> _saveTextNotes() async {
    final encoded = jsonEncode(_textNotes.map((n) => n.toJson()).toList());
    await _prefs.setString(textNotesKey, encoded);
  }

  void _loadStudyTasks() {
    _studyTasks.clear();
    final raw = _prefs.getString(studyTasksKey);
    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            try {
              final task = StudyTask.fromJson(Map<String, dynamic>.from(item));
              if (task.id.isNotEmpty) {
                _studyTasks.add(task);
              }
            } catch (_) {
              // Ignore individual malformed task defensively
            }
          }
        }
      }
    } catch (_) {
      // Corrupted JSON storage fallback without crashing
      _studyTasks.clear();
    }
  }

  Future<void> _saveStudyTasks() async {
    final encoded = jsonEncode(_studyTasks.map((t) => t.toJson()).toList());
    await _prefs.setString(studyTasksKey, encoded);
  }

  void _loadChecklists() {
    _checklists.clear();
    final raw = _prefs.getString(checklistsKey);
    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            try {
              final checklist = Checklist.fromJson(Map<String, dynamic>.from(item));
              if (checklist.id.isNotEmpty) {
                _checklists.add(checklist);
              }
            } catch (_) {
              // Ignore individual malformed checklist defensively
            }
          }
        }
      }
    } catch (_) {
      // Corrupted JSON storage fallback without crashing
      _checklists.clear();
    }
  }

  Future<void> _saveChecklists() async {
    final encoded = jsonEncode(_checklists.map((c) => c.toJson()).toList());
    await _prefs.setString(checklistsKey, encoded);
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
    await _saveTextNotes();
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
    await _saveTextNotes();
    return updated;
  }

  @override
  Future<bool> deleteTextNote(String id) async {
    final index = _textNotes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _textNotes.removeAt(index);
      await _saveTextNotes();
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
    await _saveStudyTasks();
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
    await _saveStudyTasks();
    return updated;
  }

  @override
  Future<bool> deleteStudyTask(String id) async {
    final index = _studyTasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _studyTasks.removeAt(index);
      await _saveStudyTasks();
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
    // Add any missing tasks defensively
    for (final entry in map.entries) {
      if (!_studyTasks.any((t) => t.id == entry.key)) {
        _studyTasks.add(entry.value);
      }
    }
    await _saveStudyTasks();
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
    await _saveChecklists();
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
    await _saveChecklists();
    return updated;
  }

  @override
  Future<bool> deleteChecklist(String id) async {
    final index = _checklists.indexWhere((c) => c.id == id);
    if (index != -1) {
      _checklists.removeAt(index);
      await _saveChecklists();
      return true;
    }
    return false;
  }
}
