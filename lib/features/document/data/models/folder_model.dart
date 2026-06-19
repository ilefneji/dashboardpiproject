import 'file_model.dart';

class FolderModel {
  final int? id;
  final String? name;
  final int? parentId;
  final int? projectId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<FileModel>? files;
  final List<FolderModel>? subfolders;
  final Count? count;

  FolderModel({
    this.id,
    this.name,
    this.parentId,
    this.projectId,
    this.createdAt,
    this.updatedAt,
    this.files,
    this.subfolders,
    this.count,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) => FolderModel(
        id: json['id'],
        name: json['name'],
        parentId: json['parentId'],
        projectId: json['projectId'],
        createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
        files: json['files'] == null
            ? []
            : List<FileModel>.from(
                json['files']!.map((x) => FileModel.fromJson(x))),
        subfolders: json['subfolders'] == null
            ? []
            : List<FolderModel>.from(
                json['subfolders']!.map((x) => FolderModel.fromJson(x))),
        count: json['_count'] == null ? null : Count.fromJson(json['_count']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parentId': parentId,
        'projectId': projectId,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'files': files?.map((x) => x.toJson()).toList(),
        'subfolders': subfolders?.map((x) => x.toJson()).toList(),
        '_count': count?.toJson(),
      };

  int get totalFiles =>
      (files?.length ?? 0) +
      (subfolders?.fold<int>(0, (sum, f) => sum + f.totalFiles) ?? 0);

  int get totalSubfolders =>
      (subfolders?.length ?? 0) +
      (subfolders?.fold<int>(0, (sum, f) => sum + f.totalSubfolders) ?? 0);
}

class Count {
  final int? files;
  final int? children;

  Count({this.files, this.children});

  factory Count.fromJson(Map<String, dynamic> json) => Count(
        files: json['files'],
        children: json['children'],
      );

  Map<String, dynamic> toJson() => {
        'files': files,
        'children': children,
      };
}
