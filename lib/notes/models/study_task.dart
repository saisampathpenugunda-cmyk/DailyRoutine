import '../utils/uuid.dart';

/// Represents a single directly-checkable study task in V3.
class StudyTask {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudyTask({
    String? id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.isPinned = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? Uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? (createdAt ?? DateTime.now());

  /// Returns a copy of this task with updated properties.
  /// Preserves the original [id] and [createdAt] by default.
  StudyTask copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Converts this task to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
        'isPinned': isPinned,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Constructs a [StudyTask] from a JSON map with defensive fallbacks.
  factory StudyTask.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString().trim();
    final id = (rawId != null && rawId.isNotEmpty) ? rawId : Uuid.v4();

    final title = json['title']?.toString() ?? '';
    final description = json['description']?.toString() ?? '';

    final rawCompleted = json['isCompleted'];
    final bool isCompleted;
    if (rawCompleted is bool) {
      isCompleted = rawCompleted;
    } else if (rawCompleted is String) {
      isCompleted = rawCompleted.toLowerCase() == 'true';
    } else {
      isCompleted = false;
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

    return StudyTask(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted,
      isPinned: isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyTask &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          isCompleted == other.isCompleted &&
          isPinned == other.isPinned &&
          createdAt.isAtSameMomentAs(other.createdAt) &&
          updatedAt.isAtSameMomentAs(other.updatedAt);

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      isCompleted.hashCode ^
      isPinned.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() =>
      'StudyTask(id: $id, title: "$title", isCompleted: $isCompleted, isPinned: $isPinned)';
}
