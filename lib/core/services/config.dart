class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://72.61.114.210:8082';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 100);
  static const Duration sendTimeout = Duration(seconds: 100);

  /// SHA-256 fingerprints (hex, lowercase) of the server's leaf cert public
  /// key. Pin the DER-encoded SubjectPublicKeyInfo, not the whole cert, so
  /// pinning survives cert renewal as long as the key pair is reused.
  static const List<String> pinnedCertSha256 = [
    'REPLACE_WITH_REAL_SHA256_FINGERPRINT_1',
    'REPLACE_WITH_REAL_SHA256_FINGERPRINT_2',
  ];
}
