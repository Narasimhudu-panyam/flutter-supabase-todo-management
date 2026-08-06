import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task_model.dart';

class TaskService {
  final _supabase = Supabase.instance.client;

  Future<List<TaskModel>> getTasks() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return [];

    final response = await _supabase
        .from('tasks')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return response.map<TaskModel>((task) => TaskModel.fromMap(task)).toList();
  }

  Future<void> addTask({required String title, String? description}) async {
    final user = _supabase.auth.currentUser;

    if (user == null) return;

    await _supabase.from('tasks').insert({
      'title': title,
      'description': description,
      'user_id': user.id,
      'is_completed': false,
    });
  }

  Future<void> updateTask(TaskModel task) async {
    await _supabase
        .from('tasks')
        .update({
          'title': task.title,
          'description': task.description,
          'is_completed': task.isCompleted,
        })
        .eq('id', task.id);
  }

  Future<void> deleteTask(String id) async {
    await _supabase.from('tasks').delete().eq('id', id);
  }

  Stream<List<TaskModel>> watchTasks() {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at')
        .map((data) => data.map((task) => TaskModel.fromMap(task)).toList());
  }
}
