import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/project_model.dart';
import '../../data/models/subscription_code_model.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../domain/repositories/project_repository.dart';

class ProjectController extends GetxController {
  static const Duration _dashboardLoadTimeout = Duration(seconds: 12);
  static const String _deleteLinkedProjectMessage =
      'Impossible de supprimer ce projet car il contient déjà des activités ou des données liées.';

  final ProjectRepository _projectRepository;

  // ─── Observable variables ───────────────────────────────────────
  final RxList<ProjectModel> projects = <ProjectModel>[].obs;
  final RxList<ProjectModel> filteredProjects = <ProjectModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool hasError = false.obs;
  final TextEditingController searchController = TextEditingController();

  // ─── Year Filter State ──────────────────────────────────────────
  final RxInt selectedYear = 0.obs;
  final RxList<int> availableYears = <int>[].obs;
  final RxBool isFiltered = false.obs;

  // ─── Subscription code ──────────────────────────────────────────
  final RxBool isGeneratingCode = false.obs;
  final Rx<SubscriptionCodeModel?> generatedCode =
      Rx<SubscriptionCodeModel?>(null);

  bool _isDisposed = false;

  ProjectController({ProjectRepository? projectRepository})
      : _projectRepository = projectRepository ??
            ProjectRepositoryImpl(apiClient: Get.find<ApiClient>());

  // ─────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    _isDisposed = true;
    searchController.dispose();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────────
  // GET ALL PROJECTS
  // ─────────────────────────────────────────────────────────────────

  Future<void> getAllProjects() async {
    if (isLoading.value) {
      debugPrint('[Dashboard][Projects] load skipped: already running');
      return;
    }

    isLoading.value = true;
    hasError.value = false;
    error.value = '';
    debugPrint('[Dashboard][Projects] load started');

    try {
      final result = await _projectRepository
          .getAllProjects()
          .timeout(_dashboardLoadTimeout);
      projects.assignAll(result);
      _generateAvailableYears();
      applyFilters();
      debugPrint('[Dashboard][Projects] loaded ${result.length} item(s)');
    } on TimeoutException {
      hasError.value = true;
      error.value = 'Project loading timeout';
      debugPrint('[Dashboard][Projects] timeout after 12s');
    } catch (e) {
      hasError.value = true;
      error.value = e.toString();
      debugPrint('[Dashboard][Projects] error: $e');
    } finally {
      isLoading.value = false;
      debugPrint('[Dashboard][Projects] loading=false');
    }
  }

