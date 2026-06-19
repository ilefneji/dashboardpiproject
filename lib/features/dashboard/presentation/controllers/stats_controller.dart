import 'package:get/get.dart';
import '../../../../core/network/api_client.dart';

class StatsController extends GetxController {
  final ApiClient _apiClient = ApiClient();
  final RxInt organizationCount = 0.obs;
  final RxInt userCount = 0.obs;
  final RxInt projectCount = 0.obs;
  final RxDouble totalRevenue = 0.0.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchStats();
  }

  Future<void> fetchStats() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _apiClient.get('/api/organizations/stats/total');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        organizationCount.value = data['organizationCount'] ?? 0;
        userCount.value = data['userCount'] ?? 0;
        projectCount.value = data['projectCount'] ?? 0;
        totalRevenue.value = data['totalRevenue'] ?? 0;
      } else {
        errorMessage.value = 'Failed to fetch stats: ${response.statusCode}';
        print('Error fetching stats: ${response.statusCode}');
      }
    } catch (e) {
      errorMessage.value = 'Error fetching stats: $e';
      print('Error fetching stats: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
