import 'package:flutter_test/flutter_test.dart';
import 'package:kutchina/core/auth/app_roles.dart';
import 'package:kutchina/module/dashboard/dashboard_profile_factory.dart';

void main() {
  test('HOD backend role maps to the shared HOD dashboard profile', () {
    final role = AppRoles.parse('HOD');
    final profile = forRole(role);

    expect(role, AppRole.hod);
    expect(profile.role, AppRole.hod);
    expect(profile.navTabs(), isNotEmpty);
    expect(profile.navTabs().first.label, 'Command');
  });

  test('Admin backend role maps to the HOD dashboard profile', () {
    final profile = forRole(AppRoles.parse('Admin'));

    expect(profile.role, AppRole.hod);
    expect(profile.navTabs().first.label, 'Command');
  });
}
