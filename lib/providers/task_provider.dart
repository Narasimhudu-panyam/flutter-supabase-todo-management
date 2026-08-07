import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task_model.dart';
import '../repositories/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repository = TaskRepository();

  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<TaskModel>>? _subscription;
  String? _listeningUserId;
  int _loadRequestId = 0;
  bool _realtimeRefreshQueued = false;

  List<TaskModel> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTasks({String source = 'manual'}) async {
    final requestId = ++_loadRequestId;
    debugPrint('TASK LOAD [$source #$requestId]: started');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final loadedTasks = await _repository.getTasks();
      if (requestId != _loadRequestId) {
        debugPrint('TASK LOAD [$source #$requestId]: ignored stale response');
        return;
      }
      _replaceTasks(loadedTasks, source: 'REST $source #$requestId');
    } catch (error, stackTrace) {
      debugPrint('TASK LOAD [$source #$requestId] ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (requestId == _loadRequestId) {
        _error = 'Could not load tasks. Please try again.';
      }
    } finally {
      if (requestId == _loadRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> startListening() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('TASK REALTIME: not started because there is no signed-in user');
      return;
    }

    if (_subscription != null && _listeningUserId == user.id) {
      debugPrint('TASK REALTIME: already listening for user ${user.id}');
      return;
    }

    await _subscription?.cancel();
    _listeningUserId = user.id;
    debugPrint('TASK REALTIME: subscribing for user ${user.id}');
    _subscription = _repository.watchTasks().listen(
      (streamTasks) {
        debugPrint(
          'TASK REALTIME: received ${streamTasks.length} parsed task(s): '
          '${streamTasks.map((task) => task.toString()).join(', ')}',
        );
        // Stream snapshots can arrive after a newer REST request. Use them as
        // a notification and reload from the authoritative REST query instead
        // of allowing a stale snapshot to replace the visible task list.
        _queueRealtimeRefresh();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('TASK REALTIME ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
        _error = 'Realtime updates are temporarily unavailable.';
        notifyListeners();
      },
    );

    await loadTasks(source: 'initial');
  }

  void _queueRealtimeRefresh() {
    if (_realtimeRefreshQueued) {
      debugPrint('TASK REALTIME: refresh already queued');
      return;
    }
    _realtimeRefreshQueued = true;
    Future<void>(() async {
      try {
        await loadTasks(source: 'realtime');
      } finally {
        _realtimeRefreshQueued = false;
      }
    });
  }

  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    required String priority,
    required String status,
  }) async {
    await _repository.addTask(
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      status: status,
    );
    await loadTasks(source: 'addTask');
  }

  Future<void> updateTask(TaskModel task) async {
    await _repository.updateTask(task);
    await loadTasks(source: 'updateTask');
  }

  Future<void> toggleCompleted(TaskModel task) =>
      updateTask(task.copyWith(isCompleted: !task.isCompleted));

  Future<void> deleteTask(String id) async {
    debugPrint('TASK DELETE REQUESTED for task $id');
    debugPrintStack(label: 'TASK DELETE CALLER');
    await _repository.deleteTask(id);
    await loadTasks(source: 'deleteTask');
  }

  void _replaceTasks(List<TaskModel> tasks, {required String source}) {
    debugPrint(
      'TASK LIST REPLACED by $source: ${_tasks.length} -> ${tasks.length} task(s). '
      'IDs: ${tasks.map((task) => task.id).join(', ')}',
    );
    _tasks = tasks;
    _error = null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
