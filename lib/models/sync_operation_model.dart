class SyncOperation {
  static const typeCreate = 'CREATE';
  static const typeUpdate = 'UPDATE';
  static const typeDelete = 'DELETE';

  static const statusPending = 'PENDING';
  static const statusSyncing = 'SYNCING';
  static const statusFailed = 'FAILED';
  static const statusCompleted = 'COMPLETED';

  final String id;
  final String operationType;
  final String entityType;
  final String entityId;
  final String payload;
  final DateTime createdAt;
  final int retryCount;
  final String status;
  final String? lastError;

  SyncOperation({
    required this.id,
    required this.operationType,
    this.entityType = 'task',
    required this.entityId,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.status = statusPending,
    this.lastError,
  });

  factory SyncOperation.fromMap(Map<String, dynamic> map) {
    return SyncOperation(
      id: map['id'] as String,
      operationType: map['operation_type'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      payload: map['payload'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      retryCount: map['retry_count'] as int? ?? 0,
      status: map['status'] as String? ?? statusPending,
      lastError: map['last_error'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operation_type': operationType,
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'status': status,
      'last_error': lastError,
    };
  }

  SyncOperation copyWith({int? retryCount, String? status, String? lastError}) {
    return SyncOperation(
      id: id,
      operationType: operationType,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
    );
  }
}
