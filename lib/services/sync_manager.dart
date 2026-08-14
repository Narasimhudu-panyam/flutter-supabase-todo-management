import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/sync_operation_model.dart';

import 'database_service.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final DatabaseService _dbService = DatabaseService();
  final SupabaseClient _supabase = Supabase.instance.client;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  void init() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        debugPrint('Connectivity restored. Triggering sync.');
        processQueue();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> enqueueOperation({
    required String operationType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    final operation = SyncOperation(
      id: const Uuid().v4(),
      operationType: operationType,
      entityId: entityId,
      payload: jsonEncode(payload),
      createdAt: DateTime.now(),
    );
    await _dbService.enqueueSyncOperation(operation);

    // Try to sync immediately if enqueued
    processQueue();
  }

  Future<void> processQueue() async {
    if (_isSyncing) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.every((r) => r == ConnectivityResult.none)) {
      debugPrint('Sync aborted: Offline');
      return;
    }

    _isSyncing = true;
    try {
      final pendingOps = await _dbService.getPendingSyncOperations();
      if (pendingOps.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint('Processing ${pendingOps.length} pending sync operations.');

      for (var op in pendingOps) {
        bool success = await _processOperation(op);
        if (success) {
          await _dbService.removeSyncOperation(op.id);

          // Also update local task sync status to synced if it was create/update
          if (op.operationType != SyncOperation.typeDelete) {
            final tasks = await _dbService.getTasks(
              _supabase.auth.currentUser!.id,
            );
            final task = tasks.where((t) => t.id == op.entityId).firstOrNull;
            if (task != null && task.syncStatus != 'synced') {
              await _dbService.updateTask(task.copyWith(syncStatus: 'synced'));
            }
          }
        } else {
          // Increment retry count
          final updatedOp = op.copyWith(
            retryCount: op.retryCount + 1,
            status: op.retryCount >= 5
                ? SyncOperation.statusFailed
                : SyncOperation.statusPending, // Fail after 5 retries
            lastError: 'Sync failed on attempt ${op.retryCount + 1}',
          );
          await _dbService.updateSyncOperation(updatedOp);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _processOperation(SyncOperation op) async {
    try {
      final payloadMap = jsonDecode(op.payload) as Map<String, dynamic>;
      // Ensure we don't send local-only fields
      payloadMap.remove('sync_status');
      payloadMap.remove('is_deleted');

      switch (op.operationType) {
        case SyncOperation.typeCreate:
          await _supabase.from('tasks').upsert(payloadMap);
          break;
        case SyncOperation.typeUpdate:
          await _supabase
              .from('tasks')
              .update(payloadMap)
              .eq('id', op.entityId);
          break;
        case SyncOperation.typeDelete:
          await _supabase.from('tasks').delete().eq('id', op.entityId);
          break;
        default:
          debugPrint('Unknown operation type: ${op.operationType}');
          return true; // Remove unknown operations from queue
      }
      return true;
    } on PostgrestException catch (e) {
      debugPrint('Supabase error during sync: ${e.message}');
      // Idempotency / Conflict handling:
      // If we try to create but it exists, upsert handles it.
      return false; // Retryable
    } catch (e) {
      debugPrint('Unknown error during sync: $e');
      return false; // Retryable
    }
  }
}
