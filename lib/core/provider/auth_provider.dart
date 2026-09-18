import 'package:flutter/foundation.dart';
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
      notifyListeners();
    }
  }

  void setUser(KUser user) {
    _user = user;
    notifyListeners();
  }

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
    notifyListeners();
  }
}
