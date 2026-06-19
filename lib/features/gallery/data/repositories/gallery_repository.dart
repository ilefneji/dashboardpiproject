import '../../../../core/network/api_client.dart';
import '../models/gallery_model.dart';

class GalleryRepository {
  final ApiClient _apiClient;

  const GalleryRepository(this._apiClient);

  Future<List<GalleryModel>> fetchByProjectId(int projectId) async {
    final response = await _apiClient.get('/reserve/gallery-with-children/$projectId');
    final body = response.data;

    final List<dynamic> raw = body is List
        ? body
        : body is Map<String, dynamic>
            ? (body['data'] as List<dynamic>? ?? [])
            : [];

    return raw
        .map((e) => GalleryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
