// task/domain/entities/task.dart


class Task {
  final int? id;
  final String name;
  final String? description;
  final int? lotId;
  final String? lotName;

  Task({
    this.id,
    required this.name,
    this.description,
    this.lotId,
    this.lotName,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final lot = json['lot'];
    return Task(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? json['desc'] ?? json['details'],
      lotId: json['lotId'] ?? (lot is Map<String, dynamic> ? lot['id'] : null),
      lotName: lot is Map<String, dynamic> ? lot['name'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    final desc = description?.trim();
    return {
      'name': name,
      if (desc != null && desc.isNotEmpty) 'description': desc,
      if (lotId != null) 'lotId': lotId,
    };
  }

  Task copyWith({
    int? id,
    String? name,
    String? description,
    int? lotId,
    String? lotName,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      lotId: lotId ?? this.lotId,
      lotName: lotName ?? this.lotName,
    );
  }
}
