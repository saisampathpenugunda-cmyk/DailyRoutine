import '../utils/uuid.dart';

/// Represents an automatic 5% savings allocation linked to an income transaction.
class MoneySavings {
  final String id;
  final String sourceTransactionId;
  final double incomeAmount;
  final double savingsPercentage;
  final double savingsAmount;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns today's date in local calendar time (midnight 00:00:00).
  static DateTime localToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  MoneySavings({
    String? id,
    required this.sourceTransactionId,
    required this.incomeAmount,
    this.savingsPercentage = 5.0,
    double? savingsAmount,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? Uuid.v4(),
        savingsAmount = savingsAmount ?? (incomeAmount * (savingsPercentage / 100.0)),
        date = date ?? localToday(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? (createdAt ?? DateTime.now());

  /// Returns a copy with updated fields.
  MoneySavings copyWith({
    String? id,
    String? sourceTransactionId,
    double? incomeAmount,
    double? savingsPercentage,
    double? savingsAmount,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final newIncomeAmount = incomeAmount ?? this.incomeAmount;
    final newPercentage = savingsPercentage ?? this.savingsPercentage;
    return MoneySavings(
      id: id ?? this.id,
      sourceTransactionId: sourceTransactionId ?? this.sourceTransactionId,
      incomeAmount: newIncomeAmount,
      savingsPercentage: newPercentage,
      savingsAmount: savingsAmount ??
          (incomeAmount != null || savingsPercentage != null
              ? (newIncomeAmount * (newPercentage / 100.0))
              : this.savingsAmount),
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceTransactionId': sourceTransactionId,
        'incomeAmount': incomeAmount,
        'savingsPercentage': savingsPercentage,
        'savingsAmount': savingsAmount,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Constructs from JSON map.
  factory MoneySavings.fromJson(Map<String, dynamic> json) {
    final rawIncome = json['incomeAmount'];
    final double parsedIncome;
    if (rawIncome is num) {
      parsedIncome = rawIncome.toDouble();
    } else if (rawIncome is String) {
      parsedIncome = double.tryParse(rawIncome) ?? 0.0;
    } else {
      parsedIncome = 0.0;
    }

    final rawPercentage = json['savingsPercentage'];
    final double parsedPercentage;
    if (rawPercentage is num) {
      parsedPercentage = rawPercentage.toDouble();
    } else if (rawPercentage is String) {
      parsedPercentage = double.tryParse(rawPercentage) ?? 5.0;
    } else {
      parsedPercentage = 5.0;
    }

    final rawSavings = json['savingsAmount'];
    final double parsedSavings;
    if (rawSavings is num) {
      parsedSavings = rawSavings.toDouble();
    } else if (rawSavings is String) {
      parsedSavings = double.tryParse(rawSavings) ?? (parsedIncome * (parsedPercentage / 100.0));
    } else {
      parsedSavings = parsedIncome * (parsedPercentage / 100.0);
    }

    final parsedDate = json['date'] != null
        ? DateTime.tryParse(json['date'] as String)
        : null;

    final parsedCreatedAt = json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String)
        : null;

    final parsedUpdatedAt = json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'] as String)
        : null;

    return MoneySavings(
      id: json['id'] as String?,
      sourceTransactionId: json['sourceTransactionId'] as String? ?? '',
      incomeAmount: parsedIncome,
      savingsPercentage: parsedPercentage,
      savingsAmount: parsedSavings,
      date: parsedDate ?? localToday(),
      createdAt: parsedCreatedAt ?? DateTime.now(),
      updatedAt: parsedUpdatedAt ?? (parsedCreatedAt ?? DateTime.now()),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoneySavings &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sourceTransactionId == other.sourceTransactionId &&
          (incomeAmount - other.incomeAmount).abs() < 0.000001 &&
          (savingsPercentage - other.savingsPercentage).abs() < 0.000001 &&
          (savingsAmount - other.savingsAmount).abs() < 0.000001 &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day;

  @override
  int get hashCode => Object.hash(
        id,
        sourceTransactionId,
        incomeAmount,
        savingsPercentage,
        savingsAmount,
        date.year,
        date.month,
        date.day,
      );

  @override
  String toString() =>
      'MoneySavings(id: $id, source: $sourceTransactionId, saved: $savingsAmount, date: ${date.toIso8601String().split("T").first})';
}
