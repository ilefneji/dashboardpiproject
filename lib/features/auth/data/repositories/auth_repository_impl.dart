import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FlutterSecureStorage _storage;
  final ApiClient _apiClient;

  AuthRepositoryImpl({required FlutterSecureStorage storage})
    : _storage = storage,
      _apiClient = ApiClient();

  @override
  Future<(User?, String?)> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/users/login',
        data: {'email': email, 'password': password},
      );

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Data: ${response.data}');

      // Check for 201 Created status code
      if (response.statusCode == 201 && response.data != null) {
        print('✓ Got 201 response with data');
        final data = response.data['data'];
        print('Data extracted: $data');

        if (data != null) {
          try {
            final user = User.fromJson(data['user']);
            final token = data['token'] as String;
            print('✓ User parsed: ${user.email}, isAdmin: ${user.isAdmin}');

            if (user.isAdmin) {
              // seulement si admin, on stocke
              await _storage.write(key: 'auth_token', value: token);
              await _storage.write(
                key: 'user_data',
                value: jsonEncode(data['user']),
              );
              print('✓ Token and user saved to storage');
              return (user, token);
            } else {
              print('✗ Login failed: user is not admin');
              return (user, token);
            }
          } catch (e) {
            print('✗ Error parsing user: $e');
            rethrow;
          }
        } else {
          print('✗ Data is null in response');
        }
      } else {
        print('✗ Invalid status code or no data: ${response.statusCode}');
      }
      return (null, null);
    } catch (e) {
      print('Login error: $e');
      return (null, null);
    }
  }

  @override
  Future<(User?, String?)> googleLogin({
    required String firebaseToken,
    required String email,
    String? name,
    String? photo,
  }) async {
    try {
      final response = await _apiClient.post(
        '/users/google-login',
        data: {
          'firebaseToken': firebaseToken,
          'email': email,
          'name': name,
          'photo': photo,
        },
      );

      print('Google Login Response Status: ${response.statusCode}');
      print('Google Login Response Data: ${response.data}');

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data != null) {
        final responseBody = response.data;
        final data = responseBody is Map<String, dynamic>
            ? responseBody['data'] ?? responseBody
            : null;

        if (data is Map<String, dynamic> && data['user'] != null) {
          final user = User.fromJson(data['user']);
          final token = data['token'] as String?;

          if (token != null && token.isNotEmpty && user.isAdmin) {
            await _storage.write(key: 'auth_token', value: token);
            await _storage.write(
              key: 'user_data',
              value: jsonEncode(data['user']),
            );
          }

          return (user, token);
        }
      }

      return (null, null);
    } catch (e) {
      print('Google login error: $e');
      return (null, null);
    }
  }

  @override
  Future<(bool, String)> sendResetPasswordEmail(String email) async {
    try {
      final response = await _apiClient.post(
        '/users/forgot-password',
        data: {'email': email},
      );

      return _successFromResponse(
        response,
        successMessage:
            'Un code de réinitialisation a été envoyé à votre adresse email.',
      );
    } catch (e) {
      print('Forgot password error: $e');
      return (false, 'Erreur lors de l’envoi du code.');
    }
  }

  @override
  Future<(bool, String)> validateResetCode(
    String email,
    String resetCode,
  ) async {
    try {
      final response = await _apiClient.post(
        '/users/validate-reset-code',
        data: {
          'email': email,
          'resetCode': int.tryParse(resetCode) ?? resetCode,
        },
      );

      return _successFromResponse(
        response,
        successMessage: 'Code vérifié avec succès.',
      );
    } catch (e) {
      print('Validate reset code error: $e');
      return (false, 'Code incorrect.');
    }
  }

  @override
  Future<(bool, String)> resetPassword(
    String email,
    String resetCode,
    String newPassword,
  ) async {
    try {
      final response = await _apiClient.post(
        '/users/reset-password',
        data: {
          'email': email,
          'resetCode': resetCode,
          'newPassword': newPassword,
        },
      );

      return _successFromResponse(
        response,
        successMessage: 'Mot de passe modifié avec succès.',
      );
    } catch (e) {
      print('Reset password error: $e');
      return (false, 'Erreur lors de la modification du mot de passe.');
    }
  }

  (bool, String) _successFromResponse(
    dynamic response, {
    required String successMessage,
  }) {
    final data = response.data;
    final message = data is Map<String, dynamic>
        ? data['message']?.toString() ?? successMessage
        : successMessage;

    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      final bodyStatusCode = data is Map<String, dynamic>
          ? data['statusCode'] as int?
          : null;
      if (bodyStatusCode == null ||
          bodyStatusCode >= 200 && bodyStatusCode < 300) {
        return (true, message);
      }
    }

    return (false, message);
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_data');
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final userData = await _storage.read(key: 'user_data');
      if (userData != null) {
        return User.fromJson(jsonDecode(userData));
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
}
