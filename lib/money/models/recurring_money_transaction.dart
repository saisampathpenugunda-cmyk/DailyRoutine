import '../utils/uuid.dart';
import 'transaction_type.dart';

/// Recurrence frequency supported by Money V2.
enum RecurrenceFrequency {
  daily,
  weekly,
  monthly;

  String toJson() => name;

  static RecurrenceFrequency fromJson(String? value) {
    if (value == null) return RecurrenceFrequency.monthly;
    final lower = value.trim().toLowerCase();
    return RecurrenceFrequency.values.firstWhere(
      (f) => f.name.toLowerCase() == lower,
      orElse: () => RecurrenceFrequency.monthly,
    );
  }

  String get displayName {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
    }
  }
}

/// Represents a recurring transaction rule in Money V2.
///
/// The recurring record is NOT itself a transaction.
/// Actual [MoneyTransaction] records are generated deterministically
/// when an occurrence becomes due.
class RecurringMoneyTransaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String? note;
  final RecurrenceFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextOccurrence;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  /// Returns a date clamped to local midnight (00:00:00).
  static DateTime normalizeDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  RecurringMoneyTransaction({
    String? id,
    required this.type,
    required this.amount,
    required this.categoryId,
    this.note,
    required this.frequency,
    required DateTime startDate,
    DateTime? endDate,
    DateTime? nextOccurrence,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  })  : id = id ?? Uuid.v4(),
        startDate = normalizeDate(startDate),
        endDate = endDate != null ? normalizeDate(endDate) : null,
        nextOccurrence = nextOccurrence != null
            ? normalizeDate(nextOccurrence)
            : normalizeDate(startDate),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Returns a copy of this recurring transaction with updated fields.
  /// Preserves [id] and [createdAt] by default.
  RecurringMoneyTransaction copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? note,
    bool clearNote = false,
    RecurrenceFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    DateTime? nextOccurrence,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return RecurringMoneyTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      note: clearNote ? null : (note ?? this.note),
      frequency: frequency ?? this.frequency,
      startDate: startDate != null ? normalizeDate(startDate) : this.startDate,
      endDate: clearEndDate
          ? null
          : (endDate != null ? normalizeDate(endDate) : this.endDate),
      nextOccurrence: nextOccurrence != null
          ? normalizeDate(nextOccurrence)
          : this.nextOccurrence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  /// Converts this recurring transaction rule to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toJson(),
        'amount': amount,
        'categoryId': categoryId,
        if (note != null && note!.isNotEmpty) 'note': note,
        'frequency': frequency.toJson(),
        'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
        'nextOccurrence': nextOccurrence.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isActive': isActive,
      };

  /// Constructs a recurring transaction from a JSON map with defensive parsing.
  factory RecurringMoneyTransaction.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final double parsedAmount;
    if (rawAmount is num) {
      parsedAmount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      parsedAmount = double.tryParse(rawAmount) ?? 0.0;
    } else {
      parsedAmount = 0.0;
    }

    final parsedStartDate = json['startDate'] != null
        ? DateTime.tryParse(json['startDate'] as String)
        : null;

    final parsedEndDate = json['endDate'] != null
        ? DateTime.tryParse(json['endDate'] as String)
        : null;

    final parsedNextOccurrence = json['nextOccurrence'] != null
        ? DateTime.tryParse(json['nextOccurrence'] as String)
        : null;

    final parsedCreatedAt = json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String)
        : null;

    final parsedUpdatedAt = json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'] as String)
        : null;

    final safeStartDate = parsedStartDate ?? DateTime.now();

    return RecurringMoneyTransaction(
      id: json['id'] as String? ?? Uuid.v4(),
      type: TransactionType.fromJson(json['type'] as String?),
      amount: parsedAmount,
      categoryId: json['categoryId'] as String? ?? '',
      note: json['note'] as String?,
      frequency: RecurrenceFrequency.fromJson(json['frequency'] as String?),
      startDate: safeStartDate,
      endDate: parsedEndDate,
      nextOccurrence: parsedNextOccurrence ?? safeStartDate,
      createdAt: parsedCreatedAt ?? DateTime.now(),
      updatedAt: parsedUpdatedAt ?? DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringMoneyTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          (amount - other.amount).abs() < 0.000001 &&
          categoryId == other.categoryId &&
          note == other.note &&
          frequency == other.frequency &&
          startDate.year == other.startDate.year &&
          startDate.month == other.startDate.month &&
          startDate.day == other.startDate.day &&
          endDate?.year == other.endDate?.year &&
          endDate?.month == other.endDate?.month &&
          endDate?.day == other.endDate?.day &&
          nextOccurrence.year == other.nextOccurrence.year &&
          nextOccurrence.month == other.nextOccurrence.month &&
          nextOccurrence.day == other.nextOccurrence.day &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(
        id,
        type,
        amount,
        categoryId,
        note,
        frequency,
        startDate.year,
        startDate.month,
        startDate.day,
        endDate?.year,
        endDate?.month,
        endDate?.day,
        nextOccurrence.year,
        nextOccurrence.month,
        nextOccurrence.day,
        isActive,
      );

  @override
  String toString() =>
      'RecurringMoneyTransaction(id: $id, type: ${type.name}, amount: $amount, categoryId: $categoryId, freq: ${frequency.name}, next: ${nextOccurrence.toIso8601String().split("T").first}, active: $isActive)';
}
