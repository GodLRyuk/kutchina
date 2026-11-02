import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class StoredCredentials {
  final String userId;
  final String password;
  const StoredCredentials(this.userId, this.password);
}

class BiometricAuthService {
  BiometricAuthService._();

  static final LocalAuthentication _auth = LocalAuthentication();

  static final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const _kEnabled = 'bio_enabled';
  static const _kUserId = 'bio_user_id';
  static const _kPassword = 'bio_password';
  static const _kUserJson = 'bio_user_json';

  /// Device has a fingerprint / face sensor with at least one enrolled.
  static Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isEnabled() async =>
      (await _storage.read(key: _kEnabled)) == '1';

  /// Shows the system fingerprint prompt. Returns true only on success.
  static Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      // Not enrolled, locked out, user cancelled, no hardware...
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Confirms the fingerprint once, then stores credentials.
  static Future<bool> enable({
    required String userId,
    required String password,
    required Map<String, dynamic> userJson,
  }) async {
    final ok = await authenticate('Confirm your fingerprint to enable login');
    if (!ok) return false;
    await _write(userId, password, userJson);
    return true;
  }

  static Future<void> refreshIfEnabled({
    required String userId,
    required String password,
    required Map<String, dynamic> userJson,
  }) async {
    if (!await isEnabled()) return;
    final storedId = await _storage.read(key: _kUserId);
    if (storedId != userId) return;
    await _write(userId, password, userJson);
  }

  static Future<String?> storedUserId() => _storage.read(key: _kUserId);

  static Future<void> _write(
    String userId,
    String password,
    Map<String, dynamic> userJson,
  ) async {
    await _storage.write(key: _kUserId, value: userId);
    await _storage.write(key: _kPassword, value: password);
    await _storage.write(key: _kUserJson, value: jsonEncode(userJson));
    await _storage.write(key: _kEnabled, value: '1');
  }

  static Future<StoredCredentials?> readCredentials() async {
    final id = await _storage.read(key: _kUserId);
    final pw = await _storage.read(key: _kPassword);
    if (id == null || pw == null) return null;
    return StoredCredentials(id, pw);
  }

  static Future<Map<String, dynamic>?> readUserJson() async {
    final raw = await _storage.read(key: _kUserJson);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> disable() async {
    await _storage.delete(key: _kEnabled);
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kPassword);
    await _storage.delete(key: _kUserJson);
  }
}
