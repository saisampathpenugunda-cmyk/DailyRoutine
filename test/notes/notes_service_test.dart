import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/notes/models/checklist.dart';
import 'package:daily_routine/notes/models/checklist_item.dart';
import 'package:daily_routine/notes/models/text_note.dart';
import 'package:daily_routine/notes/services/notes_service.dart';

void main() {
  group('NotesService Ordering & Search Tests', () {
    // ── 8. Pinning and Ordering Tests ─────────────────────────────────────

    test('8. sortTextNotes places pinned items first, then newest updated first within each group', () {
      final t1 = DateTime(2026, 9, 10, 10, 0);
      final t2 = DateTime(2026, 9, 10, 12, 0);
      final t3 = DateTime(2026, 9, 10, 14, 0);
      final t4 = DateTime(2026, 9, 10, 16, 0);

      final unpinnedOld = TextNote(
        id: 'unpinned-old',
        title: 'Unpinned Old',
        isPinned: false,
        updatedAt: t1,
      );
      final unpinnedNew = TextNote(
        id: 'unpinned-new',
        title: 'Unpinned New',
        isPinned: false,
        updatedAt: t4,
      );
      final pinnedOld = TextNote(
        id: 'pinned-old',
        title: 'Pinned Old',
        isPinned: true,
        updatedAt: t2,
      );
      final pinnedNew = TextNote(
        id: 'pinned-new',
        title: 'Pinned New',
        isPinned: true,
        updatedAt: t3,
      );

      // Input in mixed order
      final input = [unpinnedOld, pinnedOld, unpinnedNew, pinnedNew];
      final sorted = NotesService.sortTextNotes(input);

      // Expected order:
      // 1. pinnedNew (pinned, t3)
      // 2. pinnedOld (pinned, t2)
      // 3. unpinnedNew (unpinned, t4)
      // 4. unpinnedOld (unpinned, t1)
      expect(sorted.map((n) => n.id).toList(), [
        'pinned-new',
        'pinned-old',
        'unpinned-new',
        'unpinned-old',
      ]);
    });

    test('8. sortChecklists places pinned items first, then newest updated first within each group', () {
      final t1 = DateTime(2026, 9, 10, 8, 0);
      final t2 = DateTime(2026, 9, 10, 9, 0);
      final t3 = DateTime(2026, 9, 10, 10, 0);
      final t4 = DateTime(2026, 9, 10, 11, 0);

      final cUnpinnedOld = Checklist(
        id: 'c-unpinned-old',
        title: 'Chores',
        isPinned: false,
        updatedAt: t1,
      );
      final cUnpinnedNew = Checklist(
        id: 'c-unpinned-new',
        title: 'Shopping',
        isPinned: false,
        updatedAt: t4,
      );
      final cPinnedOld = Checklist(
        id: 'c-pinned-old',
        title: 'Work Tasks',
        isPinned: true,
        updatedAt: t2,
      );
      final cPinnedNew = Checklist(
        id: 'c-pinned-new',
        title: 'Critical Bugs',
        isPinned: true,
        updatedAt: t3,
      );

      final sorted = NotesService.sortChecklists([
        cUnpinnedOld,
        cPinnedOld,
        cUnpinnedNew,
        cPinnedNew,
      ]);

      expect(sorted.map((c) => c.id).toList(), [
        'c-pinned-new',
        'c-pinned-old',
        'c-unpinned-new',
        'c-unpinned-old',
      ]);
    });

    // ── 9. Search Tests ───────────────────────────────────────────────────

    test('9. searchTextNotes matches title and content case-insensitively', () {
      final n1 = TextNote(
        id: '1',
        title: 'Flutter Engine Architecture',
        content: 'Impeller rendering pipeline',
      );
      final n2 = TextNote(
        id: '2',
        title: 'Grocery List',
        content: 'Organic Milk, Apples, and Bananas',
      );
      final n3 = TextNote(
        id: '3',
        title: 'Meeting Notes',
        content: 'Discuss FLUTTER performance with team',
      );

      // Search by title lowercase
      final res1 = NotesService.searchTextNotes([n1, n2, n3], 'flutter');
      expect(res1.length, 2);
      expect(res1.map((n) => n.id), containsAll(['1', '3']));

      // Search by title uppercase
      final res2 = NotesService.searchTextNotes([n1, n2, n3], 'ENGINE');
      expect(res2.length, 1);
      expect(res2.first.id, '1');

      // Search by content mixed case
      final res3 = NotesService.searchTextNotes([n1, n2, n3], 'oRgAnIc');
      expect(res3.length, 1);
      expect(res3.first.id, '2');

      // Empty / whitespace query returns all
      expect(NotesService.searchTextNotes([n1, n2, n3], '').length, 3);
      expect(NotesService.searchTextNotes([n1, n2, n3], '   ').length, 3);

      // No match returns empty list
      expect(NotesService.searchTextNotes([n1, n2, n3], 'Kotlin'), isEmpty);
    });

    test('9. searchChecklists matches title and checklist item text case-insensitively', () {
      final c1 = Checklist(
        id: 'chk-1',
        title: 'Weekend Trip Packing',
        items: [
          ChecklistItem(id: 'i1', text: 'Passport and Visa'),
          ChecklistItem(id: 'i2', text: 'Sunscreen SPF 50'),
        ],
      );
      final c2 = Checklist(
        id: 'chk-2',
        title: 'Hardware Tools',
        items: [
          ChecklistItem(id: 'i3', text: 'Screwdriver set'),
          ChecklistItem(id: 'i4', text: 'Power Drill'),
        ],
      );
      final c3 = Checklist(
        id: 'chk-3',
        title: 'Daily Exercises',
        items: [
          ChecklistItem(id: 'i5', text: '20 pushups'),
          ChecklistItem(id: 'i6', text: 'Running 5km'),
        ],
      );

      // Search by checklist title
      final r1 = NotesService.searchChecklists([c1, c2, c3], 'WEEKEND');
      expect(r1.length, 1);
      expect(r1.first.id, 'chk-1');

      // Search by item text
      final r2 = NotesService.searchChecklists([c1, c2, c3], 'drill');
      expect(r2.length, 1);
      expect(r2.first.id, 'chk-2');

      // Search matching item text across mixed case
      final r3 = NotesService.searchChecklists([c1, c2, c3], 'pAsSpOrT');
      expect(r3.length, 1);
      expect(r3.first.id, 'chk-1');

      // Empty / whitespace query returns all
      expect(NotesService.searchChecklists([c1, c2, c3], '').length, 3);
      expect(NotesService.searchChecklists([c1, c2, c3], '   ').length, 3);

      // No match returns empty list
      expect(NotesService.searchChecklists([c1, c2, c3], 'NonExistentTerm'), isEmpty);
    });
  });
}
