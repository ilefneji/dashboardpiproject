import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/project/data/models/project_model.dart';
import '../../../../features/project/domain/repositories/project_repository.dart';
import '../../data/models/reference_plan_model.dart';
import '../../data/repositories/reference_plan_repository.dart';

class ReferencePlanController extends GetxController {
  final ReferencePlanRepository _repository;

  ReferencePlanController(this._repository);

  final RxBool isLoading = false.obs;
  final RxBool isLoadingProjects = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<ProjectModel> allProjects = <ProjectModel>[].obs;
  final Rx<ProjectModel?> selectedProject = Rx<ProjectModel?>(null);

  final RxList<ReferencePlanModel> referencePlans = <ReferencePlanModel>[].obs;

  final TextEditingController searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;

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
    loadReferencePlans();
  }

  void clearSelectedProject() {
    if (_isDisposed) return;
    selectedProject.value = null;
    referencePlans.clear();
  }

  Future<void> loadReferencePlans() async {
    if (_isDisposed) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final plans = await _repository.fetchReferencePlans();

      if (_isDisposed) return;

      referencePlans.assignAll(plans);
    } catch (e) {
      if (_isDisposed) return;
      errorMessage.value = 'Impossible de charger les plans de référence : $e';
      _showError('Erreur', errorMessage.value);
    } finally {
      if (!_isDisposed) isLoading.value = false;
    }
  }

  List<ReferencePlanModel> get filteredPlans {
    final query = _searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return referencePlans;

    return referencePlans.where((plan) {
      final name = (plan.name ?? '').toLowerCase();
      final description = (plan.description ?? '').toLowerCase();
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  void searchReferencePlans(String query) {
    _searchQuery.value = query;
  }

  void viewReferencePlan(ReferencePlanModel plan) {
    final path = plan.referencePath;
    if (path == null || path.isEmpty) {
      _showError('Erreur', 'Aucun document PDF associé à ce plan.');
      return;
    }

    final url = _buildUrl(path);

    // Sur le dashboard web, ouvrir le PDF dans un nouvel onglet.
    // Options possibles :
    //   - import 'dart:html' as html; html.window.open(url, '_blank');
    //   - utiliser le package url_launcher : await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
    debugPrint('Ouvrir le plan de référence : $url');
  }

  String _buildUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final base = ApiClient.baseUrl;
    final separator = path.startsWith('/') ? '' : '/';
    return '$base$separator$path';
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
}
