import 'dart:convert';

// ── LotOption ─────────────────────────────────────────────────────────────────
// Lightweight object: id + name, parsed from projectLots[n].lot
class LotOption {
  final int id;
  final String name;
  final String? description;

  const LotOption({
    required this.id,
    required this.name,
    this.description,
  });

  factory LotOption.fromMap(Map<String, dynamic> map) {
    return LotOption(
      id: map['id']?.toInt() ?? 0,
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
      };

  @override
  String toString() => 'LotOption(id: $id, name: $name)';
}

// ── ProjectModel ──────────────────────────────────────────────────────────────
class ProjectModel {
  final int id;
  final String name;
  final String description;
  final String startDate;
  final String endDate;
  final int budget;
  final String localisation;
  final String? latitude;
  final String? longitude;
  final bool? isActive;
  final int? organizationId;
  final List<int> lotIds; // ✅ KEPT — flat ID list (for form prefill)
  final List<LotOption> lots; // ✅ NEW  — rich objects (for detail display)

  ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    this.startDate = '',
    this.endDate = '',
    this.budget = 0,
    this.localisation = '',
    this.latitude,
    this.longitude,
    this.isActive,
    this.organizationId,
    this.lotIds = const [], // ✅ KEPT
    this.lots = const [], // ✅ NEW
  });

  // ── fromMap ────────────────────────────────────────────────────────────────
  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    // ✅ Parse rich LotOption list from projectLots[n].lot
    final List<LotOption> parsedLots = _parseLots(map);

    // ✅ Parse flat lotIds — fallback to extracting from parsedLots if missing
    final List<int> parsedLotIds = _parseLotIds(map).isNotEmpty
        ? _parseLotIds(map)
        : parsedLots.map((l) => l.id).toList();

    return ProjectModel(
      id: map['id']?.toInt() ?? 0,
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      startDate: _parseDate(map['startDate']),
      endDate: _parseDate(map['endDate']),
      budget: map['budget']?.toInt() ?? 0,
      localisation: map['localisation']?.toString() ?? '',
      latitude: map['latitude']?.toString(),
      longitude: map['longitude']?.toString(),
      isActive: map['isActive'] as bool?,
      organizationId: (map['organizationId'] as num?)?.toInt(),
      lotIds: parsedLotIds, // ✅ KEPT
      lots: parsedLots, // ✅ NEW
    );
  }

  // ── _parseLots ─────────────────────────────────────────────────────────────
  // Extracts full LotOption objects from projectLots[n].lot
  static List<LotOption> _parseLots(Map<String, dynamic> map) {
    if (map['projectLots'] is! List) return [];

    final result = <LotOption>[];
    for (final entry in map['projectLots'] as List) {
      if (entry is! Map<String, dynamic>) continue;
      final lotData = entry['lot'];
      if (lotData is Map<String, dynamic>) {
        result.add(LotOption.fromMap(lotData));
      }
    }
    return result;
  }

  // ── _parseLotIds ───────────────────────────────────────────────────────────
  // ✅ KEPT exactly as before — handles both flat and nested shapes
  /// Handles both:
  ///   - flat array:     "lotIds": [8, 9, 10]
  ///   - relation array: "projectLots": [{ "lotId": 8 }, { "lotId": 9 }]
  static List<int> _parseLotIds(Map<String, dynamic> map) {
    // Case 1 — flat lotIds array
    if (map['lotIds'] is List) {
      return List<int>.from(
        (map['lotIds'] as List).map((e) => (e as num).toInt()),
      );
    }

    // Case 2 — nested projectLots relation
    if (map['projectLots'] is List) {
      return List<int>.from(
        (map['projectLots'] as List)
            .whereType<Map>()
            .where((e) => e['lotId'] != null)
            .map((e) => (e['lotId'] as num).toInt()),
      );
    }

    return [];
  }

  // ── _parseDate ─────────────────────────────────────────────────────────────
  // ✅ KEPT exactly as before
  static String _parseDate(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.isEmpty) return '';
    if (str.contains('T')) return str.split('T').first;
    return str;
  }

  // ── toMap ──────────────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'budget': budget,
      'localisation': localisation,
      'latitude': latitude,
      'longitude': longitude,
      'isActive': isActive,
      'organizationId': organizationId,
      'lotIds': lotIds, // ✅ KEPT
    };
  }

  // ── JSON helpers ───────────────────────────────────────────────────────────
  String toJson() => json.encode(toMap());

  factory ProjectModel.fromJson(String source) =>
      ProjectModel.fromMap(json.decode(source));

  // ── copyWith ───────────────────────────────────────────────────────────────
  ProjectModel copyWith({
    int? id,
    String? name,
    String? description,
    String? startDate,
    String? endDate,
    int? budget,
    String? localisation,
    String? latitude,
    String? longitude,
    bool? isActive,
    int? organizationId,
    List<int>? lotIds, // ✅ KEPT
    List<LotOption>? lots, // ✅ NEW
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      localisation: localisation ?? this.localisation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      organizationId: organizationId ?? this.organizationId,
      lotIds: lotIds ?? this.lotIds,
      lots: lots ?? this.lots,
    );
  }

  @override
  String toString() => 'ProjectModel(id: $id, name: $name, budget: $budget, '
      'lotIds: $lotIds, lots: ${lots.length})';
}
