import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/money/utils/money_formatter.dart';

void main() {
  group('MoneyFormatter Tests', () {
    test('formats positive amounts without sign', () {
      expect(MoneyFormatter.format(0), '₹0.00');
      expect(MoneyFormatter.format(250), '₹250.00');
      expect(MoneyFormatter.format(2000), '₹2,000.00');
      expect(MoneyFormatter.format(150000), '₹1,50,000.00');
      expect(MoneyFormatter.format(12.5), '₹12.50');
    });

    test('formats positive amounts with showSign: true', () {
      expect(MoneyFormatter.format(2000, showSign: true), '+₹2,000.00');
      expect(MoneyFormatter.format(250, showSign: true), '+₹250.00');
      expect(MoneyFormatter.format(0, showSign: true), '₹0.00');
    });

    test('formats negative amounts with negative sign', () {
      expect(MoneyFormatter.format(-250), '-₹250.00');
      expect(MoneyFormatter.format(-250, showSign: true), '-₹250.00');
      expect(MoneyFormatter.format(-2000), '-₹2,000.00');
    });

    test('formats dates correctly', () {
      final now = DateTime(2026, 9, 12, 10, 0);
      expect(
        MoneyFormatter.formatDate(DateTime(2026, 9, 12, 8, 0), now: now),
        'Today',
      );
      expect(
        MoneyFormatter.formatDate(DateTime(2026, 9, 11, 15, 0), now: now),
        'Yesterday',
      );
      expect(
        MoneyFormatter.formatDate(DateTime(2026, 9, 10, 12, 0), now: now),
        '10 Sep 2026',
      );
      expect(
        MoneyFormatter.formatDate(DateTime(2026, 9, 1, 12, 0), now: now),
        '1 Sep 2026',
      );
    });

    test('maps category icons correctly', () {
      expect(MoneyFormatter.getCategoryIcon('Food'), Icons.restaurant_rounded);
      expect(MoneyFormatter.getCategoryIcon('Transport'), Icons.directions_car_rounded);
      expect(MoneyFormatter.getCategoryIcon('Work'), Icons.work_rounded);
      expect(MoneyFormatter.getCategoryIcon('Unknown'), Icons.category_rounded);
    });
  });
}
