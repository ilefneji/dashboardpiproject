// lib/features/dashboard/presentation/controllers/dashboard_controller.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:constructiondashboard/features/organization/presentation/controllers/organization_controller.dart';
import 'package:constructiondashboard/features/users/presentation/controllers/user_controller.dart';
import 'package:constructiondashboard/features/project/presentation/controllers/project_controller.dart';
import 'package:constructiondashboard/features/lot/presentation/controllers/lot_controller.dart';

import 'package:constructiondashboard/features/reserve/data/models/reserve_model.dart';
import 'package:constructiondashboard/features/reserve/data/repositories/reserve_repository.dart';

import 'package:constructiondashboard/features/journal/data/journal_repository.dart';
import 'package:constructiondashboard/features/journal/domain/entities/journal_chantier.dart';

class DashboardController extends GetxController {
  static const Duration _sectionTimeout = Duration(seconds: 12);

  late final OrganizationController organizationController;
  late final UserController userController;
  late final ProjectController projectController;
  late final LotController lotController;

  late final ReserveRepository reserveRepository;
  late final JournalRepository journalRepository;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool hasError = false.obs;

  final RxBool isStatsLoading = false.obs;
  final RxBool isBudgetLoading = false.obs;
  final RxBool isLotsLoading = false.obs;
  final RxBool isActivitiesLoading = false.obs;
  final RxBool isReservationsLoading = false.obs;
  final RxBool isJournalLoading = false.obs;

  final RxList<ReserveModel> reserves = <ReserveModel>[].obs;
  final RxList<JournalChantier> journals = <JournalChantier>[].obs;

  @override
  void onInit() {
    super.onInit();

    organizationController = Get.find<OrganizationController>();
    userController = Get.find<UserController>();
    projectController = Get.find<ProjectController>();
    lotController = Get.find<LotController>();

    reserveRepository = Get.find<ReserveRepository>();
    journalRepository = Get.find<JournalRepository>();

    loadDashboardData();
  }

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

      safetyTimer = Timer(const Duration(seconds: 15), () {
        if (isLoading.value) {
          debugPrint('[Dashboard] safety timeout — forcing loading=false');
          isLoading.value = false;
        }
      });

      await _loadBudget();
      await Future.wait([
        _loadStats(),
        _loadLots(),
        _loadActivities(),
        _loadReservations(),
        _loadJournals(),
      ]).timeout(const Duration(seconds: 12));

      debugPrint('[Dashboard] aggregate load completed');
    } on TimeoutException {
      hasError.value = true;
      error.value = 'Dashboard loading timeout';
      debugPrint('[Dashboard] aggregate timeout');
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

  Future<void> _loadStats() async {
    debugPrint('[Dashboard][Stats] start');
    isStatsLoading.value = true;

    try {
      await organizationController.fetchOrganizations().timeout(_sectionTimeout);
      debugPrint('[Dashboard][Stats] success');
    } catch (e) {
      debugPrint('[Dashboard][Stats] error: $e');
    } finally {
      isStatsLoading.value = false;
    }
  }

  Future<void> _loadBudget() async {
    debugPrint('[Dashboard][Budget] start');
    isBudgetLoading.value = true;

    try {
      await projectController.fetchProjects().timeout(_sectionTimeout);
      debugPrint('[Dashboard][Budget] success');
    } catch (e) {
      debugPrint('[Dashboard][Budget] error: $e');
    } finally {
      isBudgetLoading.value = false;
    }
  }

  Future<void> _loadLots() async {
    debugPrint('[Dashboard][Lots] start');
    isLotsLoading.value = true;

    try {
      await lotController.fetchLots().timeout(_sectionTimeout);
      debugPrint('[Dashboard][Lots] success');
    } catch (e) {
      debugPrint('[Dashboard][Lots] error: $e');
    } finally {
      isLotsLoading.value = false;
    }
  }

  Future<void> _loadActivities() async {
    debugPrint('[Dashboard][Activities] start');
    isActivitiesLoading.value = true;

    try {
      await lotController.fetchTasks().timeout(_sectionTimeout);
      debugPrint('[Dashboard][Activities] success');
    } catch (e) {
      debugPrint('[Dashboard][Activities] error: $e');
    } finally {
      isActivitiesLoading.value = false;
    }
  }

  Future<void> _loadReservations() async {
    debugPrint('[Dashboard][Reservations] start');
    isReservationsLoading.value = true;

    try {
      final projects = projectController.projects.toList();

      if (projects.isEmpty) {
        reserves.clear();
        debugPrint('[Dashboard][Reservations] no projects');
        return;
      }

      final result = await Future.wait(
        projects.map((p) => reserveRepository.fetchByProjectId(p.id)),
      ).timeout(_sectionTimeout);

      reserves.assignAll(result.expand((items) => items).toList());

      debugPrint('[Dashboard][Reservations] loaded ${reserves.length}');
    } catch (e) {
      debugPrint('[Dashboard][Reservations] error: $e');
    } finally {
      isReservationsLoading.value = false;
    }
  }

  Future<void> _loadJournals() async {
    debugPrint('[Dashboard][Journals] start');
    isJournalLoading.value = true;

    try {
      final projects = projectController.projects.toList();

      if (projects.isEmpty) {
        journals.clear();
        debugPrint('[Dashboard][Journals] no projects');
        return;
      }

      final result = await Future.wait(
        projects.map((p) => journalRepository.fetchByProject(p.id.toString())),
      ).timeout(_sectionTimeout);

      journals.assignAll(result.expand((items) => items).toList());

      debugPrint('[Dashboard][Journals] loaded ${journals.length}');
    } catch (e) {
      debugPrint('[Dashboard][Journals] error: $e');
    } finally {
      isJournalLoading.value = false;
    }
  }

  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }
}