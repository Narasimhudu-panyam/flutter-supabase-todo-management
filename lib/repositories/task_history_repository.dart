import '../models/task_history_model.dart';
import '../services/task_history_service.dart';

class TaskHistoryRepository {
  final TaskHistoryService _service = TaskHistoryService();

  Future<List<TaskHistoryModel>> getHistory(String taskId) {
    return _service.getHistory(taskId);
  }
}
