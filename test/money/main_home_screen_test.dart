import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/controllers/streak_controller.dart';
import 'package:daily_routine/controllers/user_profile_controller.dart';
import 'package:daily_routine/money/models/money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/repositories/in_memory_money_repository.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/screens/main_home_screen.dart';

void main() {
  group('MainHomeScreen Widget Tests', () {
    late InMemoryActivityRepository activityRepo;
    late InMemoryMoneyRepository moneyRepo;
    late UserProfileController profileController;
    late StreakController streakController;

    setUp(() {
      activityRepo = InMemoryActivityRepository();
      moneyRepo = InMemoryMoneyRepository();
      profileController = UserProfileController('Sampath');
      streakController = StreakController(repository: activityRepo);
    });

    Widget createScreen({DateTime? time}) {
      return MaterialApp(
        home: MainHomeScreen(
          activityRepository: activityRepo,
          moneyRepository: moneyRepo,
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
