import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kutchina/core/services/config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Token storage — secure_storage backed, never SharedPreferences for
/// tokens (SharedPreferences is plaintext on disk on most platforms).
class TokenStore {
  TokenStore._();
  static final _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  static Future<String?> getAccessToken() => _storage.read(key: _accessKey);
  static Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

/// Attaches bearer token to every request; on 401, tries one silent
/// refresh + retry before giving up and clearing session.
class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final Future<void> Function()? onSessionExpired;
  bool _isRefreshing = false;

  AuthInterceptor(this._dio, {this.onSessionExpired});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] != true) {
      final token = await TokenStore.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (!isUnauthorized || alreadyRetried) {
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      // Another request already triggered a refresh — fail this one
      // rather than stacking concurrent refresh calls.
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    try {
      final refreshed = await _refreshToken();
      _isRefreshing = false;
      if (!refreshed) {
        await TokenStore.clear();
        if (onSessionExpired != null) await onSessionExpired!();
        handler.next(err);
        return;
      }

      // Retry the original request once, with the new token.
      final opts = err.requestOptions;
      opts.extra['retried'] = true;
      final newToken = await TokenStore.getAccessToken();
      opts.headers['Authorization'] = 'Bearer $newToken';

      final cloned = await _dio.fetch(opts);
      handler.resolve(cloned);
    } catch (_) {
      _isRefreshing = false;
      await TokenStore.clear();
      if (onSessionExpired != null) await onSessionExpired!();
      handler.next(err);
    }
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await TokenStore.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      // Bare Dio instance — must NOT reuse _dio here, or the auth
      // interceptor would attach the (expired) access token to this call.
      final refreshDio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      final res = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final newAccess = res.data['access_token'] as String;
      final newRefresh = res.data['refresh_token'] as String;
      await TokenStore.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Debug-only request/response logging. Never logs Authorization headers
/// or response bodies in release builds.
class LoggingInterceptor extends Interceptor {
  @override
  // void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
  //   if (kDebugMode) {
  //     // debugPrint('→ ${options.method} ${options.uri}');
  //     final data = options.data;
  //     if (data is FormData) {
  //       for (final field in data.fields) {
  //         debugPrint('   FIELD: ${field.key} = ${field.value}');
  //       }
  //       for (final file in data.files) {
  //         debugPrint(
  //           '   FILE: ${file.key} -> '
  //           'filename=${file.value.filename}, '
  //           'length=${file.value.length}, '
  //           'contentType=${file.value.contentType}',
  //         );
  //       }
  //     } else if (data != null) {
  //       debugPrint('   BODY: $data');
  //     }
  //   }
  //   handler.next(options);
  // }
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '✕ ${err.response?.statusCode} ${err.requestOptions.uri} — ${err.message}',
      );
    }
    handler.next(err);
  }
}

/// Retries idempotent GET requests on transient network failures
/// (timeout, connection error) with exponential backoff. Never retries
/// POST/PUT/PATCH/DELETE automatically — retrying a non-idempotent write
/// after a timeout can double-submit an order.
class RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int maxRetries;
  RetryInterceptor(this._dio, {this.maxRetries = 2});

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isGet = err.requestOptions.method.toUpperCase() == 'GET';
    final isRetryable =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    final attempt = (err.requestOptions.extra['retryAttempt'] as int?) ?? 0;

    if (isGet && isRetryable && attempt < maxRetries) {
      final delay = Duration(milliseconds: 400 * (attempt + 1));
      await Future.delayed(delay);
      final opts = err.requestOptions;
      opts.extra['retryAttempt'] = attempt + 1;
      try {
        final res = await _dio.fetch(opts);
        handler.resolve(res);
        return;
      } catch (_) {
        // fall through to normal error handling
      }
    }
    handler.next(err);
  }
}

class ApiService {
  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // _applySslPinning(_dio);

    _dio.interceptors.addAll([
      AuthInterceptor(_dio, onSessionExpired: onSessionExpired),
      RetryInterceptor(_dio),
      LoggingInterceptor(),
    ]);
  }

  static final ApiService instance = ApiService._internal();
  late final Dio _dio;

  /// Set by app startup (e.g. wire this to force-logout + navigate to
  /// login) so ApiService doesn't need a BuildContext of its own.
  static Future<void> Function()? onSessionExpired;

  /// Pins the connection to the configured cert fingerprints. Any TLS
  /// handshake presenting a cert whose public key doesn't match one of
  /// ApiConfig.pinnedCertSha256 is rejected — protects against MITM even
  /// on a compromised/rogue CA or a proxied network.
  void _applySslPinning(Dio dio) {
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
            final fingerprint = sha256.convert(cert.der).toString();
            final isPinned = ApiConfig.pinnedCertSha256
                .map((e) => e.toLowerCase())
                .contains(fingerprint.toLowerCase());
            if (!isPinned && kDebugMode) {
              debugPrint('SSL PIN MISMATCH for $host: got $fingerprint');
            }
            return isPinned;
          };
      return client;
    };
  }

  Dio get client => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    dynamic data,
    bool skipAuth = false,
  }) {
    return _dio
        .get<T>(
          path,
          data: data,
          queryParameters: queryParams,
          options: Options(extra: {'skipAuth': skipAuth}),
        )
        .catchError(_handleError);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    bool skipAuth = false,
  }) {
    return _dio
        .post<T>(
          path,
          data: data,
          options: Options(extra: {'skipAuth': skipAuth}),
        )
        .catchError(_handleError);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return _dio.put<T>(path, data: data).catchError(_handleError);
  }

  Future<Response<T>> patch<T>(String path, {dynamic data}) {
    return _dio.patch<T>(path, data: data).catchError(_handleError);
  }

  Future<Response<T>> delete<T>(String path, {dynamic data}) {
    return _dio.delete<T>(path, data: data).catchError(_handleError);
  }

  Never _handleError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      String message;
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Network timed out. Please try again.';
          break;
        case DioExceptionType.connectionError:
          message = 'No internet connection.';
          break;
        case DioExceptionType.badCertificate:
          message = 'Secure connection could not be verified.';
          break;
        case DioExceptionType.badResponse:
          message =
              _extractServerMessage(error.response?.data) ??
              'Something went wrong.';
          break;
        default:
          message = error.message ?? 'Unexpected error.';
      }
      throw ApiException(
        message,
        statusCode: status,
        data: error.response?.data,
      );
    }
    throw ApiException(error.toString());
  }

  String? _extractServerMessage(dynamic data) {
    try {
      if (data is String) {
        final parsed = jsonDecode(data);
        return parsed['message'] ?? parsed['error'];
      }
      if (data is Map) {
        return data['message'] ?? data['error'];
      }
    } catch (_) {}
    return null;
  }
}

class UserStore {
  UserStore._();
  static final _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const _userKey = 'current_user';

  static Future<void> saveUser(Map<String, dynamic> userJson) =>
      _storage.write(key: _userKey, value: jsonEncode(userJson));

  static Future<Map<String, dynamic>?> getUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> clear() => _storage.delete(key: _userKey);
}
