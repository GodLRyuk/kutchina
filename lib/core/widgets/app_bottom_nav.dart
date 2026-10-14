import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/salesExe/pages/dashboard/dashboard_screen.dart';
import 'package:kutchina/module/salesExe/pages/order/order_list_screen.dart';
import 'package:kutchina/module/salesExe/pages/profile/profile.dart';

class AppBottomNav extends StatefulWidget {
  final int initialIndex;
  final bool Function(int index)? onTap;
  final Color? backgroundColor;

  const AppBottomNav({
    super.key,
    this.initialIndex = 0,
    this.onTap,
    this.backgroundColor,
  });

  static const items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.chat_bubble_outline),
      label: 'Leads',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_outlined),
      label: 'Orders',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),

    BottomNavigationBarItem(
      icon: Icon(Icons.storefront_outlined),
      label: 'Dealers',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
  ];

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  late int _navIndex = widget.initialIndex;

  void _onNavTap(int index) {
    if (index == _navIndex) return;

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderListScreen()),
      );
      return; // handled — skip toast/setState, don't steal selection
    }
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen()),
      );
      return; // handled — skip toast/setState, don't steal selection
    }
    if (index == 4) {
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
      elevation: 0,
      backgroundColor: Colors.transparent,
      currentIndex: _navIndex,
      onTap: _onNavTap,
      selectedItemColor: AppColors.navActive,
      unselectedItemColor: AppColors.navNormal,
      // backgroundColor: widget.backgroundColor,
      selectedLabelStyle: const TextStyle(
        fontFamily: AppFonts.display,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(fontFamily: AppFonts.display),
      type: BottomNavigationBarType.fixed,
      items: AppBottomNav.items,
    );
  }
}
