import 'package:flutter/material.dart';
import 'package:kutchina/core/auth/app_roles.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/provider/auth_provider.dart';
import 'package:kutchina/core/widgets/coming_soon_tab.dart';
import 'package:kutchina/module/admin/admin_products_screen.dart';
import 'package:kutchina/module/admin/admin_team_screen.dart';
import 'package:kutchina/module/admin/admin_dashboard.dart';
import 'package:kutchina/module/admin/reports/reports_hub_screen.dart';
import 'package:kutchina/module/dashboard/role_dashboard_screen.dart';
import 'package:kutchina/module/salesModule/pages/dashboard/dashboard_screen.dart';
import 'package:kutchina/module/salesModule/pages/leads/leads_screen.dart';
import 'package:kutchina/module/salesModule/pages/order/order_list_screen.dart';
import 'package:kutchina/module/salesModule/pages/profile/profile.dart';
import 'package:kutchina/module/salesModule/pages/profile/admin_profile.dart';
import 'package:provider/provider.dart';

class RoleTab {
  final String label;
  final IconData icon;
  final Color? iconColor;
  final WidgetBuilder builder;

  const RoleTab({
    required this.label,
    required this.icon,
    required this.builder,
    this.iconColor,
  });
}

/// The app's single bottom navigation widget and role-to-destination map.
/// Pass [tabs] from [RoleShell] to keep role tabs in its IndexedStack.
class AppBottomNav extends StatelessWidget {
  final int initialIndex;
  final List<RoleTab>? tabs;
  final ValueChanged<int>? onTabSelected;
  final Color? backgroundColor;

  const AppBottomNav({
    super.key,
    this.initialIndex = 0,
    this.tabs,
    this.onTabSelected,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;
    final destinations = tabs ?? destinationsFor(role);
    final selectedIndex = initialIndex.clamp(0, destinations.length - 1);
    final unselectedColor = role == AppRole.admin
        ? const Color.fromARGB(255, 112, 97, 85)
        : AppColors.navNormal;

    return BottomNavigationBar(
      elevation: 0,
      backgroundColor: backgroundColor ?? Colors.transparent,
      currentIndex: selectedIndex,
      onTap: (index) {
        if (index == selectedIndex) return;
        if (onTabSelected != null) {
          onTabSelected!(index);
          return;
        }
        _openDestination(context, destinations[index]);
      },
      selectedItemColor: AppColors.navActive,
      unselectedItemColor: unselectedColor,
      selectedLabelStyle: const TextStyle(
        fontFamily: AppFonts.display,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(fontFamily: AppFonts.display),
      type: BottomNavigationBarType.fixed,
      items: [
        for (final tab in destinations)
          BottomNavigationBarItem(
            icon: Icon(tab.icon, color: tab.iconColor ?? AppColors.navNormal),
            activeIcon: Icon(tab.icon, color: AppColors.navActive),
            label: tab.label,
          ),
      ],
    );
  }

  static List<RoleTab> destinationsFor(AppRole role) {
    switch (role) {
      case AppRole.admin:
        return [
          RoleTab(
            label: 'Home',
            icon: Icons.home_outlined,
            iconColor: AppColors.topAreaBg,
            builder: (_) => const AdminDashboard(),
          ),
          RoleTab(
            label: 'Reports',
            icon: Icons.bar_chart_outlined,
            iconColor: AppColors.topProductBg,
            builder: (_) => const ReportsHubScreen(showBottomNav: false),
          ),
          RoleTab(
            label: 'Profile',
            icon: Icons.person_outline,
            iconColor: AppColors.topSalespersonBg,
            builder: (_) => const AdminProfileScreen(),
          ),
        ];
      case AppRole.hod:
        return [
          RoleTab(
            label: 'Command',
            icon: Icons.home_outlined,
            iconColor: AppColors.regionBlue,
            builder: (_) => const RoleDashboardScreen(),
          ),
          RoleTab(
            label: 'Approve',
            icon: Icons.fact_check_outlined,
            iconColor: AppColors.productOvens,
            builder: (_) => const ComingSoonTab(title: 'Approvals'),
          ),
          RoleTab(
            label: 'People',
            icon: Icons.groups_outlined,
            iconColor: AppColors.topProductBg,
            builder: (_) => const AdminTeamScreen(),
          ),
          RoleTab(
            label: 'Masters',
            icon: Icons.inventory_2_outlined,
            iconColor: AppColors.regionPurple,
            builder: (_) => const AdminProductsScreen(),
          ),
          RoleTab(
            label: 'Profile',
            icon: Icons.person_outline,
            iconColor: AppColors.navNormal,
            builder: (_) => const ProfileScreen(
              showBottomNav: false,
              showBackButton: false,
            ),
          ),
        ];
      case AppRole.salesExec:
        return [
          RoleTab(
            label: 'Home',
            icon: Icons.home_outlined,
            iconColor: AppColors.regionBlue,
            builder: (_) => const DashboardScreen(showBottomNav: false),
          ),
          RoleTab(
            label: 'Leads',
            icon: Icons.chat_bubble_outline,
            iconColor: AppColors.productChimney,
            builder: (_) => const LeadsScreen(),
          ),
          RoleTab(
            label: 'Orders',
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.productOvens,
            builder: (_) => const OrderListScreen(showBottomNav: false),
          ),
          RoleTab(
            label: 'Tasks',
            icon: Icons.task_alt_outlined,
            iconColor: AppColors.topProductBg,
            builder: (_) => const ComingSoonTab(title: 'Tasks'),
          ),
          RoleTab(
            label: 'Profile',
            icon: Icons.person_outline,
            iconColor: AppColors.navNormal,
            builder: (_) => const ProfileScreen(
              showBottomNav: false,
              showBackButton: false,
            ),
          ),
        ];
      case AppRole.salesHead:
      case AppRole.branchManager:
      case AppRole.areaSalesManager:
      case AppRole.distributor:
        return [
          RoleTab(
            label: 'Home',
            icon: Icons.home_outlined,
            builder: (_) => const RoleDashboardScreen(),
          ),
          RoleTab(
            label: 'Tasks',
            icon: Icons.checklist_outlined,
            builder: (_) => const ComingSoonTab(title: 'Tasks'),
          ),
          RoleTab(
            label: 'Profile',
            icon: Icons.person_outline,
            builder: (_) => const ProfileScreen(
              showBottomNav: false,
              showBackButton: false,
            ),
          ),
        ];
    }
  }

  static void _openDestination(BuildContext context, RoleTab tab) {
    final screen = tab.builder(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
