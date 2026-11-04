import 'package:kutchina/core/auth/app_roles.dart';

class RolePermissions {
  RolePermissions._();

  static bool atLeast(AppRole role, AppRole min) {
    return AppRoles.level(role) >= AppRoles.level(min);
  }

  static bool isManager(AppRole role) {
    return AppRoles.level(role) >= AppRoles.level(AppRole.salesHead);
  }
}
