import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskRepository {
  final TaskService _taskService = TaskService();

  Future<List<TaskModel>> getTasks() {
    return _taskService.getTasks();
  }

  Future<void> addTask({required String title, String? description}) {
    return _taskService.addTask(title: title, description: description);
  }

  Future<void> updateTask(TaskModel task) {
    return _taskService.updateTask(task);
  }

  Future<void> deleteTask(String id) {
    return _taskService.deleteTask(id);
  }

  Stream<List<TaskModel>> watchTasks() {
    return _taskService.watchTasks();
  }
}
