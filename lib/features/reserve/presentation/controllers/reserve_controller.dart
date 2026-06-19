import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/project/data/models/project_model.dart';
import '../../../../features/project/domain/repositories/project_repository.dart';
import '../../data/models/reserve_model.dart';
import '../../data/repositories/reserve_repository.dart';

class ReserveController extends GetxController {
  final ReserveRepository _repository;

  ReserveController(this._repository);

  final RxBool isLoading = false.obs;
  final RxBool isLoadingProjects = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<ProjectModel> allProjects = <ProjectModel>[].obs;
  final Rx<ProjectModel?> selectedProject = Rx<ProjectModel?>(null);

  final RxList<ReserveModel> reserves = <ReserveModel>[].obs;

  final TextEditingController searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;

  final List<String> statusOptions = const [
    'En cours',
    'À corriger',
    'Corrigée',
    'Rejetée',
    'Suspendue',
  ];

  bool _isDisposed = false;

  @override
  void onInit() {
    super.onInit();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;
      _loadProjects();
    });
  }

  @override
  void onClose() {
    _isDisposed = true;
    searchController.dispose();
    super.onClose();
  }

  List<ReserveModel> get filteredReserves {
    final query = _searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return reserves.toList();

    return reserves.where((reserve) {
      final searchables = [
        reserve.nom,
        reserve.declaration,
        reserve.status,
        reserve.priority,
        reserve.localisation,
        reserve.aiDefectLabel,
      ].map((e) => e?.toLowerCase() ?? '').toList();

      return searchables.any((text) => text.contains(query));
    }).toList();
  }

  Future<void> _loadProjects() async {
    if (_isDisposed) return;

    isLoadingProjects.value = true;
    errorMessage.value = '';

    try {
      final projectRepo = Get.find<ProjectRepository>();
      final projects = await projectRepo.getAllProjects();

      if (_isDisposed) return;

      allProjects.assignAll(projects);

      if (projects.length == 1) {
        selectProject(projects.first);
      }
    } catch (e) {
      if (_isDisposed) return;
      errorMessage.value = 'Impossible de charger les projets : $e';
    } finally {
      if (!_isDisposed) isLoadingProjects.value = false;
    }
  }

  void selectProject(ProjectModel project) {
    if (_isDisposed) return;
    selectedProject.value = project;
    errorMessage.value = '';
    loadReserves();
  }

  void clearSelectedProject() {
    if (_isDisposed) return;
    selectedProject.value = null;
    reserves.clear();
  }

  Future<void> loadReserves() async {
    if (_isDisposed) return;

    final project = selectedProject.value;
    if (project == null) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final items = await _repository.fetchByProjectId(project.id);

      if (_isDisposed) return;

      reserves.assignAll(items);
    } catch (e) {
      if (_isDisposed) return;
      errorMessage.value = 'Impossible de charger les réserves : $e';
      _showError('Erreur', errorMessage.value);
    } finally {
      if (!_isDisposed) isLoading.value = false;
    }
  }

  void searchReserves(String query) {
    _searchQuery.value = query;
  }

  Future<void> changeStatus(ReserveModel reserve, String newStatus) async {
    if (_isDisposed || reserve.id == null) return;
    if (newStatus == reserve.status) return;

    try {
      isLoading.value = true;
      await _repository.updateStatus(reserve.id!, newStatus);

      if (_isDisposed) return;

      final index = reserves.indexWhere((r) => r.id == reserve.id);
      if (index != -1) {
        reserves[index] = reserves[index].copyWith(status: newStatus);
      }

      _showSuccess('Succès', 'Statut mis à jour : $newStatus');
    } catch (e) {
      _showError('Erreur', 'Impossible de mettre à jour le statut : $e');
    } finally {
      if (!_isDisposed) isLoading.value = false;
    }
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.error,
      colorText: Colors.white,
    );
  }

  void _showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
    );
  }
}
