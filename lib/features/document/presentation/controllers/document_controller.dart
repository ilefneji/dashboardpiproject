import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/project/data/models/project_model.dart';
import '../../../../features/project/domain/repositories/project_repository.dart';
import '../../data/models/document_model.dart';
import '../../data/models/file_model.dart';
import '../../data/models/folder_model.dart';
import '../../data/repositories/document_repository.dart';

class DocumentController extends GetxController {
  final DocumentRepository _repository;

  DocumentController(this._repository);

  final RxBool isLoading = false.obs;
  final RxBool isLoadingProjects = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<ProjectModel> allProjects = <ProjectModel>[].obs;
  final Rx<ProjectModel?> selectedProject = Rx<ProjectModel?>(null);

  final RxList<DocumentModel> documents = <DocumentModel>[].obs;
  final RxList<FileModel> flatFiles = <FileModel>[].obs;
  final RxList<FolderModel> breadcrumbs = <FolderModel>[].obs;

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
    breadcrumbs.clear();
    loadDocuments();
  }

  void clearSelectedProject() {
    if (_isDisposed) return;
    selectedProject.value = null;
    documents.clear();
    flatFiles.clear();
    breadcrumbs.clear();
  }

  Future<void> loadDocuments() async {
    if (_isDisposed) return;

    final project = selectedProject.value;
    if (project == null) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final tree = await _repository.fetchTreeByProjectId(project.id);

      if (_isDisposed) return;

      documents.assignAll(tree);
      _rebuildFlatFiles();
    } catch (e) {
      if (_isDisposed) return;
      errorMessage.value = 'Impossible de charger les documents : $e';
      _showError('Erreur', errorMessage.value);
    } finally {
      if (!_isDisposed) isLoading.value = false;
    }
  }

  void openFolder(FolderModel folder) {
    breadcrumbs.add(folder);
    _rebuildFlatFiles();
  }

  void goBack() {
    if (breadcrumbs.isNotEmpty) {
      breadcrumbs.removeLast();
      _rebuildFlatFiles();
    }
  }

  void goToRoot() {
    breadcrumbs.clear();
    _rebuildFlatFiles();
  }

  void navigateToBreadcrumb(int index) {
    if (index < 0 || index >= breadcrumbs.length) return;
    while (breadcrumbs.length > index + 1) {
      breadcrumbs.removeLast();
    }
    _rebuildFlatFiles();
  }

  void _rebuildFlatFiles() {
    final current = _currentFolder;
    if (current == null) {
      // Root level: merge files and subfolders of all root documents.
      final files = <FileModel>[];
      final folders = <FolderModel>[];
      for (final doc in documents) {
        files.addAll(doc.files);
        folders.addAll(doc.subfolders);
      }
      flatFiles.assignAll(_filterFiles(files));
    } else {
      flatFiles.assignAll(_filterFiles(current.files ?? []));
    }
  }

  FolderModel? get _currentFolder {
    if (breadcrumbs.isEmpty) return null;
    return breadcrumbs.last;
  }

  List<FileModel> _filterFiles(List<FileModel> files) {
    final query = _searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return files;
    return files
        .where((f) => f.displayName.toLowerCase().contains(query))
        .toList();
  }

  List<FolderModel> get currentFolders {
    final current = _currentFolder;
    final folders = current == null
        ? documents.expand((d) => d.subfolders).toList()
        : (current.subfolders ?? []);

    final query = _searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return folders;
    return folders
        .where((f) => (f.name ?? '').toLowerCase().contains(query))
        .toList();
  }

  void searchDocuments(String query) {
    _searchQuery.value = query;
    _rebuildFlatFiles();
  }

  Future<void> deleteFile(FileModel file) async {
    if (_isDisposed || file.id == null) return;

    try {
      await _repository.deleteFile(file.id!);
      await loadDocuments();
      _showSuccess('Succès', 'Fichier supprimé');
    } catch (e) {
      _showError('Erreur', 'Impossible de supprimer le fichier : $e');
    }
  }

  Future<void> deleteFolder(FolderModel folder) async {
    if (_isDisposed || folder.id == null) return;

    try {
      await _repository.deleteFolder(folder.id!);
      await loadDocuments();
      _showSuccess('Succès', 'Dossier supprimé');
    } catch (e) {
      _showError('Erreur', 'Impossible de supprimer le dossier : $e');
    }
  }

  Future<void> renameFile(FileModel file, String newName) async {
    if (_isDisposed || file.id == null) return;

    try {
      await _repository.updateFile(file.id!, newName);
      await loadDocuments();
      _showSuccess('Succès', 'Fichier renommé');
    } catch (e) {
      _showError('Erreur', 'Impossible de renommer le fichier : $e');
    }
  }

  Future<void> renameFolder(FolderModel folder, String newName) async {
    if (_isDisposed || folder.id == null) return;

    try {
      await _repository.updateFolder(folder.id!, newName);
      await loadDocuments();
      _showSuccess('Succès', 'Dossier renommé');
    } catch (e) {
      _showError('Erreur', 'Impossible de renommer le dossier : $e');
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
