import '../utils/uuid.dart';

/// Represents a single item within a [Checklist] in Notes V3.
class ChecklistItem {
  final String id;
  final String text;
  final bool isCompleted;
  final int order;

  ChecklistItem({
    String? id,
    this.text = '',
    this.isCompleted = false,
    this.order = 0,
  }) : id = id ?? Uuid.v4();

  /// Returns a copy of this checklist item with updated fields.
  /// Preserves original [id] by default.
  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
    int? order,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
    );
  }

  /// Converts this checklist item to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isCompleted': isCompleted,
        'order': order,
      };

  /// Constructs a [ChecklistItem] from a JSON map with defensive parsing.
  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString().trim();
    final id = (rawId != null && rawId.isNotEmpty) ? rawId : Uuid.v4();

    final text = json['text']?.toString() ?? '';

    final rawCompleted = json['isCompleted'];
    final bool isCompleted;
    if (rawCompleted is bool) {
      isCompleted = rawCompleted;
    } else if (rawCompleted is String) {
      isCompleted = rawCompleted.toLowerCase() == 'true';
    } else {
      isCompleted = false;
    }

    final rawOrder = json['order'];
    final int order;
    if (rawOrder is int) {
      order = rawOrder;
    } else if (rawOrder is num) {
      order = rawOrder.toInt();
    } else if (rawOrder is String) {
      order = int.tryParse(rawOrder) ?? 0;
    } else {
      order = 0;
    }

    return ChecklistItem(
      id: id,
      text: text,
      isCompleted: isCompleted,
      order: order,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          text == other.text &&
          isCompleted == other.isCompleted &&
          order == other.order;

  @override
  int get hashCode =>
      id.hashCode ^ text.hashCode ^ isCompleted.hashCode ^ order.hashCode;

  @override
  String toString() =>
      'ChecklistItem(id: $id, text: $text, isCompleted: $isCompleted, order: $order)';
}
