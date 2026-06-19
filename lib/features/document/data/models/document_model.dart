import 'file_model.dart';
import 'folder_model.dart';

class DocumentModel {
  final int? id;
  final String? name;
  final int? fileCount;
  final int? subfolderCount;
  final List<FileModel> files;
  final List<FolderModel> subfolders;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DocumentModel({
    this.id,
    this.name,
    this.fileCount,
    this.subfolderCount,
    required this.files,
    required this.subfolders,
    this.createdAt,
    this.updatedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
        id: json['id'],
        name: json['name'],
        fileCount: json['fileCount'],
        subfolderCount: json['subfolderCount'],
        files: json['files'] == null
            ? []
            : List<FileModel>.from(
                json['files']!.map((x) => FileModel.fromJson(x))),
        subfolders: json['subfolders'] == null
            ? []
            : List<FolderModel>.from(
                json['subfolders']!.map((x) => FolderModel.fromJson(x))),
        createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fileCount': fileCount,
        'subfolderCount': subfolderCount,
        'files': files.map((x) => x.toJson()).toList(),
        'subfolders': subfolders.map((x) => x.toJson()).toList(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
