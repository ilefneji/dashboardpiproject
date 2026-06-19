class ReserveModel {
  final int? id;
  final String? nom;
  final String? declaration;
  final String? priority;
  final String? status;
  final List<String>? imagesPath;
  final String? localisation;
  final ReserveFilePlan? filePlan;
  final DateTime? createdAt;
  final String? aiDefectLabel;
  final double? aiConfidence;

  ReserveModel({
    this.id,
    this.nom,
    this.declaration,
    this.priority,
    this.status,
    this.imagesPath,
    this.localisation,
    this.filePlan,
    this.createdAt,
    this.aiDefectLabel,
    this.aiConfidence,
  });

  factory ReserveModel.fromJson(Map<String, dynamic> json) => ReserveModel(
        id: json['id'],
        nom: _stringFromJson(json['nom']),
        declaration: _stringFromJson(json['declaration']),
        priority: _stringFromJson(json['priority']),
        status: _stringFromJson(json['status']),
        imagesPath: _parseImages(json['images'] ?? json['imagesPath']),
        localisation: _stringFromJson(json['localisation']),
        filePlan: json['filePlan'] == null
            ? null
            : ReserveFilePlan.fromJson(json['filePlan']),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        aiDefectLabel: _stringFromJson(json['aiDefectLabel']),
        aiConfidence: _parseDouble(json['aiConfidence']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'declaration': declaration,
        'priority': priority,
        'status': status,
        'images': imagesPath,
        'localisation': localisation,
        'filePlan': filePlan?.toJson(),
        'createdAt': createdAt?.toIso8601String(),
        'aiDefectLabel': aiDefectLabel,
        'aiConfidence': aiConfidence,
      };

  ReserveModel copyWith({
    int? id,
    String? nom,
    String? declaration,
    String? priority,
    String? status,
    List<String>? imagesPath,
    String? localisation,
    ReserveFilePlan? filePlan,
    DateTime? createdAt,
    String? aiDefectLabel,
    double? aiConfidence,
  }) =>
      ReserveModel(
        id: id ?? this.id,
        nom: nom ?? this.nom,
        declaration: declaration ?? this.declaration,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        imagesPath: imagesPath ?? this.imagesPath,
        localisation: localisation ?? this.localisation,
        filePlan: filePlan ?? this.filePlan,
        createdAt: createdAt ?? this.createdAt,
        aiDefectLabel: aiDefectLabel ?? this.aiDefectLabel,
        aiConfidence: aiConfidence ?? this.aiConfidence,
      );

  static String _stringFromJson(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static List<String>? _parseImages(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }
}

class ReserveFilePlan {
  final int? id;
  final String? path;
  final String? name;

  ReserveFilePlan({
    this.id,
    this.path,
    this.name,
  });

  factory ReserveFilePlan.fromJson(Map<String, dynamic> json) => ReserveFilePlan(
        id: json['id'],
        path: json['path']?.toString(),
        name: json['name']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'name': name,
      };
}
