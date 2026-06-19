import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../users/data/repositories/user_repository_impl.dart';
import '../../../users/domain/repositories/user_repository.dart';
import '../controllers/user_controller.dart';

class UserBinding extends Bindings {
  @override
  void dependencies() {
    // ✅ Register repository FIRST with GetX
    if (!Get.isRegistered<UserRepository>()) {
      Get.lazyPut<UserRepository>(
        () => UserRepositoryImpl(Get.find<ApiClient>()),
      );
    }
    
    // ✅ Register controller with injected repository
    if (!Get.isRegistered<UserController>()) {
      Get.put<UserController>(
        UserController(Get.find<UserRepository>()),
        permanent: true,
      );
    }
  }
}
