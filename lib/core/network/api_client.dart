import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' as getProvider;
import '../theme/app_colors.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:3000';
  static const Duration defaultTimeout =
      Duration(seconds: 30); // Increased timeout
  static const int maxRetries = 3;

  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient()
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          contentType: 'application/json',
          responseType: ResponseType.json,
          validateStatus: (status) => status != null && status < 500,
          connectTimeout: defaultTimeout,
          receiveTimeout: defaultTimeout,
          sendTimeout: defaultTimeout,
          followRedirects: true,
          receiveDataWhenStatusError: true,
        )) {
    // Add logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));

    // Add retry interceptor
    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      logPrint: print,
      retries: maxRetries,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 3),
      ],
      retryableExtraStatuses: {
        408,
        429
      }, // Retry on timeout and too many requests
    ));

    // Add response interceptor to handle token expiration
    _dio.interceptors.add(InterceptorsWrapper(
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired, clear storage and redirect to login
          await _handleTokenExpiration();
          return handler.reject(error);
        }
        return handler.next(error);
      },
    ));
  }

  Future<Map<String, String>> get _defaultHeaders async {
    final Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    // Add bearer token if available
    final token = await _storage.read(key: 'auth_token');
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Public method to get headers for external use
  Future<Map<String, String>> getHeaders() async {
    return await _defaultHeaders;
  }

  Future<Response> post(String path,
      {dynamic data, Map<String, String>? headers}) async {
    try {
      final defaultHeaders = await _defaultHeaders;
      final response = await _dio.post(
        path,
        data: data,
        options: Options(
          headers: {...defaultHeaders, ...?headers},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 401) {
        await _handleTokenExpiration();
      }
      return response;
    } on DioException catch (e) {
      await _handleDioError(e);
      if (e.type == DioExceptionType.connectionError) {
        throw DioException(
          requestOptions: e.requestOptions,
          error:
              'Impossible de se connecter au serveur API. Verifiez que le backend est lance sur $baseUrl.',
          type: e.type,
        );
      }
      rethrow;
    } catch (e) {
      print('Unexpected error during POST request: $e');
      rethrow;
    }
  }

  Future<Response> uploadFile(String path,
      {required String filePath, String fieldName = 'file'}) async {
    try {
      final defaultHeaders = await _defaultHeaders;
      final uploadHeaders = Map<String, String>.from(defaultHeaders)
        ..remove('Content-Type');
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: uploadHeaders,
          contentType: 'multipart/form-data',
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 401) {
        await _handleTokenExpiration();
      }
      return response;
    } on DioException catch (e) {
      await _handleDioError(e);
      rethrow;
    } catch (e) {
      print('Unexpected error during file upload: $e');
      rethrow;
    }
  }

  Future<Response> uploadFileBytes(
    String path, {
    required Uint8List bytes,
    required String fileName,
    String fieldName = 'file',
  }) async {
    try {
      final defaultHeaders = await _defaultHeaders;
      final uploadHeaders = Map<String, String>.from(defaultHeaders)
        ..remove('Content-Type');
      final formData = FormData.fromMap({
        fieldName: MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: uploadHeaders,
          contentType: 'multipart/form-data',
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 401) {
        await _handleTokenExpiration();
      }
      return response;
    } on DioException catch (e) {
      await _handleDioError(e);
      rethrow;
    } catch (e) {
      print('Unexpected error during byte file upload: $e');
      rethrow;
    }
  }

  Future<Response> get(String path, {Map<String, String>? headers}) async {
    try {
      final defaultHeaders = await _defaultHeaders;
      final response = await _dio.get(
        path,
        options: Options(
          headers: {...defaultHeaders, ...?headers},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 401) {
        await _handleTokenExpiration();
      }
      return response;
    } on DioException catch (e) {
      await _handleDioError(e);
      if (e.type == DioExceptionType.connectionError) {
        throw DioException(
          requestOptions: e.requestOptions,
          error:
              'Impossible de se connecter au serveur API. Verifiez que le backend est lance sur $baseUrl.',
          type: e.type,
        );
      }
      rethrow;
    } catch (e) {
      print('Unexpected error during GET request: $e');
      rethrow;
    }
  }

  Future<Uint8List?> getImageBytes(String imageId) async {
    try {
      final defaultHeaders = await _defaultHeaders;
      final response = await _dio.get(
        '/files/$imageId',
        options: Options(
          headers: defaultHeaders,
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 200 && response.data is List<int>) {
        return Uint8List.fromList(response.data as List<int>);
      }
      if (response.statusCode == 401) {
        await _handleTokenExpiration();
      }
      return null;
    } on DioException catch (e) {
      await _handleDioError(e);
      return null;
    } catch (e) {
      print('Unexpected error during image GET request: $e');
      return null;
    }
  }

  Future<Response> put(String path,
      {dynamic data, Map<String, String>? headers}) async {
    try {
      final defaultHeaders = await _defaultHeaders;
      final response = await _dio.put(
        path,
        data: data,
        options: Options(
          headers: {...defaultHeaders, ...?headers},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 401) {
        await _handleTokenExpiration();
      }
      return response;
    } on DioException catch (e) {
      await _handleDioError(e);
      if (e.type == DioExceptionType.connectionError) {
        throw DioException(
          requestOptions: e.requestOptions,
          error:
              'Impossible de se connecter au serveur API. Verifiez que le backend est lance sur $baseUrl.',
          type: e.type,
        );
      }
      rethrow;
    } catch (e) {
      print('Unexpected error during PUT request: $e');
      rethrow;
    }
  }

  Future<Response> patch(String path,
      {dynamic data, Map<String, String>? headers}) async {
    try {
      final defaultHeaders = await _defaultHeaders;
      final response = await _dio.patch(
        path,
        data: data,
        options: Options(
          headers: {...defaultHeaders, ...?headers},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 401) {
        await _handleTokenExpiration();
      }
      return response;
    } on DioException catch (e) {
      await _handleDioError(e);
      if (e.type == DioExceptionType.connectionError) {
        throw DioException(
          requestOptions: e.requestOptions,
          error:
              'Impossible de se connecter au serveur API. Verifiez que le backend est lance sur $baseUrl.',
          type: e.type,
        );
      }
      rethrow;
    } catch (e) {
      print('Unexpected error during PATCH request: $e');
      rethrow;
    }
  }

  Future<Response> delete(String path, {Map<String, String>? headers}) async {
    try {
      final defaultHeaders = await _defaultHeaders;
      final response = await _dio.delete(
        path,
        options: Options(
          headers: {...defaultHeaders, ...?headers},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 401) {
        await _handleTokenExpiration();
      }
      return response;
    } on DioException catch (e) {
      await _handleDioError(e);
      if (e.type == DioExceptionType.connectionError) {
        throw DioException(
          requestOptions: e.requestOptions,
          error:
              'Impossible de se connecter au serveur API. Verifiez que le backend est lance sur $baseUrl.',
          type: e.type,
        );
      }
      rethrow;
    } catch (e) {
      print('Unexpected error during DELETE request: $e');
      rethrow;
    }
  }

  Future<void> _handleDioError(DioException e) async {
    print('DioException:');
    print('  Type: ${e.type}');
    print('  Message: ${e.message}');
    print('  Status code: ${e.response?.statusCode}');
    print('  Response data: ${e.response?.data}');
    print('  Request: ${e.requestOptions.uri}');

    // Handle token expiration
    if (e.response?.statusCode == 401) {
      await _handleTokenExpiration();
    }
  }

  Future<void> _handleTokenExpiration() async {
    print('Token expired, clearing data and redirecting to login');
    // Clear all saved data
    await _storage.deleteAll();

    // Redirect to login page
    if (getProvider.Get.currentRoute != '/login') {
      getProvider.Get.offAllNamed('/login');
      getProvider.Get.snackbar(
        'session_expired'.tr,
        'please_login_again'.tr,
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
        snackPosition: getProvider.SnackPosition.TOP,
        duration: const Duration(seconds: 5),
      );
    }
  }
}
