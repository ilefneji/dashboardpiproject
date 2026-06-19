import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../features/project/data/models/project_model.dart';
import '../../../../features/project/domain/repositories/project_repository.dart';
import '../../data/models/control_report_model.dart';
import '../../data/models/process_verbal_model.dart';
import '../../data/repositories/report_repository.dart';

class ReportController extends GetxController {
  final ReportRepository _repository;

  ReportController(this._repository);

  final RxBool isLoading = false.obs;
  final RxBool isLoadingProjects = false.obs;
  final RxBool isApproving = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<ProjectModel> allProjects = <ProjectModel>[].obs;
  final Rx<ProjectModel?> selectedProject = Rx<ProjectModel?>(null);

  final RxInt tabIndex = 0.obs;

  final RxList<ControlReportModel> controlReports = <ControlReportModel>[].obs;
  final RxList<ProcessVerbalModel> processVerbals = <ProcessVerbalModel>[].obs;

  final TextEditingController searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;

  bool _isDisposed = false;

  int? get _currentUserId => Get.find<AuthController>().currentUser.value?.id;

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
    controlReports.clear();
    processVerbals.clear();
    _searchQuery.value = '';
    searchController.clear();
    refreshCurrentTab();
  }

  void clearSelectedProject() {
    if (_isDisposed) return;

    selectedProject.value = null;
    controlReports.clear();
    processVerbals.clear();
    errorMessage.value = '';
    _searchQuery.value = '';
    searchController.clear();
  }

  void setTabIndex(int index) {
    if (_isDisposed || tabIndex.value == index) return;
    tabIndex.value = index;
    _searchQuery.value = '';
    searchController.clear();
    refreshCurrentTab();
  }

  Future<void> refreshCurrentTab() async {
    if (tabIndex.value == 0) {
      await loadControlReports();
    } else {
      await loadProcessVerbals();
    }
  }

  Future<void> loadControlReports() async {
    if (_isDisposed) return;

    final project = selectedProject.value;
    if (project == null) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final reports = await _repository.fetchControlReportsByProject(project.id);

      if (_isDisposed) return;

      controlReports.assignAll(reports);
    } catch (e) {
      if (_isDisposed) return;
      errorMessage.value = 'Impossible de charger les rapports de contrôle : $e';
      _showError('Erreur', errorMessage.value);
    } finally {
      if (!_isDisposed) isLoading.value = false;
    }
  }

  Future<void> loadProcessVerbals() async {
    if (_isDisposed) return;

    final project = selectedProject.value;
    if (project == null) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final pvs = await _repository.fetchProcessVerbalsByProject(project.id);

      if (_isDisposed) return;

      processVerbals.assignAll(pvs);
    } catch (e) {
      if (_isDisposed) return;
      errorMessage.value = 'Impossible de charger les procès-verbaux : $e';
      _showError('Erreur', errorMessage.value);
    } finally {
      if (!_isDisposed) isLoading.value = false;
    }
  }

  void search(String query) {
    _searchQuery.value = query.trim().toLowerCase();
  }

  List<ControlReportModel> get filteredControlReports {
    final query = _searchQuery.value;
    if (query.isEmpty) return controlReports;

    return controlReports.where((report) {
      return (report.nom?.toLowerCase().contains(query) ?? false) ||
          (report.comment?.toLowerCase().contains(query) ?? false) ||
          (report.zone?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<ProcessVerbalModel> get filteredProcessVerbals {
    final query = _searchQuery.value;
    if (query.isEmpty) return processVerbals;

    return processVerbals.where((pv) {
      return (pv.nom?.toLowerCase().contains(query) ?? false) ||
          (pv.zone?.toLowerCase().contains(query) ?? false) ||
          (pv.comments?.any((c) =>
                  c.content?.toLowerCase().contains(query) ?? false) ??
              false);
    }).toList();
  }

  String getControlReportPrintUrl(int id) {
    return _repository.getControlReportPrintUrl(id);
  }

  String getProcessVerbalPrintUrl(int id) {
    return _repository.getProcessVerbalPrintUrl(id);
  }

  Future<void> approveProcessVerbal(ProcessVerbalModel pv) async {
    if (_isDisposed || pv.id == null || isApproving.value) return;

    final userId = _currentUserId;
    if (userId == null) {
      _showError('Erreur', 'Utilisateur non authentifié.');
      return;
    }

    isApproving.value = true;

    try {
      await _repository.approveProcessVerbal(userId: userId, pvId: pv.id!);

      if (_isDisposed) return;

      await loadProcessVerbals();
      _showSuccess('Succès', 'Procès-verbal approuvé.');
    } catch (e) {
      if (_isDisposed) return;
      _showError('Erreur', 'Impossible d\'approuver le procès-verbal : $e');
    } finally {
      if (!_isDisposed) isApproving.value = false;
    }
  }

  bool canApproveProcessVerbal(ProcessVerbalModel pv) {
    if (pv.id == null || _currentUserId == null) return false;

    return pv.userStatut.every((status) {
      final userId = status['userId'];
      final approved = status['approved'];
      return userId != _currentUserId || approved != true;
    });
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
