import 'package:kutchina/module/admin/reports/reports_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/salesExe/pages/profile/profile.dart';

class AdminBottomNav extends StatefulWidget {
  final int initialIndex;
  final bool Function(int index)? onTap;

  const AdminBottomNav({super.key, this.initialIndex = 0, this.onTap});

  static const items = [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Overview'),

    BottomNavigationBarItem(
      icon: Icon(Icons.bar_chart_outlined),
      label: 'Reports',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
  ];

  @override
  State<AdminBottomNav> createState() => _AdminBottomNavState();
}

class _AdminBottomNavState extends State<AdminBottomNav> {
  late int _navIndex = widget.initialIndex;

  void _onNavTap(int index) {
    if (index == _navIndex) return;

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReportsHubScreen()),
      );
      return; // handled — skip toast/setState, don't steal selection
    }
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen()),
      );
      return; // handled — skip toast/setState, don't steal selection
    }

    final handled = widget.onTap?.call(index) ?? false;
    if (handled) return;

    setState(() => _navIndex = index);
    AppWidgets.toast(context, 'Coming soon');
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _navIndex,
      onTap: _onNavTap,
      selectedItemColor: AppColors.navActive,
      unselectedItemColor: AppColors.navNormal,
      selectedLabelStyle: const TextStyle(
        fontFamily: AppFonts.display,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(fontFamily: AppFonts.display),
      type: BottomNavigationBarType.fixed,
      items: AdminBottomNav.items,
    );
  }
}
