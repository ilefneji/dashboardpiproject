import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final ApiClient _apiClient;

  UserRepositoryImpl(this._apiClient);

@override
Future<List<UserModel>> getUsers() async {
  try {
    final response = await _apiClient.get('/users');

    if (response.statusCode == 200 && response.data != null) {
      final responseData = response.data;

      List<dynamic> usersJson = [];

      // ── Cas 1: { "data": [ user1, user2, user3 ] } ───────────────────
      if (responseData['data'] is List) {
        usersJson = responseData['data'] as List<dynamic>;
      }

      // ── Cas 2: { "data": { "items": [...] } } ────────────────────────
      else if (responseData['data'] is Map &&
               responseData['data']['items'] is List) {
        usersJson = responseData['data']['items'] as List<dynamic>;
      }

      // ── Cas 3: { "data": { "data": [...] } } (Laravel paginate) ──────
      else if (responseData['data'] is Map &&
               responseData['data']['data'] is List) {
        usersJson = responseData['data']['data'] as List<dynamic>;
      }

      // ── Cas 4: { "users": [...] } ────────────────────────────────────
      else if (responseData['users'] is List) {
        usersJson = responseData['users'] as List<dynamic>;
      }

      // ── Cas 5: [ user1, user2 ] (root array) ─────────────────────────
      else if (responseData is List) {
        usersJson = responseData;
      }

      debugPrint('✅ Total users parsed: ${usersJson.length}');
      return usersJson.map((json) => UserModel.fromJson(json)).toList();
    }

    return [];
  } on DioException catch (e) {
    debugPrint('❌ DioError getting users: ${e.message}');
    return [];
  } catch (e) {
    debugPrint('❌ Unexpected error getting users: $e');
    return [];
  }
}

  @override
  Future<UserModel?> getUserById(int id) async {
    try {
      final response = await _apiClient.get('/users/$id');

      if (response.statusCode == 200 && response.data != null) {
        return UserModel.fromJson(response.data["user"]);
      }
      return null;
    } on DioException catch (e) {
      print('Error getting user: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error getting user: $e');
      return null;
    }
  }

  @override
  Future<UserModel?> createUser(UserModel user) async {
    try {
      final response = await _apiClient.post(
        '/users',
        data: user.toJson(),
      );

      if (response.statusCode == 201 && response.data != null) {
        return UserModel.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      print('Error creating user: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error creating user: $e');
      return null;
    }
  }

  @override
  Future<bool> updateUser(UserModel user) async {
    try {
      if (user.id == null) {
        print('Cannot update user without an ID');
        return false;
      }

      final response = await _apiClient.put(
        '/users/${user.id}',
        data: user.toJson(),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error updating user: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error updating user: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteUser(int id) async {
    try {
      final response = await _apiClient.delete('/users/$id');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error deleting user: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error deleting user: $e');
      return false;
    }
  }

  @override
  Future<bool> activateUser(int id) async {
    try {
      final response =
          await _apiClient.post('/users/reactivate-admin-user/$id');
      return response.statusCode == 201;
    } on DioException catch (e) {
      print('Error activating user: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error activating user: $e');
      return false;
    }
  }

  @override
  Future<bool> deactivateUser(int id) async {
    try {
      final response =
          await _apiClient.post('/users/deactivate-admin-user/$id');
      return response.statusCode == 201;
    } on DioException catch (e) {
      print('Error deactivating user: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error deactivating user: $e');
      return false;
    }
  }

  @override
  Future<bool> makeAdmin(int id) async {
    try {
      final response = await _apiClient.post('/users/make-admin/$id');
      final code = response.statusCode ?? 0;
      return code >= 200 && code < 300;
    } on DioException catch (e) {
      print('Error promoting user to admin: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error promoting user to admin: $e');
      return false;
    }
  }

  @override
  Future<bool> demoteAdmin(int id) async {
    try {
      final response = await _apiClient.post('/users/demote-admin/$id');
      final code = response.statusCode ?? 0;
      return code >= 200 && code < 300;
    } on DioException catch (e) {
      print('Error demoting admin: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error demoting admin: $e');
      return false;
    }
  }

  @override
  Future<bool> inviteCompanyUser(String email, int inviterId,
      {int? organizationId}) async {
    try {
      final response = await _apiClient.post(
        '/users/invite-company-user',
        data: {
          'email': email,
          'inviterId': inviterId,
          if (organizationId != null) 'organizationId': organizationId,
          'role': 'member',
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('Error inviting company user: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error inviting company user: $e');
      return false;
    }
  }
}
