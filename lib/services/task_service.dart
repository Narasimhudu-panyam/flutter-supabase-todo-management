import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task_model.dart';

class TaskService {
  TaskService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<TaskModel>> getTasks() async {
    final user = _requireUser();
    final response = await _client
        .from('tasks')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return (response as List)
        .map((row) => TaskModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    required String priority,
    required String status,
  }) async {
    final user = _requireUser();
    final normalizedPriority = priority.trim().toLowerCase();
    final normalizedStatus = status.trim().toLowerCase();
    _validateValues(normalizedPriority, normalizedStatus);
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) throw ArgumentError.value(title, 'title');
    final task = <String, dynamic>{
      'user_id': user.id,
      'title': normalizedTitle,
      'description': description?.trim().isEmpty ?? true
          ? null
          : description!.trim(),
      'status': normalizedStatus,
      'priority': normalizedPriority,
      'due_date': dueDate?.toIso8601String(),
      'is_completed': false,
    };
    debugPrint('========== ADD TASK ==========');
    task.forEach((key, value) => debugPrint('$key: $value'));
    try {
      await _client.from('tasks').insert(task);
      debugPrint('Task inserted successfully.');
    } on PostgrestException catch (error, stackTrace) {
      debugPrint(
        'ADD TASK DATABASE ERROR: ${error.message} (code: ${error.code}, details: ${error.details}, hint: ${error.hint})',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateTask(TaskModel task) async {
    final user = _requireUser();
    _validateValues(task.priority, task.status);
    await _client
        .from('tasks')
        .update(task.toUpdateMap())
        .eq('id', task.id)
        .eq('user_id', user.id);
  }

  Future<void> deleteTask(String id) async {
    final user = _requireUser();
    await _client.from('tasks').delete().eq('id', id).eq('user_id', user.id);
  }

  Stream<List<TaskModel>> watchTasks() {
    final user = _client.auth.currentUser;
    if (user == null) return Stream.value(const []);
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map((row) => TaskModel.fromMap(Map<String, dynamic>.from(row)))
              .toList(),
        );
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('No authenticated Supabase user.');
    return user;
  }

  void _validateValues(String priority, String status) {
    if (!TaskModel.priorities.contains(priority)) {
      throw ArgumentError.value(priority, 'priority', 'Unsupported priority');
    }
    if (!TaskModel.statuses.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Unsupported status');
    }
  }
}
