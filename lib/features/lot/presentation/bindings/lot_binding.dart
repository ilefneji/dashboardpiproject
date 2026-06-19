import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../task/data/repositories/task_repository_impl.dart';
import '../../../task/domain/repositories/task_repository.dart';
import '../../data/repositories/lot_repository_impl.dart';
import '../../domain/repositories/lot_repository.dart';
import '../controllers/lot_controller.dart';

class LotBinding extends Bindings {
  @override
  void dependencies() {
    // ✅ Register Lot Repository
    if (!Get.isRegistered<LotRepository>()) {
      Get.lazyPut<LotRepository>(
        () => LotRepositoryImpl(Get.find<ApiClient>()),
      );
    }

    if (!Get.isRegistered<ApiClient>()) {
      Get.lazyPut<ApiClient>(
        () => ApiClient(),
        fenix: true,
      );
    }

    // ✅ Register Task Repository (needed by LotController)
    if (!Get.isRegistered<TaskRepository>()) {
      Get.lazyPut<TaskRepository>(
        () => TaskRepositoryImpl(Get.find<ApiClient>()),
      );
    }

    // ✅ Register Controller with both repositories
    if (!Get.isRegistered<LotController>()) {
      Get.put<LotController>(
        LotController(
          Get.find<LotRepository>(),
          Get.find<TaskRepository>(),
        ),
        permanent: true,
      );
    }
  }
}
