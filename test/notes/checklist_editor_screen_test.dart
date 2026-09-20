import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/notes/models/checklist.dart';
import 'package:daily_routine/notes/models/checklist_item.dart';
import 'package:daily_routine/notes/repositories/in_memory_notes_repository.dart';
import 'package:daily_routine/notes/screens/checklist_editor_screen.dart';
import 'package:daily_routine/theme/app_theme.dart';

void main() {
  group('ChecklistEditorScreen Widget Tests', () {
    late InMemoryNotesRepository repository;

    setUp(() {
      repository = InMemoryNotesRepository();
    });

    Widget createEditorScreen({Checklist? checklist}) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: ChecklistEditorScreen(
          checklist: checklist,
          repository: repository,
        ),
      );
    }

    testWidgets('creates a new checklist and auto-saves title and items', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createEditorScreen());
      await tester.pumpAndSettle();

      expect(find.text('New Checklist'), findsOneWidget);
      expect(find.byKey(const Key('checklist_delete_button')), findsNothing);

      // Enter title
      await tester.enterText(
        find.byKey(const Key('checklist_title_field')),
        'Trip Packing',
      );

      // Add item
      await tester.tap(find.byKey(const Key('add_checklist_item_button')));
      await tester.pumpAndSettle();

      expect(find.text('0 of 1 completed'), findsOneWidget);

      final itemFields = find.byType(TextField);
      // itemFields has title field + item field
      expect(itemFields, findsNWidgets(2));

      await tester.enterText(itemFields.last, 'Passport');

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      final checklists = await repository.getChecklists();
      expect(checklists.length, 1);
      expect(checklists.first.title, 'Trip Packing');
      expect(checklists.first.items.length, 1);
      expect(checklists.first.items.first.text, 'Passport');
      expect(checklists.first.items.first.isCompleted, isFalse);
    });

    testWidgets('edits existing checklist title preserving UUID and createdAt', (
      WidgetTester tester,
    ) async {
      final initialCreated = DateTime(2026, 1, 1, 10, 0);
      final initialUpdated = DateTime(2026, 1, 1, 10, 0);
      final checklist = Checklist(
        id: 'stable-checklist-uuid',
        title: 'Original Title',
        items: [
          ChecklistItem(id: 'item-1', text: 'Task 1', isCompleted: false, order: 0),
        ],
        isPinned: false,
        createdAt: initialCreated,
        updatedAt: initialUpdated,
      );
      await repository.addChecklist(checklist);

      await tester.pumpWidget(createEditorScreen(checklist: checklist));
      await tester.pumpAndSettle();

      expect(find.text('Edit Checklist'), findsOneWidget);
      expect(find.text('Original Title'), findsOneWidget);
      expect(find.text('Task 1'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('checklist_title_field')),
        'Updated Title',
      );

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      final checklists = await repository.getChecklists();
      expect(checklists.length, 1);
      final updated = checklists.first;
      expect(updated.id, 'stable-checklist-uuid');
      expect(updated.title, 'Updated Title');
      expect(updated.createdAt, initialCreated);
      expect(updated.updatedAt.isAfter(initialUpdated), isTrue);
    });

    testWidgets('edits item text while preserving item UUID', (
      WidgetTester tester,
    ) async {
      final checklist = Checklist(
        id: 'cl-edit-item',
        title: 'Groceries',
        items: [
          ChecklistItem(id: 'stable-item-id', text: 'Milk', isCompleted: false, order: 0),
        ],
      );
      await repository.addChecklist(checklist);

      await tester.pumpWidget(createEditorScreen(checklist: checklist));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('checklist_item_field_stable-item-id')),
        'Oat Milk',
      );

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      final saved = await repository.getChecklistById('cl-edit-item');
      expect(saved?.items.length, 1);
      expect(saved?.items.first.id, 'stable-item-id');
      expect(saved?.items.first.text, 'Oat Milk');
    });

    testWidgets('checks and unchecks checklist items and updates progress count', (
      WidgetTester tester,
    ) async {
      final checklist = Checklist(
        id: 'cl-check-test',
        title: 'Tasks',
        items: [
          ChecklistItem(id: 'it-1', text: 'First', isCompleted: false, order: 0),
          ChecklistItem(id: 'it-2', text: 'Second', isCompleted: false, order: 1),
        ],
      );
      await repository.addChecklist(checklist);

      await tester.pumpWidget(createEditorScreen(checklist: checklist));
      await tester.pumpAndSettle();

      expect(find.text('0 of 2 completed'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);

      // Check first item
      await tester.tap(find.byKey(const Key('checklist_item_checkbox_it-1')));
      await tester.pumpAndSettle();

      expect(find.text('1 of 2 completed'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);

      var saved = await repository.getChecklistById('cl-check-test');
      expect(saved?.items.first.isCompleted, isTrue);
      expect(saved?.items.last.isCompleted, isFalse);

      // Uncheck first item
      await tester.tap(find.byKey(const Key('checklist_item_checkbox_it-1')));
      await tester.pumpAndSettle();

      expect(find.text('0 of 2 completed'), findsOneWidget);
      saved = await repository.getChecklistById('cl-check-test');
      expect(saved?.items.first.isCompleted, isFalse);
    });

    testWidgets('deletes checklist item and updates remaining order and progress', (
      WidgetTester tester,
    ) async {
      final checklist = Checklist(
        id: 'cl-del-item',
        title: 'Delete Test',
        items: [
          ChecklistItem(id: 'it-1', text: 'Item 1', isCompleted: true, order: 0),
          ChecklistItem(id: 'it-2', text: 'Item 2', isCompleted: false, order: 1),
          ChecklistItem(id: 'it-3', text: 'Item 3', isCompleted: false, order: 2),
        ],
      );
      await repository.addChecklist(checklist);

      await tester.pumpWidget(createEditorScreen(checklist: checklist));
      await tester.pumpAndSettle();

      expect(find.text('1 of 3 completed'), findsOneWidget);

      // Delete Item 2
      await tester.tap(find.byKey(const Key('checklist_item_delete_it-2')));
      await tester.pumpAndSettle();

      expect(find.text('1 of 2 completed'), findsOneWidget);
      expect(find.text('Item 2'), findsNothing);

      final saved = await repository.getChecklistById('cl-del-item');
      expect(saved?.items.length, 2);
      expect(saved?.items[0].id, 'it-1');
      expect(saved?.items[0].order, 0);
      expect(saved?.items[1].id, 'it-3');
      expect(saved?.items[1].order, 1);
    });

    testWidgets('pin and unpin checklist persists immediately', (
      WidgetTester tester,
    ) async {
      final checklist = Checklist(
        id: 'pin-cl-id',
        title: 'Pin Checklist Test',
        items: const [],
        isPinned: false,
      );
      await repository.addChecklist(checklist);

      await tester.pumpWidget(createEditorScreen(checklist: checklist));
      await tester.pumpAndSettle();

      // Pin
      await tester.tap(find.byKey(const Key('checklist_pin_button')));
      await tester.pumpAndSettle();

      var saved = await repository.getChecklistById('pin-cl-id');
      expect(saved?.isPinned, isTrue);

      // Unpin
      await tester.tap(find.byKey(const Key('checklist_pin_button')));
      await tester.pumpAndSettle();

      saved = await repository.getChecklistById('pin-cl-id');
      expect(saved?.isPinned, isFalse);
    });

    testWidgets('delete checklist requires confirmation dialog and deletes permanently', (
      WidgetTester tester,
    ) async {
      final checklist = Checklist(
        id: 'del-cl-id',
        title: 'Checklist to Delete',
        items: const [],
      );
      await repository.addChecklist(checklist);

      await tester.pumpWidget(createEditorScreen(checklist: checklist));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('checklist_delete_button')));
      await tester.pumpAndSettle();

      expect(find.text('Delete Checklist?'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to permanently delete "Checklist to Delete"? This cannot be undone.',
        ),
        findsOneWidget,
      );

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect((await repository.getChecklists()).length, 1);

      // Confirm Delete
      await tester.tap(find.byKey(const Key('checklist_delete_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect((await repository.getChecklists()).isEmpty, isTrue);
    });

    testWidgets('flushes pending changes on back button press', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createEditorScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('checklist_title_field')),
        'Flushed Checklist',
      );

      // Tap back immediately
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      final checklists = await repository.getChecklists();
      expect(checklists.length, 1);
      expect(checklists.first.title, 'Flushed Checklist');
    });

    testWidgets('exiting create screen with empty title and no items does not save blank checklist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createEditorScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      final checklists = await repository.getChecklists();
      expect(checklists.isEmpty, isTrue);
    });
  });
}
