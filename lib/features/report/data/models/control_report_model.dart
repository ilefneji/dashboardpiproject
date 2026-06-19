class ControlReportModel {
  final int? id;
  final String? nom;
  final String? comment;
  final String? zone;
  final int? eventId;
  final int? projectId;

  ControlReportModel({
    this.id,
    this.nom,
    this.comment,
    this.zone,
    this.eventId,
    this.projectId,
  });

  factory ControlReportModel.fromJson(Map<String, dynamic> json) =>
      ControlReportModel(
        id: json['id'],
        nom: json['nom'],
        comment: json['comment'],
        zone: json['zone'],
        eventId: json['eventId'],
        projectId: json['projectId'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'comment': comment,
        'zone': zone,
        'eventId': eventId,
        'projectId': projectId,
      };

  @override
  String toString() => '$nom, $zone, $eventId';
}
