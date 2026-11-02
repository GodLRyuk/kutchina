import 'package:flutter/foundation.dart';
import 'package:kutchina/core/offline/offline_store.dart';
import 'package:kutchina/core/offline/sync_service.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/services/auth_api.dart';

class AuthProvider extends ChangeNotifier {
  KUser? _user;
  KUser? get user => _user;
  bool get isLoggedIn => _user != null;

  Future<void> loadFromStorage() async {
    final json = await UserStore.getUser();
    if (json != null) {
      _user = KUser.fromJson(json);
      // Cache + offline queue are namespaced per user.
      OfflineStore.userScope = _user!.id;
      SyncService.instance.refreshCounts();
      notifyListeners();
    }
  }

  void setUser(KUser user) {
    _user = user;
    OfflineStore.userScope = user.id;
    SyncService.instance.refreshCounts();
    notifyListeners();
  }

  /// Logs out. Cached dropdown data and any unsynced offline items are
  /// deliberately kept on the phone (scoped to this user) so nothing the
  /// sales exec entered offline is lost and the app still has data the next
  /// time they open it without network.
  Future<void> logout() async {
    try {
      await TokenStore.clear();
    } catch (_) {
      // Continue clearing the user record even if token storage fails.
    }

    try {
      await UserStore.clear();
    } catch (_) {
      // The in-memory session is still cleared below.
    }

    _user = null;
    OfflineStore.userScope = null;
    notifyListeners();
  }
}
