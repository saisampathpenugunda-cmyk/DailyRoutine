import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/notes/models/study_task.dart';
import 'package:daily_routine/notes/repositories/in_memory_notes_repository.dart';
import 'package:daily_routine/notes/screens/notes_screen.dart';
import 'package:daily_routine/notes/screens/study_task_editor_screen.dart';
import 'package:daily_routine/notes/services/notes_service.dart';

void main() {
  group('StudyTask Model & Repository Unit Tests', () {
    test('create task with name only', () {
      final task = StudyTask(title: 'Revise Java OOP');
      expect(task.title, 'Revise Java OOP');
      expect(task.description, '');
      expect(task.isCompleted, false);
      expect(task.isPinned, false);
      expect(task.id, isNotEmpty);
      expect(task.createdAt, isNotNull);
      expect(task.updatedAt, isNotNull);
    });

    test('create task with name + description', () {
      final task = StudyTask(
        title: 'Revise Java OOP',
        description: 'Review inheritance and polymorphism.',
      );
      expect(task.title, 'Revise Java OOP');
      expect(task.description, 'Review inheritance and polymorphism.');
      expect(task.isCompleted, false);
    });

    test('direct completion toggle and persistence', () async {
      final repo = InMemoryNotesRepository();
      final task = await repo.addStudyTask(StudyTask(
        title: 'Complete DSA assignment',
        description: 'Finish binary tree implementation.',
      ));

      expect(task.isCompleted, false);

      // Check
      final checked = task.copyWith(isCompleted: true);
      await repo.updateStudyTask(checked);

      final fetched = await repo.getStudyTaskById(task.id);
      expect(fetched!.isCompleted, true);

      // Uncheck
      final unchecked = fetched.copyWith(isCompleted: false);
      await repo.updateStudyTask(unchecked);

      final reFetched = await repo.getStudyTaskById(task.id);
      expect(reFetched!.isCompleted, false);
    });

    test('stable UUID and createdAt preservation across updates', () async {
      final repo = InMemoryNotesRepository();
      final original = await repo.addStudyTask(StudyTask(
        id: 'stable-task-uuid-1',
        title: 'Initial Title',
        createdAt: DateTime(2026, 1, 1),
      ));

      final updated = original.copyWith(
        title: 'Updated Title',
        description: 'New Description',
      );
      await repo.updateStudyTask(updated);

      final fetched = await repo.getStudyTaskById('stable-task-uuid-1');
      expect(fetched!.id, 'stable-task-uuid-1');
      expect(fetched.createdAt, DateTime(2026, 1, 1));
      expect(fetched.title, 'Updated Title');
      expect(fetched.description, 'New Description');
    });

    test('reordering preserves task UUID and completion state', () async {
      final repo = InMemoryNotesRepository();
      await repo.addStudyTask(StudyTask(
        id: 't1',
        title: 'Task 1',
        isCompleted: true,
      ));
      await repo.addStudyTask(StudyTask(
        id: 't2',
        title: 'Task 2',
        isCompleted: false,
      ));

      await repo.reorderStudyTasks(['t2', 't1']);
      final tasks = await repo.getStudyTasks();

      expect(tasks[0].id, 't2');
      expect(tasks[0].isCompleted, false);
      expect(tasks[1].id, 't1');
      expect(tasks[1].isCompleted, true);
    });

    test('pinning and pinned-first ordering', () async {
      final t1 = StudyTask(id: 't1', title: 'Task 1', isPinned: false);
      final t2 = StudyTask(id: 't2', title: 'Task 2', isPinned: true);
      final t3 = StudyTask(id: 't3', title: 'Task 3', isPinned: false);

      final sorted = NotesService.sortStudyTasks([t1, t2, t3]);
      expect(sorted[0].id, 't2');
      expect(sorted[0].isPinned, true);
      expect(sorted[1].id, 't1');
      expect(sorted[2].id, 't3');
    });

    test('search filters across title and description case-insensitively', () {
      final t1 = StudyTask(
        title: 'Revise Java OOP',
        description: 'Review inheritance and polymorphism.',
      );
      final t2 = StudyTask(
        title: 'Complete DSA assignment',
        description: 'Finish binary tree implementation.',
      );

      final matchTitle = NotesService.searchStudyTasks([t1, t2], 'java');
      expect(matchTitle.length, 1);
      expect(matchTitle.first.title, 'Revise Java OOP');

      final matchDesc = NotesService.searchStudyTasks([t1, t2], 'binary tree');
      expect(matchDesc.length, 1);
      expect(matchDesc.first.title, 'Complete DSA assignment');
    });
  });

  group('StudyTask Widget & Screen Tests', () {
    late InMemoryNotesRepository repository;

    setUp(() {
      repository = InMemoryNotesRepository();
    });

    Widget createScreen(Widget child) {
      return MaterialApp(
        home: child,
      );
    }

    testWidgets('renders FAB with "+ Study Task" and exactly one plus icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen(NotesScreen(repository: repository)));
      await tester.pumpAndSettle();

      // Study Tasks is tab 0
      expect(find.text('+ Study Task'), findsOneWidget);
      // No secondary add icon
      expect(find.byIcon(Icons.add), findsNothing);

      // Switch to Notes tab
      await tester.tap(find.widgetWithText(Tab, 'Notes'));
      await tester.pumpAndSettle();

      expect(find.text('+ Note'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('direct checkbox toggle does not open editor and updates persistence', (
      WidgetTester tester,
    ) async {
      await repository.addStudyTask(StudyTask(
        id: 'task-1',
        title: 'Revise Java OOP',
        description: 'Review inheritance and polymorphism.',
        isCompleted: false,
      ));

      await tester.pumpWidget(createScreen(NotesScreen(repository: repository)));
      await tester.pumpAndSettle();

      expect(find.text('Revise Java OOP'), findsOneWidget);
      expect(find.text('Review inheritance and polymorphism.'), findsOneWidget);

      // Tap direct checkbox
      final checkboxFinder = find.byKey(const Key('study_task_checkbox_task-1'));
      expect(checkboxFinder, findsOneWidget);

      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Verify no editor was opened
      expect(find.byType(StudyTaskEditorScreen), findsNothing);

      // Verify persisted
      final updated = await repository.getStudyTaskById('task-1');
      expect(updated!.isCompleted, true);

      // Tap again to uncheck
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      final unchecked = await repository.getStudyTaskById('task-1');
      expect(unchecked!.isCompleted, false);
    });

    testWidgets('tapping study task card body opens editor and allows save', (
      WidgetTester tester,
    ) async {
      await repository.addStudyTask(StudyTask(
        id: 'task-edit-1',
        title: 'Old Title',
        description: 'Old Description',
      ));

      await tester.pumpWidget(createScreen(NotesScreen(repository: repository)));
      await tester.pumpAndSettle();

      // Tap text to open editor
      await tester.tap(find.text('Old Title'));
      await tester.pumpAndSettle();

      expect(find.byType(StudyTaskEditorScreen), findsOneWidget);
      expect(find.text('Old Title'), findsOneWidget);

      // Edit title
      await tester.enterText(
        find.byKey(const Key('study_task_title_input')),
        'Updated Task Title',
      );
      await tester.tap(find.byKey(const Key('study_task_save_button')));
      await tester.pumpAndSettle();

      // Back to NotesScreen
      expect(find.byType(NotesScreen), findsOneWidget);
      expect(find.text('Updated Task Title'), findsOneWidget);

      final persisted = await repository.getStudyTaskById('task-edit-1');
      expect(persisted!.title, 'Updated Task Title');
    });

    testWidgets('timetable button in AppBar opens TimetableScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen(NotesScreen(repository: repository)));
      await tester.pumpAndSettle();

      final timetableBtn = find.byKey(const Key('notes_timetable_button'));
      expect(timetableBtn, findsOneWidget);

      await tester.tap(timetableBtn);
      await tester.pumpAndSettle();

      expect(find.text('Timetable'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
    });
  });
}
