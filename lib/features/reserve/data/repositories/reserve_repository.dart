import '../../../../core/network/api_client.dart';
import '../models/reserve_model.dart';

class ReserveRepository {
  final ApiClient _apiClient;

  const ReserveRepository(this._apiClient);

  Future<List<ReserveModel>> fetchByProjectId(int projectId) async {
    final response = await _apiClient.get('/reserve?projectId=$projectId');
    final body = response.data;

    final List<dynamic> raw = body is List
        ? body
        : body is Map<String, dynamic>
            ? (body['data'] as List<dynamic>? ?? [])
            : [];

    return raw
        .map((e) => ReserveModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReserveModel?> fetchById(int id) async {
    final response = await _apiClient.get('/reserve/$id');
    final body = response.data;

    if (body == null) return null;

    final data = body is Map<String, dynamic>
        ? (body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : body)
        : null;

    if (data == null) return null;

    return ReserveModel.fromJson(data);
  }

  Future<ReserveModel?> updateStatus(int id, String status) async {
    final response = await _apiClient.patch(
      '/reserve/$id',
      data: {'status': status},
    );
    final body = response.data;

    if (body == null) return null;

    final data = body is Map<String, dynamic>
        ? (body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : body)
        : null;

    if (data == null) return null;

    return ReserveModel.fromJson(data);
  }
}
