import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';

import '../../domain/entities/lot.dart';
import '../../domain/repositories/lot_repository.dart';
import '../../../task/domain/entities/task.dart';
import '../../../task/domain/repositories/task_repository.dart';

class LotController extends GetxController {
  static const Duration _dashboardLoadTimeout = Duration(seconds: 12);

  final LotRepository _lotRepository;
  final TaskRepository _taskRepository;

  LotController(this._lotRepository, this._taskRepository);

  // ─────────────────────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────────────────────
  final RxList<Lot> lots = <Lot>[].obs;
  final RxList<Lot> filteredLots = <Lot>[].obs;
  final RxList<Task> tasks = <Task>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool hasError = false.obs; // ✅ ADDED
  final RxString error = ''.obs; // ✅ ADDED
  final RxString errorMessage = ''.obs; // kept for form errors
  final Rx<Lot?> selectedLot = Rxn<Lot>(); // ✅ Track selected lot

  // Task affectation
  final RxList<int> selectedTaskIds = <int>[].obs;

  // ─────────────────────────────────────────────────────────
  // INTERNAL
  // ─────────────────────────────────────────────────────────
  Timer? _autoRefreshTimer;
  bool _isFetchingLots = false;
  bool _isFetchingTasks = false;

  // ✅ Form controllers — still owned here for form dialogs only
  // ✅ searchController REMOVED — now lives in _PageHeaderState
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // ─────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    _autoRefreshTimer?.cancel();
    nameController.dispose();
    descriptionController.dispose();
    // ✅ searchController.dispose() REMOVED — no longer owned here
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────
  // AUTO REFRESH
  // ─────────────────────────────────────────────────────────
  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 500),
      (_) async => fetchLots(silent: true),
    );
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
  }

  // ─────────────────────────────────────────────────────────
  // LOT SELECTION & DASHBOARD REFRESH
  // ─────────────────────────────────────────────────────────
  Future<void> selectLotAndRefresh(Lot lot) async {
    selectedLot.value = lot;
    await fetchLots(silent: true);
    await fetchTasks();
  }

  // ─────────────────────────────────────────────────────────
  // FETCH
  // ─────────────────────────────────────────────────────────
  Future<void> fetchLots({bool silent = false}) async {
    if (_isFetchingLots) {
      debugPrint('[Dashboard][Lots] load skipped: already running');
      return;
    }
    _isFetchingLots = true;

    if (!silent) {
      isLoading.value = true;
      hasError.value = false; // ✅ reset error on fresh load
      error.value = '';
    } else {
      isRefreshing.value = true;
    }

    errorMessage.value = '';
    debugPrint('[Dashboard][Lots] load started (silent=$silent)');

    try {
      final result =
          await _lotRepository.getLots().timeout(_dashboardLoadTimeout);
      lots.assignAll(result);

      // ✅ Keep active search filter after refresh
      // Uses internal query — no searchController dependency
      searchLots(_lastQuery);
      debugPrint('[Dashboard][Lots] loaded ${result.length} item(s)');
    } on TimeoutException {
      debugPrint('[Dashboard][Lots] timeout after 12s');
      if (!silent) {
        hasError.value = true;
        error.value = 'Lot loading timeout';
      }
      errorMessage.value = 'Lot loading timeout';
    } catch (e) {
      debugPrint('[Dashboard][Lots] error: $e');
      if (!silent) {
        // ✅ Only surface error on non-silent (user-visible) fetches
        hasError.value = true;
        error.value = e.toString();
      }
      errorMessage.value = 'Failed to load lots: $e';
    } finally {
      if (!silent) {
        isLoading.value = false;
      } else {
        isRefreshing.value = false;
      }
      _isFetchingLots = false;
      debugPrint(
        '[Dashboard][Lots] loading=${isLoading.value}, '
        'refreshing=${isRefreshing.value}',
      );
    }
  }

  Future<void> fetchTasks() async {
    if (_isFetchingTasks) {
      debugPrint('[Dashboard][Tasks] load skipped: already running');
      return;
    }

    _isFetchingTasks = true;
    debugPrint('[Dashboard][Tasks] load started');
    try {
      final result =
          await _taskRepository.getTasks().timeout(_dashboardLoadTimeout);
      tasks.assignAll(result);
      debugPrint('[Dashboard][Tasks] loaded ${result.length} item(s)');
    } on TimeoutException {
      debugPrint('[Dashboard][Tasks] timeout after 12s; using empty data');
    } catch (e) {
      debugPrint('[Dashboard][Tasks] error: $e');
    } finally {
      _isFetchingTasks = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // SEARCH — no longer depends on searchController
  // ─────────────────────────────────────────────────────────

  // ✅ Internal cache of the last search query
  String _lastQuery = '';

  void searchLots(String query) {
    _lastQuery = query; // ✅ cache it for post-refresh filtering

    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      filteredLots.assignAll(
        lots.where((lot) {
          return lot.name.toLowerCase().contains(q) ||
              lot.description.toLowerCase().contains(q);
        }).toList(),
      );
      return;
    }

    filteredLots.assignAll(lots);
  }

  // ─────────────────────────────────────────────────────────
  // LOCAL UPSERT
  // ─────────────────────────────────────────────────────────
  void _upsertLocalLot(Lot lot) {
    if (lot.id == null) {
      lots.insert(0, lot);
      searchLots(_lastQuery); // ✅ use cached query
      return;
    }

    final index = lots.indexWhere((item) => item.id == lot.id);
    if (index >= 0) {
      lots[index] = lot;
    } else {
      lots.insert(0, lot);
    }

    searchLots(_lastQuery); // ✅ use cached query
  }

  // ─────────────────────────────────────────────────────────
  // CRUD
  // ─────────────────────────────────────────────────────────
  Future<bool> createLot() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final lot = Lot(
        name: nameController.text,
        description: descriptionController.text,
      );

      final result = await _lotRepository.createLot(lot);

      if (result != null) {
        clearForm();
        _upsertLocalLot(result);
        await fetchLots(silent: true);
        return true;
      }

      errorMessage.value = 'Failed to create lot';
      return false;
    } catch (e) {
      errorMessage.value = 'Error creating lot: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

Future<bool> updateLot(Lot lot) async {
  isLoading.value = true;
  errorMessage.value = '';

  try {
    final updated = lot.copyWith(
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
    );

    final result = await _lotRepository.updateLot(updated);

    if (result) {
      _upsertLocalLot(updated);
      await fetchLots(silent: true);
      clearForm(); // مهم باش add بعد update يجي فارغ
      return true;
    }

    errorMessage.value = 'Failed to update lot';
    return false;
  } catch (e) {
    errorMessage.value = 'Error updating lot: $e';
    return false;
  } finally {
    isLoading.value = false;
  }
}
  Future<bool> deleteLot(int id) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      debugPrint('🚀 DELETE /lots/$id');
      final result = await _lotRepository.deleteLot(id);

      if (result) {
        lots.removeWhere((lot) => lot.id == id);
        filteredLots.removeWhere((lot) => lot.id == id);

        Get.snackbar(
          'Succès',
          'Lot supprimé avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        return true;
      }

      errorMessage.value = 'Failed to delete lot';
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le lot',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      errorMessage.value = 'Error deleting lot: $e';
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le lot: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // TASK OPERATIONS
  // ─────────────────────────────────────────────────────────
  Future<bool> affectTask(int lotId, int taskId) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _lotRepository.affectTask(lotId, taskId);
      if (result) {
        await fetchLots(silent: true);
        return true;
      }
      errorMessage.value = 'Failed to affect task to lot';
      return false;
    } catch (e) {
      errorMessage.value = 'Error affecting task to lot: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> affectTasks(int lotId, List<int> taskIds) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      if (taskIds.isEmpty) {
        errorMessage.value = 'No tasks selected to affect';
        return false;
      }

      debugPrint('Controller: Affecting ${taskIds.length} tasks to lot $lotId');

      final result = await _lotRepository.affectTasks(lotId, taskIds);
      if (result) {
        await fetchLots(silent: true);
        return true;
      }

      errorMessage.value = 'Failed to affect tasks to lot';
      return false;
    } catch (e) {
      debugPrint('❌ affectTasks error: $e');
      errorMessage.value = 'Error affecting tasks to lot: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> removeTask(int lotId, int taskId) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      debugPrint('Controller: Removing task $taskId from lot $lotId');

      final result = await _lotRepository.removeTask(lotId, taskId);
      if (result) {
        await fetchLots(silent: true);
        return true;
      }

      errorMessage.value = 'Failed to remove task from lot';
      return false;
    } catch (e) {
      debugPrint('❌ removeTask error: $e');
      errorMessage.value = 'Error removing task from lot: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> syncTasks(
    int lotId,
    List<int> taskIds,
    List<int> originalTaskIds,
  ) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      debugPrint('Controller: Syncing tasks for lot $lotId');

      final List<int> addedTasks =
          taskIds.where((id) => !originalTaskIds.contains(id)).toList();
      final List<int> removedTasks =
          originalTaskIds.where((id) => !taskIds.contains(id)).toList();

      if (addedTasks.isEmpty && removedTasks.isEmpty) {
        debugPrint('No changes to tasks');
        return true;
      }

      bool success = true;

      if (addedTasks.isNotEmpty) {
        success = await _lotRepository.affectTasks(lotId, addedTasks);
        if (!success) {
          errorMessage.value = 'Failed to add tasks to lot';
          return false;
        }
      }

      for (final taskId in removedTasks) {
        final removed = await _lotRepository.removeTask(lotId, taskId);
        if (!removed) {
          success = false;
          errorMessage.value = 'Failed to remove some tasks from lot';
        }
      }

      await fetchLots(silent: true);
      return success;
    } catch (e) {
      debugPrint('❌ syncTasks error: $e');
      errorMessage.value = 'Error syncing tasks: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // FORM HELPERS
  // ─────────────────────────────────────────────────────────
  void clearForm() {
    nameController.clear();
    descriptionController.clear();
    selectedTaskIds.clear();
  }

  void setFormValues(Lot lot) {
    nameController.text = lot.name;
    descriptionController.text = lot.description;
    selectedTaskIds.assignAll(lot.taskIds);
  }
}
