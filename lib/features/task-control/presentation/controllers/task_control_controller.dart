import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';

import '../../../dashboard/presentation/controllers/app_search_controller.dart';
import '../../domain/entities/task_control.dart';
import '../../domain/entities/predefined_control_data.dart';
import '../../domain/repositories/task_control_repository.dart';
import '../../data/services/predefined_control_service.dart';
import '../../../../core/helper/helper.dart';

class TaskControlController extends GetxController {
  final TaskControlRepository _taskControlRepository;

  TaskControlController(this._taskControlRepository);

  final RxList<TaskControl> taskControls = <TaskControl>[].obs;
  final RxList<TaskControl> filteredTaskControls = <TaskControl>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString formErrorMessage = ''.obs;

  bool _isDisposed = false;

  // ─────────────────────────────────────────────
  //  Form Controllers
  // ─────────────────────────────────────────────
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController referencePathController = TextEditingController();
  final TextEditingController searchController =
      TextEditingController(); // ✅ FIX #6: Added missing searchController
  final RxInt selectedTaskId = 0.obs;

  // ─────────────────────────────────────────────
  //  Predefined Control Data (Lot / Activity / Control)
  // ─────────────────────────────────────────────
  final PredefinedControlService _predefinedService =
      PredefinedControlService();
  final RxList<ControlLot> predefinedLots = <ControlLot>[].obs;
  final RxString selectedLotId = ''.obs;
  final RxString selectedActivityId = ''.obs;
  final RxString selectedPredefinedControlId = ''.obs;
  final RxBool isPredefinedDataLoading = false.obs;

  // ─────────────────────────────────────────────
  //  File Related
  // ─────────────────────────────────────────────
  final RxBool isFileUploading = false.obs;
  final RxBool isFileViewing = false.obs;
  final RxBool isFileDownloading = false.obs;
  final RxString uploadedFileName = ''.obs;
  final RxString uploadedFilePath = ''.obs;
  final RxInt uploadedFileId = 0.obs;
  final RxString fileError = ''.obs;

  // ─────────────────────────────────────────────
  //  LIFECYCLE
  // ─────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();

