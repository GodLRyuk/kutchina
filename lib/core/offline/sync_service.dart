import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:kutchina/core/offline/connectivity_service.dart';
import 'package:kutchina/core/offline/offline_store.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/services/auth_api.dart';
import 'package:kutchina/core/services/biometric_auth_service.dart';
import 'package:kutchina/core/services/location_address_service.dart';

/// Outcome of [SyncService.submitOrQueue].
enum SubmitResult { sent, queued }

/// Offline write queue.
///
/// * [submitOrQueue] sends right away when online, otherwise (or when the
///   request never reached the server) stores it in SQLite.
/// * [syncNow] replays queued writes in the order they were made. It runs
///   automatically when the connection comes back, when the app returns to
///   the foreground, and on a timer while items are waiting.
class SyncService extends ChangeNotifier with WidgetsBindingObserver {
  SyncService._();
  static final SyncService instance = SyncService._();

  static const _maxAttempts = 5;

  final OfflineStore _store = OfflineStore.instance;
  StreamSubscription<bool>? _connSub;
  Timer? _retryTimer;
  Timer? _messageTimer;
  bool _started = false;

  bool _syncing = false;
  int _pending = 0;
  int _failed = 0;
  String? _message; // short banner text after a sync run
  bool _needsLogin = false;

  bool get isSyncing => _syncing;
  int get pendingCount => _pending;
  int get failedCount => _failed;
  int get totalCount => _pending + _failed;
  String? get message => _message;

