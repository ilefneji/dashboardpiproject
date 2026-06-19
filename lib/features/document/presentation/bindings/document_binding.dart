import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../data/repositories/document_repository.dart';
import '../controllers/document_controller.dart';

class DocumentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DocumentRepository>(
      () => DocumentRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<DocumentController>(
      () => DocumentController(Get.find<DocumentRepository>()),
    );
  }
}
