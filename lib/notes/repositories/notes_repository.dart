import '../models/checklist.dart';
import '../models/study_task.dart';
import '../models/text_note.dart';

/// Contract for accessing and manipulating Notes/Study V3 data.
///
/// Keeps Text Notes, Study Tasks, and Checklists strictly separated.
abstract class NotesRepository {
  // ── Text Notes ──────────────────────────────────────────────────────────

  /// Retrieves all text notes.
  Future<List<TextNote>> getTextNotes();

  /// Retrieves a specific text note by its [id], or null if not found.
  Future<TextNote?> getTextNoteById(String id);

  /// Adds a new text note.
  Future<TextNote> addTextNote(TextNote note);

  /// Updates an existing text note while preserving original [createdAt]
  /// and advancing [updatedAt].
  Future<TextNote> updateTextNote(TextNote note);

  /// Permanently removes a text note by its [id].
  /// Returns true if found and removed, false otherwise.
  Future<bool> deleteTextNote(String id);

  // ── Study Tasks ─────────────────────────────────────────────────────────

  /// Retrieves all study tasks.
  Future<List<StudyTask>> getStudyTasks();

  /// Retrieves a specific study task by its [id], or null if not found.
  Future<StudyTask?> getStudyTaskById(String id);

  /// Adds a new study task.
  Future<StudyTask> addStudyTask(StudyTask task);

  /// Updates an existing study task while preserving original [createdAt]
  /// and advancing [updatedAt].
  Future<StudyTask> updateStudyTask(StudyTask task);

  /// Permanently removes a study task by its [id].
  /// Returns true if found and removed, false otherwise.
  Future<bool> deleteStudyTask(String id);

  /// Reorders study tasks to match [orderedIds].
  Future<void> reorderStudyTasks(List<String> orderedIds);

  // ── Checklists (Legacy V3 support) ──────────────────────────────────────

  /// Retrieves all checklists.
  Future<List<Checklist>> getChecklists();

  /// Retrieves a specific checklist by its [id], or null if not found.
  Future<Checklist?> getChecklistById(String id);

  /// Adds a new checklist.
  Future<Checklist> addChecklist(Checklist checklist);

  /// Updates an existing checklist while preserving original [createdAt]
  /// and advancing [updatedAt]. Checklist item IDs remain stable.
  Future<Checklist> updateChecklist(Checklist checklist);

  /// Permanently removes a checklist by its [id].
  /// Returns true if found and removed, false otherwise.
  Future<bool> deleteChecklist(String id);
}
