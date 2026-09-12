import 'package:flutter/material.dart';

/// Centralized utility for currency formatting, date presentation, and category visual mapping.
class MoneyFormatter {
  /// Standard Indian Rupee currency symbol.
  static const String rupeeSymbol = '₹';

  /// Formats a financial [amount] into Indian Rupee presentation.
  ///
  /// Examples:
  /// - `250.0` -> `₹250.00`
  /// - `2000.0` -> `₹2,000.00`
  /// - `-250.0` -> `-₹250.00`
  /// - `2000.0` with `showSign: true` -> `+₹2,000.00`
  /// - `0.0` -> `₹0.00`
  static String format(double amount, {bool showSign = false}) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    final formattedInt = _formatIndianGrouping(intPart);
    final valueStr = '$rupeeSymbol$formattedInt.$decPart';

    if (isNegative) {
      return '-$valueStr';
    } else if (showSign && amount > 0) {
      return '+$valueStr';
    } else {
      return valueStr;
    }
  }

  /// Formats an integer string according to Indian numbering system:
  /// Last 3 digits grouped, then groups of 2 digits.
  static String _formatIndianGrouping(String digits) {
    if (digits.length <= 3) return digits;
    final lastThree = digits.substring(digits.length - 3);
    var remaining = digits.substring(0, digits.length - 3);
    final chunks = <String>[];
    while (remaining.length > 2) {
      chunks.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) {
      chunks.insert(0, remaining);
    }
    return '${chunks.join(',')},$lastThree';
  }

  /// Formats a transaction [date] into user-friendly text:
  /// - Today -> "Today"
  /// - Yesterday -> "Yesterday"
  /// - Other -> "11 Sep 2026"
  static String formatDate(DateTime date, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final isToday = date.year == current.year &&
        date.month == current.month &&
        date.day == current.day;
    if (isToday) return 'Today';

    final yesterday = current.subtract(const Duration(days: 1));
    final isYesterday = date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
    if (isYesterday) return 'Yesterday';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Standard set of selectable Material icons for Money categories.
  static const Map<String, IconData> selectableIcons = {
    'restaurant': Icons.restaurant_rounded,
    'directions_bus': Icons.directions_bus_rounded,
    'directions_car': Icons.directions_car_rounded,
    'school': Icons.school_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'movie': Icons.movie_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'medical_services': Icons.medical_services_rounded,
    'favorite': Icons.favorite_rounded,
    'work': Icons.work_rounded,
    'home': Icons.home_rounded,
    'payments': Icons.payments_rounded,
    'laptop': Icons.laptop_rounded,
    'business': Icons.business_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'flight': Icons.flight_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'pets': Icons.pets_rounded,
    'category': Icons.category_rounded,
  };

  /// Returns the corresponding [IconData] for a category by name or icon identifier.
  static IconData getCategoryIcon(String categoryName, [String? iconName]) {
    final key = (iconName ?? categoryName).trim().toLowerCase();
    if (selectableIcons.containsKey(key)) {
      return selectableIcons[key]!;
    }
    switch (key) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'health':
        return Icons.medical_services_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'salary':
        return Icons.payments_rounded;
      case 'freelance':
        return Icons.laptop_rounded;
      case 'business':
        return Icons.business_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'income_other':
      case 'other':
      default:
        return Icons.category_rounded;
    }
  }
}
