import 'package:flutter/material.dart';
import 'package:kutchina/core/auth/app_roles.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/module/dashboard/dashboard_controller.dart';
import 'package:kutchina/module/dashboard/dashboard_profile.dart';
import 'package:kutchina/module/dashboard/se_dashboard_controller.dart';
import 'package:kutchina/module/salesExe/pages/order/new_order_sheet.dart';
import 'package:kutchina/module/salesExe/pages/order/order_list_screen.dart';
import 'package:kutchina/module/salesExe/pages/visits/new_visit.dart';

class SeProfile extends DashboardProfile {
  @override
  AppRole get role => AppRole.salesExec;

  @override
  DashboardController createController() => SeDashboardController();

  @override
  List<QuickActionItem> quickActions(
    BuildContext context,
    DashboardController controller,
  ) {
    return [
      QuickActionItem(
        icon: Icons.receipt_long,
        label: 'New Order',
        backgroundColor: AppColors.aiBlueBg,
        onTap: () => showNewOrderSheet(context),
      ),
      QuickActionItem(
        icon: Icons.list_alt,
        label: 'View Order',
        backgroundColor: AppColors.greenLight,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrderListScreen()),
        ),
      ),
      QuickActionItem(
        icon: Icons.location_on_outlined,
        label: 'New Visit',
        backgroundColor: AppColors.amberLight,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewVisitScreen()),
        ),
      ),
    ];
  }

  @override
  List<Widget> sections(BuildContext context, DashboardController controller) {
    return [
      const SizedBox(height: 12),
      const Text(
        'Sales Exec dashboard',
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.ink,
        ),
      ),
    ];
  }
}
