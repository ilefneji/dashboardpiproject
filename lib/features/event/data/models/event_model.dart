import 'package:flutter/material.dart';

import '../../../project/data/models/project_model.dart';

/// Modèle de données pour un événement projet, aligné sur le contrat
/// de l'application mobile.
class EventModel {
  EventModel({
    this.id,
    this.userId,
    this.title,
    this.description,
    this.zone,
    this.name,
    this.duration,
    this.date,
    this.startHour,
    this.endHour,
    this.projectId,
    this.project,
    this.eventUsers,
    this.status,
  });

  final int? id;
  final int? userId;
  final String? title;
  final String? description;
  final String? zone;
  final String? name;
  final String? duration;
  final String? date;
  final String? startHour;
  final String? endHour;
  final int? projectId;
  final ProjectModel? project;
  final List<EventParticipant>? eventUsers;
  final String? status;

  factory EventModel.fromJson(Map<String, dynamic> json) => EventModel(
        id: json['id'],
        userId: json['userId'],
        title: json['title']?.toString(),
        description: json['description']?.toString(),
        zone: json['zone']?.toString(),
        name: json['name']?.toString(),
        duration: _computeDuration(json['startHour'], json['endHour']),
        date: json['date']?.toString(),
        startHour: json['startHour']?.toString(),
        endHour: json['endHour']?.toString(),
        projectId: json['projectId'],
        project: json['project'] != null
            ? ProjectModel.fromMap(json['project'] as Map<String, dynamic>)
            : null,
        eventUsers: _parseParticipants(json['eventUsers']),
        status: json['status']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'zone': zone,
        'name': name,
        'date': date,
        'startHour': startHour,
        'endHour': endHour,
        'projectId': projectId,
        'eventUsers': eventUsers?.map((x) => x.toJson()).toList() ?? [],
        'status': status,
      };

  String get displayName {
    if (title != null && title!.trim().isNotEmpty) return title!;
    if (name != null && name!.trim().isNotEmpty) return name!;
    return 'Événement #${id ?? ''}';
  }

  static String? _computeDuration(dynamic start, dynamic end) {
    if (start == null || end == null) return null;

    final startTime = _parseTime(start.toString());
    final endTime = _parseTime(end.toString());
    if (startTime == null || endTime == null) return null;

    var startMinutes = startTime.hour * 60 + startTime.minute;
    var endMinutes = endTime.hour * 60 + endTime.minute;
    if (endMinutes < startMinutes) endMinutes += 24 * 60;

    final diff = endMinutes - startMinutes;
    final hours = diff ~/ 60;
    final minutes = diff % 60;

    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes.toString().padLeft(2, '0')}';
  }

  static TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static List<EventParticipant>? _parseParticipants(dynamic value) {
    if (value is! List) return null;
    return value
        .whereType<Map<String, dynamic>>()
        .map((x) => EventParticipant.fromJson(x))
        .toList();
  }

  @override
  String toString() =>
      'EventModel(id: $id, title: $title, date: $date, projectId: $projectId)';
}

/// Représentation allégée d'un participant à un événement.
class EventParticipant {
  EventParticipant({
    this.id,
    this.eventId,
    this.userId,
    this.firstName,
    this.lastName,
    this.email,
    this.function,
    this.imageId,
  });

  final int? id;
  final int? eventId;
  final int? userId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? function;
  final String? imageId;

  factory EventParticipant.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : null;

    return EventParticipant(
      id: json['id'],
      eventId: json['eventId'],
      userId: json['userId'] ?? user?['id'],
      firstName: user?['firstname']?.toString() ??
          json['firstname']?.toString(),
      lastName:
          user?['lastname']?.toString() ?? json['lastname']?.toString(),
      email: user?['email']?.toString() ?? json['email']?.toString(),
      function:
          user?['function']?.toString() ?? json['function']?.toString(),
      imageId: user?['imageId']?.toString() ??
          json['imageId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'userId': userId,
        'firstname': firstName,
        'lastname': lastName,
        'email': email,
        'function': function,
        'imageId': imageId,
      };

  String get fullName {
    final parts = <String>[
      if (firstName != null && firstName!.trim().isNotEmpty) firstName!,
      if (lastName != null && lastName!.trim().isNotEmpty) lastName!,
    ];
    return parts.isEmpty ? 'Participant' : parts.join(' ');
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'))
      ..removeWhere((s) => s.isEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return '$first$last'.toUpperCase();
  }
}
