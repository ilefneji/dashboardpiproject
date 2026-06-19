class PredefinedControl {
  final String id;
  final String titre;
  final String description;
  final String? element;
  final String? reference;

  PredefinedControl({
    required this.id,
    required this.titre,
    required this.description,
    this.element,
    this.reference,
  });

  factory PredefinedControl.fromJson(Map<String, dynamic> json) {
    return PredefinedControl(
      id: json['id'] as String,
      titre: json['titre'] as String,
      description: json['description'] as String,
      element: json['element'] as String?,
      reference: json['reference'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titre': titre,
        'description': description,
        'element': element,
        'reference': reference,
      };
}

class ControlActivity {
  final String id;
  final String nom;
  final List<PredefinedControl> controles;

  ControlActivity({
    required this.id,
    required this.nom,
    required this.controles,
  });

  factory ControlActivity.fromJson(Map<String, dynamic> json) {
    return ControlActivity(
      id: json['id'] as String,
      nom: json['nom'] as String,
      controles: (json['controles'] as List<dynamic>)
          .map((e) => PredefinedControl.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'controles': controles.map((e) => e.toJson()).toList(),
      };
}

class ControlLot {
  final String id;
  final String nom;
  final List<ControlActivity> activites;

  ControlLot({
    required this.id,
    required this.nom,
    required this.activites,
  });

  factory ControlLot.fromJson(Map<String, dynamic> json) {
    return ControlLot(
      id: json['id'] as String,
      nom: json['nom'] as String,
      activites: (json['activites'] as List<dynamic>)
          .map((e) => ControlActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'activites': activites.map((e) => e.toJson()).toList(),
      };
}

class PredefinedControlData {
  final int version;
  final String source;
  final String description;
  final List<ControlLot> lots;

  PredefinedControlData({
    required this.version,
    required this.source,
    required this.description,
    required this.lots,
  });

  factory PredefinedControlData.fromJson(Map<String, dynamic> json) {
    return PredefinedControlData(
      version: json['version'] as int,
      source: json['source'] as String,
      description: json['description'] as String,
      lots: (json['lots'] as List<dynamic>)
          .map((e) => ControlLot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'source': source,
        'description': description,
        'lots': lots.map((e) => e.toJson()).toList(),
      };
}
