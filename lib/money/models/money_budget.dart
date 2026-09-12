import '../utils/uuid.dart';

/// Represents a monthly expense budget for a specific category in Money V2.
class MoneyBudget {
  final String id;
  final String categoryId;
  final int year;
  final int month;
  final double amount;
  final DateTime createdAt;
  final DateTime updatedAt;

  MoneyBudget({
    String? id,
    required this.categoryId,
    required this.year,
    required this.month,
    required this.amount,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? Uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Creates a copy of this budget with given fields replaced.
  MoneyBudget copyWith({
    String? id,
    String? categoryId,
    int? year,
    int? month,
    double? amount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MoneyBudget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      year: year ?? this.year,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serializes budget to JSON format.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'year': year,
      'month': month,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Deserializes budget from a JSON map with defensive parsing.
  factory MoneyBudget.fromJson(Map<String, dynamic> json) {
    return MoneyBudget(
      id: json['id'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoneyBudget &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          categoryId == other.categoryId &&
          year == other.year &&
          month == other.month &&
          (amount - other.amount).abs() < 0.000001 &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        categoryId,
        year,
        month,
        amount,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'MoneyBudget(id: $id, categoryId: $categoryId, year: $year, month: $month, amount: $amount)';
}
