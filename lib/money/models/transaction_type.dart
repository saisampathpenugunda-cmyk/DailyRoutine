/// Represents the type of a monetary transaction: Income or Expense.
enum TransactionType {
  income,
  expense;

  /// Returns true if this transaction represents income.
  bool get isIncome => this == TransactionType.income;

  /// Returns true if this transaction represents an expense.
  bool get isExpense => this == TransactionType.expense;

  /// Human-readable display label.
  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
    }
  }

  /// Converts this [TransactionType] to a JSON-safe string.
  String toJson() => name;

  /// Deserializes a string into a [TransactionType].
  /// Defaults to [TransactionType.expense] if unrecognized.
  static TransactionType fromJson(String? value) {
    if (value == null) return TransactionType.expense;
    return TransactionType.values.firstWhere(
      (type) => type.name.toLowerCase() == value.toLowerCase().trim(),
      orElse: () => TransactionType.expense,
    );
  }
}
