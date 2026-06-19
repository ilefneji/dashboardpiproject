//task/domain/repositories/task_repository.dart
import '../entities/task.dart';


abstract class TaskRepository {
  Future<List<Task>> getTasks();
  Future<Task?> getTask(int id);
  Future<Task?> createTask(Task task);
  Future<Task?> updateTask(Task task);
  Future<bool> deleteTask(int id);
}

