import '../../../../core/network/api_client.dart';
import '../models/reference_plan_model.dart';

class ReferencePlanRepository {
  final ApiClient _apiClient;

  const ReferencePlanRepository(this._apiClient);

  Future<List<ReferencePlanModel>> fetchReferencePlans() async {
    final response = await _apiClient.get('/task-controls');
    final body = response.data;

    final List<dynamic> raw = body is List
        ? body
        : body is Map<String, dynamic>
            ? (body['data'] as List<dynamic>? ?? [])
            : [];

    return raw
        .map((e) => ReferencePlanModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
