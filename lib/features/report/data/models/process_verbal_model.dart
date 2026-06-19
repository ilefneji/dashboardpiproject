class ProcessVerbalModel {
  final int? id;
  final int? userId;
  final int? eventId;
  final int? projectId;
  final String? zone;
  final String? nom;
  final ProcessVerbalFileModel? file;
  final List<ProcessVerbalCommentModel>? comments;
  final List<Map<String, dynamic>> userStatut;

  ProcessVerbalModel({
    this.id,
    this.userId,
    this.eventId,
    this.projectId,
    this.zone,
    this.nom,
    this.file,
    this.comments,
    this.userStatut = const [],
  });

  factory ProcessVerbalModel.fromJson(Map<String, dynamic> json) =>
      ProcessVerbalModel(
        id: json['id'],
        userId: json['userId'],
        projectId: json['projectId'],
        eventId: json['eventId'],
        zone: json['zone'],
        nom: json['nom'],
        file: json['file'] == null
            ? null
            : ProcessVerbalFileModel.fromJson(json['file']),
        comments: json['comments'] == null
            ? []
            : List<ProcessVerbalCommentModel>.from(
                json['comments']!.map((x) => ProcessVerbalCommentModel.fromJson(x))),
        userStatut: json['userStatut'] == null
            ? []
            : List<Map<String, dynamic>>.from(json['userStatut']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'eventId': eventId,
        'projectId': projectId,
        'zone': zone,
        'nom': nom,
        'file': file?.toJson(),
        'comments': comments?.map((x) => x.toJson()).toList(),
        'userStatut': userStatut,
      };

  @override
  String toString() => '$nom, $zone, $id';
}

class ProcessVerbalFileModel {
  final int? id;
  final String? path;
  final String? name;
  final dynamic folderId;
  final dynamic size;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProcessVerbalFileModel({
    this.id,
    this.path,
    this.name,
    this.folderId,
    this.size,
    this.createdAt,
    this.updatedAt,
  });

  factory ProcessVerbalFileModel.fromJson(Map<String, dynamic> json) =>
      ProcessVerbalFileModel(
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
}

class ProcessVerbalCommentModel {
  final int? id;
  final String? content;
  final DateTime? dateCreated;
  final int? userId;
  final int? pvCommentId;
  final int? fileId;
  final ProcessVerbalFileModel? file;
  final ReportUser? user;

  ProcessVerbalCommentModel({
    this.id,
    this.content,
    this.dateCreated,
    this.userId,
    this.pvCommentId,
    this.fileId,
    this.file,
    this.user,
  });

  factory ProcessVerbalCommentModel.fromJson(Map<String, dynamic> json) =>
      ProcessVerbalCommentModel(
        id: json['id'],
        content: json['content'],
        dateCreated: DateTime.tryParse(json['dateCreated'] ?? ''),
        userId: json['userId'],
        pvCommentId: json['pvCommentId'],
        fileId: json['fileId'],
        file: json['file'] == null
            ? null
            : ProcessVerbalFileModel.fromJson(json['file']),
        user: json['user'] == null ? null : ReportUser.fromJson(json['user']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'dateCreated': dateCreated?.toIso8601String(),
        'userId': userId,
        'fileId': fileId,
        'pvCommentId': pvCommentId,
        'file': file?.toJson(),
        'user': user?.toJson(),
      };
}

class ReportUser {
  final int? id;
  final String? firstname;
  final String? lastname;
  final String? image;

  ReportUser({
    this.id,
    this.firstname,
    this.lastname,
    this.image,
  });

  factory ReportUser.fromJson(Map<String, dynamic> json) => ReportUser(
        id: json['id'],
        firstname: json['firstname'],
        lastname: json['lastname'],
        image: json['image'] != null && json['image'] is Map
            ? json['image']['path']
            : json['image']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstname': firstname,
        'lastname': lastname,
        'image': image,
      };

  String get fullName => '${firstname ?? ''} ${lastname ?? ''}'.trim();
}