  /// True when queued items exist but the session is gone and no saved
  /// fingerprint credentials are available to log in silently.
  bool get needsLogin => _needsLogin;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _connSub = ConnectivityService.instance.onlineChanges.listen((online) {
      if (online) syncNow();
    });
    _retryTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (totalCount > 0 && ConnectivityService.instance.isOnline) {
        syncNow();
      }
    });
    await refreshCounts();
    if (_pending > 0) unawaited(syncNow());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshCounts();
      if (ConnectivityService.instance.isOnline && totalCount > 0) syncNow();
    }
  }

  // ------------------------------------------------------------- identity

  /// Which account's queue to work on. Prefer the logged-in user, fall back
  /// to the last stored session so a queue is never orphaned by a logout.
  Future<String?> _resolveUserId() async {
    if (OfflineStore.userScope != null) return OfflineStore.userScope;
    final u = await UserStore.getUser();
    if (u != null && u['id'] != null) return u['id'].toString();
    final b = await BiometricAuthService.readUserJson();
    if (b != null && b['id'] != null) return b['id'].toString();
    return null;
  }

  Future<void> refreshCounts() async {
    final uid = await _resolveUserId();
    if (uid == null) {
      _pending = 0;
      _failed = 0;
    } else {
      _pending = await _store.countRequests(uid, status: 'pending');
      _failed = await _store.countRequests(uid, status: 'failed');
    }
    notifyListeners();
  }

  Future<List<PendingRequest>> listAll() async {
    final uid = await _resolveUserId();
    if (uid == null) return const [];
    return _store.listRequests(uid);
  }

  // --------------------------------------------------------------- submit

  /// Sends now if possible, otherwise queues.
  ///
  /// [body] is a Map (or a List for bulk endpoints). When [filePaths] is
  /// not empty the request goes out as multipart with each file under
  /// [fileField] (same wire format the app already used for visits).
  ///
  /// Throws [ApiException] for real server rejections (400, 500...) so the
  /// screen can show the message. Only "could not reach the server" is
  /// turned into a queued item.
  Future<SubmitResult> submitOrQueue({
    required String kind,
    required String label,
    required String path,
    required dynamic body,
    List<String> filePaths = const [],
    String fileField = 'image',
  }) async {
    final clientId = _newClientId();

    if (ConnectivityService.instance.isOnline) {
      try {
        await _send(
          path: path,
          body: body,
          filePaths: filePaths,
          fileField: fileField,
          clientId: clientId,
          silent: false,
        );
        return SubmitResult.sent;
      } on ApiException catch (e) {
        // Timed out AFTER connecting is ambiguous (server may have got it):
        // surface the error instead of risking a duplicate order.
        if (!e.notDelivered) rethrow;
      }
    }

    final uid = await _resolveUserId();
    if (uid == null) {
      throw ApiException('Please log in again before working offline.');
    }
    final saved = await _store.persistFiles(clientId, filePaths);
    await _store.enqueue(
      clientId: clientId,
      userId: uid,
      kind: kind,
      label: label,
      method: 'POST',
      path: path,
      body: body,
      filePaths: saved,
      fileField: fileField,
    );
    await refreshCounts();
    return SubmitResult.queued;
  }

  Future<void> _send({
    required String path,
    required dynamic body,
    required List<String> filePaths,
    required String fileField,
    required String clientId,
    required bool silent,
  }) async {
    dynamic data = body;
    if (filePaths.isNotEmpty) {
      final map = Map<String, dynamic>.from(body as Map);
      final parts = <MultipartFile>[];
      for (final p in filePaths) {
        parts.add(
          await MultipartFile.fromFile(
            p,
            filename: p.split(RegExp(r'[\\/]')).last,
          ),
        );
      }
      map[fileField] = parts;
      data = FormData.fromMap(map);
    }
    await ApiService.instance.post(
      path,
      data: data,
      silent: silent,
      // Lets the backend drop a replay if the first attempt did reach it.
      headers: {'Idempotency-Key': clientId},
    );
  }

  // ----------------------------------------------------------------- sync

  Future<void> syncNow({bool manual = false}) async {
    if (_syncing) return;
    final uid = await _resolveUserId();
    if (uid == null) return;

    if (manual) {
      await ConnectivityService.instance.recheck();
    }
    if (!ConnectivityService.instance.isOnline) {
      if (manual) _flash('Still offline. Will retry automatically.');
      return;
    }

    final items = await _store.listRequests(uid, status: 'pending');
    if (items.isEmpty) {
      _needsLogin = false;
      await refreshCounts();
      return;
    }

    _syncing = true;
    _needsLogin = false;
    notifyListeners();

    var sent = 0;
    var failed = 0;
    try {
      if (!await _ensureSession(uid)) {
        _needsLogin = true;
        return;
      }

      for (final item in items) {
        try {
          await _sendQueued(item);
          await _store.deleteRequest(item.id);
          await _store.deleteFiles(item);
          sent++;
        } on ApiException catch (e) {
          if (e.isNetworkError) {
            break; // lost connection again, keep the rest for later
          }
          if (e.statusCode == 401) {
            // Token dead and refresh failed: log in silently once, retry.
            if (await _silentRelogin(uid)) {
              try {
                await _sendQueued(item);
                await _store.deleteRequest(item.id);
                await _store.deleteFiles(item);
                sent++;
                continue;
              } on ApiException catch (e2) {
                if (e2.isNetworkError) break;
                await _store.recordAttempt(item.id, e2.message);
                _needsLogin = true;
                break;
              }
            }
            _needsLogin = true;
            break;
          }
          final code = e.statusCode ?? 0;
          final permanent =
              code >= 400 && code < 500 && code != 408 && code != 429;
          if (permanent || item.attempts + 1 >= _maxAttempts) {
            await _store.markFailed(item.id, e.message);
            failed++;
            continue; // don't let one bad item block the rest
          }
          await _store.recordAttempt(item.id, e.message);
          break; // 5xx: stop, keep order, retry on next tick
        } catch (e) {
          await _store.markFailed(item.id, e.toString());
          failed++;
        }
      }
    } finally {
      _syncing = false;
      await refreshCounts();
      if (sent > 0 || failed > 0) {
        final parts = <String>[];
        if (sent > 0) parts.add('$sent synced');
        if (failed > 0) parts.add('$failed need attention');
        _flash(parts.join(', '));
      }
    }
  }

  Future<void> _sendQueued(PendingRequest item) async {
    dynamic body = item.body;

    if (item.kind == 'visit' && body is Map) {
      body = Map<String, dynamic>.from(body);

      final lat = double.tryParse(body['lat']?.toString() ?? '');
      final long = double.tryParse(body['long']?.toString() ?? '');

      if (lat != null && long != null) {
        final address = await LocationAddressService.getAddress(
          latitude: lat,
          longitude: long,
        );

        if (address != null && address.isNotEmpty) {
          body['address'] = address;
        }
      }
    } else if (item.kind == 'order' && body is List) {
      final updatedOrders = <dynamic>[];

      for (final value in body) {
        if (value is! Map) continue;

        final order = Map<String, dynamic>.from(value);
        final lat = double.tryParse(order['lat']?.toString() ?? '');
        final long = double.tryParse(order['long']?.toString() ?? '');

        if (lat != null && long != null) {
          final address = await LocationAddressService.getAddress(
            latitude: lat,
            longitude: long,
          );

          if (address != null && address.isNotEmpty) {
            order['address'] = address;
          }
        }

        updatedOrders.add(order);
      }

      body = updatedOrders;
    }

    await _send(
      path: item.path,
      body: body,
      filePaths: item.filePaths,
      fileField: item.fileField,
      clientId: item.clientId,
      silent: true,
    );
  }

  Future<dynamic> _prepareBodyForSync(PendingRequest item) async {
    if (item.kind == 'visit') {
      return _prepareVisitBody(item.body);
    }

    if (item.kind == 'order') {
      return _prepareOrderBody(item.body);
    }

    return item.body;
  }

  Future<List<dynamic>> _prepareOrderBody(dynamic rawBody) async {
    if (rawBody is! List) {
      return <dynamic>[];
    }

    final orders = <dynamic>[];

    for (final rawItem in rawBody) {
      final item = Map<String, dynamic>.from(
        rawItem is Map ? rawItem : <String, dynamic>{},
      );

      final lat = double.tryParse(item['lat']?.toString() ?? '');

      final long = double.tryParse(item['long']?.toString() ?? '');

      if (lat != null && long != null) {
        final address = await LocationAddressService.getAddress(
          latitude: lat,
          longitude: long,
        );

        if (address != null && address.isNotEmpty) {
          item['address'] = address;
        }
      }

      orders.add(item);
    }

    return orders;
  }

  Future<Map<String, dynamic>> _prepareVisitBody(dynamic rawBody) async {
    final body = Map<String, dynamic>.from(
      rawBody is Map ? rawBody : <String, dynamic>{},
    );

    final lat = double.tryParse(body['lat']?.toString() ?? '');

    final long = double.tryParse(body['long']?.toString() ?? '');

    if (lat == null || long == null) {
      return body;
    }

    final existingAddress = body['address']?.toString().trim() ?? '';

    // If we already have a proper address, keep it.
    final coordinateAddress = '$lat, $long';

    final onlyCoordinates =
        existingAddress.isEmpty || existingAddress == coordinateAddress;

    if (onlyCoordinates) {
      final address = await LocationAddressService.getAddress(
        latitude: lat,
        longitude: long,
      );

      if (address != null && address.isNotEmpty) {
        body['address'] = address;
      }
    }

    return body;
  }

  /// Makes sure an access token exists. If the session was cleared (logout,
  /// failed refresh) and fingerprint login is on, log in with the stored
  /// credentials, but only for the same account that owns the queue.
  Future<bool> _ensureSession(String uid) async {
    final token = await TokenStore.getAccessToken();
    if (token != null) return true;
    return _silentRelogin(uid);
  }

  Future<bool> _silentRelogin(String uid) async {
    try {
      if (!await BiometricAuthService.isEnabled()) return false;
      final stored = await BiometricAuthService.readUserJson();
      if (stored == null || stored['id']?.toString() != uid) return false;
      final creds = await BiometricAuthService.readCredentials();
      if (creds == null) return false;
      await AuthApi.login(username: creds.userId, password: creds.password);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------- queue actions

  Future<void> retry(PendingRequest item) async {
    await _store.resetToPending(item.id);
    await refreshCounts();
    unawaited(syncNow(manual: true));
  }

  Future<void> discard(PendingRequest item) async {
    await _store.deleteRequest(item.id);
    await _store.deleteFiles(item);
    await refreshCounts();
  }

  // -------------------------------------------------------------- helpers

  void _flash(String text) {
    _message = text;
    notifyListeners();
    _messageTimer?.cancel();
    _messageTimer = Timer(const Duration(seconds: 4), () {
      _message = null;
      notifyListeners();
    });
  }

  static final Random _rng = Random.secure();
  static String _newClientId() {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final rnd = List.generate(
      8,
      (_) => _rng.nextInt(16).toRadixString(16),
    ).join();
    return '$ts-$rnd';
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _retryTimer?.cancel();
    _messageTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<List<PendingRequest>> getPendingByKind(String kind) async {
    final uid = await _resolveUserId();

    if (uid == null) {
      return const [];
    }

    final items = await _store.listRequests(uid, status: 'pending');

    return items.where((item) => item.kind == kind).toList();
  }

  Future<List<PendingRequest>> getFailedByKind(String kind) async {
    final uid = await _resolveUserId();

    if (uid == null) {
      return const [];
    }

    final items = await _store.listRequests(uid, status: 'failed');

    return items.where((item) => item.kind == kind).toList();
  }
}
