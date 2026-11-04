import 'package:flutter/material.dart';

enum AppRole {
  admin,
  salesExec,
  salesHead,
  branchManager,
  areaSalesManager,
  hod,
  distributor,
}

class AppRoles {
  AppRoles._();

  static AppRole parse(String? raw) {
    final r = (raw ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    switch (r) {
      case 'superadmin':
        return AppRole.admin;
      case 'admin':
        return AppRole.admin;
      case 'hod':
        return AppRole.hod;
      case 'se':
      case 'salesexec':
        return AppRole.salesExec;
      case 'sh':
      case 'saleshead':
        return AppRole.salesHead;
      case 'bm':
      case 'branchmanager':
        return AppRole.branchManager;
      case 'asm':
      case 'areasalesmanager':
        return AppRole.areaSalesManager;
      case 'areasaleshead':
        return AppRole.areaSalesManager;
      case 'distributor':
      case 'dealer':
        return AppRole.distributor;
      default:
        return AppRole.salesExec;
    }
  }

  static int level(AppRole role) {
    switch (role) {
      case AppRole.admin:
        return 6;
      case AppRole.salesExec:
        return 1;
      case AppRole.salesHead:
        return 2;
      case AppRole.branchManager:
        return 3;
      case AppRole.areaSalesManager:
        return 4;
      case AppRole.hod:
        return 5;
      case AppRole.distributor:
        return 0;
    }
  }

  /// Opens the right home screen after login (password, fingerprint or
  /// offline login all call this).
  static void openHome(BuildContext context, String? roleName) {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }
}