  Future<void> getAllProjectsNoFilter() async {
    if (isLoading.value) {
      debugPrint('[Dashboard][ProjectsNoFilter] load skipped: already running');
      return;
    }

    isLoading.value = true;
    hasError.value = false;
    error.value = '';
    debugPrint('[Dashboard][ProjectsNoFilter] load started');

    try {
      final result = await _projectRepository
          .getAllProjectsNoFilter()
          .timeout(_dashboardLoadTimeout);
      projects.assignAll(result);
      _generateAvailableYears();
      applyFilters();
      debugPrint(
          '[Dashboard][ProjectsNoFilter] loaded ${result.length} item(s)');
    } on TimeoutException {
      hasError.value = true;
      error.value = 'Project loading timeout';
      debugPrint('[Dashboard][ProjectsNoFilter] timeout after 12s');
    } catch (e) {
      hasError.value = true;
      error.value = e.toString();
      debugPrint('[Dashboard][ProjectsNoFilter] error: $e');
    } finally {
      isLoading.value = false;
      debugPrint('[Dashboard][ProjectsNoFilter] loading=false');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // SEARCH
  // ─────────────────────────────────────────────────────────────────

  void searchProjects(String query) {
    final trimmedQuery = query.trim().toLowerCase();

    if (trimmedQuery.isNotEmpty) {
      filteredProjects.assignAll(
        projects.where((project) {
          final name = project.name.toLowerCase();
          final description = project.description.toLowerCase();
          return name.contains(trimmedQuery) ||
              description.contains(trimmedQuery);
        }).toList(),
      );
      return;
    }

    applyFilters();
  }

  // ─────────────────────────────────────────────────────────────────
  // CREATE PROJECT
  // ─────────────────────────────────────────────────────────────────

  Future<bool> createProject({
    required String name,
    required String description,
    required String startDate,
    required String endDate,
    required int budget,
    required String localisation,
    String? latitude,
    String? longitude,
    List<int> lotIds = const [],
  }) async {
    if (isLoading.value) return false;

    isLoading.value = true;
    hasError.value = false;
    error.value = '';

    try {
      final normalizedStartDate = _normalizeDate(startDate);
      final normalizedEndDate = _normalizeDate(endDate);

      if (normalizedStartDate.isEmpty) {
        throw Exception('startDate must be in YYYY-MM-DD format');
      }

      final success = await _projectRepository.createProject(
        name: name,
        description: description,
        startDate: normalizedStartDate,
        endDate: normalizedEndDate,
        budget: budget,
        localisation: localisation,
        latitude: latitude,
        longitude: longitude,
        lotIds: lotIds,
        organizationId: _currentOrganizationId,
      );

      if (success) {
        await getAllProjects();
        Get.snackbar(
          'Succès',
          'Projet créé avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      }

      return success;
    } catch (e) {
      hasError.value = true;
      error.value = e.toString();
      debugPrint('❌ createProject error: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de créer le projet: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // UPDATE PROJECT
  // ─────────────────────────────────────────────────────────────────

  Future<bool> updateProject(
    int projectId, {
    required String name,
    required String description,
    required String startDate,
    required String endDate,
    required int budget,
    required String localisation,
    String? latitude,
    String? longitude,
    List<int> lotIds = const [], // ✅ FIX: default value so it's never missing
  }) async {
    if (isLoading.value) return false;

    isLoading.value = true;
    hasError.value = false;
    error.value = '';

    try {
      final normalizedStartDate = _normalizeDate(startDate);
      final normalizedEndDate = _normalizeDate(endDate);

      if (normalizedStartDate.isEmpty) {
        throw Exception('startDate must be in YYYY-MM-DD format');
      }

      // ✅ FIX: use _projectRepository instead of raw apiClient
      final success = await _projectRepository.updateProject(
        projectId,
        name: name,
        description: description,
        startDate: normalizedStartDate,
        endDate: normalizedEndDate,
        budget: budget,
        localisation: localisation,
        latitude: latitude,
        longitude: longitude,
        lotIds: lotIds, // ✅ FIX: now actually passed
      );

      if (success) {
        await getAllProjects();
        Get.snackbar(
          'Succès',
          'Projet modifié avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      }

      return success;
    } catch (e) {
      hasError.value = true;
      error.value = e.toString();
      debugPrint('❌ updateProject error: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de modifier le projet: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // DELETE PROJECT
  // ─────────────────────────────────────────────────────────────────

  Future<bool> deleteProject(int projectId) async {
    if (isLoading.value) return false;

    isLoading.value = true;
    hasError.value = false;
    error.value = '';

    try {
      final apiClient = Get.find<ApiClient>();
      debugPrint('🚀 DELETE /projects/$projectId');

      final response = await apiClient.delete('/projects/$projectId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        projects.removeWhere((p) => p.id == projectId);
        filteredProjects.removeWhere((p) => p.id == projectId);
        debugPrint('✅ Projet $projectId supprimé localement');
        Get.snackbar(
          'Succès',
          'Projet supprimé avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        return true;
      } else {
        final responseData = response.data;
        final message = (responseData is Map && responseData['message'] != null)
            ? responseData['message'].toString()
            : responseData?.toString() ?? 'Erreur: ${response.statusCode}';
        throw Exception(message);
      }
    } catch (e) {
      hasError.value = true;
      error.value = _deleteLinkedProjectMessage;
      debugPrint('❌ deleteProject error: $e');
      Get.snackbar(
        'Erreur',
        _deleteLinkedProjectMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // ARCHIVE PROJECT
  // ─────────────────────────────────────────────────────────────────

  Future<bool> archiveProject(int projectId) async {
    try {
      final apiClient = Get.find<ApiClient>();
      debugPrint('PATCH /projects/archiveProject/$projectId');

      final response =
          await apiClient.patch('/projects/archiveProject/$projectId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _markProjectArchived(projectId);
        debugPrint('Projet $projectId archive localement');
        Get.snackbar(
          'Succes',
          'Projet archive avec succes',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        return true;
      }

      final responseData = response.data;
      final message = (responseData is Map && responseData['message'] != null)
          ? responseData['message'].toString()
          : responseData?.toString() ?? 'Erreur: ${response.statusCode}';
      throw Exception(message);
    } catch (e) {
      debugPrint('archiveProject error: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d archiver le projet',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return false;
    }
  }

  void _markProjectArchived(int projectId) {
    final projectIndex =
        projects.indexWhere((project) => project.id == projectId);
    if (projectIndex != -1) {
      projects[projectIndex] = projects[projectIndex].copyWith(
        isActive: false,
      );
    }

    final filteredIndex =
        filteredProjects.indexWhere((project) => project.id == projectId);
    if (filteredIndex != -1) {
      filteredProjects[filteredIndex] =
          filteredProjects[filteredIndex].copyWith(isActive: false);
    }
  }

  // GENERATE SUBSCRIPTION CODE

  Future<SubscriptionCodeModel?> generateSubscriptionCode({
    required int projectId,
    required int numberOfMembers,
  }) async {
    if (isGeneratingCode.value) return null;

    isGeneratingCode.value = true;
    hasError.value = false;
    error.value = '';

    try {
      final result = await _projectRepository.generateSubscriptionCode(
        projectId: projectId,
        numberOfMembers: numberOfMembers,
      );
      generatedCode.value = result;
      debugPrint('✅ Subscription code généré pour projet $projectId');
      return result;
    } catch (e) {
      hasError.value = true;
      error.value = e.toString();
      debugPrint('❌ generateSubscriptionCode error: $e');
      return null;
    } finally {
      isGeneratingCode.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // YEAR FILTER
  // ─────────────────────────────────────────────────────────────────

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  void _generateAvailableYears() {
    final years = <int>{};
    for (final p in projects) {
      final start = _parseDate(p.startDate);
      final end = _parseDate(p.endDate);
      if (start != null) years.add(start.year);
      if (end != null) years.add(end.year);
    }
    availableYears.assignAll(
      years.toList()..sort((a, b) => b.compareTo(a)),
    );
  }

  void filterByYear(int year) {
    selectedYear.value = year;
    applyFilters();
  }

  void clearYearFilter() {
    selectedYear.value = 0;
    applyFilters();
  }

  void applyFilters() {
    if (selectedYear.value == 0) {
      filteredProjects.assignAll(projects);
      isFiltered.value = false;
      return;
    }

    filteredProjects.assignAll(
      projects.where((p) {
        final start = _parseDate(p.startDate);
        final end = _parseDate(p.endDate);
        if (start == null || end == null) return false;
        return start.year <= selectedYear.value &&
            end.year >= selectedYear.value;
      }).toList(),
    );

    isFiltered.value = true;
  }

  // ─────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────

  Future<void> fetchProjects() => getAllProjects();
  RxString get errorMessage => error;

  String _normalizeDate(String value) {
    final v = value.trim();
    if (v.isEmpty) return '';

    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (regex.hasMatch(v)) return v;

    final parsed = DateTime.tryParse(v);
    if (parsed == null) return '';

    return DateFormat('yyyy-MM-dd').format(parsed);
  }

  int? get _currentOrganizationId {
    if (!Get.isRegistered<AuthController>()) return null;
    return Get.find<AuthController>().currentUser.value?.organizationId;
  }

  Future<ProjectModel?> getProject(int id) async {
    try {
      final project = await _projectRepository.getProject(id);
      return project;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getProject error: $e');
      return null;
    }
  }
}
