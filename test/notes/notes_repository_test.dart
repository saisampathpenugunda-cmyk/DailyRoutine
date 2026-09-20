import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_routine/notes/exceptions/notes_exception.dart';
import 'package:daily_routine/notes/models/checklist.dart';
import 'package:daily_routine/notes/models/checklist_item.dart';
import 'package:daily_routine/notes/models/text_note.dart';
import 'package:daily_routine/notes/repositories/in_memory_notes_repository.dart';
import 'package:daily_routine/notes/storage/shared_preferences_notes_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InMemoryNotesRepository Tests', () {
    late InMemoryNotesRepository repo;

    setUp(() {
      repo = InMemoryNotesRepository();
    });

    test('Text Notes CRUD operations', () async {
      expect(await repo.getTextNotes(), isEmpty);

      final note = TextNote(
        id: 'n-1',
        title: 'Ideas',
        content: 'Idea 1 and 2',
      );

      final added = await repo.addTextNote(note);
      expect(added.id, 'n-1');
      expect(await repo.getTextNotes(), [added]);
      expect(await repo.getTextNoteById('n-1'), equals(added));
      expect(await repo.getTextNoteById('missing'), isNull);

      // Duplicate add throws NotesException
      expect(() => repo.addTextNote(note), throwsA(isA<NotesException>()));

      // Update
      final updated = await repo.updateTextNote(
        added.copyWith(title: 'Updated Ideas'),
      );
      expect(updated.title, 'Updated Ideas');
      expect((await repo.getTextNoteById('n-1'))?.title, 'Updated Ideas');

      // Delete
      expect(await repo.deleteTextNote('n-1'), isTrue);
      expect(await repo.getTextNotes(), isEmpty);
      expect(await repo.deleteTextNote('n-1'), isFalse);
    });

    test('Checklists CRUD operations', () async {
      expect(await repo.getChecklists(), isEmpty);

      final checklist = Checklist(
        id: 'c-1',
        title: 'My Checklist',
        items: [
          ChecklistItem(id: 'i-1', text: 'Step 1'),
        ],
      );

      final added = await repo.addChecklist(checklist);
      expect(added.id, 'c-1');
      expect(await repo.getChecklists(), [added]);
      expect(await repo.getChecklistById('c-1'), equals(added));
      expect(await repo.getChecklistById('missing'), isNull);

      // Duplicate add throws NotesException
      expect(() => repo.addChecklist(checklist), throwsA(isA<NotesException>()));

      // Update
      final updated = await repo.updateChecklist(
        added.copyWith(
          title: 'Updated Checklist',
          items: [
            ChecklistItem(id: 'i-1', text: 'Step 1', isCompleted: true),
            ChecklistItem(id: 'i-2', text: 'Step 2'),
          ],
        ),
      );
      expect(updated.title, 'Updated Checklist');
      expect(updated.items.length, 2);
      expect(updated.items[0].id, 'i-1');
      expect(updated.items[0].isCompleted, isTrue);

      // Delete
      expect(await repo.deleteChecklist('c-1'), isTrue);
      expect(await repo.getChecklists(), isEmpty);
      expect(await repo.deleteChecklist('c-1'), isFalse);
    });

    test('5 & 6. Repository update preserves createdAt and advances updatedAt', () async {
      final initialCreated = DateTime(2026, 9, 1, 10, 0);
      final initialUpdated = DateTime(2026, 9, 1, 10, 0);

      final note = TextNote(
        id: 'n-preserve',
        title: 'Original',
        createdAt: initialCreated,
        updatedAt: initialUpdated,
      );
      await repo.addTextNote(note);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Attempt to tamper with createdAt in the payload
      final tampered = TextNote(
        id: 'n-preserve',
        title: 'Tampered Attempt',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: initialUpdated,
      );

      final result = await repo.updateTextNote(tampered);

      // Repository strictly preserved original createdAt
      expect(result.createdAt, initialCreated);
      expect(result.updatedAt.isAfter(initialUpdated), isTrue);

      final stored = await repo.getTextNoteById('n-preserve');
      expect(stored?.createdAt, initialCreated);
      expect(stored?.updatedAt.isAfter(initialUpdated), isTrue);
    });
  });

  group('SharedPreferencesNotesRepository Persistence Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('11. Persistence survives repository reload across separate storage keys', () async {
      final repo1 = SharedPreferencesNotesRepository(prefs);

      // Add a Text Note
      final note = TextNote(
        id: 'note-persist-1',
        title: 'Persistent Title',
        content: 'Persistent Content',
        isPinned: true,
      );
      await repo1.addTextNote(note);

      // Add a Checklist
      final checklist = Checklist(
        id: 'chk-persist-1',
        title: 'Persistent Checklist',
        items: [
          ChecklistItem(id: 'item-1', text: 'Milk', isCompleted: true),
          ChecklistItem(id: 'item-2', text: 'Bread', isCompleted: false),
        ],
      );
      await repo1.addChecklist(checklist);

      // Verify separate storage keys are used in SharedPreferences
      expect(prefs.getString(SharedPreferencesNotesRepository.textNotesKey), contains('note-persist-1'));
      expect(prefs.getString(SharedPreferencesNotesRepository.textNotesKey), isNot(contains('chk-persist-1')));

      expect(prefs.getString(SharedPreferencesNotesRepository.checklistsKey), contains('chk-persist-1'));
      expect(prefs.getString(SharedPreferencesNotesRepository.checklistsKey), isNot(contains('note-persist-1')));

      // Simulate app restart / new repository instance
      final repo2 = SharedPreferencesNotesRepository(prefs);

      final loadedNotes = await repo2.getTextNotes();
      expect(loadedNotes.length, 1);
      expect(loadedNotes.first.id, 'note-persist-1');
      expect(loadedNotes.first.title, 'Persistent Title');
      expect(loadedNotes.first.content, 'Persistent Content');
      expect(loadedNotes.first.isPinned, isTrue);

      final loadedChecklists = await repo2.getChecklists();
      expect(loadedChecklists.length, 1);
      expect(loadedChecklists.first.id, 'chk-persist-1');
      expect(loadedChecklists.first.title, 'Persistent Checklist');
      expect(loadedChecklists.first.items.length, 2);
      expect(loadedChecklists.first.items[0].id, 'item-1');
      expect(loadedChecklists.first.items[0].isCompleted, isTrue);
      expect(loadedChecklists.first.items[1].id, 'item-2');
      expect(loadedChecklists.first.items[1].isCompleted, isFalse);
    });

    test('10. Corrupted SharedPreferences data is handled defensively on load', () async {
      // Intentionally insert corrupted non-JSON strings into preferences
      await prefs.setString(
        SharedPreferencesNotesRepository.textNotesKey,
        '{ corrupted json string missing brackets',
      );
      await prefs.setString(
        SharedPreferencesNotesRepository.checklistsKey,
        '<<<not even json>>>',
      );

      // Instantiating repository must NOT throw or crash
      final repo = SharedPreferencesNotesRepository(prefs);

      expect(await repo.getTextNotes(), isEmpty);
      expect(await repo.getChecklists(), isEmpty);

      // Can add new items normally after corrupted load
      await repo.addTextNote(TextNote(id: 'recovered-1', title: 'New Note'));
      expect((await repo.getTextNotes()).length, 1);
    });
  });
}
