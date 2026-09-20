import '../models/checklist.dart';
import '../models/study_task.dart';
import '../models/text_note.dart';

/// Helper service providing pure ordering and search functions for Notes V3.
class NotesService {
  // ── Ordering Helpers ───────────────────────────────────────────────────

  /// Sorts [StudyTask] list keeping pinned tasks first while preserving relative order.
  static List<StudyTask> sortStudyTasks(Iterable<StudyTask> tasks) {
    final list = List<StudyTask>.from(tasks);
    final pinned = list.where((t) => t.isPinned).toList();
    final unpinned = list.where((t) => !t.isPinned).toList();
    return List.unmodifiable([...pinned, ...unpinned]);
  }

  /// Sorts [TextNote] list with:
  /// - Pinned notes first
  /// - Newest [updatedAt] first within pinned notes
  /// - Newest [updatedAt] first within unpinned notes
  static List<TextNote> sortTextNotes(Iterable<TextNote> notes) {
    final list = List<TextNote>.from(notes);
    list.sort((a, b) {
      // 1. Pinned status first
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      // 2. Newest updatedAt descending
      final updatedCmp = b.updatedAt.compareTo(a.updatedAt);
      if (updatedCmp != 0) {
        return updatedCmp;
      }
      // 3. Fallback to newest createdAt descending
      return b.createdAt.compareTo(a.createdAt);
    });
    return List.unmodifiable(list);
  }

  /// Sorts [Checklist] list with:
  /// - Pinned checklists first
  /// - Newest [updatedAt] first within pinned checklists
  /// - Newest [updatedAt] first within unpinned checklists
  static List<Checklist> sortChecklists(Iterable<Checklist> checklists) {
    final list = List<Checklist>.from(checklists);
    list.sort((a, b) {
      // 1. Pinned status first
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      // 2. Newest updatedAt descending
      final updatedCmp = b.updatedAt.compareTo(a.updatedAt);
      if (updatedCmp != 0) {
        return updatedCmp;
      }
      // 3. Fallback to newest createdAt descending
      return b.createdAt.compareTo(a.createdAt);
    });
    return List.unmodifiable(list);
  }

  // ── Search Foundation ──────────────────────────────────────────────────

  /// Filters [tasks] by [query] case-insensitively across `title` and `description`.
  /// Returns all [tasks] unchanged if [query] is empty or whitespace.
  static List<StudyTask> searchStudyTasks(
    Iterable<StudyTask> tasks,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return List.unmodifiable(tasks.toList());
    }

    final filtered = tasks.where((task) {
      final titleMatch = task.title.toLowerCase().contains(q);
      final descMatch = task.description.toLowerCase().contains(q);
      return titleMatch || descMatch;
    }).toList();

    return List.unmodifiable(filtered);
  }

  /// Filters [notes] by [query] case-insensitively across `title` and `content`.
  /// Returns all [notes] unchanged if [query] is empty or whitespace.
  static List<TextNote> searchTextNotes(
    Iterable<TextNote> notes,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return List.unmodifiable(notes.toList());
    }

    final filtered = notes.where((note) {
      final titleMatch = note.title.toLowerCase().contains(q);
      final contentMatch = note.content.toLowerCase().contains(q);
      return titleMatch || contentMatch;
    }).toList();

    return List.unmodifiable(filtered);
  }

  /// Filters [checklists] by [query] case-insensitively across `title`
  /// and any `ChecklistItem.text`.
  /// Returns all [checklists] unchanged if [query] is empty or whitespace.
  static List<Checklist> searchChecklists(
    Iterable<Checklist> checklists,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return List.unmodifiable(checklists.toList());
    }

    final filtered = checklists.where((checklist) {
      final titleMatch = checklist.title.toLowerCase().contains(q);
      final itemMatch = checklist.items.any(
        (item) => item.text.toLowerCase().contains(q),
      );
      return titleMatch || itemMatch;
    }).toList();

    return List.unmodifiable(filtered);
  }
}
