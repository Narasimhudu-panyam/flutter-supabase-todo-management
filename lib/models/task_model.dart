import 'package:flutter/foundation.dart';

class TaskModel {
  static const priorities = {'low', 'medium', 'high'};
  static const statuses = {'pending', 'in_progress', 'completed'};

  final String id;
  final String title;
  final String status;
  final String priority;
  final String userId;
  final String? description;
  final DateTime? dueDate;
  final DateTime? updatedAt;
  final bool isCompleted;
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.isCompleted,
    required this.createdAt,
    this.updatedAt,
    required this.userId,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    debugPrint('TASK MODEL RAW MAP: $map');
    final task = TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: (map['status'] as String?) ?? 'pending',
      priority: (map['priority'] as String?) ?? 'medium',
      dueDate: map['due_date'] == null
          ? null
          : DateTime.parse(map['due_date'] as String),
      isCompleted: (map['is_completed'] as bool?) ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.parse(map['updated_at'] as String),
      userId: map['user_id'] as String,
    );
    debugPrint('TASK MODEL PARSED: $task');
    return task;
  }

  @override
  String toString() =>
      'TaskModel(id: $id, title: $title, userId: $userId, status: $status, '
      'priority: $priority, completed: $isCompleted)';

  Map<String, dynamic> toUpdateMap() => {
        'title': title.trim(),
        'description': description?.trim().isEmpty ?? true
            ? null
            : description!.trim(),
        'status': status,
        'priority': priority,
        'due_date': dueDate?.toIso8601String(),
        'is_completed': isCompleted,
      };

  TaskModel copyWith({
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? isCompleted,
    DateTime? updatedAt,
  }) =>
      TaskModel(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        userId: userId,
      );
}
