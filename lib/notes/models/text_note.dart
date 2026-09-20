import '../utils/uuid.dart';

/// Represents an independent text note in Notes V3.
class TextNote {
  final String id;
  final String title;
  final String content;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  TextNote({
    String? id,
    this.title = '',
    this.content = '',
    this.isPinned = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? Uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? (createdAt ?? DateTime.now());

  /// Returns a copy of this text note with updated fields.
  /// Preserves original [id] and [createdAt] by default.
  /// [updatedAt] defaults to current time on edit unless explicitly provided.
  TextNote copyWith({
    String? id,
    String? title,
    String? content,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TextNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Converts this text note to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'isPinned': isPinned,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Constructs a [TextNote] from a JSON map with defensive parsing.
  /// Corrupted fields or missing values fallback gracefully without throwing.
  factory TextNote.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString().trim();
    final id = (rawId != null && rawId.isNotEmpty) ? rawId : Uuid.v4();

    final title = json['title']?.toString() ?? '';
    final content = json['content']?.toString() ?? '';

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

    return TextNote(
      id: id,
      title: title,
      content: content,
      isPinned: isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextNote &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          content == other.content &&
          isPinned == other.isPinned &&
          createdAt.isAtSameMomentAs(other.createdAt) &&
          updatedAt.isAtSameMomentAs(other.updatedAt);

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      content.hashCode ^
      isPinned.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() =>
      'TextNote(id: $id, title: $title, isPinned: $isPinned, createdAt: $createdAt, updatedAt: $updatedAt)';
}
