import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/task_model.dart';
import '../models/sync_operation_model.dart';

class DatabaseService {
  static const String _dbName = 'todo_app.db';
  static const int _dbVersion = 1;

  static const String tableTasks = 'tasks';
  static const String tableSyncQueue = 'sync_queue';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTasks (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        priority TEXT NOT NULL,
        due_date TEXT,
        reminder_at TEXT,
        is_completed INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        sync_status TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableSyncQueue (
        id TEXT PRIMARY KEY,
        operation_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        last_error TEXT
      )
    ''');
  }

  // --- Task Methods ---

  Future<List<TaskModel>> getTasks(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTasks,
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => TaskModel.fromMap(map)).toList();
  }

  Future<void> insertTask(TaskModel task) async {
    final db = await database;
    await db.insert(
      tableTasks,
      task.toLocalDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTask(TaskModel task) async {
    final db = await database;
    await db.update(
      tableTasks,
      task.toLocalDbMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [task.id, task.userId],
    );
  }

  Future<void> softDeleteTask(String id, String userId) async {
    final db = await database;
    await db.update(
      tableTasks,
      {'is_deleted': 1, 'sync_status': 'pending_delete'},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> hardDeleteTask(String id) async {
    final db = await database;
    await db.delete(tableTasks, where: 'id = ?', whereArgs: [id]);
  }

  // --- Sync Queue Methods ---

  Future<void> enqueueSyncOperation(SyncOperation operation) async {
    final db = await database;
    await db.insert(
      tableSyncQueue,
      operation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SyncOperation>> getPendingSyncOperations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableSyncQueue,
      where: 'status = ? OR status = ?',
      whereArgs: [SyncOperation.statusPending, SyncOperation.statusFailed],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => SyncOperation.fromMap(map)).toList();
  }

  Future<void> updateSyncOperation(SyncOperation operation) async {
    final db = await database;
    await db.update(
      tableSyncQueue,
      operation.toMap(),
      where: 'id = ?',
      whereArgs: [operation.id],
    );
  }

  Future<void> removeSyncOperation(String id) async {
    final db = await database;
    await db.delete(tableSyncQueue, where: 'id = ?', whereArgs: [id]);
  }
}
