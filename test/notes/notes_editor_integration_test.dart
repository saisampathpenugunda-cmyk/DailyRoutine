import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/notes/models/study_task.dart';
import 'package:daily_routine/notes/models/text_note.dart';
import 'package:daily_routine/notes/repositories/in_memory_notes_repository.dart';
import 'package:daily_routine/notes/screens/notes_screen.dart';
import 'package:daily_routine/theme/app_theme.dart';

void main() {
  group('Notes Screen & Editors Integration Tests', () {
    late InMemoryNotesRepository repository;

    setUp(() {
      repository = InMemoryNotesRepository();
    });

    Widget createNotesApp() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: NotesScreen(repository: repository),
      );
    }

    testWidgets('create text note from NotesScreen FAB updates list on return', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createNotesApp());
      await tester.pumpAndSettle();

      // Switch to Notes tab
      await tester.tap(find.widgetWithText(Tab, 'Notes'));
      await tester.pumpAndSettle();

      expect(find.text('No notes yet'), findsOneWidget);

      // Tap FAB
      await tester.tap(find.byKey(const Key('notes_fab')));
      await tester.pumpAndSettle();

      // In editor
      await tester.enterText(
        find.byKey(const Key('text_note_title_field')),
        'Integration Note',
      );
      await tester.enterText(
        find.byKey(const Key('text_note_content_field')),
        'Integration Content Body',
      );

      // Return
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Back on NotesScreen
      expect(find.text('Integration Note'), findsOneWidget);
      expect(find.text('Integration Content Body'), findsOneWidget);
    });

    testWidgets('edit text note from list updates title and preview on return', (
      WidgetTester tester,
    ) async {
      await repository.addTextNote(
        TextNote(
          id: 'int-note-1',
          title: 'Original Title',
          content: 'Original Content',
        ),
      );

      await tester.pumpWidget(createNotesApp());
      await tester.pumpAndSettle();

      // Switch to Notes tab
      await tester.tap(find.widgetWithText(Tab, 'Notes'));
      await tester.pumpAndSettle();

      // Tap note card
      await tester.tap(find.text('Original Title'));
      await tester.pumpAndSettle();

      // Edit title and content
      await tester.enterText(
        find.byKey(const Key('text_note_title_field')),
        'Edited Title',
      );
      await tester.enterText(
        find.byKey(const Key('text_note_content_field')),
        'Edited Content',
      );

      // Return
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Edited Title'), findsOneWidget);
      expect(find.text('Edited Content'), findsOneWidget);
      expect(find.text('Original Title'), findsNothing);
    });

    testWidgets('delete text note from editor removes record from NotesScreen', (
      WidgetTester tester,
    ) async {
      await repository.addTextNote(
        TextNote(
          id: 'delete-note-id',
          title: 'To Be Deleted Note',
          content: 'Will be deleted',
        ),
      );

      await tester.pumpWidget(createNotesApp());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Tab, 'Notes'));
      await tester.pumpAndSettle();

      expect(find.text('To Be Deleted Note'), findsOneWidget);

      await tester.tap(find.text('To Be Deleted Note'));
      await tester.pumpAndSettle();

      // Tap delete in editor
      await tester.tap(find.byKey(const Key('note_delete_button')));
      await tester.pumpAndSettle();

      // Confirm delete in dialog
      await tester.tap(find.byKey(const Key('confirm_delete_note_button')));
      await tester.pumpAndSettle();

      // Returned to NotesScreen
      expect(find.text('To Be Deleted Note'), findsNothing);
      expect(find.text('No notes yet'), findsOneWidget);
    });

    testWidgets('pin text note from editor updates pinned-first order on NotesScreen', (
      WidgetTester tester,
    ) async {
      await repository.addTextNote(
        TextNote(
          id: 'note-a',
          title: 'Note A',
          content: 'A',
          updatedAt: DateTime(2026, 1, 2),
        ),
      );
      await repository.addTextNote(
        TextNote(
          id: 'note-b',
          title: 'Note B',
          content: 'B',
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      await tester.pumpWidget(createNotesApp());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Tab, 'Notes'));
      await tester.pumpAndSettle();

      // Tap Note B (currently second because Note A has newer updatedAt)
      await tester.tap(find.text('Note B'));
      await tester.pumpAndSettle();

      // Pin Note B in editor
      await tester.tap(find.byKey(const Key('note_pin_button')));
      await tester.pumpAndSettle();

      // Return
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Verify Note B has pin indicator on NotesScreen
      final noteBCard = find.ancestor(
        of: find.text('Note B'),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(
          of: noteBCard,
          matching: find.byIcon(Icons.push_pin),
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('create study task from FAB updates list on return', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createNotesApp());
      await tester.pumpAndSettle();

      expect(find.text('No study tasks yet'), findsOneWidget);

      // Tap FAB on Study Tasks tab
      await tester.tap(find.byKey(const Key('notes_fab')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('study_task_title_input')),
        'Revise Java OOP',
      );
      await tester.enterText(
        find.byKey(const Key('study_task_description_input')),
        'Review inheritance and polymorphism.',
      );
      await tester.tap(find.byKey(const Key('study_task_save_button')));
      await tester.pumpAndSettle();

      expect(find.text('Revise Java OOP'), findsOneWidget);
      expect(find.text('Review inheritance and polymorphism.'), findsOneWidget);
    });

    testWidgets('search on NotesScreen finds newly created study task records', (
      WidgetTester tester,
    ) async {
      await repository.addStudyTask(
        StudyTask(
          id: 't-search-1',
          title: 'Buy Groceries',
          description: 'Apples, bananas, milk',
        ),
      );
      await repository.addStudyTask(
        StudyTask(
          id: 't-search-2',
          title: 'Gym Workout',
          description: 'Squats and bench press',
        ),
      );

      await tester.pumpWidget(createNotesApp());
      await tester.pumpAndSettle();

      expect(find.text('Buy Groceries'), findsOneWidget);
      expect(find.text('Gym Workout'), findsOneWidget);

      // Open search
      await tester.tap(find.byKey(const Key('notes_search_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('notes_search_field')),
        'apples',
      );
      await tester.pumpAndSettle();

      expect(find.text('Buy Groceries'), findsOneWidget);
      expect(find.text('Gym Workout'), findsNothing);
    });

    testWidgets('study task and text note storage remain strictly independent', (
      WidgetTester tester,
    ) async {
      await repository.addTextNote(
        TextNote(id: 'independent-note', title: 'Independent Note'),
      );
      await repository.addStudyTask(
        StudyTask(id: 'independent-task', title: 'Independent Task'),
      );

      await tester.pumpWidget(createNotesApp());
      await tester.pumpAndSettle();

      // Delete study task via UI
      await tester.tap(find.byKey(const Key('study_task_delete_independent-task')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Independent Task'), findsNothing);

      // Verify text note is unaffected
      await tester.tap(find.widgetWithText(Tab, 'Notes'));
      await tester.pumpAndSettle();

      expect(find.text('Independent Note'), findsOneWidget);
      final notes = await repository.getTextNotes();
      expect(notes.length, 1);
      expect(notes.first.title, 'Independent Note');
    });
  });
}
