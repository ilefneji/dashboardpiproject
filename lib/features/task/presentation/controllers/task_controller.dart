// task/presentation/controllers/task_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../../../lot/presentation/controllers/lot_controller.dart';
import '../../../lot/domain/entities/lot.dart';
class TaskController extends GetxController {
  final TaskRepository _taskRepository;
  LotController? _lotController;

  TaskController(this._taskRepository);

  // ── State ──
  final RxList<Task> tasks = <Task>[].obs;
  final RxList<Task> filteredTasks = <Task>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // ── Form controllers ──
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  // ── Lot selection (for form) ──
  // ✅ We reuse LotController — no direct ApiClient call here
  final Rx<Lot?> selectedLot = Rx<Lot?>(null);
  final RxnInt selectedLotId = RxnInt();

  // ── Getter: lots come from LotController ──
  List<Lot> get availableLots {
    try {
      return Get.find<LotController>().lots;
    } catch (_) {
      return [];
    }
  }

  // ─────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _bindLotController();
    fetchTasks();
    ever(tasks, (_) {
      if (searchController.text.isEmpty) {
        filteredTasks.assignAll(tasks);
      }
    });
  }

  void _bindLotController() {
    try {
      _lotController = Get.find<LotController>();
      ever(_lotController!.lots, (_) => _syncSelectedLotFromId());

      if (_lotController!.lots.isEmpty && !_lotController!.isLoading.value) {
        _lotController!.fetchLots();
      }
    } catch (_) {
      _lotController = null;
    }
  }

  void _syncSelectedLotFromId() {
    final lotId = selectedLotId.value;
    if (lotId == null || _lotController == null) return;

    selectedLot.value = _lotController!.lots.firstWhereOrNull(
      (lot) => lot.id == lotId,
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    searchController.dispose();
    super.onClose();
  }

  // ─────────────────────────────────────────
  // ── FETCH ──
  // ─────────────────────────────────────────
  Future<void> fetchTasks({bool silent = false}) async {
    final shouldShowLoading = !silent || tasks.isEmpty;
    if (shouldShowLoading) {
      isLoading.value = true;
    }
    errorMessage.value = '';
    try {
      final result = await _taskRepository.getTasks();
      tasks.assignAll(result);
      filteredTasks.assignAll(result);
    } catch (e) {
      errorMessage.value = 'Failed to load tasks: $e';
    } finally {
      if (shouldShowLoading) {
        isLoading.value = false;
      }
    }
  }

  void _upsertTaskLocal(Task task) {
    if (task.id == null) return;

    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index >= 0) {
      tasks[index] = task;
    } else {
      tasks.insert(0, task);
    }

    searchTasks(searchController.text);
  }

  // ─────────────────────────────────────────
  // ── CREATE ──
  // ─────────────────────────────────────────
Future<bool> createTask() async {
  if (nameController.text.trim().isEmpty) {
    errorMessage.value = 'task_name_required';
    return false;
  }

  isLoading.value = true;
  errorMessage.value = '';

  try {
    final task = Task(
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      lotId: selectedLotId.value ?? selectedLot.value?.id,
    );

    final result = await _taskRepository.createTask(task);

    if (result != null) {
      tasks.insert(0, result); // ✅ Latest on top — ever() handles filteredTasks
      clearForm();
      return true;
    }

    errorMessage.value = 'Failed to create task';
    return false;
  } catch (e) {
    errorMessage.value = 'Error creating task: $e';
    return false;
  } finally {
    isLoading.value = false;
  }
}

  // ─────────────────────────────────────────
  // ── UPDATE ──
  // ─────────────────────────────────────────
  Future<bool> updateTask(Task task) async {
    if (nameController.text.trim().isEmpty) {
      errorMessage.value = 'task_name_required';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final updated = task.copyWith(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        lotId: selectedLotId.value ?? selectedLot.value?.id,
      );

      final result = await _taskRepository.updateTask(updated);

      if (result != null) {
        _upsertTaskLocal(result);
        return true;
      }

      errorMessage.value = 'Failed to update task';
      return false;
    } catch (e) {
      errorMessage.value = 'Error updating task: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────
  // ── DELETE ──
  // ─────────────────────────────────────────
  Future<bool> deleteTask(int id) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _taskRepository.deleteTask(id);

      if (result) {
        tasks.removeWhere((t) => t.id == id);
        filteredTasks.removeWhere((t) => t.id == id);
        return true;
      }

      errorMessage.value = 'Failed to delete task';
      return false;
    } catch (e) {
      errorMessage.value = 'Error deleting task: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────
  // ── FORM HELPERS ──
  // ─────────────────────────────────────────
  void clearForm() {
    nameController.clear();
    descriptionController.clear();
    selectedLot.value = null;
    selectedLotId.value = null;
  }

  void setFormValues(Task task) {
    nameController.text = task.name;
    descriptionController.text = task.description ?? '';
    selectedLotId.value = task.lotId;
    // ✅ Pre-select lot from LotController list — no API call
    _syncSelectedLotFromId();
  }

  // ─────────────────────────────────────────
  // ── SEARCH & FILTER ──
  // ─────────────────────────────────────────
  void searchTasks(String query) {
    if (query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      filteredTasks.assignAll(tasks.where((task) {
        return task.name.toLowerCase().contains(lowercaseQuery) ||
            (task.description?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList());
      return;
    }

    filteredTasks.assignAll(tasks);
  }
}
