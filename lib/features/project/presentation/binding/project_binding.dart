// lib/features/project/presentation/binding/project_binding.dart

import 'package:get/get.dart';
import '../../../../core/network/api_client.dart';
import '../../../lot/data/repositories/lot_repository_impl.dart';
import '../../../lot/domain/repositories/lot_repository.dart';
import '../../../lot/presentation/controllers/lot_controller.dart';
import '../../../task/data/repositories/task_repository_impl.dart';
import '../../../task/domain/repositories/task_repository.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../domain/repositories/project_repository.dart';
import '../controllers/project_admin_detail_controller.dart';
import '../controllers/project_controller.dart';

class ProjectBinding extends Bindings {
  @override
  void dependencies() {
    // ✅ ProjectRepository — safety guard (already registered in AppBinding)
    if (!Get.isRegistered<ProjectRepository>()) {
      Get.lazyPut<ProjectRepository>(
        () => ProjectRepositoryImpl(apiClient: Get.find<ApiClient>()),
        fenix: true,
      );
    }

    // ✅ ProjectController
    if (!Get.isRegistered<ProjectController>()) {
      Get.put<ProjectController>(
        ProjectController(projectRepository: Get.find<ProjectRepository>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<ProjectAdminDetailController>()) {
      Get.lazyPut<ProjectAdminDetailController>(
        () => ProjectAdminDetailController(apiClient: Get.find<ApiClient>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<LotRepository>()) {
      Get.lazyPut<LotRepository>(
        () => LotRepositoryImpl(Get.find<ApiClient>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<TaskRepository>()) {
      Get.lazyPut<TaskRepository>(
        () => TaskRepositoryImpl(Get.find<ApiClient>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<LotController>()) {
      Get.put<LotController>(
        LotController(Get.find<LotRepository>(), Get.find<TaskRepository>()),
        permanent: true,
      );
    }
  }
}
