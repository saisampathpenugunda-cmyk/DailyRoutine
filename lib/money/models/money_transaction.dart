import '../utils/uuid.dart';
import 'transaction_type.dart';

/// Represents a single monetary transaction (income or expense).
class MoneyTransaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns today's date in local calendar time (midnight 00:00:00).
  static DateTime localToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  MoneyTransaction({
    String? id,
    required this.type,
    required this.amount,
    required this.category,
    DateTime? date,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? Uuid.v4(),
        date = date ?? localToday(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? (createdAt ?? DateTime.now());

  /// Returns a copy of this transaction with updated fields.
  /// Preserves original [id] and [createdAt] by default, and updates [updatedAt].
  MoneyTransaction copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
    bool clearNote = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MoneyTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Converts transaction to JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toJson(),
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        if (note != null && note!.isNotEmpty) 'note': note,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Constructs a transaction from a JSON map.
  factory MoneyTransaction.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final double parsedAmount;
    if (rawAmount is num) {
      parsedAmount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      parsedAmount = double.tryParse(rawAmount) ?? 0.0;
    } else {
      parsedAmount = 0.0;
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

    return MoneyTransaction(
      id: json['id'] as String?,
      type: TransactionType.fromJson(json['type'] as String?),
      amount: parsedAmount,
      category: json['category'] as String? ?? '',
      date: parsedDate ?? localToday(),
      note: json['note'] as String?,
      createdAt: parsedCreatedAt ?? DateTime.now(),
      updatedAt: parsedUpdatedAt ?? (parsedCreatedAt ?? DateTime.now()),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoneyTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          (amount - other.amount).abs() < 0.000001 &&
          category == other.category &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day &&
          note == other.note;

  @override
  int get hashCode => Object.hash(
        id,
        type,
        amount,
        category,
        date.year,
        date.month,
        date.day,
        note,
      );

  @override
  String toString() =>
      'MoneyTransaction(id: $id, type: ${type.name}, amount: $amount, category: $category, date: ${date.toIso8601String().split("T").first})';
}
