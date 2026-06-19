// lib/features/journal/presentation/binding/journal_binding.dart

import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../project/data/repositories/project_repository_impl.dart';
import '../../../project/domain/repositories/project_repository.dart';
import '../../data/journal_repository.dart';
import '../controllers/journal_controller.dart';

class JournalBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProjectRepository>()) {
      Get.lazyPut<ProjectRepository>(
        () => ProjectRepositoryImpl(apiClient: Get.find<ApiClient>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<JournalRepository>()) {
      Get.lazyPut<JournalRepository>(
        () => JournalRepository(Get.find<ApiClient>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<JournalController>()) {
      Get.put<JournalController>(
        JournalController(Get.find<JournalRepository>()),
        permanent: true,
      );
    }
  }
}
