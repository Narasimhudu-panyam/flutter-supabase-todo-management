class TaskHistoryModel {
  final int id;
  final String taskId;
  final String userId;
  final String action;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final DateTime changedAt;

  const TaskHistoryModel({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.action,
    this.oldValue,
    this.newValue,
    required this.changedAt,
  });

  factory TaskHistoryModel.fromMap(Map<String, dynamic> map) {
    return TaskHistoryModel(
      id: map['id'] as int,
      taskId: map['task_id'] as String,
      userId: map['user_id'] as String,
      action: map['action'] as String,
      oldValue: map['old_value'] != null
          ? Map<String, dynamic>.from(map['old_value'])
          : null,
      newValue: map['new_value'] != null
          ? Map<String, dynamic>.from(map['new_value'])
          : null,
      changedAt: DateTime.parse(map['changed_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'action': action,
      'old_value': oldValue,
      'new_value': newValue,
      'changed_at': changedAt.toIso8601String(),
    };
  }
}
