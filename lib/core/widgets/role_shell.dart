import 'package:flutter/material.dart';
import 'package:kutchina/core/widgets/app_bottom_nav.dart';

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
            if (_visited.contains(i))
              tabs[i].builder(context)
            else
              const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        tabs: tabs,
        initialIndex: _index,
        onTabSelected: (i) {
          setState(() {
            _index = i;
            _visited.add(i);
          });
        },
      ),
    );
  }
}
