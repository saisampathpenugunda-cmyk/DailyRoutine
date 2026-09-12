import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/money/models/money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/utils/uuid.dart';

void main() {
  group('MoneyTransaction Model Tests', () {
    test('creates transaction with valid auto-generated UUID', () {
      final t = MoneyTransaction(
        type: TransactionType.expense,
        amount: 250.0,
        category: 'Food',
      );

      expect(t.id, isNotEmpty);
      expect(Uuid.isValid(t.id), isTrue);
      expect(t.type, TransactionType.expense);
      expect(t.amount, 250.0);
      expect(t.category, 'Food');
      expect(t.note, isNull);
    });

    test('accepts explicit ID and preserves it', () {
      const explicitId = 'custom-uuid-1234';
      final t = MoneyTransaction(
        id: explicitId,
        type: TransactionType.income,
        amount: 5000.0,
        category: 'Work',
      );

      expect(t.id, explicitId);
      expect(t.type.isIncome, isTrue);
      expect(t.type.isExpense, isFalse);
    });

    test('defaults date to local today (midnight calendar date)', () {
      final now = DateTime.now();
      final expectedLocalToday = DateTime(now.year, now.month, now.day);

      final t = MoneyTransaction(
        type: TransactionType.expense,
        amount: 50.0,
        category: 'Transport',
      );

      expect(t.date.year, expectedLocalToday.year);
      expect(t.date.month, expectedLocalToday.month);
      expect(t.date.day, expectedLocalToday.day);
    });

    test('retains historical explicitly supplied date without shift', () {
      final historicalDate = DateTime(2025, 4, 15);
      final t = MoneyTransaction(
        type: TransactionType.income,
        amount: 1200.0,
        category: 'Freelance',
        date: historicalDate,
      );

      expect(t.date, historicalDate);
      expect(t.date.year, 2025);
      expect(t.date.month, 4);
      expect(t.date.day, 15);
    });

    test('supports optional note', () {
      final t = MoneyTransaction(
        type: TransactionType.expense,
        amount: 80.0,
        category: 'Bills',
        note: 'Electricity bill payment',
      );

      expect(t.note, 'Electricity bill payment');
    });

    test('copyWith updates fields while preserving original ID and createdAt', () {
      final createdTime = DateTime(2026, 1, 1, 10, 0);
      final original = MoneyTransaction(
        id: 'stable-id-1',
        type: TransactionType.expense,
        amount: 100.0,
        category: 'Shopping',
        note: 'Shoes',
        createdAt: createdTime,
        updatedAt: createdTime,
      );

      final updated = original.copyWith(
        amount: 120.0,
        category: 'Gifts',
        note: 'Birthday gift shoes',
      );

      expect(updated.id, 'stable-id-1');
      expect(updated.createdAt, createdTime);
      expect(updated.amount, 120.0);
      expect(updated.category, 'Gifts');
      expect(updated.note, 'Birthday gift shoes');
      expect(updated.updatedAt.isAfter(createdTime) || updated.updatedAt == createdTime, isTrue);
    });

    test('copyWith can clear note', () {
      final original = MoneyTransaction(
        type: TransactionType.expense,
        amount: 45.0,
        category: 'Food',
        note: 'Snack',
      );

      final cleared = original.copyWith(clearNote: true);
      expect(cleared.note, isNull);
    });

    test('toJson and fromJson serialize and deserialize accurately', () {
      final original = MoneyTransaction(
        id: 'json-test-id',
        type: TransactionType.income,
        amount: 3500.50,
        category: 'Work',
        date: DateTime(2026, 9, 11),
        note: 'Monthly salary credit',
        createdAt: DateTime(2026, 9, 11, 9, 30),
        updatedAt: DateTime(2026, 9, 11, 9, 30),
      );

      final json = original.toJson();
      expect(json['id'], 'json-test-id');
      expect(json['type'], 'income');
      expect(json['amount'], 3500.50);
      expect(json['category'], 'Work');
      expect(json['note'], 'Monthly salary credit');

      final reconstructed = MoneyTransaction.fromJson(json);
      expect(reconstructed.id, original.id);
      expect(reconstructed.type, original.type);
      expect(reconstructed.amount, original.amount);
      expect(reconstructed.category, original.category);
      expect(reconstructed.date.year, original.date.year);
      expect(reconstructed.date.month, original.date.month);
      expect(reconstructed.date.day, original.date.day);
      expect(reconstructed.note, original.note);
      expect(reconstructed == original, isTrue);
    });

    test('fromJson handles string amount defensively', () {
      final json = {
        'id': 'defensive-id',
        'type': 'expense',
        'amount': '42.75',
        'category': 'Transport',
      };

      final transaction = MoneyTransaction.fromJson(json);
      expect(transaction.amount, 42.75);
      expect(transaction.type, TransactionType.expense);
    });

    test('fromJson defaults gracefully when fields are missing', () {
      final json = <String, dynamic>{};
      final transaction = MoneyTransaction.fromJson(json);

      expect(transaction.id, isNotEmpty);
      expect(Uuid.isValid(transaction.id), isTrue);
      expect(transaction.amount, 0.0);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.category, isEmpty);
      expect(transaction.date, isNotNull);

      // Explicit empty string preserves empty string for validator to catch
      final emptyIdTrans = MoneyTransaction.fromJson({'id': ''});
      expect(emptyIdTrans.id, isEmpty);
    });
  });
}
