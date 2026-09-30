import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:kutchina/core/services/config.dart';

/// Single source of truth for "can I talk to the server right now?".
///
/// Two signals are combined:
///  1. the OS network interface (Wi-Fi / mobile data present) via
///     connectivity_plus, and
///  2. real request outcomes. Wi-Fi with no internet, captive portals and
///     dead mobile data all look "connected" to the OS. When a request
///     fails with a connection error [reportRequestFailure] flips us to
///     offline and a lightweight TCP probe runs until the server answers
///     again.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _probeTimer;

  final StreamController<bool> _changes = StreamController<bool>.broadcast();

  bool _started = false;
  bool _hasInterface = true;
  bool _serverReachable = true;
  bool _lastEmitted = true;

  /// True when the device has a network AND the API server was reachable
  /// on the last attempt.
  bool get isOnline => _hasInterface && _serverReachable;

  /// Emits only when [isOnline] actually changes.
  Stream<bool> get onlineChanges => _changes.stream;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      _hasInterface = _anyInterface(await _connectivity.checkConnectivity());
    } catch (_) {
      _hasInterface = true;
    }
    _lastEmitted = isOnline;
    _sub = _connectivity.onConnectivityChanged.listen(_onInterfaceChanged);
    if (_hasInterface) {
      // Verify the server really answers; do not trust the interface alone.
      unawaited(_probeOnce());
    }
    _notifyIfChanged();
  }

  bool _anyInterface(List<ConnectivityResult> r) =>
      r.any((e) => e != ConnectivityResult.none);

  void _onInterfaceChanged(List<ConnectivityResult> results) {
    final had = _hasInterface;
    _hasInterface = _anyInterface(results);
    if (_hasInterface && !had) {
      // Network came back: assume unreachable until the probe proves
      // otherwise, so we never fire queued requests into a dead link.
      _serverReachable = false;
      unawaited(_probeOnce());
      _startProbeTimer();
    }
    if (!_hasInterface) _stopProbeTimer();
    _notifyIfChanged();
  }

  /// Called by the Dio interceptor when a request could not reach the server.
  void reportRequestFailure() {
    if (_serverReachable) {
      _serverReachable = false;
      _notifyIfChanged();
    }
    if (_hasInterface) _startProbeTimer();
  }

  /// Called by the Dio interceptor whenever the server answered.
  void reportRequestSuccess() {
    if (!_serverReachable) {
      _serverReachable = true;
      _stopProbeTimer();
      _notifyIfChanged();
    }
  }

  /// Force an immediate reachability check (e.g. "Sync now" button).
  Future<bool> recheck() async {
    if (!_hasInterface) return false;
    await _probeOnce();
    return isOnline;
  }

  void _startProbeTimer() {
    _probeTimer ??= Timer.periodic(
      const Duration(seconds: 10),
      (_) => _probeOnce(),
    );
  }

  void _stopProbeTimer() {
    _probeTimer?.cancel();
    _probeTimer = null;
  }

  Future<void> _probeOnce() async {
    if (!_hasInterface) return;
    try {
      final uri = Uri.parse(ApiConfig.baseUrl);
      final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
      final socket = await Socket.connect(
        uri.host,
        port,
        timeout: const Duration(seconds: 4),
      );
      socket.destroy();
      reportRequestSuccess();
    } catch (_) {
      if (_serverReachable) {
        _serverReachable = false;
        _notifyIfChanged();
      }
      _startProbeTimer();
    }
  }

  void _notifyIfChanged() {
    notifyListeners();
    final now = isOnline;
    if (now != _lastEmitted) {
      _lastEmitted = now;
      _changes.add(now);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _stopProbeTimer();
    _changes.close();
    super.dispose();
  }
}
