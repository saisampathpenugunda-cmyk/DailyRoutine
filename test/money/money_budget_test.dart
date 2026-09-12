import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/money/models/money_budget.dart';

void main() {
  group('MoneyBudget Model Tests', () {
    final now = DateTime(2026, 9, 12, 10, 0);
    final budget = MoneyBudget(
      id: 'b1',
      categoryId: 'food',
      year: 2026,
      month: 9,
      amount: 5000.0,
      createdAt: now,
      updatedAt: now,
    );

    test('toJson and fromJson serialize and deserialize correctly', () {
      final json = budget.toJson();
      expect(json['id'], 'b1');
      expect(json['categoryId'], 'food');
      expect(json['year'], 2026);
      expect(json['month'], 9);
      expect(json['amount'], 5000.0);
      expect(json['createdAt'], now.toIso8601String());
      expect(json['updatedAt'], now.toIso8601String());

      final restored = MoneyBudget.fromJson(json);
      expect(restored, equals(budget));
    });

    test('fromJson handles missing or malformed fields safely', () {
      final malformed = MoneyBudget.fromJson({});
      expect(malformed.id, '');
      expect(malformed.categoryId, '');
      expect(malformed.year, 0);
      expect(malformed.month, 0);
      expect(malformed.amount, 0.0);
      expect(malformed.createdAt, isNotNull);
      expect(malformed.updatedAt, isNotNull);
    });

    test('copyWith updates specified fields only', () {
      final later = DateTime(2026, 9, 12, 12, 0);
      final updated = budget.copyWith(
        amount: 6000.0,
        updatedAt: later,
      );

      expect(updated.id, 'b1');
      expect(updated.categoryId, 'food');
      expect(updated.amount, 6000.0);
      expect(updated.year, 2026);
      expect(updated.month, 9);
      expect(updated.createdAt, now);
      expect(updated.updatedAt, later);
    });

    test('equality and hashCode work as expected', () {
      final same = MoneyBudget(
        id: 'b1',
        categoryId: 'food',
        year: 2026,
        month: 9,
        amount: 5000.0,
        createdAt: now,
        updatedAt: now,
      );
      final different = budget.copyWith(amount: 4000.0);

      expect(budget, equals(same));
      expect(budget.hashCode, equals(same.hashCode));
      expect(budget, isNot(equals(different)));
    });
  });
}
