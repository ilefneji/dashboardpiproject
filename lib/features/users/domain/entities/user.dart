
class UserModel {
  UserModel({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.phone,
    required this.password,
    required this.resetCode,
    required this.function,
    required this.activationCode,
    required this.isActive,
    required this.isConfirmed,
    required this.resetToken,
    required this.deviceToken,
    required this.imageId,
    required this.organizationId,
    required this.deactivatedAt,
    required this.deletionScheduledAt,
    required this.image,
    required this.organization,
    required this.isAdmin,
    this.projectCount,
    this.eventCount,
  });

  final int? id;
  final String? firstname;
  final String? lastname;
  final String? email;
  final dynamic phone;
  final String? password;
  final dynamic resetCode;
  final String? function;
  final String? activationCode;
  final bool? isActive;
  final dynamic isConfirmed;
  final dynamic resetToken;
  final dynamic deviceToken;
  final dynamic imageId;
  final int? organizationId;
  final dynamic deactivatedAt;
  final dynamic deletionScheduledAt;
  final dynamic image;
  final Organization? organization;
  final bool? isAdmin;
  final int? projectCount;
  final int? eventCount;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["id"],
      firstname: json["firstname"],
      lastname: json["lastname"],
      email: json["email"],
      phone: json["phone"],
      password: json["password"],
      resetCode: json["resetCode"],
      function: json["function"],
      activationCode: json["activationCode"],
      isActive: json["isActive"],
      isConfirmed: json["isConfirmed"],
      resetToken: json["resetToken"],
      deviceToken: json["deviceToken"],
      imageId: json["imageId"],
      organizationId: json["organizationId"],
      deactivatedAt: json["deactivatedAt"],
      deletionScheduledAt: json["deletionScheduledAt"],
      image: json["image"],
      organization: json["organization"] == null
          ? null
          : Organization.fromJson(json["organization"]),
      isAdmin: json["isAdmin"],
      projectCount: json["projectCount"],
      eventCount: json["eventCount"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "firstname": firstname,
        "lastname": lastname,
        "email": email,
        "phone": phone,
        "password": password,
        "resetCode": resetCode,
        "function": function,
        "activationCode": activationCode,
        "isActive": isActive,
        "isConfirmed": isConfirmed,
        "resetToken": resetToken,
        "deviceToken": deviceToken,
        "imageId": imageId,
        "organizationId": organizationId,
        "deactivatedAt": deactivatedAt,
        "deletionScheduledAt": deletionScheduledAt,
        "image": image,
        "organization": organization?.toJson(),
        "isAdmin": isAdmin,
      };

  UserModel copyWith({
    int? id,
    String? firstname,
    String? lastname,
    String? email,
    dynamic phone,
    String? password,
    dynamic resetCode,
    String? function,
    String? activationCode,
    bool? isActive,
    dynamic isConfirmed,
    dynamic resetToken,
    dynamic deviceToken,
    dynamic imageId,
    int? organizationId,
    dynamic deactivatedAt,
    dynamic deletionScheduledAt,
    dynamic image,
    Organization? organization,
    bool? isAdmin,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      resetCode: resetCode ?? this.resetCode,
      function: function ?? this.function,
      activationCode: activationCode ?? this.activationCode,
      isActive: isActive ?? this.isActive,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      resetToken: resetToken ?? this.resetToken,
      deviceToken: deviceToken ?? this.deviceToken,
      imageId: imageId ?? this.imageId,
      organizationId: organizationId ?? this.organizationId,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      deletionScheduledAt: deletionScheduledAt ?? this.deletionScheduledAt,
      image: image ?? this.image,
      organization: organization ?? this.organization,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}

class Organization {
  Organization({
    required this.id,
    required this.name,
    required this.createdAt,
    this.organismeType,
  });

  final int? id;
  final String? name;
  final DateTime? createdAt;
  final String? organismeType;

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json["id"],
      name: json["name"],
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      organismeType: json["organismeType"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "createdAt": createdAt?.toIso8601String(),
        "organismeType": organismeType,
      };
}
