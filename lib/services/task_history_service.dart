import '../models/task_history_model.dart';
import 'supabase_service.dart';

class TaskHistoryService {
  Future<List<TaskHistoryModel>> getHistory(String taskId) async {
    final response = await SupabaseService.client
        .from('task_history')
        .select()
        .eq('task_id', taskId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((history) => TaskHistoryModel.fromMap(history))
        .toList();
  }
}
