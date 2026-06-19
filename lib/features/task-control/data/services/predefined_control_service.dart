import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/predefined_control_data.dart';

class PredefinedControlService {
  static const String _assetPath =
      'assets/data/lots_activites_controles_predefinis.json';

  PredefinedControlData? _cachedData;

  Future<PredefinedControlData> loadData() async {
    if (_cachedData != null) return _cachedData!;

    final jsonString = await rootBundle.loadString(_assetPath);
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    _cachedData = PredefinedControlData.fromJson(jsonMap);
    return _cachedData!;
  }

  List<ControlLot> get lots => _cachedData?.lots ?? [];

  List<ControlActivity> activitiesForLot(String lotId) {
    final lot = _cachedData?.lots.firstWhereOrNull((l) => l.id == lotId);
    return lot?.activites ?? [];
  }

  List<PredefinedControl> controlsForActivity(String lotId, String activityId) {
    final lot = _cachedData?.lots.firstWhereOrNull((l) => l.id == lotId);
    final activity =
        lot?.activites.firstWhereOrNull((a) => a.id == activityId);
    return activity?.controles ?? [];
  }
}

extension _FirstWhereOrNull<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
