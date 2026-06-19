import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/organization.dart';
import '../../domain/repositories/organization_repository.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  final ApiClient _apiClient;

  OrganizationRepositoryImpl(this._apiClient);

  // ─────────────────────────────────────────────────────────────────
  // GET ALL
  // ─────────────────────────────────────────────────────────────────

  @override
  Future<List<Organization>> getOrganizations() async {
    try {
      final response = await _apiClient.get('/organizations');

      debugPrint('📦 getOrganizations status: ${response.statusCode}');
      debugPrint('📦 getOrganizations data:   ${response.data}');

      if (response.statusCode == 200) {
        final dynamic raw = response.data['data'];

        if (raw == null) return [];
        if (raw is! List) {
          debugPrint(
              '⚠️ getOrganizations — data is not a List: ${raw.runtimeType}');
          return [];
        }

        return raw
            .whereType<Map<String, dynamic>>() // ✅ skip malformed entries
            .map(_mapToOrganization)
            .toList();
      }

      throw Exception('Failed to fetch organizations: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('❌ DioException getOrganizations: ${e.message}');
      debugPrint('❌ Response body:               ${e.response?.data}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ Unexpected error getOrganizations: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // GET ONE
  // ─────────────────────────────────────────────────────────────────

  @override
  Future<Organization> getOrganization(int id) async {
    // ✅ int not String
    try {
      final response = await _apiClient.get('/organizations/$id');

      debugPrint('📦 getOrganization($id) status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final raw = response.data['data'];
        if (raw == null) throw Exception('Organization $id not found');
        return _mapToOrganization(raw as Map<String, dynamic>);
      }

      throw Exception(
          'Failed to fetch organization $id: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('❌ DioException getOrganization: ${e.message}');
      debugPrint('❌ Response body:              ${e.response?.data}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ Unexpected error getOrganization: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────────────────────────

  @override
  Future<Organization> createOrganization(Organization organization) async {
    try {
      final response = await _apiClient.post(
        '/organizations',
        data: {
          'name': organization.name,
          if (organization.organismeType != null)
            'organismeType': organization.organismeType,
          if (organization.description != null &&
              organization.description!.trim().isNotEmpty)
            'description': organization.description,
        },
      );

      debugPrint('📦 createOrganization status: ${response.statusCode}');
      debugPrint('📦 createOrganization data:   ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final raw = response.data['data'];
        if (raw == null) throw Exception('Create response data is null');
        return _mapToOrganization(raw as Map<String, dynamic>);
      }

      throw Exception('Failed to create organization: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('❌ DioException createOrganization: ${e.message}');
      debugPrint('❌ Response body:                  ${e.response?.data}');

      // ✅ surface backend conflict message (P2002 duplicate name)
      final message = e.response?.data?['message']?.toString() ??
          'Network error: ${e.message}';
      throw Exception(message);
    } catch (e) {
      debugPrint('❌ Unexpected error createOrganization: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────────────

  @override
  Future<Organization> updateOrganization(Organization organization) async {
    try {
      final response = await _apiClient.put(
        '/organizations/${organization.id}',
        data: {
          'name': organization.name,
          if (organization.organismeType != null)
            'organismeType': organization.organismeType,
          if (organization.description != null)
            'description': organization.description,
        },
      );

      debugPrint('📦 updateOrganization status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final raw = response.data['data'];
        if (raw == null) throw Exception('Update response data is null');
        return _mapToOrganization(raw as Map<String, dynamic>);
      }

      throw Exception('Failed to update organization: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('❌ DioException updateOrganization: ${e.message}');
      debugPrint('❌ Response body:                  ${e.response?.data}');
      final message = e.response?.data?['message']?.toString() ??
          'Network error: ${e.message}';
      throw Exception(message);
    } catch (e) {
      debugPrint('❌ Unexpected error updateOrganization: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────────────

  @override
  Future<void> deleteOrganization(int id) async {
    try {
      final response = await _apiClient.delete('/organizations/$id');

      debugPrint('📦 deleteOrganization($id) status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) return;

      // ✅ surface backend error message if present
      final message = response.data?['message']?.toString() ??
          'Failed to delete organization: ${response.statusCode}';
      throw Exception(message);
    } on DioException catch (e) {
      debugPrint('❌ DioException deleteOrganization: ${e.message}');
      debugPrint('❌ Response body:                  ${e.response?.data}');
      final message = e.response?.data?['message']?.toString() ??
          'Network error: ${e.message}';
      throw Exception(message);
    } catch (e) {
      debugPrint('❌ Unexpected error deleteOrganization: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // PRIVATE MAPPER
  // ─────────────────────────────────────────────────────────────────

  Organization _mapToOrganization(Map<String, dynamic> json) {
    // ✅ Keep createdAt as ISO string — controller handles formatting
    // ✅ Never call DateFormat here — that broke all date parsing in controller
    return Organization(
      id: json['id'],
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      organismeType: json['organismeType']?.toString(),
      createdAt: json['createdAt']?.toString(), // ✅ raw ISO string
      companyId: json['companyId'],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // PUBLIC DISPLAY HELPER
  // ─────────────────────────────────────────────────────────────────

  /// Use this in UI widgets when you need dd/MM/yyyy display format
  /// Never call this during mapping — keep raw ISO in entity
  static String formatDisplayDate(String? isoDate) {
    if (isoDate == null || isoDate.trim().isEmpty) return '—';
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return '—';
    return DateFormat('dd/MM/yyyy').format(parsed);
  }
}
