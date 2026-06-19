class Organization {
  final int     id;           // ✅ non-nullable — backend always returns it
  final String  name;
  final String? description;
  final String? organismeType;
  final String? createdAt;    // ✅ stored as ISO string — never pre-formatted
  final int?    companyId;    // ✅ NEW — backend now returns companyId

  Organization({
    required this.id,
    required this.name,
    this.description,
    this.organismeType,
    this.createdAt,
    this.companyId,
  });

  Organization copyWith({
    int?    id,
    String? name,
    String? description,
    String? organismeType,
    String? createdAt,
    int?    companyId,
  }) {
    return Organization(
      id:            id            ?? this.id,
      name:          name          ?? this.name,
      description:   description   ?? this.description,
      organismeType: organismeType ?? this.organismeType,
      createdAt:     createdAt     ?? this.createdAt,
      companyId:     companyId     ?? this.companyId,
    );
  }

  @override
  String toString() =>
      'Organization(id: $id, name: $name, organismeType: $organismeType, companyId: $companyId)';
}