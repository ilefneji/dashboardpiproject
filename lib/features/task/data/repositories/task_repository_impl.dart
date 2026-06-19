// task/data/repositories/task_repository_impl.dart

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  final ApiClient _apiClient;

  TaskRepositoryImpl(this._apiClient);

  @override
  Future<List<Task>> getTasks() async {
    try {
      final response = await _apiClient.get('/tasks');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Task.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      print('Error getting tasks: ${e.message}');
      return [];
    } catch (e) {
      print('Unexpected error getting tasks: $e');
      return [];
    }
  }

  @override
  Future<Task?> getTask(int id) async {
    try {
      final response = await _apiClient.get('/tasks/$id');
      if (response.statusCode == 200 && response.data != null) {
        return Task.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      print('Error getting task: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error getting task: $e');
      return null;
    }
  }

  @override
  Future<Task?> createTask(Task task) async {
    try {
      final response = await _apiClient.post(
        '/tasks',
        data: task.toJson(),
      );
      if (response.statusCode == 201 && response.data != null) {
        return Task.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      print('Error creating task: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error creating task: $e');
      return null;
    }
  }

  @override
  Future<Task?> updateTask(Task task) async {
    try {
      final response = await _apiClient.patch(
        '/tasks/${task.id}',
        data: task.toJson(),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Task.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      print('Error updating task: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error updating task: $e');
      return null;
    }
  }

  @override
  Future<bool> deleteTask(int id) async {
    try {
      final response = await _apiClient.delete('/tasks/$id');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error deleting task: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error deleting task: $e');
      return false;
    }
  }
}
