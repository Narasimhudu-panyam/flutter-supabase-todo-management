import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/task_model.dart';
import '../models/sync_operation_model.dart';
import '../services/database_service.dart';
import '../services/sync_manager.dart';
import '../services/task_service.dart';
import '../services/notification_service.dart';

class TaskRepository {
  final DatabaseService _dbService = DatabaseService();
  final SyncManager _syncManager = SyncManager();
  final TaskService _remoteService = TaskService();
  final NotificationService _notificationService = NotificationService();
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<TaskModel>> getTasks() async {
    final user = _requireUser();

    // Attempt to trigger a sync in the background
    _syncManager.processQueue();

    // Always return local tasks for immediate offline-first UI
    return await _dbService.getTasks(user.id);
  }

  Stream<List<TaskModel>> watchTasks() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value(const []);

    // We still watch Supabase realtime. When a change comes from remote,
    // we save it to the local DB. The provider will then reload from local DB.
    final remoteStream = _remoteService.watchTasks();

    // We don't yield directly from remoteStream, we use a custom stream controller
    // that fetches from local DB when remote changes occur.
    // However, to keep it simple and match the provider's expectation, we can just
    // yield the local DB tasks whenever the remote stream emits.
    return remoteStream.asyncMap((remoteTasks) async {
      for (var task in remoteTasks) {
        // Last write wins: check local task updatedAt
        final localTasks = await _dbService.getTasks(user.id);
        final localTask = localTasks.where((t) => t.id == task.id).firstOrNull;

        if (localTask == null ||
            localTask.updatedAt == null ||
            task.updatedAt == null ||
            task.updatedAt!.isAfter(localTask.updatedAt!)) {
          await _dbService.insertTask(
            task.copyWith(syncStatus: 'synced', isDeleted: false),
          );
          // Schedule notification if reminder is set and in the future
          if (task.reminderAt != null) {
            await _notificationService.scheduleTaskReminder(
              task.id,
              task.title,
              task.reminderAt!,
            );
          } else {
            await _notificationService.cancelTaskReminder(task.id);
          }
        }
      }
      return await _dbService.getTasks(user.id);
    });
  }

  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    DateTime? reminderAt,
    required String priority,
    required String status,
  }) async {
    final user = _requireUser();
    final taskId = const Uuid().v4();
    final now = DateTime.now();

    final task = TaskModel(
      id: taskId,
      title: title.trim(),
      description: description?.trim().isEmpty ?? true
          ? null
          : description!.trim(),
      status: status,
      priority: priority,
      dueDate: dueDate,
      reminderAt: reminderAt,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      userId: user.id,
      syncStatus: 'pending_create',
      isDeleted: false,
    );

    // 1. Save locally
    await _dbService.insertTask(task);

    // 2. Schedule notification if needed
    if (reminderAt != null) {
      await _notificationService.scheduleTaskReminder(
        taskId,
        title,
        reminderAt,
      );
    }

    // 3. Enqueue sync
    await _syncManager.enqueueOperation(
      operationType: SyncOperation.typeCreate,
      entityId: taskId,
      payload: task.toUpdateMap()
        ..addAll({
          'id': taskId,
          'user_id': user.id,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        }),
    );
  }

  Future<void> updateTask(TaskModel task) async {
    _requireUser(); // Ensure authenticated
    final updatedTask = task.copyWith(
      updatedAt: DateTime.now(),
      syncStatus: 'pending_update',
    );

    // 1. Save locally
    await _dbService.updateTask(updatedTask);

    // 2. Reschedule notification if needed
    if (updatedTask.reminderAt != null) {
      await _notificationService.rescheduleTaskReminder(
        updatedTask.id,
        updatedTask.title,
        updatedTask.reminderAt!,
      );
    } else {
      await _notificationService.cancelTaskReminder(updatedTask.id);
    }

    // 3. Enqueue sync
    await _syncManager.enqueueOperation(
      operationType: SyncOperation.typeUpdate,
      entityId: updatedTask.id,
      payload: updatedTask.toUpdateMap()
        ..addAll({'updated_at': updatedTask.updatedAt!.toIso8601String()}),
    );
  }

  Future<void> deleteTask(String id) async {
    final user = _requireUser();

    // 1. Soft delete locally
    await _dbService.softDeleteTask(id, user.id);

    // 2. Cancel notification
    await _notificationService.cancelTaskReminder(id);

    // 3. Enqueue sync
    await _syncManager.enqueueOperation(
      operationType: SyncOperation.typeDelete,
      entityId: id,
      payload: {},
    );
  }

  User _requireUser() {
    final user = _supabase.auth.currentUser;
    if (user == null) throw StateError('No authenticated Supabase user.');
    return user;
  }
}
