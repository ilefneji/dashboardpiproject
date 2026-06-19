import 'package:get/get.dart';
import '../../../../core/network/api_client.dart';
import '../../../task-control/data/repositories/task_control_repository_impl.dart';
import '../../../task-control/domain/repositories/task_control_repository.dart';
import '../../../task/data/repositories/task_repository_impl.dart';
import '../../../task/domain/repositories/task_repository.dart';
import '../../../task/presentation/controllers/task_controller.dart';
import '../../../lot/data/repositories/lot_repository_impl.dart';
import '../../../lot/domain/repositories/lot_repository.dart';
import '../../../lot/presentation/controllers/lot_controller.dart';
import '../controllers/task_control_controller.dart';

class TaskControlBinding extends Bindings {
  @override
  void dependencies() {
    // ✅ Register TaskControl Repository FIRST
    if (!Get.isRegistered<TaskControlRepository>()) {
      Get.lazyPut<TaskControlRepository>(
        () => TaskControlRepositoryImpl(Get.find<ApiClient>()),
      );
    }

    // ✅ Register Task Repository (needed for task dropdowns)
    if (!Get.isRegistered<TaskRepository>()) {
      Get.lazyPut<TaskRepository>(
        () => TaskRepositoryImpl(Get.find<ApiClient>()),
      );
    }

    if (!Get.isRegistered<LotRepository>()) {
      Get.lazyPut<LotRepository>(
        () => LotRepositoryImpl(Get.find<ApiClient>()),
      );
    }

    if (!Get.isRegistered<LotController>()) {
      Get.put<LotController>(
        LotController(
          Get.find<LotRepository>(),
          Get.find<TaskRepository>(),
        ),
        permanent: true,
      );
    }

    // ✅ Register TaskControl Controller
    if (!Get.isRegistered<TaskControlController>()) {
      Get.put<TaskControlController>(
        TaskControlController(Get.find<TaskControlRepository>()),
        permanent: true,
      );
    }

    // ✅ Register Task Controller
    if (!Get.isRegistered<TaskController>()) {
      Get.put<TaskController>(
        TaskController(Get.find<TaskRepository>()),
        permanent: true,
      );
    }
  }
}
