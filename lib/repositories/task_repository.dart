import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskRepository {
  final TaskService _service = TaskService();
  Future<List<TaskModel>> getTasks() => _service.getTasks();
  Stream<List<TaskModel>> watchTasks() => _service.watchTasks();
  Future<void> addTask({required String title, String? description, DateTime? dueDate, required String priority, required String status}) =>
      _service.addTask(title: title, description: description, dueDate: dueDate, priority: priority, status: status);
  Future<void> updateTask(TaskModel task) => _service.updateTask(task);
  Future<void> deleteTask(String id) => _service.deleteTask(id);
}