    // ✅ FIX #1: Removed fetchTaskControls() from here.
    //    It is called by the screen's initState via addPostFrameCallback.
    //    Calling it here too caused DOUBLE API requests on every screen open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final searchService = Get.find<AppSearchController>();
        searchService.setContext('task-controls');
        ever(searchService.query, (String q) => searchTaskControls(q));
      } catch (e) {
        // AppSearchController not registered — safe to ignore
      }
      _loadPredefinedData();
    });

    // Reset cascading selections when parent changes
    ever(selectedLotId, (_) {
      selectedActivityId.value = '';
      selectedPredefinedControlId.value = '';
    });
    ever(selectedActivityId, (_) {
      selectedPredefinedControlId.value = '';
    });
    ever(selectedPredefinedControlId, (String controlId) {
      if (controlId.isNotEmpty) {
        _applyPredefinedControl(controlId);
      }
    });
  }

  Future<void> _loadPredefinedData() async {
    isPredefinedDataLoading.value = true;
    try {
      final data = await _predefinedService.loadData();
      predefinedLots.assignAll(data.lots);
    } catch (e) {
      debugPrint('Error loading predefined controls: $e');
    } finally {
      isPredefinedDataLoading.value = false;
    }
  }

  List<ControlActivity> get activitiesForSelectedLot {
    if (selectedLotId.value.isEmpty) return [];
    final lot = predefinedLots.firstWhereOrNull(
      (l) => l.id == selectedLotId.value,
    );
    return lot?.activites ?? [];
  }

  List<PredefinedControl> get controlsForSelectedActivity {
    if (selectedLotId.value.isEmpty || selectedActivityId.value.isEmpty)
      return [];
    final lot = predefinedLots.firstWhereOrNull(
      (l) => l.id == selectedLotId.value,
    );
    final activity = lot?.activites.firstWhereOrNull(
      (a) => a.id == selectedActivityId.value,
    );
    return activity?.controles ?? [];
  }

  void _applyPredefinedControl(String controlId) {
    final control = controlsForSelectedActivity.firstWhereOrNull(
      (c) => c.id == controlId,
    );
    if (control != null) {
      nameController.text = control.titre;
      descriptionController.text = control.description;
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    nameController.dispose();
    descriptionController.dispose();
    referencePathController.dispose();
    searchController.dispose(); // ✅ FIX #6: Dispose the new searchController
    super.onClose();
  }

  // ─────────────────────────────────────────────
  //  FETCH
  // ─────────────────────────────────────────────
  Future<void> fetchTaskControls({bool silent = false}) async {
    if (_isDisposed) return;
    final shouldShowLoading = !silent || taskControls.isEmpty;
    if (shouldShowLoading) {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      final result = await _taskControlRepository.getTaskControls();
      if (_isDisposed) return;
      taskControls.assignAll(result);
      filteredTaskControls.assignAll(result);
    } catch (e) {
      if (_isDisposed) return;
      errorMessage.value = 'Failed to load task controls: $e';
    } finally {
      if (!_isDisposed && shouldShowLoading) {
        isLoading.value = false;
      }
    }
  }

  // ─────────────────────────────────────────────
  //  SEARCH (name + description)
  // ─────────────────────────────────────────────
  void searchTaskControls(String query) {
    if (_isDisposed) return;

    if (query.isEmpty) {
      filteredTaskControls.assignAll(taskControls);
      return;
    }

    final q = query.toLowerCase();

    filteredTaskControls.assignAll(
      taskControls.where((taskControl) {
        return (taskControl.name?.toLowerCase().contains(q) ?? false) ||
            (taskControl.description?.toLowerCase().contains(q) ?? false);
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────
  //  CREATE
  // ─────────────────────────────────────────────
  Future<bool> createTaskControl() async {
    if (_isDisposed) return false;
    isLoading.value = true;
    formErrorMessage.value = '';

    if (selectedTaskId.value == 0) {
      formErrorMessage.value = 'please_select_task'.tr;
      isLoading.value = false;
      return false;
    }

    if (nameController.text.trim().isEmpty) {
      formErrorMessage.value = 'task_control_name_required'.tr;
      isLoading.value = false;
      return false;
    }

    try {
      // ✅ FIX #2 & #3: Duplicate check now scoped by taskId (matches @@unique([name, taskId]))
      //    instead of checking globally across ALL tasks.
      final duplicateName = taskControls.any(
        (control) =>
            control.taskId == selectedTaskId.value &&
            control.name?.toLowerCase() ==
                nameController.text.trim().toLowerCase(),
      );

      if (duplicateName) {
        formErrorMessage.value = 'task_control_name_duplicate'.tr;
        isLoading.value = false;
        return false;
      }

      final taskControl = TaskControl(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        referencePath: uploadedFilePath.value.isNotEmpty
            ? uploadedFilePath.value
            : null,
        taskId: selectedTaskId.value,
      );

      final result = await _taskControlRepository.createTaskControl(
        taskControl,
      );

      if (result != null) {
        taskControls.add(result);
        filteredTaskControls.add(result);
        clearForm();
        return true;
      }

      formErrorMessage.value = 'failed_to_create_task_control'.tr;
      return false;
    } catch (e) {
      if (_isDisposed) return false;

      // ✅ FIX #3: Detect server-side unique constraint violation gracefully
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('unique') ||
          errorStr.contains('duplicate') ||
          errorStr.contains('already exists')) {
        formErrorMessage.value = 'task_control_name_duplicate'.tr;
      } else {
        errorMessage.value = 'Error creating task control: $e';
      }
      return false;
    } finally {
      if (!_isDisposed) isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────
  //  UPDATE
  // ─────────────────────────────────────────────
  Future<bool> updateTaskControl(TaskControl taskControl) async {
    if (_isDisposed) return false;
    isLoading.value = true;
    formErrorMessage.value = '';

    if (nameController.text.trim().isEmpty) {
      formErrorMessage.value = 'task_control_name_required'.tr;
      isLoading.value = false;
      return false;
    }

    try {
      // ✅ FIX #2: Duplicate check scoped by taskId — same name allowed on different tasks
      final duplicateName = taskControls.any(
        (control) =>
            control.id != taskControl.id &&
            control.taskId ==
                (selectedTaskId.value != 0
                    ? selectedTaskId.value
                    : taskControl.taskId) &&
            control.name?.toLowerCase() ==
                nameController.text.trim().toLowerCase(),
      );

      if (duplicateName) {
        formErrorMessage.value = 'task_control_name_duplicate'.tr;
        isLoading.value = false;
        return false;
      }

      // ✅ FIX #4: Respect intentional file clear
      //    - New file uploaded → use new path
      //    - referencePathController cleared → user wants to remove file (null)
      //    - Neither changed → keep original path
      String? resolvedPath;
      if (uploadedFilePath.value.isNotEmpty) {
        resolvedPath = uploadedFilePath.value; // New file uploaded
      } else if (referencePathController.text.isEmpty) {
        resolvedPath = null; // User intentionally cleared it
      } else {
        resolvedPath = taskControl.referencePath; // Keep original
      }

      final updatedTaskControl = taskControl.copyWith(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        referencePath: resolvedPath,
        taskId: selectedTaskId.value != 0
            ? selectedTaskId.value
            : taskControl.taskId,
      );

      final result = await _taskControlRepository.updateTaskControl(
        updatedTaskControl,
      );

      if (result) {
        // ✅ Sync both lists
        final index = taskControls.indexWhere(
          (t) => t.id == updatedTaskControl.id,
        );
        if (index != -1) taskControls[index] = updatedTaskControl;

        final filteredIndex = filteredTaskControls.indexWhere(
          (t) => t.id == updatedTaskControl.id,
        );
        if (filteredIndex != -1) {
          filteredTaskControls[filteredIndex] = updatedTaskControl;
        }

        return true;
      }

      formErrorMessage.value = 'failed_to_update_task_control'.tr;
      return false;
    } catch (e) {
      if (_isDisposed) return false;

      // ✅ FIX #3: Detect server-side unique constraint violation gracefully
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('unique') ||
          errorStr.contains('duplicate') ||
          errorStr.contains('already exists')) {
        formErrorMessage.value = 'task_control_name_duplicate'.tr;
      } else {
        errorMessage.value = 'Error updating task control: $e';
      }
      return false;
    } finally {
      if (!_isDisposed) isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────
  //  DELETE
  // ─────────────────────────────────────────────
  Future<bool> deleteTaskControl(int id) async {
    if (_isDisposed) return false;
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _taskControlRepository.deleteTaskControl(id);

      if (result) {
        taskControls.removeWhere((t) => t.id == id);
        filteredTaskControls.removeWhere((t) => t.id == id);
        return true;
      }

      errorMessage.value = 'failed_to_delete_task_control'.tr;
      return false;
    } catch (e) {
      if (_isDisposed) return false;
      errorMessage.value = 'Error deleting task control: $e';
      return false;
    } finally {
      if (!_isDisposed) isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────
  //  FORM HELPERS
  // ─────────────────────────────────────────────
  void clearForm() {
    nameController.clear();
    descriptionController.clear();
    referencePathController.clear();
    searchController.clear();
    selectedTaskId.value = 0;
    selectedLotId.value = '';
    selectedActivityId.value = '';
    selectedPredefinedControlId.value = '';
    uploadedFileName.value = '';
    uploadedFilePath.value = '';
    uploadedFileId.value = 0;
    formErrorMessage.value = '';
    fileError.value = '';
  }

  void setFormValues(TaskControl taskControl) {
    nameController.text = taskControl.name ?? '';
    descriptionController.text = taskControl.description ?? '';
    referencePathController.text = taskControl.referencePath ?? '';
    selectedTaskId.value = taskControl.taskId ?? 0;
    uploadedFilePath.value = taskControl.referencePath ?? '';
    uploadedFileName.value =
        taskControl.referencePath != null &&
            taskControl.referencePath!.isNotEmpty
        ? taskControl.referencePath!.split('/').last
        : '';
    formErrorMessage.value = '';
    fileError.value = '';
  }

  // ─────────────────────────────────────────────
  //  FILE OPERATIONS
  // ─────────────────────────────────────────────

  // ✅ FIX #4: New method to allow user to intentionally clear an uploaded file
  void clearFile() {
    uploadedFileName.value = '';
    uploadedFilePath.value = '';
    uploadedFileId.value = 0;
    referencePathController.clear();
    fileError.value = '';
  }

  Future<void> pickAndUploadFile() async {
    try {
      errorMessage.value = '';
      fileError.value = '';

      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        uploadedFileName.value = file.name;

        if (file.bytes == null && file.path == null) {
          fileError.value = 'file_data_not_available'.tr;
          return;
        }

        isFileUploading.value = true;

        try {
          final uploadResult = await Helper.uploadFile(file);

          if (uploadResult['filePath'] != null &&
              uploadResult['filePath'].toString().isNotEmpty) {
            uploadedFilePath.value = uploadResult['filePath'];
            uploadedFileId.value = uploadResult['fileId'] ?? 0;
            referencePathController.text = uploadedFilePath.value;
            // ✅ FIX #5: Replaced print() with debugPrint()
            debugPrint('File uploaded successfully: ${uploadedFilePath.value}');
          } else {
            fileError.value = 'server_returned_empty_file_path'.tr;
          }
        } catch (uploadError) {
          fileError.value = 'upload_failed'.tr;
          // ✅ FIX #5: Replaced print() with debugPrint()
          debugPrint('Upload error: $uploadError');
        }
      }
    } catch (e) {
      fileError.value = 'file_selection_error'.tr;
      // ✅ FIX #5: Replaced print() with debugPrint()
      debugPrint('File picker error: $e');
    } finally {
      isFileUploading.value = false;
    }
  }

  bool hasFileExtension(String path) {
    if (path.isEmpty) return false;
    final parts = path.split('/');
    final filename = parts.isNotEmpty ? parts.last : '';
    if (!filename.contains('.') || filename.startsWith('.')) return false;
    final extension = filename.split('.').last.toLowerCase();
    const supportedExtensions = [
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      'txt',
      'csv',
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'zip',
      'rar',
      'odf',
      'odt',
      'ods',
      'odp',
      'odg',
    ];
    return supportedExtensions.contains(extension);
  }

  Future<void> viewFile(String filePath) async {
    if (filePath.isEmpty) {
      fileError.value = 'no_file_path_provided'.tr;
      return;
    }
    if (!hasFileExtension(filePath)) {
      fileError.value = 'invalid_file_format'.tr;
      return;
    }

    try {
      isFileViewing.value = true;
      fileError.value = '';
      final result = await Helper.viewFile(filePath);
      if (!result['success']) {
        fileError.value = result['error'] ?? 'failed_to_view_file'.tr;
      }
    } catch (e) {
      fileError.value = 'error_viewing_file'.tr;
      // ✅ FIX #5: Replaced print() with debugPrint()
      debugPrint('View file error: $e');
    } finally {
      isFileViewing.value = false;
    }
  }

  Future<void> downloadFile(String filePath) async {
    if (filePath.isEmpty) {
      fileError.value = 'no_file_path_provided'.tr;
      return;
    }
    if (!hasFileExtension(filePath)) {
      fileError.value = 'invalid_file_format'.tr;
      return;
    }

    try {
      isFileDownloading.value = true;
      fileError.value = '';
      final result = await Helper.downloadFile(filePath);
      if (!result['success']) {
        fileError.value = result['error'] ?? 'failed_to_download_file'.tr;
      }
    } catch (e) {
      fileError.value = 'error_downloading_file'.tr;
      // ✅ FIX #5: Replaced print() with debugPrint()
      debugPrint('Download file error: $e');
    } finally {
      isFileDownloading.value = false;
    }
  }
}
