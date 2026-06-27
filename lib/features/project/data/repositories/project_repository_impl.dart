import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/repositories/project_repository.dart';
import '../models/project_model.dart';
import '../models/subscription_code_model.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  static const int _defaultListLimit = 30;

  final ApiClient _apiClient;

  ProjectRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<ProjectModel>> getAllProjects() async {
    return _fetchProjectList('/projects?limit=$_defaultListLimit');
  }

  @override
  Future<List<ProjectModel>> getAllProjectsNoFilter() async {
    return getAllProjects();
  }

  @override
  Future<List<ProjectModel>> getSubProjects(int parentId) async {
    return _fetchProjectList(
      '/projects?parentId=$parentId&limit=$_defaultListLimit',
    );
  }

  Future<List<ProjectModel>> _fetchProjectList(String endpoint) async {
    try {
      final response = await _apiClient.get(endpoint);
      if (kDebugMode) {
        debugPrint('[Projects] list status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final raw = _responseData(response.data);
        if (raw == null) return [];
        if (raw is! List) {
          debugPrint('[Projects] list data is not a list: ${raw.runtimeType}');
          return [];
        }

        return raw
            .whereType<Map<String, dynamic>>()
            .map(ProjectModel.fromMap)
            .toList();
      }

      throw Exception('Failed to load projects: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('[Projects] DioException list: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('[Projects] Unexpected list error: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<ProjectModel?> getProject(int id) async {
    try {
      final response = await _apiClient.get('/projects/$id');

      if (response.statusCode == 200 && response.data != null) {
        final data = _responseData(response.data) ?? response.data;
        if (data is Map<String, dynamic>) {
          return ProjectModel.fromMap(data);
        }
      }

      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[Projects] getProject($id) error: ${e.message}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Projects] getProject($id) error: $e');
      }
      return null;
    }
  }

  @override
  Future<SubscriptionCodeModel> generateSubscriptionCode({
    required int projectId,
    required int numberOfMembers,
  }) async {
    try {
      final response = await _apiClient.post(
        '/subscription-codes',
        data: {
          'projectId': projectId,
          'numberOfMembers': numberOfMembers,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _responseData(response.data);
        if (data is Map<String, dynamic>) {
          return SubscriptionCodeModel.fromMap(data);
        }
      }

      throw Exception(
        'Failed to generate subscription code: ${response.statusCode}',
      );
    } on DioException catch (e) {
      debugPrint('[Projects] generateSubscriptionCode error: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('[Projects] generateSubscriptionCode unexpected error: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<bool> createProject({
    required String name,
    required String description,
    required String startDate,
    required String endDate,
    required int budget,
    required String localisation,
    String? latitude,
    String? longitude,
    int? organizationId,
    List<int> lotIds = const [],
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'budget': budget,
      'localisation': localisation,
      if (latitude != null && latitude.isNotEmpty) 'latitude': latitude,
      if (longitude != null && longitude.isNotEmpty) 'longitude': longitude,
      if (organizationId != null) 'organizationId': organizationId,
      'lotIds': lotIds,
    };

    try {
      final response = await _apiClient.post('/projects', data: data);
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      debugPrint('[Projects] createProject error: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('[Projects] createProject unexpected error: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<bool> updateProject(
    int projectId, {
    required String name,
    required String description,
    required String startDate,
    required String endDate,
    required int budget,
    required String localisation,
    String? latitude,
    String? longitude,
    List<int> lotIds = const [],
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'budget': budget,
      'localisation': localisation,
      if (latitude != null && latitude.isNotEmpty) 'latitude': latitude,
      if (longitude != null && longitude.isNotEmpty) 'longitude': longitude,
      'lotIds': lotIds,
    };

    try {
      final response = await _apiClient.patch('/projects/$projectId', data: data);
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('[Projects] updateProject error: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('[Projects] updateProject unexpected error: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  dynamic _responseData(dynamic responseData) {
    if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }
}
