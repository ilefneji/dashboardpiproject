
class JournalChantier {
  final String id;
  final int projectId;
  final int userId;
  final int jour;
  final int mois;
  final int annee;
  final String status;

  final String? meteo;
  final String? accidents;
  final String? materiaux;
  final String? essaisControle;
  final String? experience;
  final String? observations;
  final String? approvisionnement;
  final String? organismeType;
  final String? ressources;
  final String? travaux;
  final int? organizationId;

  final DateTime? sentAt;
  final DateTime? reminderSentAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalChantier({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.jour,
    required this.mois,
    required this.annee,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.meteo,
    this.accidents,
    this.materiaux,
    this.essaisControle,
    this.experience,
    this.observations,
    this.approvisionnement,
    this.organismeType,
    this.ressources,
    this.travaux,
    this.organizationId,
    this.sentAt,
    this.reminderSentAt,
  });

  bool get isDraft => status == 'DRAFT';
  bool get isSubmitted => status == 'SUBMITTED';
  bool get isClosed => status == 'CLOSED';
  bool get isLocked => status == 'LOCKED';
  bool get isArchived => status == 'ARCHIVED';
  bool get isEditable => isDraft || isSubmitted;

  String get dateLabel =>
      '${jour.toString().padLeft(2, '0')}/${mois.toString().padLeft(2, '0')}/$annee';

  JournalChantier copyWith({
    String? id,
    int? projectId,
    int? userId,
    int? jour,
    int? mois,
    int? annee,
    String? status,
    String? meteo,
    String? accidents,
    String? materiaux,
    String? essaisControle,
    String? experience,
    String? observations,
    String? approvisionnement,
    String? organismeType,
    String? ressources,
    String? travaux,
    int? organizationId,
    DateTime? sentAt,
    DateTime? reminderSentAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalChantier(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      jour: jour ?? this.jour,
      mois: mois ?? this.mois,
      annee: annee ?? this.annee,
      status: status ?? this.status,
      meteo: meteo ?? this.meteo,
      accidents: accidents ?? this.accidents,
      materiaux: materiaux ?? this.materiaux,
      essaisControle: essaisControle ?? this.essaisControle,
      experience: experience ?? this.experience,
      observations: observations ?? this.observations,
      approvisionnement: approvisionnement ?? this.approvisionnement,
      organismeType: organismeType ?? this.organismeType,
      ressources: ressources ?? this.ressources,
      travaux: travaux ?? this.travaux,
      organizationId: organizationId ?? this.organizationId,
      sentAt: sentAt ?? this.sentAt,
      reminderSentAt: reminderSentAt ?? this.reminderSentAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory JournalChantier.fromJson(Map<String, dynamic> json) {
    return JournalChantier(
      id: json['id'] as String,
      projectId: json['projectId'],
      userId: json['userId'],
      jour: json['jour'],
      mois: json['mois'],
      annee: json['annee'],
      status: json['status'] as String? ?? 'DRAFT',
      meteo: json['meteo'] as String?,
      accidents: json['accidents'] as String?,
      materiaux: json['materiaux'] as String?,
      essaisControle: json['essaisControle'] as String?,
      experience: json['experience'] as String?,
      observations: json['observations'] as String?,
      approvisionnement: json['approvisionnement'] as String?,
      organismeType: json['organismeType'] as String?,
      ressources: json['ressources'] as String?,
      travaux: json['travaux'] as String?,
      organizationId: json['organizationId'],
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'] as String)
          : null,
      reminderSentAt: json['reminderSentAt'] != null
          ? DateTime.tryParse(json['reminderSentAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'userId': userId,
        'jour': jour,
        'mois': mois,
        'annee': annee,
        'status': status,
        'meteo': meteo,
        'accidents': accidents,
        'materiaux': materiaux,
        'essaisControle': essaisControle,
        'experience': experience,
        'observations': observations,
        'approvisionnement': approvisionnement,
        'organismeType': organismeType,
        'ressources': ressources,
        'travaux': travaux,
        'organizationId': organizationId,
        'sentAt': sentAt?.toIso8601String(),
        'reminderSentAt': reminderSentAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
