
class User {
  final int id;
  final String firstname;
  final String? lastname;
  final String email;
  final String? phone;
  final String? function;
  final bool isActive;
  final bool isAdmin;
  final int? imageId;
  final int? organizationId;

  User({
    required this.id,
    required this.firstname,
    this.lastname,
    required this.email,
    this.phone,
    this.function,
    required this.isActive,
    required this.isAdmin,
    this.imageId,
    this.organizationId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      email: json['email'],
      phone: json['phone'],
      function: json['function'],
      isActive: json['isActive'],
      isAdmin: json['isAdmin'] ?? false,
      imageId: json['imageId'],
      organizationId: json['organizationId'],
    );
  }

  String get fullName => '$firstname ${lastname ?? ''}'.trim();
}
