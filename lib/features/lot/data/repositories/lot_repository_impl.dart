import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/lot.dart';
import '../../domain/repositories/lot_repository.dart';

class LotRepositoryImpl implements LotRepository {
  final ApiClient _apiClient;

  LotRepositoryImpl(this._apiClient);

  // Helper method for better error logging
  void _logError(String method, dynamic error) {
    if (kDebugMode) {
      log('Error in LotRepositoryImpl.$method: ${error.toString()}', name: 'LotRepository');
      
      if (error is DioException) {
        log('Request: ${error.requestOptions.uri}', name: 'LotRepository');
        log('Request data: ${error.requestOptions.data}', name: 'LotRepository');
        log('Response: ${error.response?.data}', name: 'LotRepository');
        log('Status code: ${error.response?.statusCode}', name: 'LotRepository');
      }
    }
  }

  @override
  Future<List<Lot>> getLots() async {
    try {
      final response = await _apiClient.get('/lots');
      
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> lotsJson = response.data['data'];
        return lotsJson.map((json) => Lot.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      _logError('getLots', e);
      return [];
    } catch (e) {
      _logError('getLots', e);
      return [];
    }
  }

  @override
  Future<Lot?> getLot(int id) async {
    try {
      final response = await _apiClient.get('/lots/$id');
      
      if (response.statusCode == 200 && response.data != null) {
        return Lot.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      _logError('getLot', e);
      return null;
    } catch (e) {
      _logError('getLot', e);
      return null;
    }
  }

  @override
  Future<Lot?> createLot(Lot lot) async {
    try {
      final response = await _apiClient.post(
        '/lots',
        data: lot.toJson(),
      );
      
      if (response.statusCode == 201 && response.data != null) {
        return Lot.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      _logError('createLot', e);
      return null;
    } catch (e) {
      _logError('createLot', e);
      return null;
    }
  }

  @override
  Future<bool> updateLot(Lot lot) async {
    try {
      final response = await _apiClient.patch(
        '/lots/${lot.id}',
        data: lot.toJson(),
      );
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      _logError('updateLot', e);
      return false;
    } catch (e) {
      _logError('updateLot', e);
      return false;
    }
  }

  @override
  Future<bool> deleteLot(int id) async {
    try {
      final response = await _apiClient.delete('/lots/$id');
      print('deleteLot status=${response.statusCode} body=${response.data}');
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      _logError('deleteLot', e);
      return false;
    } catch (e) {
      _logError('deleteLot', e);
      return false;
    }
  }
  
  @override
  Future<bool> affectTask(int lotId, int taskId) async {
    try {
      final response = await _apiClient.post(
        '/lots/$lotId/affect-task',
        data: {"taskId": taskId},
      );
      
      return response.statusCode == 201;
    } on DioException catch (e) {
      _logError('affectTask', e);
      return false;
    } catch (e) {
      _logError('affectTask', e);
      return false;
    }
  }
  
  @override
  Future<bool> affectTasks(int lotId, List<int> taskIds) async {
    try {
      // Ensure we're sending non-empty list
      if (taskIds.isEmpty) {
        if (kDebugMode) {
          print('Warning: Attempting to affect tasks with empty taskIds list');
        }
        return false;
      }
      
      if (kDebugMode) {
        print('Sending affect-tasks request: /lots/$lotId/affect-tasks');
        print('Request data: {"taskIds": $taskIds}');
      }
      
      final response = await _apiClient.post(
        '/lots/$lotId/affect-tasks',
        data: {"taskIds": taskIds},
      );
      
      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response data: ${response.data}');
      }
      
      // Accept both 200 and 201 as success codes
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      _logError('affectTasks', e);
      if (kDebugMode) {
        print('DioException in affectTasks:');
        print('Request data: {"taskIds": $taskIds}');
        print('Error type: ${e.type}');
        print('Error message: ${e.message}');
        if (e.response != null) {
          print('Response status: ${e.response?.statusCode}');
          print('Response data: ${e.response?.data}');
        }
      }
      return false;
    } catch (e) {
      _logError('affectTasks', e);
      return false;
    }
  }
  
  @override
  Future<bool> removeTask(int lotId, int taskId) async {
    try {
      if (kDebugMode) {
        print('Sending remove-task request: /lots/$lotId/remove-task');
        print('Request data: {"taskId": $taskId}');
      }
      
      // Since there might not be a specific API endpoint for removing tasks,
      // we'll use a DELETE request to the task-specific endpoint
      final response = await _apiClient.delete(
        '/lots/$lotId/tasks/$taskId',
      );
      
      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response data: ${response.data}');
      }
      
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      _logError('removeTask', e);
      return false;
    } catch (e) {
      _logError('removeTask', e);
      return false;
    }
  }
  
  @override
  Future<bool> syncTasks(int lotId, List<int> taskIds) async {
    try {
      if (kDebugMode) {
        print('Sending sync-tasks request: /lots/$lotId/sync-tasks');
        print('Request data: {"taskIds": $taskIds}');
      }
      
      // Use PUT method to replace the entire collection of tasks
      final response = await _apiClient.put(
        '/lots/$lotId/sync-tasks',
        data: {"taskIds": taskIds},
      );
      
      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response data: ${response.data}');
      }
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      _logError('syncTasks', e);
      if (kDebugMode) {
        print('DioException in syncTasks:');
        print('Request data: {"taskIds": $taskIds}');
        if (e.response != null) {
          print('Response status: ${e.response?.statusCode}');
          print('Response data: ${e.response?.data}');
        }
      }
      return false;
    } catch (e) {
      _logError('syncTasks', e);
      return false;
    }
  }
}
