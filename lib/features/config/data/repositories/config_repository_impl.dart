import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/config.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/config_repository.dart';

class ConfigRepositoryImpl implements ConfigRepository {
  final ApiClient _apiClient;

  ConfigRepositoryImpl(this._apiClient);

  // ════════════════════════════════════════════
  // ⚙️ Config
  // ════════════════════════════════════════════

  @override
  Future<Config?> getConfig() async {
    try {
      final response = await _apiClient.get('/config/default');
      if (response.statusCode == 200 && response.data != null) {
        return Config.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      _logError('getConfig', e.message);
      return null;
    } catch (e) {
      _logError('getConfig', e);
      return null;
    }
  }

  @override
  Future<bool> updateConfig(Config config) async {
    try {
      final response = await _apiClient.put(
        '/config/price-subscription',
        data: config.toJson(),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      _logError('updateConfig', e.message);
      return false;
    } catch (e) {
      _logError('updateConfig', e);
      return false;
    }
  }

  // ════════════════════════════════════════════
  // 💳 Subscriptions — READ
  // ════════════════════════════════════════════

  @override
  Future<List<SubscriptionModel>> getSubscriptions() async {
    try {
      final response = await _apiClient.get('/subscriptions');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((j) => SubscriptionModel.fromJson(j)).toList();
      }
      return [];
    } on DioException catch (e) {
      _logError('getSubscriptions', e.message);
      return [];
    } catch (e) {
      _logError('getSubscriptions', e);
      return [];
    }
  }

  @override
  Future<SubscriptionModel?> getSubscription(int id) async {
    try {
      final response = await _apiClient.get('/subscriptions/$id');
      if (response.statusCode == 200 && response.data != null) {
        return SubscriptionModel.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      _logError('getSubscription($id)', e.message);
      return null;
    } catch (e) {
      _logError('getSubscription($id)', e);
      return null;
    }
  }

  @override
  Future<List<SubscriptionModel>> getSubscriptionHistory() async {
    try {
      final response = await _apiClient.get('/payment-history');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((j) => SubscriptionModel.fromJson(j)).toList();
      }
      return [];
    } on DioException catch (e) {
      _logError('getSubscriptionHistory', e.message);
      return [];
    } catch (e) {
      _logError('getSubscriptionHistory', e);
      return [];
    }
  }

  @override
  Future<List<SubscriptionModel>> getSubscriptionsByCompany(
      int companyId) async {
    try {
      final response =
          await _apiClient.get('/subscriptions/company/$companyId');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((j) => SubscriptionModel.fromJson(j)).toList();
      }
      return [];
    } on DioException catch (e) {
      _logError('getSubscriptionsByCompany($companyId)', e.message);
      return [];
    } catch (e) {
      _logError('getSubscriptionsByCompany($companyId)', e);
      return [];
    }
  }

  @override
  Future<List<SubscriptionModel>> getSubscriptionsByUser(int userId) async {
    try {
      final response =
          await _apiClient.get('/subscriptions/user?userId=$userId');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((j) => SubscriptionModel.fromJson(j)).toList();
      }
      return [];
    } on DioException catch (e) {
      _logError(
        'getSubscriptionsByUser($userId)',
        {
          'message': e.message,
          'statusCode': e.response?.statusCode,
          'data': e.response?.data,
        },
      );
      return [];
    } catch (e) {
      _logError('getSubscriptionsByUser($userId)', e);
      return [];
    }
  }

  // ════════════════════════════════════════════
  // 💳 Subscriptions — WRITE
  // ════════════════════════════════════════════

  @override
  Future<SubscriptionModel?> createSubscription(
      Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(
        '/subscriptions',
        data: data,
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return SubscriptionModel.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      _logError('createSubscription', e.message);
      return null;
    } catch (e) {
      _logError('createSubscription', e);
      return null;
    }
  }

  @override
  Future<SubscriptionModel?> updateSubscription(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        '/subscriptions/$id',
        data: data,
      );
      if (response.statusCode == 200 && response.data != null) {
        return SubscriptionModel.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      _logError('updateSubscription($id)', e.message);
      return null;
    } catch (e) {
      _logError('updateSubscription($id)', e);
      return null;
    }
  }

  @override
  Future<bool> deleteSubscription(int id) async {
    try {
      final response = await _apiClient.delete('/subscriptions/$id');
      return response.statusCode == 200;
    } on DioException catch (e) {
      _logError('deleteSubscription($id)', e.message);
      return false;
    } catch (e) {
      _logError('deleteSubscription($id)', e);
      return false;
    }
  }

  @override
  Future<bool> cancelSubscription(int id) async {
    try {
      final response = await _apiClient.put(
        '/subscriptions/$id/cancel',
        data: {'cancelAtPeriodEnd': true},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      _logError('cancelSubscription($id)', e.message);
      return false;
    } catch (e) {
      _logError('cancelSubscription($id)', e);
      return false;
    }
  }

  // ════════════════════════════════════════════
  // 🧾 Invoice
  // ════════════════════════════════════════════

  @override
  Future<Uint8List?> downloadInvoice(int id) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiClient.baseUrl,
        responseType: ResponseType.bytes,
        headers: await _apiClient.getHeaders(),
      ));

      final response = await dio.get('/subscriptions/$id/invoice');
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Uint8List;
      }
      return null;
    } on DioException catch (e) {
      _logError('downloadInvoice($id)', e.message);
      return null;
    } catch (e) {
      _logError('downloadInvoice($id)', e);
      return null;
    }
  }

  // ════════════════════════════════════════════
  // 🔧 Private helpers
  // ════════════════════════════════════════════

  void _logError(String method, dynamic message) {
    print('[ConfigRepository] ❌ $method — $message');
  }

@override
Future<String?> createRenewalCheckoutSession({
  required int subscriptionId,
}) async {
  try {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    final apiHeaders = await _apiClient.getHeaders();

    final token =
        apiHeaders['Authorization'] ??
        apiHeaders['authorization'];

    final response = await dio.post(
      'http://192.168.1.68:3005/api/create-renewal-checkout-session',
      data: {
        'subscriptionId': subscriptionId,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': token,
        },
      ),
    );

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data != null) {
      return response.data['url']?.toString();
    }

    _logError(
      'createRenewalCheckoutSession($subscriptionId)',
      {
        'statusCode': response.statusCode,
        'data': response.data,
      },
    );

    return null;
  } on DioException catch (e) {
    _logError(
      'createRenewalCheckoutSession($subscriptionId)',
      {
        'statusCode': e.response?.statusCode,
        'data': e.response?.data,
        'message': e.message,
      },
    );
    return null;
  } catch (e) {
    _logError('createRenewalCheckoutSession($subscriptionId)', e);
    return null;
  }
}

}
