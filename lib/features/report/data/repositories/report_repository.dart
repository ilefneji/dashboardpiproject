import '../../../../core/network/api_client.dart';
import '../models/control_report_model.dart';
import '../models/process_verbal_model.dart';

class ReportRepository {
  final ApiClient _apiClient;

  const ReportRepository(this._apiClient);

  Future<List<ControlReportModel>> fetchControlReportsByProject(
    int projectId,
  ) async {
    final response = await _apiClient.get('/pvs/project/$projectId');
    final body = response.data;

    final List<dynamic> raw = body is List
        ? body
        : body is Map<String, dynamic>
            ? (body['data'] as List<dynamic>? ?? [])
            : [];

    return raw
        .map((e) => ControlReportModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProcessVerbalModel>> fetchProcessVerbalsByProject(
    int projectId,
  ) async {
    final response = await _apiClient.get('/pv-comment/project/$projectId');
    final body = response.data;

    final List<dynamic> raw = body is List
        ? body
        : body is Map<String, dynamic>
            ? (body['data'] as List<dynamic>? ?? [])
            : [];

    return raw
        .map((e) => ProcessVerbalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String getControlReportPrintUrl(int id) {
    return '${ApiClient.baseUrl}/pvs/print/$id';
  }

  String getProcessVerbalPrintUrl(int id) {
    return '${ApiClient.baseUrl}/pv-comment/print/$id';
  }

  Future<void> approveProcessVerbal({
    required int userId,
    required int pvId,
  }) async {
    await _apiClient.patch('/pvs/$userId/$pvId/approval');
  }
}
