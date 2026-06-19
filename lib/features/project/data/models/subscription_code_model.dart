import 'dart:convert';


class SubscriptionCodeModel {
  final int id;
  final String code;
  final int projectId;
  final int numberOfMembers;
  final bool isUsed;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionCodeModel({
    required this.id,
    required this.code,
    required this.projectId,
    required this.numberOfMembers,
    required this.isUsed,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'projectId': projectId,
      'numberOfMembers': numberOfMembers,
      'isUsed': isUsed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SubscriptionCodeModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionCodeModel(
      id: map['id'],
      code: map['code'] ?? '',
      projectId: map['projectId'],
      numberOfMembers: map['numberOfMembers'],
      isUsed: map['isUsed'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory SubscriptionCodeModel.fromJson(String source) =>
      SubscriptionCodeModel.fromMap(json.decode(source));

  // Request model for creating a subscription code
  static Map<String, dynamic> createRequest({
    required int projectId,
    required int numberOfMembers,
  }) {
    return {
      'projectId': projectId,
      'numberOfMembers': numberOfMembers,
    };
  }
}
