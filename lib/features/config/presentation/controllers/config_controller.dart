import 'package:get/get.dart';

import '../../domain/entities/config.dart';
import '../../domain/repositories/config_repository.dart';

class ConfigController extends GetxController {
  final ConfigRepository _configRepository;
  
  ConfigController(this._configRepository);

  final Rx<Config?> config = Rx<Config?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchConfig();
  }

  Future<void> fetchConfig() async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      final result = await _configRepository.getConfig();
      if (result != null) {
        config.value = result;
      } else {
        // Initialize with default values if no config exists
        config.value = Config(priceSubscription: 0.0);
      }
    } catch (e) {
      errorMessage.value = 'Failed to load configuration: $e';
      print('Error fetching config: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateConfig({required double priceSubscription}) async {
    isUpdating.value = true;
    errorMessage.value = '';
    
    try {
      final updatedConfig = Config(
        priceSubscription: priceSubscription,
      );
      
      final result = await _configRepository.updateConfig(updatedConfig);
      
      if (result) {
        config.value = updatedConfig;
        return true;
      } else {
        errorMessage.value = 'Failed to update configuration';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error updating configuration: $e';
      print('Error updating config: $e');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }
}
