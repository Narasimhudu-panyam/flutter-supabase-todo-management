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
  final DateTime? reminderAt;
  final DateTime? updatedAt;
  final bool isCompleted;
  final DateTime createdAt;

  // Local-only fields for offline support
  final String
  syncStatus; // 'synced', 'pending_create', 'pending_update', 'pending_delete'
  final bool isDeleted; // soft-delete for local DB

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    this.reminderAt,
    required this.isCompleted,
    required this.createdAt,
    this.updatedAt,
    required this.userId,
    this.syncStatus = 'synced',
    this.isDeleted = false,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: (map['status'] as String?) ?? 'pending',
      priority: (map['priority'] as String?) ?? 'medium',
      dueDate: map['due_date'] == null
          ? null
          : DateTime.parse(map['due_date'] as String),
      reminderAt: map['reminder_at'] == null
          ? null
          : DateTime.parse(map['reminder_at'] as String),
      isCompleted: (map['is_completed'] == 1 || map['is_completed'] == true),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.parse(map['updated_at'] as String),
      userId: map['user_id'] as String,
      syncStatus: (map['sync_status'] as String?) ?? 'synced',
      isDeleted: (map['is_deleted'] == 1 || map['is_deleted'] == true),
    );
  }

  @override
  String toString() =>
      'TaskModel(id: $id, title: $title, userId: $userId, status: $status, '
      'priority: $priority, completed: $isCompleted, syncStatus: $syncStatus, isDeleted: $isDeleted)';

  Map<String, dynamic> toUpdateMap() => {
    'title': title.trim(),
    'description': description?.trim().isEmpty ?? true
        ? null
        : description!.trim(),
    'status': status,
    'priority': priority,
    'due_date': dueDate?.toIso8601String(),
    'reminder_at': reminderAt?.toIso8601String(),
    'is_completed': isCompleted,
  };

  Map<String, dynamic> toLocalDbMap() {
    final map = toUpdateMap();
    map['id'] = id;
    map['user_id'] = userId;
    map['created_at'] = createdAt.toIso8601String();
    if (updatedAt != null) map['updated_at'] = updatedAt!.toIso8601String();
    map['sync_status'] = syncStatus;
    map['is_deleted'] = isDeleted ? 1 : 0;
    map['is_completed'] = isCompleted ? 1 : 0;
    return map;
  }

  TaskModel copyWith({
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? reminderAt,
    bool clearReminderAt = false,
    bool? isCompleted,
    DateTime? updatedAt,
    String? syncStatus,
    bool? isDeleted,
  }) => TaskModel(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
    reminderAt: clearReminderAt ? null : reminderAt ?? this.reminderAt,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    userId: userId,
    syncStatus: syncStatus ?? this.syncStatus,
    isDeleted: isDeleted ?? this.isDeleted,
  );
}
