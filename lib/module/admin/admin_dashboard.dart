import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/constants/customePaint.dart';
import 'package:kutchina/core/utils/admin_widgets.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/admin/admin_product_detail_screen.dart';
import 'package:kutchina/module/admin/admin_products_screen.dart';
import 'package:kutchina/module/admin/admin_region_detail_screen.dart';
import 'package:kutchina/module/admin/admin_regions_screen.dart';
import 'package:kutchina/module/admin/admin_team_member_detail_screen.dart';
import 'package:kutchina/module/admin/admin_team_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _navIndex = 0;

  static const _products = [
    {
      'name': 'Chimneys',
      'value': '₹18.6L',
      'percent': 0.38,
      'label': '38%',
      'color': AppColors.productChimney,
      'icon': Icons.kitchen_outlined,
    },
    {
      'name': 'Hobs',
      'value': '₹12.4L',
      'percent': 0.26,
      'label': '26%',
      'color': AppColors.productHobs,
      'icon': Icons.local_fire_department_outlined,
    },
    {
      'name': 'Water Purifiers',
      'value': '₹9.8L',
      'percent': 0.20,
      'label': '20%',
      'color': AppColors.productWaterPurifiers,
      'icon': Icons.water_drop_outlined,
    },
    {
      'name': 'Ovens',
      'value': '₹7.8L',
      'percent': 0.16,
      'label': '16%',
      'color': AppColors.productOvens,
      'icon': Icons.microwave_outlined,
    },
  ];

  static const _regions = [
    {
      'name': 'Kolkata',
      'value': '₹18.6L',
      'percent': 38.0,
      'color': AppColors.regionBlue,
    },
    {
      'name': 'Howrah & Hooghly',
      'value': '₹11.7L',
      'percent': 24.0,
      'color': AppColors.regionPurple,
    },
    {
      'name': 'North Bengal',
      'value': '₹10.2L',
      'percent': 21.0,
      'color': AppColors.regionCyan,
    },
    {
      'name': 'South Bengal',
      'value': '₹8.1L',
      'percent': 17.0,
      'color': AppColors.regionOrange,
    },
  ];

  static const _team = [
    {
      'initials': 'AM',
      'name': 'Arjun Mehta',
      'today': '₹1.25L',
      'month': '₹15.8L',
      'bg': AppColors.avatarBg1,
    },
    {
      'initials': 'NS',
      'name': 'Neha Sharma',
      'today': '₹0.98L',
      'month': '₹13.2L',
      'bg': AppColors.avatarBg2,
    },
    {
      'initials': 'RD',
      'name': 'Rohan Das',
      'today': '₹0.76L',
      'month': '₹9.5L',
      'bg': AppColors.avatarBg3,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppTopBar.greeting(
        greeting: 'Good morning',
        subtitle: 'Sylvester Rajesh Mondal',
        centerImage: const AssetImage('assets/images/logo.jpg'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => AppWidgets.toast(context, 'No new notifications'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildStatCards(),
              const SizedBox(height: 16),
              _buildHighPerformers(),
              const SizedBox(height: 16),
              _buildSalesByProduct(),
              const SizedBox(height: 16),
              _buildSalesByRegion(),
              const SizedBox(height: 16),
              _buildTeamPerformance(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ---------------- Header: title + period selector + trend ----------------

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Sales Command Centre',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.commandCentreText,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: AppColors.commandCentreText,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'This Month',
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.commandCentreText,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 15,
                    color: AppColors.commandCentreText,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.greenLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.trending_up, size: 13, color: AppColors.green),
              SizedBox(width: 4),
              Text(
                '+12.4%',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.green,
                ),
              ),
              SizedBox(width: 4),
              Text(
                'vs Last Month',
                style: TextStyle(fontSize: 10, color: AppColors.steel),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Stat cards ----------------

  Widget _buildStatCards() {
    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          AdminCustomWidgets.statCard(
            icon: Icons.currency_rupee,
            iconBg: AppColors.rupeeIconBg,
            iconColor: AppColors.commandCentreText,
            label: 'Total Sales',
            value: '₹48.6L',
            footer: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up, size: 11, color: AppColors.green),
                SizedBox(width: 3),
                Text(
                  'vs Last Month',
                  style: TextStyle(fontSize: 9.5, color: AppColors.green),
                ),
              ],
            ),
          ),
          AdminCustomWidgets.statCard(
            icon: Icons.shopping_cart_outlined,
            iconBg: AppColors.dayEndIconBg.withOpacity(0.15),
            iconColor: AppColors.dayEndIconBg,
            label: 'Day-End Sales',
            value: '₹3.8L',
            footer: const Text(
              'Today · 126 Orders',
              style: TextStyle(fontSize: 9.5, color: AppColors.steel),
            ),
          ),
          AdminCustomWidgets.statCard(
            icon: Icons.track_changes_outlined,
            iconBg: AppColors.achievementIconBg.withOpacity(0.15),
            iconColor: AppColors.achievementIconBg,
            label: 'Target Achieved',
            value: '82%',
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.82,
                    minHeight: 4,
                    backgroundColor: AppColors.ash,
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.achievementIconBg,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'of ₹59.0L Target',
                  style: TextStyle(fontSize: 9, color: AppColors.steel),
                ),
              ],
            ),
          ),
          AdminCustomWidgets.statCard(
            icon: Icons.auto_awesome,
            iconBg: AppColors.aiIconBg.withOpacity(0.15),
            iconColor: AppColors.aiIconBg,
            label: 'AI Sales Forecast\n- Tomorrow',
            value: '₹4.6L',
            footer: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 11,
                  color: AppColors.aiBlue,
                ),
                const SizedBox(height: 3),
                const Text(
                  '86% Confidence',
                  style: TextStyle(fontSize: 9.5, color: AppColors.aiBlue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- High performers banner ----------------

  Widget _buildHighPerformers() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.highPerformersBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.emoji_events,
                color: AppColors.topSalespersonBg,
                size: 28,
              ),
              SizedBox(width: 8),
              Text(
                'High Performers',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              Spacer(),
              Icon(Icons.auto_awesome, color: AppColors.white, size: 18),
              Icon(Icons.auto_awesome, color: AppColors.white, size: 30),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AdminCustomWidgets.performerChip(
                  bg: AppColors.topAreaBg,
                  icon: Icons.location_on_outlined,
                  label: 'Top Area',
                  name: 'Kolkata',
                  value: '₹12.8L',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AdminCustomWidgets.performerChip(
                  bg: AppColors.topProductBg,
                  icon: Icons.science_outlined,
                  label: 'Top Product',
                  name: 'Chimney',
                  value: '₹18.6L',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AdminCustomWidgets.performerChip(
                  bg: AppColors.topSalespersonBg,
                  icon: Icons.star_outline,
                  label: 'Top Salesperson',
                  name: 'Arjun Mehta',
                  value: '₹15.8L',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Sales by Product ----------------

  Widget _buildSalesByProduct() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: AppColors.commandCentreText,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Sales by Product',
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.commandCentreText,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminProductsScreen(),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.viewAllButton,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 15,
                      color: AppColors.viewAllButton,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final p in _products) ...[
            _productRow(
              icon: p['icon'] as IconData,
              color: p['color'] as Color,
              name: p['name'] as String,
              value: p['value'] as String,
              percent: p['percent'] as double,
              label: p['label'] as String,
            ),
            if (p != _products.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _productRow({
    required IconData icon,
    required Color color,
    required String name,
    required String value,
    required double percent,
    required String label,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminProductDetailScreen(
            name: name,
            value: value,
            percent: percent,
            label: label,
            color: color,
            icon: icon,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 6,
                    backgroundColor: AppColors.ash,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 30,
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 10, color: AppColors.steel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Sales by Region (donut) ----------------

  Widget _buildSalesByRegion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.public,
                    size: 16,
                    color: AppColors.commandCentreText,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Sales by Region',
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.commandCentreText,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminRegionsScreen()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.viewAllButton,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 15,
                      color: AppColors.viewAllButton,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: CustomPaint(
                painter: DonutChartPainter(
                  values: _regions.map((r) => r['percent'] as double).toList(),
                  colors: _regions.map((r) => r['color'] as Color).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final r in _regions) ...[
            _regionLegendRow(
              color: r['color'] as Color,
              name: r['name'] as String,
              value: r['value'] as String,
              percent: '${(r['percent'] as double).toInt()}%',
            ),
            if (r != _regions.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _regionLegendRow({
    required Color color,
    required String name,
    required String value,
    required String percent,
  }) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminRegionDetailScreen(
            name: name,
            value: value,
            percent: percent,
            color: color,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 11.5, color: AppColors.ink),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 11.5,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 32,
              child: Text(
                percent,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11, color: AppColors.steel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Sales Team Performance ----------------

  Widget _buildTeamPerformance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.groups_outlined,
                size: 16,
                color: AppColors.commandCentreText,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Sales Team Performance',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.commandCentreText,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminTeamScreen()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.viewAllButton,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 15,
                      color: AppColors.viewAllButton,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Salesperson',
                  style: TextStyle(fontSize: 10, color: AppColors.steel),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Sales Today',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 10, color: AppColors.steel),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Sales This Month',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 10, color: AppColors.steel),
                ),
              ),
            ],
          ),
          const Divider(height: 18, color: AppColors.line),
          for (final t in _team) ...[
            _teamRow(
              initials: t['initials'] as String,
              name: t['name'] as String,
              today: t['today'] as String,
              month: t['month'] as String,
              avatarBg: t['bg'] as Color,
            ),
            if (t != _team.last)
              const Divider(height: 18, color: AppColors.line),
          ],
        ],
      ),
    );
  }

  Widget _teamRow({
    required String initials,
    required String name,
    required String today,
    required String month,
    required Color avatarBg,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminTeamMemberDetailScreen(
            initials: initials,
            name: name,
            today: today,
            month: month,
            avatarBg: avatarBg,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: avatarBg,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.commandCentreText,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              today,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.salesTodayColumn,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              month,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.salesThisMonthColumn,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Bottom nav (own item set) ----------------

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _navIndex,
      onTap: (i) => setState(() => _navIndex = i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.navActive,
      unselectedItemColor: AppColors.navNormal,
      selectedLabelStyle: const TextStyle(
        fontFamily: AppFonts.display,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(fontFamily: AppFonts.display),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Overview',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          label: 'Products',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.public_outlined),
          label: 'Regions',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.groups_outlined),
          label: 'Team',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          label: 'Reports',
        ),
      ],
    );
  }
}
