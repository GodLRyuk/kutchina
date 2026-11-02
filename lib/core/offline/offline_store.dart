import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// One queued write (order, visit, attendance...) waiting for the network.
class PendingRequest {
  final int id;
  final String clientId; // also sent as Idempotency-Key
  final String userId;
  final String kind; // 'order' | 'visit' | 'attendance'
  final String label; // shown in the queue screen
  final String method;
  final String path;
  final dynamic body; // Map or List, JSON-decoded
  final List<String> filePaths; // copied into app storage
  final String fileField;
  final DateTime createdAt;
  final String status; // 'pending' | 'failed'
  final int attempts;
  final String? lastError;

  const PendingRequest({
    required this.id,
    required this.clientId,
    required this.userId,
    required this.kind,
    required this.label,
    required this.method,
    required this.path,
    required this.body,
    required this.filePaths,
    required this.fileField,
    required this.createdAt,
    required this.status,
    required this.attempts,
    required this.lastError,
  });

  bool get isFailed => status == 'failed';

  factory PendingRequest.fromRow(Map<String, Object?> r) {
    final rawBody = r['body'] as String?;
    final rawFiles = r['files'] as String?;
    return PendingRequest(
      id: r['id'] as int,
      clientId: r['client_id'] as String,
      userId: r['user_id'] as String,
      kind: r['kind'] as String,
      label: r['label'] as String,
      method: r['method'] as String,
      path: r['path'] as String,
      body: rawBody == null ? null : jsonDecode(rawBody),
      filePaths: rawFiles == null
          ? const []
          : (jsonDecode(rawFiles) as List).map((e) => e.toString()).toList(),
      fileField: (r['file_field'] as String?) ?? 'image',
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
      status: r['status'] as String,
      attempts: r['attempts'] as int,
      lastError: r['last_error'] as String?,
    );
  }
}

class CachedBody {
  final dynamic body;
  final DateTime savedAt;
  const CachedBody(this.body, this.savedAt);
}

/// SQLite storage for
///  * `api_cache`        last good GET responses (dropdowns, lists)
///  * `pending_requests` writes made while offline
class OfflineStore {
  OfflineStore._();
  static final OfflineStore instance = OfflineStore._();

  /// Set by AuthProvider on login / logout. Cache entries and queued writes
  /// are namespaced by user so two accounts on one phone never see each
  /// other's data.
  static String? userScope;

