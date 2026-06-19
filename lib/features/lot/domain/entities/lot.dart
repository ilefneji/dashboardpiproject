
class Lot {
  final int? id;
  final String name;
  final String description;
  final List<int> taskIds;
  final String? createdAt;
  final String? updatedAt;

  // ✅ Safe getter — use this everywhere an int is required
  int get safeId => id ?? 0;

  Lot({
    this.id,
    required this.name,
    required this.description,
    this.taskIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Lot.fromJson(Map<String, dynamic> json) {
    return Lot(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      taskIds: json['tasks'] != null
          ? (json['tasks'] as List).map((task) => task['id'] as int).toList()
          : [],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
    };
  }

  Lot copyWith({
    int? id,
    String? name,
    String? description,
    List<int>? taskIds,
    String? createdAt,
    String? updatedAt,
  }) {
    return Lot(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      taskIds: taskIds ?? this.taskIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
