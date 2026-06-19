class ReferencePlanModel {
  final int? id;
  final String? name;
  final String? description;
  final String? referencePath;
  final int? taskId;

  ReferencePlanModel({
    this.id,
    this.name,
    this.description,
    this.referencePath,
    this.taskId,
  });

  factory ReferencePlanModel.fromJson(Map<String, dynamic> json) {
    return ReferencePlanModel(
      id: json['id'],
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      referencePath: json['referencePath']?.toString(),
      taskId: json['taskId'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'referencePath': referencePath,
        'taskId': taskId,
      };
}
