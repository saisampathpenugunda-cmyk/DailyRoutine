import 'transaction_type.dart';

/// Represents a category for transactions, which can be built-in or user-created.
class MoneyCategory {
  final String id;
  final String name;
  final bool isBuiltIn;
  final String? icon;
  final TransactionType type;

  const MoneyCategory({
    required this.id,
    required this.name,
    this.isBuiltIn = false,
    this.icon,
    this.type = TransactionType.expense,
  });

  /// The 10 permanent built-in expense categories for DailyRoutine Money.
  static const List<MoneyCategory> defaultExpenseCategories = [
    MoneyCategory(id: 'food', name: 'Food', isBuiltIn: true, icon: 'restaurant', type: TransactionType.expense),
    MoneyCategory(id: 'transport', name: 'Transport', isBuiltIn: true, icon: 'directions_car', type: TransactionType.expense),
    MoneyCategory(id: 'education', name: 'Education', isBuiltIn: true, icon: 'school', type: TransactionType.expense),
    MoneyCategory(id: 'shopping', name: 'Shopping', isBuiltIn: true, icon: 'shopping_bag', type: TransactionType.expense),
    MoneyCategory(id: 'bills', name: 'Bills', isBuiltIn: true, icon: 'receipt_long', type: TransactionType.expense),
    MoneyCategory(id: 'entertainment', name: 'Entertainment', isBuiltIn: true, icon: 'movie', type: TransactionType.expense),
    MoneyCategory(id: 'health', name: 'Health', isBuiltIn: true, icon: 'medical_services', type: TransactionType.expense),
    MoneyCategory(id: 'work', name: 'Work', isBuiltIn: true, icon: 'work', type: TransactionType.expense),
    MoneyCategory(id: 'home', name: 'Home', isBuiltIn: true, icon: 'home', type: TransactionType.expense),
    MoneyCategory(id: 'other', name: 'Other', isBuiltIn: true, icon: 'category', type: TransactionType.expense),
  ];

  /// The 5 permanent built-in income categories for DailyRoutine Money.
  static const List<MoneyCategory> defaultIncomeCategories = [
    MoneyCategory(id: 'salary', name: 'Salary', isBuiltIn: true, icon: 'payments', type: TransactionType.income),
    MoneyCategory(id: 'freelance', name: 'Freelance', isBuiltIn: true, icon: 'laptop', type: TransactionType.income),
    MoneyCategory(id: 'business', name: 'Business', isBuiltIn: true, icon: 'business', type: TransactionType.income),
    MoneyCategory(id: 'gift', name: 'Gift', isBuiltIn: true, icon: 'card_giftcard', type: TransactionType.income),
    MoneyCategory(id: 'income_other', name: 'Other', isBuiltIn: true, icon: 'category', type: TransactionType.income),
  ];

  /// All 15 permanent built-in categories (10 Expense + 5 Income).
  static const List<MoneyCategory> defaultCategories = [
    ...defaultExpenseCategories,
    ...defaultIncomeCategories,
  ];

  /// Creates a copy of this category with given fields replaced.
  MoneyCategory copyWith({
    String? id,
    String? name,
    bool? isBuiltIn,
    String? icon,
    TransactionType? type,
  }) {
    return MoneyCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      icon: icon ?? this.icon,
      type: type ?? this.type,
    );
  }

  /// Serializes category to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isBuiltIn': isBuiltIn,
        if (icon != null) 'icon': icon,
        'type': type.name,
      };

  /// Deserializes category from a JSON map.
  factory MoneyCategory.fromJson(Map<String, dynamic> json) {
    return MoneyCategory(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      icon: json['icon'] as String?,
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoneyCategory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          isBuiltIn == other.isBuiltIn &&
          icon == other.icon &&
          type == other.type;

  @override
  int get hashCode => Object.hash(id, name, isBuiltIn, icon, type);

  @override
  String toString() =>
      'MoneyCategory(id: $id, name: $name, type: ${type.name}, isBuiltIn: $isBuiltIn)';
}
