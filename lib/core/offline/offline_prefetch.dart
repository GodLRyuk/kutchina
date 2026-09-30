import 'package:flutter/foundation.dart';
import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/core/offline/connectivity_service.dart';

/// Warms the offline cache with everything the sales flows need for their
/// dropdowns, so a field visit with no signal still has data even if the
/// user never opened those screens online.
///
/// Every MastersApi fetch goes through ApiService.getCached, so simply
/// calling them stores the responses.
class OfflinePrefetch {
  OfflinePrefetch._();

  static bool _running = false;

  static Future<void> run() async {
    if (_running || !ConnectivityService.instance.isOnline) return;
    _running = true;
    try {
      await Future.wait([
        _safe(MastersApi.fetchDistributors),
        _safe(MastersApi.fetchRetailers),
        _safe(MastersApi.fetchCategories),
        _safe(MastersApi.fetchChannels),
        _safe(MastersApi.fetchZones),
        _safe(MastersApi.fetchProducts),
        _safe(OrderService.fetchOrders),
      ]);
    } finally {
      _running = false;
    }
  }

  static Future<void> _safe(Future<dynamic> Function() call) async {
    try {
      await call();
    } catch (e) {
      if (kDebugMode) debugPrint('prefetch skipped: $e');
    }
  }
}
