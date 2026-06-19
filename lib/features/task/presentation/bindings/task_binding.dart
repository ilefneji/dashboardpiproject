//task/presentation/bindings/task_binding.dart
import 'package:get/get.dart';
import '../../../../core/network/api_client.dart';
import '../../../task/data/repositories/task_repository_impl.dart';
import '../../../task/domain/repositories/task_repository.dart';
import '../../../lot/data/repositories/lot_repository_impl.dart';
import '../../../lot/domain/repositories/lot_repository.dart';
import '../../../lot/presentation/controllers/lot_controller.dart';
import '../controllers/task_controller.dart';

class TaskBinding extends Bindings {
  @override
  void dependencies() {
    // ✅ Register repository FIRST with GetX
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

    // ✅ Register controller and inject repository
    if (!Get.isRegistered<TaskController>()) {
      Get.put<TaskController>(
        TaskController(Get.find<TaskRepository>()),
        permanent: true,
      );
    }
  }
}
