// lib/features/dashboard/presentation/bindings/dashboard_binding.dart

import 'package:get/get.dart';
import 'package:constructiondashboard/core/network/api_client.dart';
import 'package:constructiondashboard/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:constructiondashboard/features/organization/data/repositories/organization_repository_impl.dart';
import 'package:constructiondashboard/features/organization/domain/repositories/organization_repository.dart';
import 'package:constructiondashboard/features/organization/presentation/controllers/organization_controller.dart';
import 'package:constructiondashboard/features/users/data/repositories/user_repository_impl.dart';
import 'package:constructiondashboard/features/users/domain/repositories/user_repository.dart';
import 'package:constructiondashboard/features/users/presentation/controllers/user_controller.dart';
import 'package:constructiondashboard/features/project/presentation/controllers/project_controller.dart';
import 'package:constructiondashboard/features/project/domain/repositories/project_repository.dart';
import 'package:constructiondashboard/features/project/data/repositories/project_repository_impl.dart';
import 'package:constructiondashboard/features/task/data/repositories/task_repository_impl.dart';
import 'package:constructiondashboard/features/task/domain/repositories/task_repository.dart';
import 'package:constructiondashboard/features/lot/data/repositories/lot_repository_impl.dart';
import 'package:constructiondashboard/features/lot/domain/repositories/lot_repository.dart';
import 'package:constructiondashboard/features/lot/presentation/controllers/lot_controller.dart';
import 'package:constructiondashboard/features/reserve/data/repositories/reserve_repository.dart';
import 'package:constructiondashboard/features/journal/data/journal_repository.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // ✅ ApiClient
    if (!Get.isRegistered<ApiClient>()) {
      Get.lazyPut<ApiClient>(() => ApiClient(), fenix: true);
    }

    // ✅ OrganizationRepository + Controller
    if (!Get.isRegistered<OrganizationRepository>()) {
      Get.lazyPut<OrganizationRepository>(
        () => OrganizationRepositoryImpl(Get.find<ApiClient>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<OrganizationController>()) {
      Get.put<OrganizationController>(
        OrganizationController(Get.find<OrganizationRepository>()),
        permanent: true,
      );
    }

    // ✅ UserRepository + Controller
    if (!Get.isRegistered<UserRepository>()) {
      Get.lazyPut<UserRepository>(
        () => UserRepositoryImpl(Get.find<ApiClient>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<UserController>()) {
      Get.put<UserController>(
        UserController(Get.find<UserRepository>()),
        permanent: true,
      );
    }

    // ✅ ProjectRepository + Controller
    if (!Get.isRegistered<ProjectRepository>()) {
      Get.lazyPut<ProjectRepository>(
        () => ProjectRepositoryImpl(apiClient: Get.find<ApiClient>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<ProjectController>()) {
      Get.put<ProjectController>(ProjectController(), permanent: true);
    }

    // ✅ TaskRepository
    if (!Get.isRegistered<TaskRepository>()) {
      Get.lazyPut<TaskRepository>(
        () => TaskRepositoryImpl(Get.find<ApiClient>()),
        fenix: true,
      );
    }

    // ✅ LotRepository + Controller
    if (!Get.isRegistered<LotRepository>()) {
      Get.lazyPut<LotRepository>(
        () => LotRepositoryImpl(Get.find<ApiClient>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<LotController>()) {
      Get.put<LotController>(
        LotController(Get.find<LotRepository>(), Get.find<TaskRepository>()),
        permanent: true,
      );
    }

    // ✅ ReserveRepository
    if (!Get.isRegistered<ReserveRepository>()) {
      Get.lazyPut<ReserveRepository>(
        () => ReserveRepository(Get.find<ApiClient>()),
        fenix: true,
      );
    }

    // ✅ JournalRepository
    if (!Get.isRegistered<JournalRepository>()) {
      Get.lazyPut<JournalRepository>(
        () => JournalRepository(Get.find<ApiClient>()),
        fenix: true,
      );
    }

    // ✅ DashboardController — EN DERNIER
    if (!Get.isRegistered<DashboardController>()) {
      Get.lazyPut<DashboardController>(
        () => DashboardController(),
        fenix: true,
      );
    }

    // 🔥 PRÉCHARGEMENT — force l'initialisation AVANT l'affichage
    _preloadData();
  }

  // ─────────────────────────────────────────────────────────────
  // 🔥 Précharge toutes les données AVANT le premier build
  // ─────────────────────────────────────────────────────────────
  void _preloadData() {
    Future.microtask(() async {
      final orgController = Get.find<OrganizationController>();
      final userController = Get.find<UserController>();
      final projController = Get.find<ProjectController>();
      final lotController = Get.find<LotController>();

      final tasks = <Future<void>>[];

      if (orgController.organizations.isEmpty &&
          !orgController.isLoading.value) {
        tasks.add(_safeLoad(() => orgController.fetchOrganizations()));
      }
      if (userController.users.isEmpty && !userController.isLoading.value) {
        tasks.add(_safeLoad(() => userController.fetchUsers()));
      }
      if (projController.projects.isEmpty && !projController.isLoading.value) {
        tasks.add(_safeLoad(() => projController.getAllProjectsNoFilter()));
      }
      if (lotController.lots.isEmpty && !lotController.isLoading.value) {
        tasks.add(_safeLoad(() => lotController.fetchLots()));
      }

      if (tasks.isEmpty) return;
      await Future.wait(tasks);
    });
  }

  Future<void> _safeLoad(Future<void> Function() call) async {
    try {
      await call();
    } catch (e) {
      print('⚠️ Preload échoué: $e');
    }
  }
}
