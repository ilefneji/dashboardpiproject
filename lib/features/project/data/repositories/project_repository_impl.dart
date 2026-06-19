import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/repositories/project_repository.dart';
import '../models/project_model.dart';
import '../models/subscription_code_model.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ApiClient _apiClient;

  ProjectRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  // ─────────────────────────────────────────────────────────────────
  // GET ALL PROJECTS
  // ─────────────────────────────────────────────────────────────────

  @override
  Future<List<ProjectModel>> getAllProjects() async {
    try {
      final response = await _apiClient.get('/projects');

      print('📦 getAllProjects status: ${response.statusCode}');
      print('📦 getAllProjects data: ${response.data}');

      if (response.statusCode == 200) {
        final dynamic raw = response.data['data'];

        if (raw == null) return [];
        if (raw is! List) {
          print('⚠️ data nest pas une liste: ${raw.runtimeType}');
          return [];
        }

        return (raw)
            .map((json) => ProjectModel.fromMap(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load projects: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ DioException getAllProjects: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error getAllProjects: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // GET SUB PROJECTS
  // ─────────────────────────────────────────────────────────────────

  @override
  Future<List<ProjectModel>> getSubProjects(int parentId) async {
    try {
      final response = await _apiClient.get('/projects?parentId=$parentId');

      print('📦 getSubProjects($parentId) status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic raw = response.data['data'];
        if (raw == null) return [];
        if (raw is! List) return [];

        return (raw)
            .map((json) => ProjectModel.fromMap(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load subprojects: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ DioException getSubProjects: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error getSubProjects: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // GET ALL PROJECTS NO FILTER
  // ─────────────────────────────────────────────────────────────────

  @override
  Future<List<ProjectModel>> getAllProjectsNoFilter() async {
    return getAllProjects();
  }

  // ─────────────────────────────────────────────────────────────────
  // GENERATE SUBSCRIPTION CODE
  // ─────────────────────────────────────────────────────────────────

  @override
  Future<SubscriptionCodeModel> generateSubscriptionCode({
    required int projectId,
    required int numberOfMembers,
  }) async {
    try {
      final data = {
        'projectId': projectId,
        'numberOfMembers': numberOfMembers,
      };

      final response = await _apiClient.post('/subscription-codes', data: data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return SubscriptionCodeModel.fromMap(response.data['data']);
      } else {
        throw Exception(
            'Failed to generate subscription code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ DioException generateSubscriptionCode: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error generateSubscriptionCode: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // CREATE PROJECT
  // ─────────────────────────────────────────────────────────────────

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
    List<int> lotIds = const [], // ✅ default here in impl
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name.trim(),
        'description': description.trim(),
        'startDate': startDate,
        'localisation': localisation.trim(),
        'budget': budget,
        if (endDate.isNotEmpty) 'endDate': endDate,
        if (organizationId != null) 'organizationId': organizationId,
        if (latitude != null && latitude.trim().isNotEmpty)
          'latitude': latitude.trim(),
        if (longitude != null && longitude.trim().isNotEmpty)
          'longitude': longitude.trim(),
        // ✅ always send lotIds so backend can sync correctly
        // empty [] means "no lots" — backend handles it
        'lotIds': lotIds,
      };

      print('🚀 POST /projects — data: $data');
      final response = await _apiClient.post('/projects', data: data);
      print('📦 POST /projects — response: ${response.data}');

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('❌ DioException createProject: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error createProject: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // UPDATE PROJECT
  // ─────────────────────────────────────────────────────────────────

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
    List<int> lotIds = const [], // ✅ default here in impl
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name.trim(),
        'description': description.trim(),
        'startDate': startDate,
        'localisation': localisation.trim(),
        'budget': budget,
        if (endDate.isNotEmpty) 'endDate': endDate,
        if (latitude != null && latitude.trim().isNotEmpty)
          'latitude': latitude.trim(),
        if (longitude != null && longitude.trim().isNotEmpty)
          'longitude': longitude.trim(),
        // ✅ always send lotIds so backend can sync ([] = remove all)
        'lotIds': lotIds,
      };

      print('🚀 PATCH /projects/$projectId — data: $data');
      final response =
          await _apiClient.patch('/projects/$projectId', data: data);
      print('📦 PATCH /projects/$projectId — response: ${response.data}');

      return response.statusCode == 200;
    } on DioException catch (e) {
      print('❌ DioException updateProject: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error updateProject: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<ProjectModel?> getProject(int id) async {
    try {
      final response = await _apiClient.get('/projects/$id');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return ProjectModel.fromMap(data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ getProject($id) error: ${e.response?.data}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ getProject($id) error: $e');
      }
      return null;
    }
  }
}
