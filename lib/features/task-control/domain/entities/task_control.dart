
class TaskControl {
  final int? id;
  final String? name;
  final String? description;
  final String? referencePath;
  final String? status;
  final int? taskId;

  TaskControl({
    this.id,
    this.name,
    this.description,
    this.referencePath,
    this.status,
    this.taskId,
  });

  factory TaskControl.fromJson(Map<String, dynamic> json) {
    return TaskControl(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      referencePath: json['referencePath'],
      status: json['status'],
      taskId: json['taskId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'referencePath': referencePath,
      'taskId': taskId,
    };
  }

  TaskControl copyWith({
    int? id,
    String? name,
    String? description,
    String? referencePath,
    String? status,
    int? taskId,
  }) {
    return TaskControl(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      referencePath: referencePath ?? this.referencePath,
      status: status ?? this.status,
      taskId: taskId ?? this.taskId,
    );
  }
}