  static const _maxCacheRows = 400;

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      '$dir/kutchina_offline.db',
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE api_cache(
            cache_key TEXT PRIMARY KEY,
            body      TEXT NOT NULL,
            saved_at  INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE pending_requests(
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            client_id  TEXT NOT NULL,
            user_id    TEXT NOT NULL,
            kind       TEXT NOT NULL,
            label      TEXT NOT NULL,
            method     TEXT NOT NULL,
            path       TEXT NOT NULL,
            body       TEXT,
            files      TEXT,
            file_field TEXT,
            created_at INTEGER NOT NULL,
            status     TEXT NOT NULL DEFAULT 'pending',
            attempts   INTEGER NOT NULL DEFAULT 0,
            last_error TEXT
          )''');
      },
    );
    return _db!;
  }

  // ---------------------------------------------------------------- cache

  static String cacheKey(
    String path,
    Map<String, dynamic>? queryParams,
    dynamic data,
  ) {
    final q = <String>[];
    if (queryParams != null) {
      final keys = queryParams.keys.toList()..sort();
      for (final k in keys) {
        q.add('$k=${queryParams[k]}');
      }
    }
    final d = data == null ? '' : jsonEncode(data);
    return '${userScope ?? 'anon'}|$path|${q.join('&')}|$d';
  }

  Future<void> putCache(String key, dynamic body) async {
    try {
      final db = await _database;
      await db.insert('api_cache', {
        'cache_key': key,
        'body': jsonEncode(body),
        'saved_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      // Keep the cache bounded (paginated admin screens create many keys).
      await db.execute(
        'DELETE FROM api_cache WHERE cache_key NOT IN '
        '(SELECT cache_key FROM api_cache ORDER BY saved_at DESC LIMIT $_maxCacheRows)',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('putCache failed: $e');
    }
  }

  Future<CachedBody?> getCache(String key) async {
    try {
      final db = await _database;
      final rows = await db.query(
        'api_cache',
        where: 'cache_key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return CachedBody(
        jsonDecode(rows.first['body'] as String),
        DateTime.fromMillisecondsSinceEpoch(rows.first['saved_at'] as int),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    final db = await _database;
    await db.delete('api_cache');
  }

  // ---------------------------------------------------------------- queue

  /// Copies picked/camera images out of the temp cache into app storage so
  /// the OS cannot purge them before the upload happens.
  Future<List<String>> persistFiles(
    String clientId,
    List<String> sourcePaths,
  ) async {
    if (sourcePaths.isEmpty) return const [];
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/offline_uploads/$clientId');
    await dir.create(recursive: true);
    final out = <String>[];
    for (var i = 0; i < sourcePaths.length; i++) {
      final src = File(sourcePaths[i]);
      final name = sourcePaths[i].split(Platform.pathSeparator).last;
      final dest = File('${dir.path}/${i}_$name');
      await src.copy(dest.path);
      out.add(dest.path);
    }
    return out;
  }

  Future<void> deleteFiles(PendingRequest r) async {
    if (r.filePaths.isEmpty) return;
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/offline_uploads/${r.clientId}');
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  Future<int> enqueue({
    required String clientId,
    required String userId,
    required String kind,
    required String label,
    required String method,
    required String path,
    required dynamic body,
    List<String> filePaths = const [],
    String fileField = 'image',
  }) async {
    final db = await _database;
    return db.insert('pending_requests', {
      'client_id': clientId,
      'user_id': userId,
      'kind': kind,
      'label': label,
      'method': method,
      'path': path,
      'body': body == null ? null : jsonEncode(body),
      'files': filePaths.isEmpty ? null : jsonEncode(filePaths),
      'file_field': fileField,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'status': 'pending',
      'attempts': 0,
    });
  }

  /// FIFO. Order matters: attendance check-in must reach the server before
  /// the orders and visits that were made after it.
  Future<List<PendingRequest>> listRequests(
    String userId, {
    String? status,
  }) async {
    final db = await _database;
    final rows = await db.query(
      'pending_requests',
      where: status == null ? 'user_id = ?' : 'user_id = ? AND status = ?',
      whereArgs: status == null ? [userId] : [userId, status],
      orderBy: 'id ASC',
    );
    return rows.map(PendingRequest.fromRow).toList();
  }

  Future<int> countRequests(String userId, {String? status}) async {
    final db = await _database;
    final rows = await db.rawQuery(
      status == null
          ? 'SELECT COUNT(*) c FROM pending_requests WHERE user_id = ?'
          : 'SELECT COUNT(*) c FROM pending_requests WHERE user_id = ? AND status = ?',
      status == null ? [userId] : [userId, status],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<void> markFailed(int id, String error) async {
    final db = await _database;
    await db.rawUpdate(
      "UPDATE pending_requests SET status='failed', last_error=?, attempts=attempts+1 WHERE id=?",
      [error, id],
    );
  }

  Future<void> recordAttempt(int id, String error) async {
    final db = await _database;
    await db.rawUpdate(
      'UPDATE pending_requests SET last_error=?, attempts=attempts+1 WHERE id=?',
      [error, id],
    );
  }

  Future<void> resetToPending(int id) async {
    final db = await _database;
    await db.update(
      'pending_requests',
      {'status': 'pending', 'attempts': 0, 'last_error': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteRequest(int id) async {
    final db = await _database;
    await db.delete('pending_requests', where: 'id = ?', whereArgs: [id]);
  }
}
