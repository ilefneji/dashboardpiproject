import '../../../../core/network/api_client.dart';
import '../models/document_model.dart';
import '../models/file_model.dart';
import '../models/folder_model.dart';

class DocumentRepository {
  final ApiClient _apiClient;

  const DocumentRepository(this._apiClient);

  Future<List<DocumentModel>> fetchTreeByProjectId(int projectId) async {
    final response = await _apiClient.get('/folders/tree/$projectId');
    final body = response.data;

    final List<dynamic> raw = body is List
        ? body
        : body is Map<String, dynamic>
            ? (body['data'] as List<dynamic>? ?? [])
            : [];

    return raw
        .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FileModel>> fetchFilesByFolderId(int folderId) async {
    final response = await _apiClient.get('/files/folder/$folderId');
    final body = response.data;

    final List<dynamic> raw = body is List
        ? body
        : body is Map<String, dynamic>
            ? (body['data'] as List<dynamic>? ?? [])
            : [];

    return raw
        .map((e) => FileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteFile(int id) async {
    await _apiClient.delete('/files/$id');
  }

  Future<void> deleteFolder(int id) async {
    await _apiClient.delete('/folders/$id');
  }

  Future<FileModel> updateFile(int id, String newName) async {
    final response = await _apiClient.patch(
      '/files/$id',
      data: {'name': newName},
    );
    return _parseFile(response.data);
  }

  Future<FolderModel> updateFolder(int id, String newName) async {
    final response = await _apiClient.patch(
      '/folders/$id',
      data: {'name': newName},
    );
    return _parseFolder(response.data);
  }

  FileModel _parseFile(dynamic body) {
    if (body == null) throw Exception('Response body is null');

    final data = body is Map<String, dynamic>
        ? (body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : body)
        : throw Exception('Unexpected body format: ${body.runtimeType}');

    return FileModel.fromJson(data);
  }

  FolderModel _parseFolder(dynamic body) {
    if (body == null) throw Exception('Response body is null');

    final data = body is Map<String, dynamic>
        ? (body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : body)
        : throw Exception('Unexpected body format: ${body.runtimeType}');

    return FolderModel.fromJson(data);
  }
}
