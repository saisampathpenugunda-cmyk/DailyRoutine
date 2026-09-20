import '../utils/uuid.dart';
import 'checklist_item.dart';

/// Represents an independent checklist note in Notes V3.
class Checklist {
  final String id;
  final String title;
  final List<ChecklistItem> items;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  Checklist({
    String? id,
    this.title = '',
    List<ChecklistItem>? items,
    this.isPinned = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? Uuid.v4(),
        items = List.unmodifiable(items ?? const []),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? (createdAt ?? DateTime.now());

  /// Total count of checklist items.
  int get totalItemsCount => items.length;

  /// Count of completed items.
  int get completedItemsCount => items.where((i) => i.isCompleted).length;

  /// Whether all items in this checklist are completed.
  bool get isAllCompleted => items.isNotEmpty && items.every((i) => i.isCompleted);

  /// Returns a copy of this checklist with updated fields.
  /// Preserves original [id] and [createdAt] by default.
  /// [updatedAt] defaults to current time on edit unless explicitly provided.
  Checklist copyWith({
    String? id,
    String? title,
    List<ChecklistItem>? items,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Checklist(
      id: id ?? this.id,
      title: title ?? this.title,
      items: items ?? this.items,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Converts this checklist to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'items': items.map((item) => item.toJson()).toList(),
        'isPinned': isPinned,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Constructs a [Checklist] from a JSON map with defensive parsing.
  /// Corrupted fields, invalid list shapes, or malformed items fallback safely.
  factory Checklist.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString().trim();
    final id = (rawId != null && rawId.isNotEmpty) ? rawId : Uuid.v4();

    final title = json['title']?.toString() ?? '';

    final rawItems = json['items'];
    final List<ChecklistItem> parsedItems = [];
    if (rawItems is List) {
      for (int i = 0; i < rawItems.length; i++) {
        final item = rawItems[i];
        if (item is Map) {
          try {
            final parsed = ChecklistItem.fromJson(Map<String, dynamic>.from(item));
            parsedItems.add(parsed);
          } catch (_) {
            // Defensively skip individual malformed item
          }
        }
      }
    }

    final rawPinned = json['isPinned'];
    final bool isPinned;
    if (rawPinned is bool) {
      isPinned = rawPinned;
    } else if (rawPinned is String) {
      isPinned = rawPinned.toLowerCase() == 'true';
    } else {
      isPinned = false;
    }

    final parsedCreatedAt = json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null;
    final createdAt = parsedCreatedAt ?? DateTime.now();

    final parsedUpdatedAt = json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'].toString())
        : null;
    final updatedAt = parsedUpdatedAt ?? createdAt;

    return Checklist(
      id: id,
      title: title,
      items: parsedItems,
      isPinned: isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Checklist &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          isPinned == other.isPinned &&
          createdAt.isAtSameMomentAs(other.createdAt) &&
          updatedAt.isAtSameMomentAs(other.updatedAt) &&
          _areItemsEqual(items, other.items);

  static bool _areItemsEqual(List<ChecklistItem> a, List<ChecklistItem> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      items.length.hashCode ^
      isPinned.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() =>
      'Checklist(id: $id, title: $title, itemsCount: ${items.length}, isPinned: $isPinned, createdAt: $createdAt, updatedAt: $updatedAt)';
}
