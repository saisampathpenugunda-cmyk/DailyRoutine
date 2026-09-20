import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/controllers/streak_controller.dart';
import 'package:daily_routine/controllers/user_profile_controller.dart';
import 'package:daily_routine/money/models/money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/repositories/in_memory_money_repository.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/screens/main_home_screen.dart';
import 'package:daily_routine/notes/repositories/in_memory_notes_repository.dart';
import 'package:daily_routine/notes/screens/notes_screen.dart';
import 'package:daily_routine/notes/models/study_task.dart';
import 'package:daily_routine/notes/models/text_note.dart';

void main() {
  group('MainHomeScreen Widget Tests', () {
    late InMemoryActivityRepository activityRepo;
    late InMemoryMoneyRepository moneyRepo;
    late InMemoryNotesRepository notesRepo;
    late UserProfileController profileController;
    late StreakController streakController;

    setUp(() {
      activityRepo = InMemoryActivityRepository();
      moneyRepo = InMemoryMoneyRepository();
      notesRepo = InMemoryNotesRepository();
      profileController = UserProfileController('Sampath');
      streakController = StreakController(repository: activityRepo);
    });

    Widget createScreen({DateTime? time}) {
      return MaterialApp(
        home: MainHomeScreen(
          activityRepository: activityRepo,
          moneyRepository: moneyRepo,
          notesRepository: notesRepo,
          userProfileController: profileController,
          streakController: streakController,
          currentTime: time ?? DateTime(2026, 9, 12, 9, 0), // 9 AM -> Good Morning
        ),
      );
    }

    testWidgets('renders greeting with saved name, title, and module cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('DailyRoutine'), findsOneWidget);
      expect(find.text('Good Morning, Sampath!'), findsOneWidget);

      expect(find.text('Your Day'), findsOneWidget);
      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('0 of 3 completed'), findsOneWidget); // 3 default InMemory activities

      expect(find.text('Your Money'), findsOneWidget);
      expect(find.text('Money'), findsOneWidget);
      expect(find.text('Current Balance: ₹0.00'), findsOneWidget);

      expect(find.text('Your Notes'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('0 tasks, 0 notes'), findsOneWidget);
    });

    testWidgets('displays updated Money balance when transactions exist', (
      WidgetTester tester,
    ) async {
      await moneyRepo.addTransaction(
        MoneyTransaction(
          type: TransactionType.income,
          amount: 2500.0,
          category: 'Work',
        ),
      );
      await moneyRepo.addTransaction(
        MoneyTransaction(
          type: TransactionType.expense,
          amount: 120.0,
          category: 'Food',
        ),
      );

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // 2500 - 120 = 2380.00 -> ₹2,380.00
      expect(find.text('Current Balance: ₹2,380.00'), findsOneWidget);
    });

    testWidgets('tapping Activities card opens existing HomeScreen and returns cleanly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Activities'));
      await tester.pumpAndSettle();

      // Verify we are on existing HomeScreen
      expect(find.text("Today's Plan"), findsOneWidget);
      expect(find.text('Meditation'), findsOneWidget);
      expect(find.text('Walking'), findsOneWidget);
      expect(find.text('Dumbbells'), findsOneWidget);

      // Back navigation
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }

      // Back on MainHomeScreen
      expect(find.text('Your Day'), findsOneWidget);
      expect(find.text('Your Money'), findsOneWidget);
    });

    testWidgets('tapping Money card opens MoneyDashboardScreen and returns cleanly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Money'));
      await tester.pumpAndSettle();

      // Verify on MoneyDashboardScreen
      expect(find.text('Current Balance'), findsOneWidget);
      expect(find.text('Add Transaction'), findsOneWidget);

      // Back navigation
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }

      // Back on MainHomeScreen
      expect(find.text('Your Day'), findsOneWidget);
      expect(find.text('Your Money'), findsOneWidget);
    });

    testWidgets('tapping Notes card opens NotesScreen and returns cleanly', (
      WidgetTester tester,
    ) async {
      // Seed a study task and a text note so the summary is non-zero
      await notesRepo.addStudyTask(
        StudyTask(
          id: 't1',
          title: 'Shopping',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );
      await notesRepo.addTextNote(
        TextNote(
          id: 'n1',
          title: 'Ideas',
          content: 'content here',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Verify summary reflects seeded data
      expect(find.text('1 task, 1 note'), findsOneWidget);

      // Tap the Notes module card
      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();

      // Verify we are on NotesScreen
      expect(find.byType(NotesScreen), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Study Tasks'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Notes'), findsOneWidget);

      // Back navigation
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }

      // Back on MainHomeScreen
      expect(find.text('Your Day'), findsOneWidget);
      expect(find.text('Your Money'), findsOneWidget);
      expect(find.text('Your Notes'), findsOneWidget);
    });

    testWidgets('settings icon opens SettingsScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('PROFILE'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
    });
  });
}
