class TaskHistoryModel {
  final String id, taskId, userId, action;
  final Map<String, dynamic>? oldValue, newValue;
  final DateTime changedAt;
  const TaskHistoryModel({required this.id, required this.taskId, required this.userId, required this.action, this.oldValue, this.newValue, required this.changedAt});
  factory TaskHistoryModel.fromMap(Map<String, dynamic> map) => TaskHistoryModel(id: map['id'].toString(), taskId: map['task_id'] as String, userId: map['user_id'] as String, action: map['action'] as String, oldValue: map['old_value'] == null ? null : Map<String, dynamic>.from(map['old_value']), newValue: map['new_value'] == null ? null : Map<String, dynamic>.from(map['new_value']), changedAt: DateTime.parse(map['created_at'] as String));
  Map<String, dynamic> toMap() => {'id': id, 'task_id': taskId, 'user_id': userId, 'action': action, 'old_value': oldValue, 'new_value': newValue, 'created_at': changedAt.toIso8601String()};
}
