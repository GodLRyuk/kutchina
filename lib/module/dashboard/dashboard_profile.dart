import 'package:flutter/material.dart';
import 'package:kutchina/core/auth/app_roles.dart';
import 'package:kutchina/module/dashboard/dashboard_controller.dart';

class QuickActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;

  const QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
  });
}

abstract class DashboardProfile {
  AppRole get role;
  bool get needsCheckIn => false;
  DashboardController createController();
  List<QuickActionItem> quickActions(
    BuildContext context,
    DashboardController controller,
  );
  List<Widget> sections(BuildContext context, DashboardController controller);
}
