import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../domain/entities/journal_chantier.dart';

class JournalRepository {
  final ApiClient _apiClient;

  const JournalRepository(this._apiClient);

  Future<List<JournalChantier>> fetchByProject(String projectId) async {
    final response = await _apiClient.get(
      '/journal-chantier/project/$projectId',
    );

    final body = response.data;

    final List<dynamic> raw = body is List
        ? body
        : body is Map<String, dynamic>
            ? (body['data'] as List<dynamic>? ?? [])
            : [];

    return raw
        .map((e) => JournalChantier.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<JournalChantier> getOrCreateToday(String projectId) async {
    final response = await _apiClient.get(
      '/journal-chantier/project/$projectId/today',
    );

    return _parseJournal(response.data);
  }

  Future<JournalChantier> update(
    String journalId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.patch(
      '/journal-chantier/$journalId',
      data: data,
    );

    return _parseJournal(response.data);
  }

  Future<JournalChantier> lockJournal(String journalId) async {
    debugPrint('🔒 lockJournal($journalId)');

    final response = await _apiClient.patch(
      '/journal-chantier/$journalId/lock',
      data: {},
    );

    return _parseJournal(response.data);
  }

  Future<JournalChantier> unlockJournal(String journalId) async {
    debugPrint('🔓 unlockJournal($journalId)');

    final response = await _apiClient.patch(
      '/journal-chantier/$journalId/unlock',
      data: {},
    );

    return _parseJournal(response.data);
  }

  JournalChantier _parseJournal(dynamic body) {
    debugPrint('_parseJournal: type=${body.runtimeType}');

    if (body == null) {
      throw Exception('_parseJournal: response body is null');
    }

    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected body format: ${body.runtimeType}');
    }

    if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
      return JournalChantier.fromJson(body['data'] as Map<String, dynamic>);
    }

    if (body.containsKey('error') && !body.containsKey('id')) {
      final message = body['message'] ?? 'Unknown backend error';
      throw Exception('Backend error: $message');
    }

    return JournalChantier.fromJson(body);
  }
}