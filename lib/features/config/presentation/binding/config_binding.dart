import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../config/data/repositories/config_repository_impl.dart';
import '../../../config/domain/repositories/config_repository.dart';
import '../controllers/config_controller.dart';
import '../controllers/subscription_controller.dart';

class ConfigBinding extends Bindings {
  @override
  void dependencies() {
    // API Client
    if (!Get.isRegistered<ApiClient>()) {
      Get.lazyPut<ApiClient>(() => ApiClient(), fenix: true);
    }

    // Repositories
    if (!Get.isRegistered<ConfigRepository>()) {
      Get.lazyPut<ConfigRepository>(
        () => ConfigRepositoryImpl(Get.find<ApiClient>()),
        fenix: true,
      );
    }

    // Controllers
    if (!Get.isRegistered<ConfigController>()) {
      Get.lazyPut<ConfigController>(
        () => ConfigController(Get.find<ConfigRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<SubscriptionController>()) {
      Get.put<SubscriptionController>(
        SubscriptionController(Get.find<ConfigRepository>()),
        permanent: true,
      );
    }
  }
}
