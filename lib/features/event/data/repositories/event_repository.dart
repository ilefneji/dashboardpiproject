import '../../../../core/network/api_client.dart';
import '../models/event_model.dart';

class EventRepository {
  final ApiClient _apiClient;

  const EventRepository(this._apiClient);

  Future<List<EventModel>> fetchByProjectId(int projectId) async {
    final response = await _apiClient.get('/events/project/$projectId');
    final body = response.data;

    final List<dynamic> raw = body is List
        ? body
        : body is Map<String, dynamic>
            ? (body['data'] as List<dynamic>? ?? [])
            : [];

    return raw
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EventModel?> fetchById(int id) async {
    final response = await _apiClient.get('/events/$id');
    final body = response.data;

    if (body == null) return null;

    final data = body is Map<String, dynamic>
        ? (body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : body)
        : null;

    if (data == null) return null;

    return EventModel.fromJson(data);
  }
}
