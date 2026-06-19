import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/project/data/models/project_model.dart';
import '../../../../features/project/domain/repositories/project_repository.dart';
import '../../data/models/gallery_model.dart';
import '../../data/repositories/gallery_repository.dart';

class GalleryController extends GetxController {
  final GalleryRepository _repository;

  GalleryController(this._repository);

  final RxBool isLoading = false.obs;
  final RxBool isLoadingProjects = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<ProjectModel> allProjects = <ProjectModel>[].obs;
  final Rx<ProjectModel?> selectedProject = Rx<ProjectModel?>(null);

  final RxList<GalleryModel> allGalleries = <GalleryModel>[].obs;
  final RxList<GalleryModel> filteredGalleries = <GalleryModel>[].obs;

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
    loadGalleries();
  }

  void clearSelectedProject() {
    if (_isDisposed) return;
    selectedProject.value = null;
    allGalleries.clear();
    filteredGalleries.clear();
  }

  Future<void> loadGalleries() async {
    if (_isDisposed) return;

    final project = selectedProject.value;
    if (project == null) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final items = await _repository.fetchByProjectId(project.id);

      if (_isDisposed) return;

      allGalleries.assignAll(items);
      _applySearch();
    } catch (e) {
      if (_isDisposed) return;
      errorMessage.value = 'Impossible de charger les galeries : $e';
      _showError('Erreur', errorMessage.value);
    } finally {
      if (!_isDisposed) isLoading.value = false;
    }
  }

  void searchGalleries(String query) {
    _searchQuery.value = query;
    _applySearch();
  }

  void _applySearch() {
    final query = _searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      filteredGalleries.assignAll(allGalleries);
      return;
    }

    filteredGalleries.assignAll(
      allGalleries.where((g) {
        final nameMatch = (g.name ?? '').toLowerCase().contains(query);
        final reserveMatch =
            (g.reserve?.nom ?? '').toLowerCase().contains(query);
        final authorMatch =
            '${g.reserve?.user?.firstname ?? ''} ${g.reserve?.user?.lastname ?? ''}'
                .toLowerCase()
                .contains(query);
        return nameMatch || reserveMatch || authorMatch;
      }).toList(),
    );
  }

  void viewImage(GalleryModel gallery) {
    if (_isDisposed) return;

    final path = gallery.path;
    if (path == null || path.isEmpty) {
      _showError('Erreur', 'Aucune image à afficher');
      return;
    }

    final imageUrl = 'https://pipropmsapi.onrender.com/$path';

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.black87,
                padding: const EdgeInsets.all(32),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image_outlined, color: Colors.white, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Impossible de charger l\'image',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
