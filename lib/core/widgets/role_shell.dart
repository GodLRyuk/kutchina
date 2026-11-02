import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/module/salesExe/pages/profile/profile.dart';

class RoleTab {
  final String label;
  final IconData icon;

  /// Tab body. Null for a tab that opens a full screen instead ([push]).
  final WidgetBuilder? builder;

  /// Opens this screen on top instead of switching tab (Profile, Reports).
  final WidgetBuilder? push;

  const RoleTab({
    required this.label,
    required this.icon,
    this.builder,
    this.push,
  }) : assert(builder != null || push != null);

  factory RoleTab.profile() => RoleTab(
    label: 'Profile',
    icon: Icons.person_outline,
    push: (_) => const ProfileScreen(),
  );
}

/// Bottom-nav container shared by the Distributor, Sales Head and HOD homes.
/// Tabs keep their state (IndexedStack) so scroll position and loaded data
/// survive switching tabs.
class RoleShell extends StatefulWidget {
  final List<RoleTab> tabs;
  const RoleShell({super.key, required this.tabs});

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int _index = 0;
  final Set<int> _visited = {0};

  @override
  Widget build(BuildContext context) {
    final tabs = widget.tabs;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < tabs.length; i++)
            // Build a tab only once it is opened the first time.
            if (tabs[i].builder != null && _visited.contains(i))
              tabs[i].builder!(context)
            else
              const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.navActive,
        unselectedItemColor: AppColors.navNormal,
        selectedLabelStyle: const TextStyle(
          fontFamily: AppFonts.display,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(fontFamily: AppFonts.display),
        onTap: (i) {
          final tab = tabs[i];
          if (tab.push != null) {
            Navigator.push(context, MaterialPageRoute(builder: tab.push!));
            return;
          }
          setState(() {
            _index = i;
            _visited.add(i);
          });
        },
        items: [
          for (final t in tabs)
            BottomNavigationBarItem(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}
