import 'dart:async';

import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../repositories/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repository = TaskRepository();

  List<TaskModel> _tasks = [];
  bool _isLoading = false;

  StreamSubscription<List<TaskModel>>? _subscription;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _repository.getTasks();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startListening() {
    _subscription?.cancel();

    _subscription = _repository.watchTasks().listen((tasks) {
      _tasks = tasks;
      notifyListeners();
    });
  }

  Future<void> addTask({required String title, String? description}) async {
    await _repository.addTask(title: title, description: description);
  }

  Future<void> updateTask(TaskModel task) async {
    await _repository.updateTask(task);
  }

  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
