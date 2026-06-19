import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../data/repositories/gallery_repository.dart';
import '../controllers/gallery_controller.dart';

class GalleryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GalleryRepository>(
      () => GalleryRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<GalleryController>(
      () => GalleryController(Get.find<GalleryRepository>()),
    );
  }
}
