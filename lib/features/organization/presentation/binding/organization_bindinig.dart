import 'package:get/get.dart';
import '../../../../core/network/api_client.dart';

import '../../data/repositories/organization_repository_impl.dart';
import '../../domain/repositories/organization_repository.dart';
import '../controllers/organization_controller.dart';

class OrganizationBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<OrganizationRepository>()) {
      Get.lazyPut<OrganizationRepository>(
        () => OrganizationRepositoryImpl(Get.find<ApiClient>()),
      );
    }

    if (!Get.isRegistered<OrganizationController>()) {
      Get.put<OrganizationController>(
        OrganizationController(Get.find<OrganizationRepository>()),
        permanent: true,
      );
    }
  }
}
