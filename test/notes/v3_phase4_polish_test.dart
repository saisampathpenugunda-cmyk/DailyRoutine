import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_routine/notes/models/study_task.dart';
import 'package:daily_routine/notes/models/text_note.dart';
import 'package:daily_routine/notes/repositories/in_memory_notes_repository.dart';
import 'package:daily_routine/notes/storage/shared_preferences_notes_repository.dart';
import 'package:daily_routine/notes/screens/notes_screen.dart';
import 'package:daily_routine/notes/screens/study_task_editor_screen.dart';
import 'package:daily_routine/notes/screens/text_note_editor_screen.dart';
import 'package:daily_routine/notes/screens/timetable_screen.dart';
import 'package:daily_routine/theme/app_theme.dart';
import 'package:daily_routine/screens/main_home_screen.dart';
import 'package:daily_routine/money/repositories/in_memory_money_repository.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/controllers/user_profile_controller.dart';
import 'package:daily_routine/controllers/streak_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Part A — V3 Phase 4 Polish & Verification Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Widget wrapWithTheme(Widget child, {ThemeController? controller}) {
      final themeCtrl = controller ?? ThemeController(ThemeMode.dark, prefs);
      return ThemeScope(
        controller: themeCtrl,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: child,
        ),
      );
    }

    testWidgets('A1. Study Tasks are single-level, support direct checkbox toggle, strikethrough, and persist', (
      WidgetTester tester,
    ) async {
      final repo = SharedPreferencesNotesRepository(prefs);
      final task = StudyTask(
        id: 'task-1',
        title: 'Revise Discrete Math',
        description: 'Chapter 3 graphs',
        isCompleted: false,
        isPinned: false,
      );
      await repo.addStudyTask(task);

      await tester.pumpWidget(wrapWithTheme(NotesScreen(repository: repo)));
      await tester.pumpAndSettle();

      // Verify single-level task appearance — no "0 of 1 completed"
      expect(find.text('Revise Discrete Math'), findsOneWidget);
      expect(find.text('Chapter 3 graphs'), findsOneWidget);
      expect(find.textContaining('0 of 1 completed'), findsNothing);
      expect(find.text('Study Tasks'), findsOneWidget);
      expect(find.text('+ Study Task'), findsOneWidget);

      // Verify checkbox is unchecked initially
      final checkboxFinder = find.byKey(const Key('study_task_checkbox_task-1'));
      expect(checkboxFinder, findsOneWidget);

      // Tap checkbox directly on screen
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Check repository persistence
      final tasksAfter = await repo.getStudyTasks();
      expect(tasksAfter.first.isCompleted, isTrue);

      // Verify Text widget now has lineThrough decoration
      final textWidget = tester.widget<Text>(find.text('Revise Discrete Math'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);

      // Toggle back to incomplete
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      final tasksAfterSecond = await repo.getStudyTasks();
      expect(tasksAfterSecond.first.isCompleted, isFalse);
      final textWidget2 = tester.widget<Text>(find.text('Revise Discrete Math'));
      expect(textWidget2.style?.decoration, isNot(TextDecoration.lineThrough));
    });

    testWidgets('A1. Pin/unpin and delete study task with confirmation dialog', (
      WidgetTester tester,
    ) async {
      final repo = SharedPreferencesNotesRepository(prefs);
      final task = StudyTask(
        id: 'task-pin-test',
        title: 'Operating Systems Quiz',
      );
      await repo.addStudyTask(task);

      await tester.pumpWidget(wrapWithTheme(NotesScreen(repository: repo)));
      await tester.pumpAndSettle();

      // Pin
      final pinButton = find.byKey(const Key('study_task_pin_task-pin-test'));
      await tester.tap(pinButton);
      await tester.pumpAndSettle();
      expect((await repo.getStudyTasks()).first.isPinned, isTrue);

      // Delete action opens confirmation
      final deleteButton = find.byKey(const Key('study_task_delete_task-pin-test'));
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(find.text('Delete Study Task?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Cancel keeps task
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect((await repo.getStudyTasks()).length, 1);

      // Delete confirms and removes task
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect((await repo.getStudyTasks()).isEmpty, isTrue);
      expect(find.text('No study tasks yet'), findsOneWidget);
    });

    testWidgets('A1. Study task editor creates task and preserves stable UUID', (
      WidgetTester tester,
    ) async {
      final repo = SharedPreferencesNotesRepository(prefs);

      await tester.pumpWidget(wrapWithTheme(NotesScreen(repository: repo)));
      await tester.pumpAndSettle();

      // Tap FAB to create new task
      await tester.tap(find.byKey(const Key('notes_fab')));
      await tester.pumpAndSettle();

      expect(find.byType(StudyTaskEditorScreen), findsOneWidget);

      // Enter title and description
      await tester.enterText(find.byKey(const Key('study_task_title_input')), 'Computer Networks Lab');
      await tester.enterText(find.byKey(const Key('study_task_description_input')), 'Packet tracer experiments');
      await tester.pump(const Duration(milliseconds: 600)); // debounce

      // Save button tap
      await tester.tap(find.byKey(const Key('study_task_save_button')));
      await tester.pumpAndSettle();

      // Back on NotesScreen
      expect(find.byType(NotesScreen), findsOneWidget);
      expect(find.text('Computer Networks Lab'), findsOneWidget);

      final tasks = await repo.getStudyTasks();
      expect(tasks.length, 1);
      final savedTask = tasks.first;
      expect(savedTask.title, 'Computer Networks Lab');
      expect(savedTask.description, 'Packet tracer experiments');
      final originalId = savedTask.id;
      expect(originalId.isNotEmpty, isTrue);

      // Re-edit task by tapping card
      await tester.tap(find.text('Computer Networks Lab'));
      await tester.pumpAndSettle();

      expect(find.byType(StudyTaskEditorScreen), findsOneWidget);
      await tester.enterText(find.byKey(const Key('study_task_title_input')), 'Computer Networks Lab Final');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.byKey(const Key('study_task_save_button')));
      await tester.pumpAndSettle();

      // Back on NotesScreen
      expect(find.byType(NotesScreen), findsOneWidget);
      expect(find.text('Computer Networks Lab Final'), findsOneWidget);

      final tasksUpdated = await repo.getStudyTasks();
      expect(tasksUpdated.length, 1);
      expect(tasksUpdated.first.id, originalId); // UUID preserved!
      expect(tasksUpdated.first.title, 'Computer Networks Lab Final');
    });

    testWidgets('A2. Text Notes support title, content, autosave debounce, pin, and search', (
      WidgetTester tester,
    ) async {
      final repo = SharedPreferencesNotesRepository(prefs);

      await tester.pumpWidget(wrapWithTheme(TextNoteEditorScreen(repository: repo)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('text_note_title_field')), 'Compiler Design Notes');
      await tester.enterText(find.byKey(const Key('text_note_content_field')), 'LR parser shift-reduce conflicts');
      await tester.pump(const Duration(milliseconds: 600)); // debounce autosave

      final notes = await repo.getTextNotes();
      expect(notes.length, 1);
      expect(notes.first.title, 'Compiler Design Notes');
      expect(notes.first.content, 'LR parser shift-reduce conflicts');

      // Now verify on NotesScreen
      await tester.pumpWidget(wrapWithTheme(NotesScreen(repository: repo)));
      await tester.pumpAndSettle();

      // Switch to Notes tab
      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();

      expect(find.text('Compiler Design Notes'), findsOneWidget);
      expect(find.text('+ Note'), findsOneWidget);

      // Search functionality
      await tester.tap(find.byKey(const Key('notes_search_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('notes_search_field')), 'parser');
      await tester.pumpAndSettle();
      expect(find.text('Compiler Design Notes'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('notes_search_field')), 'nonexistent');
      await tester.pumpAndSettle();
      expect(find.text('Compiler Design Notes'), findsNothing);
      expect(find.text('No matching notes'), findsOneWidget);
    });

    testWidgets('A4. Timetable screen renders Mon-Sat chips and active class highlight', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapWithTheme(const TimetableScreen(initialDay: 1))); // Monday
      await tester.pumpAndSettle();

      expect(find.text('Timetable'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);

      // Monday has classes:
      expect(find.text('Object Oriented Programming'), findsOneWidget);
      expect(find.text('Computer Organization and Architecture'), findsOneWidget);

      // Switch to Saturday (no classes)
      await tester.tap(find.text('Sat'));
      await tester.pumpAndSettle();

      expect(find.text('No Classes Scheduled'), findsOneWidget);
    });

    testWidgets('A5. MainHomeScreen dynamically displays task and note count', (
      WidgetTester tester,
    ) async {
      final activityRepo = InMemoryActivityRepository();
      final moneyRepo = InMemoryMoneyRepository();
      final notesRepo = InMemoryNotesRepository();
      final profileController = UserProfileController('Sampath');
      final streakController = StreakController(repository: activityRepo);

      await notesRepo.addStudyTask(StudyTask(id: 't-1', title: 'Task 1'));
      await notesRepo.addStudyTask(StudyTask(id: 't-2', title: 'Task 2'));
      await notesRepo.addTextNote(TextNote(id: 'n-1', title: 'Note 1', content: 'c1'));

      await tester.pumpWidget(
        MaterialApp(
          home: MainHomeScreen(
            activityRepository: activityRepo,
            moneyRepository: moneyRepo,
            notesRepository: notesRepo,
            userProfileController: profileController,
            streakController: streakController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your Notes'), findsOneWidget);
      expect(find.text('2 tasks, 1 note'), findsOneWidget);
    });
  });
}
