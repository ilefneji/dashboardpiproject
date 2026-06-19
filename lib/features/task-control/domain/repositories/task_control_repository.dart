import '../entities/task_control.dart';

abstract class TaskControlRepository {
  Future<List<TaskControl>> getTaskControls();
  Future<TaskControl?> createTaskControl(TaskControl taskControl);
  Future<bool> updateTaskControl(TaskControl taskControl);
  Future<bool> deleteTaskControl(int id);
}
