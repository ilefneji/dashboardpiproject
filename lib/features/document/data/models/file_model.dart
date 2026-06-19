class FileModel {
  final int? id;
  final String? path;
  final String? name;
  final int? folderId;
  final String? size;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FileModel({
    this.id,
    this.path,
    this.name,
    this.folderId,
    this.size,
    this.createdAt,
    this.updatedAt,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) => FileModel(
        id: json['id'],
        path: json['path'],
        name: json['name'],
        folderId: json['folderId'],
        size: json['size'],
        createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'name': name,
        'folderId': folderId,
        'size': size,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  String get extension {
    final fileName = name ?? path ?? '';
    final lastDot = fileName.lastIndexOf('.');
    return lastDot == -1 ? '' : fileName.substring(lastDot + 1).toLowerCase();
  }

  String get displayName => name ?? path?.split('/').last ?? 'Fichier sans nom';
}
