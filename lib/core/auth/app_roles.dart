import 'package:flutter/material.dart';
import 'package:kutchina/module/admin/admin_dashboard.dart';

enum AppRole { salesExec, distributor, salesHead, hod, admin }

class AppRoles {
  AppRoles._();

  static AppRole parse(String? raw) {
    final r = (raw ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    switch (r) {
      case 'admin':
      case 'superadmin':
        return AppRole.admin;
      case 'hod':
        return AppRole.hod;
      case 'sh':
        return AppRole.salesHead;
      case 'areasaleshead':
      case 'distributor':
      case 'dealer':
        return AppRole.distributor;
      default:
        return AppRole.salesExec;
    }
  }

  static String routeFor(AppRole role) {
    switch (role) {
      case AppRole.distributor:
        return '/distributor';
      case AppRole.salesHead:
        return '/saleshead';
      case AppRole.hod:
        return '/hod';
      case AppRole.admin:
      case AppRole.salesExec:
        return '/dashboard';
    }
  }

  /// Opens the right home screen after login (password, fingerprint or
  /// offline login all call this).
  static void openHome(BuildContext context, String? roleName) {
    print('Opening home for role: $roleName');
    final role = parse(roleName);
    if (role == AppRole.admin) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminDashboard()),
      );
      return;
    }
    if (role == AppRole.salesExec) {
      Navigator.pushReplacementNamed(context, '/dashboard');
      return;
    }
    if (role == AppRole.distributor) {
      Navigator.pushReplacementNamed(context, '/distributor');
      return;
    }
    if (role == AppRole.salesHead) {
      Navigator.pushReplacementNamed(context, '/saleshead');
      return;
    }
    if (role == AppRole.hod) {
      Navigator.pushReplacementNamed(context, '/hod');
      return;
    }
    Navigator.pushReplacementNamed(context, routeFor(role));
  }
}
