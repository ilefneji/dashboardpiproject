// lib/features/dashboard/presentation/controllers/dashboard_controller.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:constructiondashboard/features/organization/presentation/controllers/organization_controller.dart';
import 'package:constructiondashboard/features/users/presentation/controllers/user_controller.dart';
import 'package:constructiondashboard/features/project/presentation/controllers/project_controller.dart';
import 'package:constructiondashboard/features/lot/presentation/controllers/lot_controller.dart';

class DashboardController extends GetxController {
  static const Duration _sectionTimeout = Duration(seconds: 12);

  // ─── Dépendances ──────────────────────────────────────────────
  late final OrganizationController organizationController;
  late final UserController userController;
  late final ProjectController projectController;
  late final LotController lotController;

  // ─── Observable variables ─────────────────────────────────────
  final RxBool isLoading = false.obs; // isDashboardLoading
  final RxString error = ''.obs;
  final RxBool hasError = false.obs;

  // ─── Granular loading flags ───────────────────────────────────
  final RxBool isStatsLoading = false.obs;
  final RxBool isBudgetLoading = false.obs;
  final RxBool isLotsLoading = false.obs;
  final RxBool isActivitiesLoading = false.obs;
  final RxBool isReservationsLoading = false.obs;
  final RxBool isJournalLoading = false.obs;

  // ─────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    // 🔥 Récupère tous les controllers déjà injectés
    organizationController = Get.find<OrganizationController>();
    userController = Get.find<UserController>();
    projectController = Get.find<ProjectController>();
    lotController = Get.find<LotController>();

    // 🔥 Premier chargement
    loadDashboardData();
  }

  // ─────────────────────────────────────────────────────────────
  // METHODS
  // ─────────────────────────────────────────────────────────────

  /// 🔄 Charge toutes les données du dashboard
  Future<void> loadDashboardData() async {
    if (isLoading.value) {
      debugPrint('[Dashboard] reload skipped: already running');
      return;
    }

    Timer? safetyTimer;
    try {
      isLoading.value = true;
      hasError.value = false;
      error.value = '';
      debugPrint('[Dashboard] aggregate load started');

      // Safety net — force isLoading to false after 15s no matter what
      safetyTimer = Timer(const Duration(seconds: 15), () {
        if (isLoading.value) {
          debugPrint('[Dashboard] safety timeout — forcing loading=false');
          isLoading.value = false;
        }
      });

      // 🔥 Recharge TOUS les controllers en parallèle avec timeout global
      await Future.wait([
        _loadStats(),
        _loadBudget(),
        _loadLots(),
        _loadActivities(),
        _loadReservations(),
        _loadJournals(),
      ]).timeout(const Duration(seconds: 12));
      debugPrint('[Dashboard] aggregate load completed');
    } on TimeoutException {
      hasError.value = true;
      error.value = 'Dashboard loading timeout';
      debugPrint('[Dashboard] aggregate timeout; showing fallback values');
    } catch (e) {
      hasError.value = true;
      error.value = e.toString();
      debugPrint('[Dashboard] aggregate error: $e');
    } finally {
      safetyTimer?.cancel();
      isLoading.value = false;
      debugPrint('[Dashboard] loading=false');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SECTION LOADERS — chacun avec son propre flag + logs + finally
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadStats() async {
    debugPrint('[Dashboard][Stats] start');
    isStatsLoading.value = true;
    try {
      await organizationController
          .fetchOrganizations()
          .timeout(_sectionTimeout);
      debugPrint('[Dashboard][Stats] success');
    } on TimeoutException {
      debugPrint('[Dashboard][Stats] timeout');
    } catch (e) {
      debugPrint('[Dashboard][Stats] error: $e');
    } finally {
      isStatsLoading.value = false;
      debugPrint('[Dashboard][Stats] loading=false');
    }
  }

  Future<void> _loadBudget() async {
    debugPrint('[Dashboard][Budget] start');
    isBudgetLoading.value = true;
    try {
      await projectController.fetchProjects().timeout(_sectionTimeout);
      debugPrint('[Dashboard][Budget] success');
    } on TimeoutException {
      debugPrint('[Dashboard][Budget] timeout');
    } catch (e) {
      debugPrint('[Dashboard][Budget] error: $e');
    } finally {
      isBudgetLoading.value = false;
      debugPrint('[Dashboard][Budget] loading=false');
    }
  }

  Future<void> _loadLots() async {
    debugPrint('[Dashboard][Lots] start');
    isLotsLoading.value = true;
    try {
      await lotController.fetchLots().timeout(_sectionTimeout);
      debugPrint('[Dashboard][Lots] success');
    } on TimeoutException {
      debugPrint('[Dashboard][Lots] timeout');
    } catch (e) {
      debugPrint('[Dashboard][Lots] error: $e');
    } finally {
      isLotsLoading.value = false;
      debugPrint('[Dashboard][Lots] loading=false');
    }
  }

  Future<void> _loadActivities() async {
    debugPrint('[Dashboard][Activities] start');
    isActivitiesLoading.value = true;
    try {
      await lotController.fetchTasks().timeout(_sectionTimeout);
      debugPrint('[Dashboard][Activities] success');
    } on TimeoutException {
      debugPrint('[Dashboard][Activities] timeout');
    } catch (e) {
      debugPrint('[Dashboard][Activities] error: $e');
    } finally {
      isActivitiesLoading.value = false;
      debugPrint('[Dashboard][Activities] loading=false');
    }
  }

  Future<void> _loadReservations() async {
    debugPrint('[Dashboard][Reservations] start');
    isReservationsLoading.value = true;
    try {
      // Pas d'API globale pour le moment — on marque comme terminé
      await Future.value();
      debugPrint('[Dashboard][Reservations] success (no-op)');
    } catch (e) {
      debugPrint('[Dashboard][Reservations] error: $e');
    } finally {
      isReservationsLoading.value = false;
      debugPrint('[Dashboard][Reservations] loading=false');
    }
  }

  Future<void> _loadJournals() async {
    debugPrint('[Dashboard][Journals] start');
    isJournalLoading.value = true;
    try {
      // Pas d'API globale pour le moment — on marque comme terminé
      await Future.value();
      debugPrint('[Dashboard][Journals] success (no-op)');
    } catch (e) {
      debugPrint('[Dashboard][Journals] error: $e');
    } finally {
      isJournalLoading.value = false;
      debugPrint('[Dashboard][Journals] loading=false');
    }
  }

  /// 🔁 Refresh manuel (Pull to Refresh)
  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }
}
