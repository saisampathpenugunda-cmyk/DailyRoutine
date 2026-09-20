import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/notes/models/study_task.dart';
import 'package:daily_routine/notes/models/text_note.dart';
import 'package:daily_routine/notes/repositories/in_memory_notes_repository.dart';
import 'package:daily_routine/notes/screens/notes_screen.dart';
import 'package:daily_routine/notes/screens/study_task_editor_screen.dart';
import 'package:daily_routine/notes/screens/text_note_editor_screen.dart';

void main() {
  group('NotesScreen Widget Tests', () {
    late InMemoryNotesRepository repository;

    setUp(() {
      repository = InMemoryNotesRepository();
    });

    Widget createNotesScreen({InMemoryNotesRepository? repo}) {
      return MaterialApp(
        home: NotesScreen(
          repository: repo ?? repository,
        ),
      );
    }

    testWidgets('renders empty state when no study tasks or text notes exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createNotesScreen());
      await tester.pumpAndSettle();

      // Study Tasks tab is selected by default
      expect(find.text('No study tasks yet'), findsOneWidget);
      expect(
        find.text('Tap + Study Task to create your first task.'),
        findsOneWidget,
      );
      expect(find.text('+ Study Task'), findsOneWidget);

      // Switch to Notes tab
      await tester.tap(find.widgetWithText(Tab, 'Notes'));
      await tester.pumpAndSettle();

      expect(find.text('No notes yet'), findsOneWidget);
      expect(find.text('Tap + Note to create your first note.'), findsOneWidget);
      expect(find.text('+ Note'), findsOneWidget);
    });

    testWidgets('loads and displays study tasks with checkbox and pin status', (
      WidgetTester tester,
    ) async {
      await repository.addStudyTask(
        StudyTask(
          id: 't1',
          title: 'Revise Java OOP',
          description: 'Review inheritance and polymorphism.',
          isCompleted: false,
          isPinned: true,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      await tester.pumpWidget(createNotesScreen());
      await tester.pumpAndSettle();

      expect(find.text('Revise Java OOP'), findsOneWidget);
      expect(
        find.text('Review inheritance and polymorphism.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.push_pin), findsWidgets);
    });

    testWidgets('loads and displays text notes with preview and pin status', (
      WidgetTester tester,
    ) async {
      await repository.addTextNote(
        TextNote(
          id: 'n1',
          title: 'Meeting Thoughts',
          content: 'Discuss quarterly roadmap\nEnsure test coverage is 100%',
          isPinned: false,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      await tester.pumpWidget(createNotesScreen());
      await tester.pumpAndSettle();

      // Switch to Notes tab
      await tester.tap(find.widgetWithText(Tab, 'Notes'));
      await tester.pumpAndSettle();

      expect(find.text('Meeting Thoughts'), findsOneWidget);
      expect(
        find.text('Discuss quarterly roadmap\nEnsure test coverage is 100%'),
        findsOneWidget,
      );
    });

    testWidgets('orders items pinned-first', (
      WidgetTester tester,
    ) async {
      await repository.addStudyTask(
        StudyTask(
          id: 't1',
          title: 'Task Unpinned',
          isPinned: false,
        ),
      );
      await repository.addStudyTask(
        StudyTask(
          id: 't2',
          title: 'Task Pinned',
          isPinned: true,
        ),
      );

      await tester.pumpWidget(createNotesScreen());
      await tester.pumpAndSettle();

      final titles = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .where((t) => t != null && t.startsWith('Task '))
          .toList();

      expect(titles, [
        'Task Pinned',
        'Task Unpinned',
      ]);
    });

    testWidgets('filters study tasks case-insensitively on title and description while preserving order', (
      WidgetTester tester,
    ) async {
      await repository.addStudyTask(
        StudyTask(
          id: 't1',
          title: 'Revise Java OOP',
          description: 'Review inheritance',
          isPinned: false,
        ),
      );
      await repository.addStudyTask(
        StudyTask(
          id: 't2',
          title: 'Complete DSA assignment',
          description: 'Finish binary tree Java implementation',
          isPinned: true,
        ),
      );
      await repository.addStudyTask(
        StudyTask(
          id: 't3',
          title: 'Prepare SIH ideas',
          description: 'Hardware concepts',
          isPinned: false,
        ),
      );

      await tester.pumpWidget(createNotesScreen());
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byKey(const Key('notes_search_button')));
      await tester.pumpAndSettle();

      // Search for 'java'
      await tester.enterText(find.byKey(const Key('notes_search_field')), 'java');
      await tester.pumpAndSettle();

      expect(find.text('Complete DSA assignment'), findsOneWidget);
      expect(find.text('Revise Java OOP'), findsOneWidget);
      expect(find.text('Prepare SIH ideas'), findsNothing);
    });

    testWidgets('filters text notes case-insensitively on title and content while preserving order', (
      WidgetTester tester,
    ) async {
      await repository.addTextNote(
        TextNote(
          id: 'n1',
          title: 'Cooking Recipes',
          content: 'Pasta with tomatoes',
          isPinned: false,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 2),
        ),
      );
      await repository.addTextNote(
        TextNote(
          id: 'n2',
          title: 'Grocery Items',
          content: 'Buy tomatoes and basil',
          isPinned: true,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      await tester.pumpWidget(createNotesScreen());
      await tester.pumpAndSettle();

      // Switch to Notes tab
      await tester.tap(find.widgetWithText(Tab, 'Notes'));
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byKey(const Key('notes_search_button')));
      await tester.pumpAndSettle();

      // Search for 'tomatoes'
      await tester.enterText(
        find.byKey(const Key('notes_search_field')),
        'tomatoes',
      );
      await tester.pumpAndSettle();

      expect(find.text('Grocery Items'), findsOneWidget);
      expect(find.text('Cooking Recipes'), findsOneWidget);
    });

    testWidgets('pin and unpin study task immediately updates repository and list', (
      WidgetTester tester,
    ) async {
      final task = StudyTask(
        id: 't1',
        title: 'Project Ideas',
        description: 'Idea 1, Idea 2',
        isPinned: false,
      );
      await repository.addStudyTask(task);

      await tester.pumpWidget(createNotesScreen());
      await tester.pumpAndSettle();

      final pinBtn = find.byKey(const Key('study_task_pin_t1'));
      expect(pinBtn, findsOneWidget);

      await tester.tap(pinBtn);
      await tester.pumpAndSettle();

      final updated = await repository.getStudyTaskById('t1');
      expect(updated?.isPinned, isTrue);

      await tester.tap(pinBtn);
      await tester.pumpAndSettle();

      final unpinned = await repository.getStudyTaskById('t1');
      expect(unpinned?.isPinned, isFalse);
    });

    testWidgets('pin and unpin text note immediately updates repository and list', (
      WidgetTester tester,
    ) async {
      final note = TextNote(
        id: 'n1',
        title: 'Project Ideas',
        content: 'Idea 1, Idea 2',
        isPinned: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await repository.addTextNote(note);

      await tester.pumpWidget(createNotesScreen());
      await tester.pumpAndSettle();

      // Switch to Notes tab
      await tester.tap(find.widgetWithText(Tab, 'Notes'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Pin'), findsOneWidget);

      await tester.tap(find.byTooltip('Pin'));
      await tester.pumpAndSettle();

      final updated = await repository.getTextNoteById('n1');
      expect(updated?.isPinned, isTrue);
      expect(find.byTooltip('Unpin'), findsOneWidget);

      await tester.tap(find.byTooltip('Unpin'));
      await tester.pumpAndSettle();

      final unpinned = await repository.getTextNoteById('n1');
      expect(unpinned?.isPinned, isFalse);
    });

    testWidgets('delete study task requires confirmation dialog and permanently deletes', (
      WidgetTester tester,
    ) async {
      await repository.addStudyTask(
        StudyTask(
          id: 't1',
          title: 'Shopping Task',
        ),
      );

      await tester.pumpWidget(createNotesScreen());
      await tester.pumpAndSettle();

      expect(find.text('Shopping Task'), findsOneWidget);

      // Tap Delete button on task
      await tester.tap(find.byKey(const Key('study_task_delete_t1')));
      await tester.pumpAndSettle();

      // Dialog appears
      expect(find.text('Delete Study Task?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Shopping Task'), findsOneWidget);
      expect(await repository.getStudyTaskById('t1'), isNotNull);

      // Tap Delete again and Confirm
      await tester.tap(find.byKey(const Key('study_task_delete_t1')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Deleted
      expect(find.text('Shopping Task'), findsNothing);
      expect(await repository.getStudyTaskById('t1'), isNull);
      expect(find.text('No study tasks yet'), findsOneWidget);
    });

    testWidgets('delete text note requires confirmation dialog and permanently deletes', (
      WidgetTester tester,
    ) async {
      await repository.addTextNote(
        TextNote(
          id: 'n1',
          title: 'Draft',
          content: 'Some draft note',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      await tester.pumpWidget(createNotesScreen());
      await tester.pumpAndSettle();

      // Switch to Notes tab
      await tester.tap(find.widgetWithText(Tab, 'Notes'));
      await tester.pumpAndSettle();

      expect(find.text('Draft'), findsOneWidget);

      // Tap Delete
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Note?'), findsOneWidget);

      // Confirm
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Draft'), findsNothing);
      expect(await repository.getTextNoteById('n1'), isNull);
      expect(find.text('No notes yet'), findsOneWidget);
    });

    testWidgets('FAB navigates to StudyTaskEditorScreen on Study Tasks tab and TextNoteEditorScreen on Notes tab', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createNotesScreen());
      await tester.pumpAndSettle();

      // On Study Tasks tab -> FAB label is '+ Study Task'
      expect(find.text('+ Study Task'), findsOneWidget);
      await tester.tap(find.byKey(const Key('notes_fab')));
      await tester.pumpAndSettle();

      expect(find.byType(StudyTaskEditorScreen), findsOneWidget);
      expect(find.text('New Study Task'), findsOneWidget);
      expect(find.byKey(const Key('study_task_title_input')), findsOneWidget);

      // Return back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Switch to Notes tab -> FAB label is '+ Note'
      await tester.tap(find.widgetWithText(Tab, 'Notes'));
      await tester.pumpAndSettle();

      expect(find.text('+ Note'), findsOneWidget);
      await tester.tap(find.byKey(const Key('notes_fab')));
      await tester.pumpAndSettle();

      expect(find.byType(TextNoteEditorScreen), findsOneWidget);
      expect(find.text('New Note'), findsOneWidget);
      expect(find.byKey(const Key('text_note_title_field')), findsOneWidget);
    });

    testWidgets('tapping study task or note card navigates to respective editor screen', (
      WidgetTester tester,
    ) async {
      await repository.addStudyTask(
        StudyTask(
          id: 't1',
          title: 'My Study Task',
        ),
      );
      await repository.addTextNote(
        TextNote(
          id: 'n1',
          title: 'My Note',
          content: 'My Note Content',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      await tester.pumpWidget(createNotesScreen());
      await tester.pumpAndSettle();

      // Tap task card body
      await tester.tap(find.text('My Study Task'));
      await tester.pumpAndSettle();

      expect(find.byType(StudyTaskEditorScreen), findsOneWidget);
      expect(find.text('Edit Study Task'), findsOneWidget);
      expect(find.text('My Study Task'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Switch to Notes tab and tap note card
      await tester.tap(find.widgetWithText(Tab, 'Notes'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Note'));
      await tester.pumpAndSettle();

      expect(find.byType(TextNoteEditorScreen), findsOneWidget);
      expect(find.text('Edit Note'), findsOneWidget);
      expect(find.text('My Note'), findsOneWidget);
    });
  });
}
