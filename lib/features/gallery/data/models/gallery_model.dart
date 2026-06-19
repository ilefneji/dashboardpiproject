class GalleryModel {
  final int? id;
  final String? path;
  final String? name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Reserve? reserve;

  GalleryModel({
    this.id,
    this.path,
    this.name,
    this.createdAt,
    this.updatedAt,
    this.reserve,
  });

  factory GalleryModel.fromJson(Map<String, dynamic> json) => GalleryModel(
        id: json['id'],
        path: json['path'],
        name: json['name'],
        createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
        reserve:
            json['reserve'] == null ? null : Reserve.fromJson(json['reserve']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'name': name,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'reserve': reserve?.toJson(),
      };
}

class Reserve {
  final int? id;
  final String? nom;
  final DateTime? createdAt;
  final User? user;

  Reserve({
    this.id,
    this.nom,
    this.createdAt,
    this.user,
  });

  factory Reserve.fromJson(Map<String, dynamic> json) => Reserve(
        id: json['id'],
        nom: json['nom'],
        createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
        user: json['user'] == null ? null : User.fromJson(json['user']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'createdAt': createdAt?.toIso8601String(),
        'user': user?.toJson(),
      };
}

class User {
  final int? id;
  final String? firstname;
  final String? lastname;

  User({
    this.id,
    this.firstname,
    this.lastname,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        firstname: json['firstname'],
        lastname: json['lastname'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstname': firstname,
        'lastname': lastname,
      };
}
