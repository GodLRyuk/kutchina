import 'package:flutter/material.dart';
import 'package:kutchina/core/auth/app_roles.dart';
import 'package:kutchina/core/provider/auth_provider.dart';
import 'package:kutchina/core/widgets/app_bottom_nav.dart';
import 'package:kutchina/core/widgets/role_shell.dart';
import 'package:kutchina/module/admin/admin_dashboard.dart';
import 'package:provider/provider.dart';

class RoleHome extends StatelessWidget {
  const RoleHome({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;

    if (role == AppRole.admin) return const AdminDashboard();
    // if(role == AppRole.distributor) return const DistributorDashboard();
    // if (role == AppRole.hod) return const DashboardScreen();
    //if (role == AppRole.areaSalesManager) return const DashboardScreen();
    return RoleShell(tabs: AppBottomNav.destinationsFor(role));
  }
}
