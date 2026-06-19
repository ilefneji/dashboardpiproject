import '../../../../core/network/api_client.dart';
import '../../domain/entities/task_control.dart';
import '../../domain/repositories/task_control_repository.dart';

class TaskControlRepositoryImpl implements TaskControlRepository {
  final ApiClient _apiClient;

  TaskControlRepositoryImpl(this._apiClient);

  // ─────────────────────────────────────────────
  //  GET ALL
  // ─────────────────────────────────────────────
  @override
  Future<List<TaskControl>> getTaskControls() async {
    try {
      final response = await _apiClient.get('/task-controls');

      if (response.statusCode == 200) {
        List<dynamic> data = [];
        if (response.data is List) {
          data = response.data;
        } else if (response.data is Map) {
          data = response.data['data'] ??
              response.data['taskControls'] ??
              response.data['items'] ??
              [];
        }

        return data.map((json) => TaskControl.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch task controls: $e');
    }
  }

  // ─────────────────────────────────────────────
  //  CREATE
  // ─────────────────────────────────────────────
  @override
  Future<TaskControl?> createTaskControl(TaskControl taskControl) async {
    try {
      final response = await _apiClient.post(   
        '/task-controls',
        data: taskControl.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = (response.data is Map && response.data['data'] != null)
            ? response.data['data']
            : response.data;
        return TaskControl.fromJson(data);

        
      }
      return null;
    } catch (e) {
      throw Exception('Failed to create task control: $e');
    }
  }

  // ─────────────────────────────────────────────
  //  UPDATE
  // ─────────────────────────────────────────────
  @override
  Future<bool> updateTaskControl(TaskControl taskControl) async {
    try {
      final response = await _apiClient.patch(
        '/task-controls/${taskControl.id}',
        data: taskControl.toJson(),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to update task control: $e');
    }
  }

  // ─────────────────────────────────────────────
  //  DELETE
  // ─────────────────────────────────────────────
  @override
  Future<bool> deleteTaskControl(int id) async {
    try {
      final response = await _apiClient.delete('/task-controls/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete task control: $e');
    }
  }
}
