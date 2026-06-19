import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../data/repositories/reference_plan_repository.dart';
import '../controllers/reference_plan_controller.dart';

class ReferencePlanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReferencePlanRepository>(
      () => ReferencePlanRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<ReferencePlanController>(
      () => ReferencePlanController(Get.find<ReferencePlanRepository>()),
    );
  }
}
