import 'package:flutter/material.dart';
import 'package:kutchina/core/auth/app_roles.dart';
import 'package:kutchina/module/dashboard/dashboard_controller.dart';
import 'package:kutchina/module/dashboard/dashboard_profile.dart';
import 'package:kutchina/module/dashboard/profiles/hod_profile.dart';
import 'package:kutchina/module/dashboard/profiles/se_profile.dart';
import 'package:kutchina/module/dashboard/se_dashboard_controller.dart';

class _StubProfile extends DashboardProfile {
  @override
  final AppRole role;

  _StubProfile(this.role);

  @override
  DashboardController createController() => SeDashboardController();

  @override
  List<QuickActionItem> quickActions(
    BuildContext context,
    DashboardController controller,
  ) => const [];

  @override
  List<Widget> sections(BuildContext context, DashboardController controller) =>
      [const SizedBox.shrink()];
}

DashboardProfile forRole(AppRole role) {
  switch (role) {
    case AppRole.admin:
      return _StubProfile(AppRole.admin);
    case AppRole.salesExec:
      return SeProfile();
    case AppRole.salesHead:
      return _StubProfile(AppRole.salesHead);
    case AppRole.branchManager:
      return _StubProfile(AppRole.branchManager);
    case AppRole.areaSalesManager:
      return _StubProfile(AppRole.areaSalesManager);
    case AppRole.hod:
      return HodProfile();
    case AppRole.distributor:
      return _StubProfile(AppRole.distributor);
  }
}
