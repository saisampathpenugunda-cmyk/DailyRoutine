import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/money/models/recurring_money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';

void main() {
  group('RecurrenceFrequency Enum', () {
    test('displayName returns user-friendly label', () {
      expect(RecurrenceFrequency.daily.displayName, 'Daily');
      expect(RecurrenceFrequency.weekly.displayName, 'Weekly');
      expect(RecurrenceFrequency.monthly.displayName, 'Monthly');
    });

    test('toJson and fromJson serialize correctly', () {
      expect(RecurrenceFrequency.daily.toJson(), 'daily');
      expect(RecurrenceFrequency.weekly.toJson(), 'weekly');
      expect(RecurrenceFrequency.monthly.toJson(), 'monthly');

      expect(RecurrenceFrequency.fromJson('daily'), RecurrenceFrequency.daily);
      expect(RecurrenceFrequency.fromJson('weekly'), RecurrenceFrequency.weekly);
      expect(RecurrenceFrequency.fromJson('monthly'), RecurrenceFrequency.monthly);
      expect(RecurrenceFrequency.fromJson('MONTHLY'), RecurrenceFrequency.monthly);
      expect(RecurrenceFrequency.fromJson('unknown'), RecurrenceFrequency.monthly);
      expect(RecurrenceFrequency.fromJson(null), RecurrenceFrequency.monthly);
    });
  });

  group('RecurringMoneyTransaction Model', () {
    test('creates default instance with valid UUID and dates normalized to midnight', () {
      final startDate = DateTime(2026, 9, 15, 14, 30, 45);
      final recurring = RecurringMoneyTransaction(
        type: TransactionType.expense,
        amount: 2500.0,
        categoryId: 'food',
        note: 'Monthly pantry subscription',
        frequency: RecurrenceFrequency.monthly,
        startDate: startDate,
      );

      expect(recurring.id, isNotEmpty);
      expect(recurring.type, TransactionType.expense);
      expect(recurring.amount, 2500.0);
      expect(recurring.categoryId, 'food');
      expect(recurring.note, 'Monthly pantry subscription');
      expect(recurring.frequency, RecurrenceFrequency.monthly);
      expect(recurring.startDate, DateTime(2026, 9, 15));
      expect(recurring.nextOccurrence, DateTime(2026, 9, 15));
      expect(recurring.endDate, isNull);
      expect(recurring.isActive, isTrue);
      expect(recurring.createdAt, isNotNull);
      expect(recurring.updatedAt, isNotNull);
    });

    test('copyWith updates fields while preserving unprovided ones', () {
      final recurring = RecurringMoneyTransaction(
        id: 'test-rec-1',
        type: TransactionType.income,
        amount: 50000.0,
        categoryId: 'salary',
        note: 'Primary salary',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 12, 31),
        isActive: true,
      );

      final updated = recurring.copyWith(
        amount: 55000.0,
        note: 'Promoted salary',
        isActive: false,
      );

      expect(updated.id, 'test-rec-1');
      expect(updated.type, TransactionType.income);
      expect(updated.amount, 55000.0);
      expect(updated.categoryId, 'salary');
      expect(updated.note, 'Promoted salary');
      expect(updated.frequency, RecurrenceFrequency.monthly);
      expect(updated.startDate, DateTime(2026, 9, 1));
      expect(updated.endDate, DateTime(2026, 12, 31));
      expect(updated.isActive, isFalse);

      // Clear note and clear end date
      final cleared = updated.copyWith(
        clearNote: true,
        clearEndDate: true,
      );
      expect(cleared.note, isNull);
      expect(cleared.endDate, isNull);
    });

    test('toJson and fromJson serialize and deserialize correctly', () {
      final now = DateTime.now();
      final recurring = RecurringMoneyTransaction(
        id: 'uuid-123',
        type: TransactionType.expense,
        amount: 1200.50,
        categoryId: 'bills',
        note: 'Internet bill',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 9, 10),
        endDate: DateTime(2027, 9, 10),
        nextOccurrence: DateTime(2026, 10, 10),
        createdAt: now,
        updatedAt: now,
        isActive: true,
      );

      final json = recurring.toJson();
      expect(json['id'], 'uuid-123');
      expect(json['type'], 'expense');
      expect(json['amount'], 1200.50);
      expect(json['categoryId'], 'bills');
      expect(json['note'], 'Internet bill');
      expect(json['frequency'], 'monthly');
      expect(json['startDate'], DateTime(2026, 9, 10).toIso8601String());
      expect(json['endDate'], DateTime(2027, 9, 10).toIso8601String());
      expect(json['nextOccurrence'], DateTime(2026, 10, 10).toIso8601String());
      expect(json['isActive'], isTrue);

      final restored = RecurringMoneyTransaction.fromJson(json);
      expect(restored.id, recurring.id);
      expect(restored.type, recurring.type);
      expect(restored.amount, recurring.amount);
      expect(restored.categoryId, recurring.categoryId);
      expect(restored.note, recurring.note);
      expect(restored.frequency, recurring.frequency);
      expect(restored.startDate, recurring.startDate);
      expect(restored.endDate, recurring.endDate);
      expect(restored.nextOccurrence, recurring.nextOccurrence);
      expect(restored.isActive, recurring.isActive);
    });

    test('fromJson handles defensive fallbacks for missing/malformed fields', () {
      final malformed = {
        'amount': 'not_a_number',
        'type': 'invalid_type',
        'frequency': null,
        'startDate': 'not-a-date',
      };

      final parsed = RecurringMoneyTransaction.fromJson(malformed);
      expect(parsed.id, isNotEmpty);
      expect(parsed.amount, 0.0);
      expect(parsed.type, TransactionType.expense);
      expect(parsed.frequency, RecurrenceFrequency.monthly);
      expect(parsed.isActive, isTrue);
      expect(parsed.categoryId, '');
    });

    test('equality and hashCode compare core properties', () {
      final r1 = RecurringMoneyTransaction(
        id: 'rec-1',
        type: TransactionType.expense,
        amount: 500.0,
        categoryId: 'transport',
        frequency: RecurrenceFrequency.weekly,
        startDate: DateTime(2026, 9, 1),
      );

      final r2 = RecurringMoneyTransaction(
        id: 'rec-1',
        type: TransactionType.expense,
        amount: 500.0,
        categoryId: 'transport',
        frequency: RecurrenceFrequency.weekly,
        startDate: DateTime(2026, 9, 1),
      );

      final r3 = r1.copyWith(amount: 600.0);

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1, isNot(equals(r3)));
    });
  });
}
