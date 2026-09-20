import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/notes/models/text_note.dart';
import 'package:daily_routine/notes/repositories/in_memory_notes_repository.dart';
import 'package:daily_routine/notes/screens/text_note_editor_screen.dart';
import 'package:daily_routine/theme/app_theme.dart';

void main() {
  group('TextNoteEditorScreen Widget Tests', () {
    late InMemoryNotesRepository repository;

    setUp(() {
      repository = InMemoryNotesRepository();
    });

    Widget createEditorScreen({TextNote? note}) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: TextNoteEditorScreen(
          note: note,
          repository: repository,
        ),
      );
    }

    testWidgets('creates a new text note with title and content and auto-saves', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createEditorScreen());
      await tester.pumpAndSettle();

      expect(find.text('New Note'), findsOneWidget);
      expect(find.byKey(const Key('note_delete_button')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('text_note_title_field')),
        'My First Note',
      );
      await tester.enterText(
        find.byKey(const Key('text_note_content_field')),
        'This is the content of my first note.',
      );

      // Before 500ms debounce: not yet saved
      expect((await repository.getTextNotes()).length, 0);

      // Advance clock past 500ms debounce
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      final notes = await repository.getTextNotes();
      expect(notes.length, 1);
      expect(notes.first.title, 'My First Note');
      expect(notes.first.content, 'This is the content of my first note.');
      expect(notes.first.isPinned, isFalse);
    });

    testWidgets('edits existing note and preserves original UUID and createdAt', (
      WidgetTester tester,
    ) async {
      final initialCreated = DateTime(2026, 1, 1, 10, 0);
      final initialUpdated = DateTime(2026, 1, 1, 10, 0);
      final note = TextNote(
        id: 'stable-note-uuid',
        title: 'Original Title',
        content: 'Original Content',
        isPinned: false,
        createdAt: initialCreated,
        updatedAt: initialUpdated,
      );
      await repository.addTextNote(note);

      await tester.pumpWidget(createEditorScreen(note: note));
      await tester.pumpAndSettle();

      expect(find.text('Edit Note'), findsOneWidget);
      expect(find.text('Original Title'), findsOneWidget);
      expect(find.text('Original Content'), findsOneWidget);
      expect(find.byKey(const Key('note_delete_button')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('text_note_title_field')),
        'Updated Title',
      );
      await tester.enterText(
        find.byKey(const Key('text_note_content_field')),
        'Updated Content',
      );

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      final notes = await repository.getTextNotes();
      expect(notes.length, 1);
      final updated = notes.first;
      expect(updated.id, 'stable-note-uuid');
      expect(updated.title, 'Updated Title');
      expect(updated.content, 'Updated Content');
      expect(updated.createdAt, initialCreated);
      expect(updated.updatedAt.isAfter(initialUpdated), isTrue);
    });

    testWidgets('flushes pending changes immediately on back button press', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createEditorScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('text_note_title_field')),
        'Quick Note',
      );
      await tester.enterText(
        find.byKey(const Key('text_note_content_field')),
        'Saved immediately on exit',
      );

      // Immediately tap back without waiting for 500ms
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      final notes = await repository.getTextNotes();
      expect(notes.length, 1);
      expect(notes.first.title, 'Quick Note');
      expect(notes.first.content, 'Saved immediately on exit');
    });

    testWidgets('exiting create screen with empty title and content does not save blank note', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createEditorScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      final notes = await repository.getTextNotes();
      expect(notes.isEmpty, isTrue);
    });

    testWidgets('pin and unpin persists immediately', (
      WidgetTester tester,
    ) async {
      final note = TextNote(
        id: 'pin-note-id',
        title: 'Pin Test',
        content: 'Content',
        isPinned: false,
      );
      await repository.addTextNote(note);

      await tester.pumpWidget(createEditorScreen(note: note));
      await tester.pumpAndSettle();

      // Pin
      await tester.tap(find.byKey(const Key('note_pin_button')));
      await tester.pumpAndSettle();

      var saved = await repository.getTextNoteById('pin-note-id');
      expect(saved?.isPinned, isTrue);

      // Unpin
      await tester.tap(find.byKey(const Key('note_pin_button')));
      await tester.pumpAndSettle();

      saved = await repository.getTextNoteById('pin-note-id');
      expect(saved?.isPinned, isFalse);
    });

    testWidgets('delete note requires confirmation and removes note from repository', (
      WidgetTester tester,
    ) async {
      final note = TextNote(
        id: 'delete-note-id',
        title: 'Note to Delete',
        content: 'Content to be deleted',
      );
      await repository.addTextNote(note);

      await tester.pumpWidget(createEditorScreen(note: note));
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.byKey(const Key('note_delete_button')));
      await tester.pumpAndSettle();

      // Verify dialog
      expect(find.text('Delete Note?'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to permanently delete "Note to Delete"? This cannot be undone.',
        ),
        findsOneWidget,
      );

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect((await repository.getTextNotes()).length, 1);

      // Tap delete again and confirm
      await tester.tap(find.byKey(const Key('note_delete_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect((await repository.getTextNotes()).isEmpty, isTrue);
    });

    testWidgets('flushes pending changes on app lifecycle paused state', (
      WidgetTester tester,
    ) async {
      final note = TextNote(
        id: 'lifecycle-note-id',
        title: 'Initial',
        content: 'Initial',
      );
      await repository.addTextNote(note);

      await tester.pumpWidget(createEditorScreen(note: note));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('text_note_title_field')),
        'Updated before pause',
      );

      // App transitions to paused
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      final saved = await repository.getTextNoteById('lifecycle-note-id');
      expect(saved?.title, 'Updated before pause');
    });
  });
}
