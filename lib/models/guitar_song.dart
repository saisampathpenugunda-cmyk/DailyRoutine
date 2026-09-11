class GuitarSong {
  final String id;
  final String name;
  final String videoLink;
  final DateTime createdAt;

  const GuitarSong({
    required this.id,
    required this.name,
    required this.videoLink,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'videoLink': videoLink,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GuitarSong.fromJson(Map<String, dynamic> json) => GuitarSong(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        videoLink: json['videoLink'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  GuitarSong copyWith({
    String? id,
    String? name,
    String? videoLink,
    DateTime? createdAt,
  }) {
    return GuitarSong(
      id: id ?? this.id,
      name: name ?? this.name,
      videoLink: videoLink ?? this.videoLink,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuitarSong &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          videoLink == other.videoLink;

  @override
  int get hashCode => Object.hash(id, name, videoLink);
}
