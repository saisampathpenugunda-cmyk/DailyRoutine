import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_routine/money/models/money_transaction.dart';
import 'package:daily_routine/money/models/recurring_money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/repositories/in_memory_money_repository.dart';
import 'package:daily_routine/money/storage/shared_preferences_money_repository.dart';
import 'package:daily_routine/money/validation/money_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Recurring Transactions Repository Tests', () {
    group('InMemoryMoneyRepository - Recurring', () {
      late InMemoryMoneyRepository repo;

      setUp(() {
        repo = InMemoryMoneyRepository();
      });

      test('initial recurring transactions are empty by default', () async {
        final list = await repo.getRecurringTransactions();
        expect(list, isEmpty);
      });

      test('can add and retrieve recurring transaction by ID and list', () async {
        final rule = RecurringMoneyTransaction(
          id: 'rec-1',
          type: TransactionType.expense,
          amount: 2500.0,
          categoryId: 'food',
          note: 'Groceries subscription',
          frequency: RecurrenceFrequency.weekly,
          startDate: DateTime(2026, 9, 1),
        );

        await repo.addRecurring(rule);

        final list = await repo.getRecurringTransactions();
        expect(list.length, 1);
        expect(list.first.id, 'rec-1');

        final retrieved = await repo.getRecurringById('rec-1');
        expect(retrieved, isNotNull);
        expect(retrieved!.amount, 2500.0);
        expect(retrieved.frequency, RecurrenceFrequency.weekly);
      });

      test('throws when adding duplicate recurring rule ID', () async {
        final rule = RecurringMoneyTransaction(
          id: 'rec-duplicate',
          type: TransactionType.expense,
          amount: 500.0,
          categoryId: 'bills',
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
        );

        await repo.addRecurring(rule);

        expect(
          () => repo.addRecurring(rule),
          throwsA(isA<MoneyValidationException>()),
        );
      });

      test('can update existing recurring rule', () async {
        final rule = RecurringMoneyTransaction(
          id: 'rec-update',
          type: TransactionType.expense,
          amount: 500.0,
          categoryId: 'bills',
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
        );

        await repo.addRecurring(rule);

        final updated = rule.copyWith(amount: 750.0, note: 'Updated power bill');
        await repo.updateRecurring(updated);

        final retrieved = await repo.getRecurringById('rec-update');
        expect(retrieved!.amount, 750.0);
        expect(retrieved.note, 'Updated power bill');
      });

      test('delete recurring rule does not delete generated transactions', () async {
        final rule = RecurringMoneyTransaction(
          id: 'rec-delete',
          type: TransactionType.expense,
          amount: 1000.0,
          categoryId: 'bills',
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
        );

        await repo.addRecurring(rule);

        // Add a generated transaction
        final tx = MoneyTransaction(
          id: 'rec_rec-delete_20260901',
          type: TransactionType.expense,
          amount: 1000.0,
          category: 'Bills',
          date: DateTime(2026, 9, 1),
        );
        await repo.addTransaction(tx);

        final deleted = await repo.deleteRecurring('rec-delete');
        expect(deleted, isTrue);

        final remainingRules = await repo.getRecurringTransactions();
        expect(remainingRules, isEmpty);

        // Generated transaction must remain completely untouched!
        final remainingTxs = await repo.getTransactions();
        expect(remainingTxs.length, 1);
        expect(remainingTxs.first.id, 'rec_rec-delete_20260901');
      });
    });

    group('SharedPreferencesMoneyRepository - Recurring', () {
      late SharedPreferences prefs;

      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
      });

      test('persists recurring rules to separate key and survives re-instantiation', () async {
        final repo1 = SharedPreferencesMoneyRepository(prefs);

        final rule = RecurringMoneyTransaction(
          id: 'sp-rec-1',
          type: TransactionType.income,
          amount: 75000.0,
          categoryId: 'salary',
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
        );

        await repo1.addRecurring(rule);

        // Verify separate persistence key
        final rawJson = prefs.getString(SharedPreferencesMoneyRepository.recurringKey);
        expect(rawJson, isNotNull);
        final decoded = jsonDecode(rawJson!) as List;
        expect(decoded.length, 1);
        expect(decoded.first['id'], 'sp-rec-1');

        // Create fresh repo instance from same prefs
        final repo2 = SharedPreferencesMoneyRepository(prefs);
        final list = await repo2.getRecurringTransactions();
        expect(list.length, 1);
        expect(list.first.id, 'sp-rec-1');
        expect(list.first.amount, 75000.0);
        expect(list.first.type, TransactionType.income);
      });

      test('defensively handles corrupted JSON string in recurring preference key', () async {
        await prefs.setString(
          SharedPreferencesMoneyRepository.recurringKey,
          '<<<invalid json string>>>',
        );

        final repo = SharedPreferencesMoneyRepository(prefs);
        final list = await repo.getRecurringTransactions();
        expect(list, isEmpty);
      });

      test('defensively ignores individual malformed recurring records', () async {
        final mixedJson = jsonEncode([
          {
            'id': 'valid-rec-1',
            'type': 'expense',
            'amount': 300.0,
            'categoryId': 'food',
            'frequency': 'daily',
            'startDate': DateTime(2026, 9, 1).toIso8601String(),
            'nextOccurrence': DateTime(2026, 9, 1).toIso8601String(),
          },
          {
            // Missing id and amount
            'type': 'unknown',
          },
          {
            'id': 'valid-rec-2',
            'type': 'expense',
            'amount': 500.0,
            'categoryId': 'transport',
            'frequency': 'weekly',
            'startDate': DateTime(2026, 9, 1).toIso8601String(),
            'nextOccurrence': DateTime(2026, 9, 1).toIso8601String(),
          }
        ]);

        await prefs.setString(
          SharedPreferencesMoneyRepository.recurringKey,
          mixedJson,
        );

        final repo = SharedPreferencesMoneyRepository(prefs);
        final list = await repo.getRecurringTransactions();
        expect(list.length, 2);
        expect(list.map((r) => r.id), containsAll(['valid-rec-1', 'valid-rec-2']));
      });
    });
  });
}
