import 'package:kutchina/core/services/api_services.dart';

class UserLocation {
  final String id;
  final String name;
  UserLocation({required this.id, required this.name});

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString().trim() ?? '',
    );
  }
}

class UserZone {
  final String id;
  final String name;
  UserZone({required this.id, required this.name});

  factory UserZone.fromJson(Map<String, dynamic> json) {
    return UserZone(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString().trim() ?? '',
    );
  }
}

class KUser {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final UserLocation? location;
  final UserZone? zone;
  final String? role; // null in your sample response
  final bool isActive;

  KUser({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    this.location,
    this.zone,
    this.role,
    required this.isActive,
  });

  String get fullName =>
      [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

  factory KUser.fromJson(Map<String, dynamic> json) {
    return KUser(
      id: (json['id'] ?? '').toString(),
      userId: json['userid']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      location: json['location'] != null
          ? UserLocation.fromJson(json['location'])
          : null,
      zone: json['zone'] != null ? UserZone.fromJson(json['zone']) : null,
      role: json['role']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class LoginResult {
  final KUser user;
  final String accessToken;
  final String refreshToken;
  LoginResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}

class AuthApi {
  AuthApi._();

  static Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    final res = await ApiService.instance.post(
      '/api/v1/users/login/',
      data: {'userid': username, 'password': password},
      skipAuth: true, // no token exists yet for this call
    );

    final data = res.data as Map<String, dynamic>;

    if (data['success'] != true) {
      throw ApiException(data['message']?.toString() ?? 'Login failed');
    }

    final access = data['access_token'] as String;
    final refresh = data['refresh_token'] as String;
    final userJson = data['user'] as Map<String, dynamic>;
    final user = KUser.fromJson(userJson);
    print("User Json ${userJson}");
    print("User ${user}");
    await TokenStore.saveTokens(accessToken: access, refreshToken: refresh);
    await UserStore.saveUser(userJson);
    return LoginResult(user: user, accessToken: access, refreshToken: refresh);
  }
}
