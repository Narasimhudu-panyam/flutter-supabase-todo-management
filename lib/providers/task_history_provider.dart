import 'package:flutter/material.dart';

import '../models/task_history_model.dart';
import '../repositories/task_history_repository.dart';

class TaskHistoryProvider extends ChangeNotifier {
  final TaskHistoryRepository _repository = TaskHistoryRepository();

  final List<TaskHistoryModel> _history = [];

  bool _isLoading = false;

  List<TaskHistoryModel> get history => List.unmodifiable(_history);

  bool get isLoading => _isLoading;

  Future<void> loadHistory(String taskId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _repository.getHistory(taskId);

      _history
        ..clear()
        ..addAll(data);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
