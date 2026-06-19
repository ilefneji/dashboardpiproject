import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../data/repositories/reserve_repository.dart';
import '../controllers/reserve_controller.dart';

class ReserveBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReserveRepository>(
      () => ReserveRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<ReserveController>(
      () => ReserveController(Get.find<ReserveRepository>()),
    );
  }
}
