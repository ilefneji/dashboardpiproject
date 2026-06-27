import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../dashboard/presentation/controllers/app_search_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/organization.dart';
import '../../domain/repositories/organization_repository.dart';

class OrganizationController extends GetxController {
  static const Duration _dashboardLoadTimeout = Duration(seconds: 12);

  final OrganizationRepository _repository;

  final RxList<Organization> organizations = <Organization>[].obs;
  final RxList<Organization> filteredOrganizations = <Organization>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString error = ''.obs;

  OrganizationController(this._repository);

  // ─────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _initSearchAndFetch();
  }

  void _initSearchAndFetch() {
    try {
      final searchService = Get.find<AppSearchController>();
      searchService.setContext('organizations');
      ever(searchService.query, (String q) => searchOrganizations(q));
    } catch (_) {
      // AppSearchController not registered — search disabled gracefully
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // FETCH
  // ─────────────────────────────────────────────────────────────────

  Future<void> fetchOrganizations() async {
    if (isLoading.value) {
      debugPrint('[Dashboard][Organizations] load skipped: already running');
      return;
    }

    isLoading.value = true;
    hasError.value = false;
    error.value = '';
    debugPrint('[Dashboard][Organizations] load started');

    try {
      final result =
          await _repository.getOrganizations().timeout(_dashboardLoadTimeout);
      organizations.assignAll(result); // ✅ GetX pattern
      filteredOrganizations.assignAll(result); // ✅ GetX pattern
      debugPrint('[Dashboard][Organizations] loaded ${result.length} item(s)');
    } on TimeoutException {
      hasError.value = true;
      error.value = 'Organization loading timeout';
      debugPrint('[Dashboard][Organizations] timeout after 12s');
    } catch (e) {
      hasError.value = true;
      error.value = e.toString();
      debugPrint('[Dashboard][Organizations] error: $e');
    } finally {
      isLoading.value = false;
      debugPrint('[Dashboard][Organizations] loading=false');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // SEARCH
  // ─────────────────────────────────────────────────────────────────

  void searchOrganizations(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      filteredOrganizations.assignAll(organizations);
      return;
    }
    filteredOrganizations.assignAll(
      organizations.where((org) {
        final name = org.name.toLowerCase();
        final type = (org.organismeType ?? '').toLowerCase();
        return name.contains(q) || type.contains(q); // ✅ search name + type
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────────────────────────

  Future<bool> createOrganization(Organization organization) async {
    if (isLoading.value) return false;

    isLoading.value = true;
    hasError.value = false;
    error.value = '';

    try {
      await _repository.createOrganization(organization);
      await fetchOrganizations();
      Get.snackbar(
        'success'.tr,
        'organization_created'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.successColor,
        colorText: AppColors.white,
      );
      return true;
    } catch (e) {
      hasError.value = true;
      error.value = e.toString();
      debugPrint('❌ createOrganization error: $e');
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────────────

  Future<bool> updateOrganization(Organization organization) async {
    if (isLoading.value) return false;

    isLoading.value = true;
    hasError.value = false;
    error.value = '';

    try {
      await _repository.updateOrganization(organization);
      await fetchOrganizations();
      Get.snackbar(
        'success'.tr,
        'organization_updated'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.successColor,
        colorText: AppColors.white,
      );
      return true;
    } catch (e) {
      hasError.value = true;
      error.value = e.toString();
      debugPrint('❌ updateOrganization error: $e');
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────────────

  Future<bool> deleteOrganization(int id) async {
    if (isLoading.value) return false;

    isLoading.value = true;
    hasError.value = false;
    error.value = '';

    try {
      await _repository.deleteOrganization(id);
      await fetchOrganizations();
      Get.snackbar(
        'success'.tr,
        'organization_deleted'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.successColor,
        colorText: AppColors.white,
      );
      return true;
    } catch (e) {
      hasError.value = true;
      error.value = e.toString();
      debugPrint('❌ deleteOrganization error: $e');
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────

  bool doesOrganizationNameExist(String name, {int? excludeId}) =>
      organizations.any((org) =>
          org.name.toLowerCase() == name.toLowerCase() &&
          org.id != excludeId); // ✅ excludeId so edit doesn't flag itself

  /// Format ISO createdAt for display in UI
  String formatDate(String? isoDate) {
    if (isoDate == null || isoDate.trim().isEmpty) return '—';
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return '—';
    return DateFormat('dd/MM/yyyy').format(parsed);
  }

  // ─────────────────────────────────────────────────────────────────
  // DASHBOARD — Basic getters
  // ─────────────────────────────────────────────────────────────────

  int get totalOrganizations => organizations.length;
  int get filteredCount => filteredOrganizations.length;

  int get totalTypes => organizations
      .map((o) => (o.organismeType ?? '').trim())
      .where((t) => t.isNotEmpty)
      .toSet()
      .length;

  int get organizationsWithDescription => organizations
      .where((o) => (o.description ?? '').trim().isNotEmpty)
      .length;

  // ─────────────────────────────────────────────────────────────────
  // DASHBOARD — By type
  // ─────────────────────────────────────────────────────────────────

  Map<String, int> get organizationsByType {
    final Map<String, int> grouped = {};
    for (final org in organizations) {
      final raw = (org.organismeType ?? '').trim();
      final type = raw.isEmpty ? 'Non défini' : raw;
      final normalized = _normalizeType(type);
      final existingKey = grouped.keys.firstWhere(
        (k) => _normalizeType(k) == normalized,
        orElse: () => '',
      );
      if (existingKey.isNotEmpty) {
        grouped[existingKey] = (grouped[existingKey] ?? 0) + 1;
      } else {
        grouped[type] = (grouped[type] ?? 0) + 1;
      }
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // DASHBOARD — Recent orgs (last 30 days)
  // ✅ FIXED: DateTime.tryParse works now — createdAt is ISO string
  // ─────────────────────────────────────────────────────────────────

  List<Organization> get recentOrganizations {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    final withDate = organizations.where((o) {
      if (o.createdAt == null) return false;
      final date = DateTime.tryParse(o.createdAt!);
      return date != null && date.isAfter(cutoff);
    }).toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(2000);
        final db = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(2000);
        return db.compareTo(da);
      });

    if (withDate.isNotEmpty) return withDate;

    // Fallback — last 5 by id
    final fallback = [...organizations]
      ..sort((a, b) => b.id.compareTo(a.id)); // ✅ id is non-nullable now
    return fallback.take(5).toList();
  }

  // ─────────────────────────────────────────────────────────────────
  // DASHBOARD — Monthly evolution
  // ✅ FIXED: DateTime.tryParse works now — createdAt is ISO string
  // ─────────────────────────────────────────────────────────────────

  List<MapEntry<String, int>> get organizationsByMonth {
    final Map<String, int> monthMap = {};
    for (final org in organizations) {
      if (org.createdAt == null) continue;
      final date = DateTime.tryParse(org.createdAt!);
      if (date == null) continue;
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      monthMap[key] = (monthMap[key] ?? 0) + 1;
    }
    return monthMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  }

  // ─────────────────────────────────────────────────────────────────
  // DASHBOARD — Month label "2026-04" → "Avr 26"
  // ─────────────────────────────────────────────────────────────────

  String formatMonthLabel(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    const names = [
      '',
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    final m = (month >= 1 && month <= 12) ? names[month] : '?';
    return '$m ${year.toString().substring(2)}';
  }

  // ─────────────────────────────────────────────────────────────────
  // PRIVATE
  // ─────────────────────────────────────────────────────────────────

  String _normalizeType(String input) {
    const accents = 'àâäéèêëîïôùûüÿç';
    const noAccents = 'aaaeeeeiioouuuyc';
    var result = input.toLowerCase().trim();
    for (int i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], noAccents[i]);
    }
    return result;
  }
}
