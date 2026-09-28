import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/constants/customePaint.dart';
import 'package:kutchina/core/provider/auth_provider.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/utils/admin_widgets.dart';
import 'package:kutchina/core/widgets/admin_bottom_nav.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/admin/detailsScreen/admin_product_detail_screen.dart';
import 'package:kutchina/module/admin/admin_products_screen.dart';
import 'package:kutchina/module/admin/detailsScreen/admin_region_detail_screen.dart';
import 'package:kutchina/module/admin/admin_regions_screen.dart';
import 'package:kutchina/module/admin/detailsScreen/admin_team_member_detail_screen.dart';
import 'package:kutchina/module/admin/admin_team_screen.dart';
import 'package:kutchina/core/services/admin_dashboard_api.dart';
import 'package:provider/provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  AdminDashboardData? _dashboardData;
  bool _isLoading = true;
  String? _loadError;

  static const List<Map<String, dynamic>> _products = [];
  static const List<Map<String, dynamic>> _regions = [];
  static const List<Map<String, dynamic>> _team = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final data = await AdminDashboardApi.fetchOverview();
      if (!mounted) return;
      setState(() => _dashboardData = data);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Unable to load dashboard data');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppTopBar.greeting(
        greeting: getGreeting(),
        subtitle: user.fullName,
        centerImage: const AssetImage('assets/images/logo.jpg'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => AppWidgets.toast(context, 'No new notifications'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                _buildHeader(),
                if (_loadError != null) _buildLoadError(),
                const SizedBox(height: 14),
                _buildStatCards(),
                const SizedBox(height: 16),
                _buildHighPerformers(),
                const SizedBox(height: 16),
                _buildSalesByCategory(),
                const SizedBox(height: 16),
                _buildSalesByRegion(),
                const SizedBox(height: 16),
                _buildTeamPerformance(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(),
    );
  }

  Widget _buildLoadError() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Dashboard data could not be loaded.',
              style: TextStyle(fontSize: 11, color: AppColors.redDark),
            ),
          ),
          TextButton(onPressed: _loadDashboard, child: const Text('Retry')),
        ],
      ),
    );
  }

  // ---------------- Header: title + period selector + trend ----------------

  Widget _buildHeader() {
    final data = _dashboardData;
    final growth = data?.totalSalesGrowthPercentage;
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
            children: [
              Icon(Icons.trending_up, size: 13, color: AppColors.green),
              SizedBox(width: 4),
              Text(
                growth == null
                    ? '--'
                    : '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.green,
                ),
              ),
              SizedBox(width: 4),
              Text(
                growth == null ? 'No comparison data' : 'vs Last Month',
                style: const TextStyle(fontSize: 10, color: AppColors.steel),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Stat cards ----------------

  Widget _buildStatCards() {
    final data = _dashboardData;
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
            value: _currency(data?.totalSalesValue ?? 0),
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
            iconBg: AppColors.dayEndIconBg.withValues(alpha: 0.15),
            iconColor: AppColors.dayEndIconBg,
            label: 'Day-End Sales',
            value: _currency(data?.dayEndSalesValue ?? 0),
            footer: Text(
              'Today · ${data?.dayEndOrdersCount ?? 0} Orders',
              style: TextStyle(fontSize: 9.5, color: AppColors.steel),
            ),
          ),
          AdminCustomWidgets.statCard(
            icon: Icons.track_changes_outlined,
            iconBg: AppColors.achievementIconBg.withValues(alpha: 0.15),
            iconColor: AppColors.achievementIconBg,
            label: 'Target Achieved',
            value:
                '${(data?.targetAchievedPercentage ?? 0).toStringAsFixed(0)}%',
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ((data?.targetAchievedPercentage ?? 0) / 100).clamp(
                      0.0,
                      1.0,
                    ),
                    minHeight: 4,
                    backgroundColor: AppColors.ash,
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.achievementIconBg,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'of ${_currency(data?.targetValue ?? 0)} Target',
                  style: const TextStyle(fontSize: 9, color: AppColors.steel),
                ),
              ],
            ),
          ),
          AdminCustomWidgets.statCard(
            icon: Icons.auto_awesome,
            iconBg: AppColors.aiIconBg.withValues(alpha: 0.15),
            iconColor: AppColors.aiIconBg,
            label: 'AI Sales Forecast\n- Tomorrow',
            value: _currency(data?.forecastTomorrowValue ?? 0),
            footer: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 11,
                  color: AppColors.aiBlue,
                ),
                const SizedBox(height: 3),
                Text(
                  '${(data?.forecastTomorrowConfidencePercentage ?? 0).toStringAsFixed(0)}% Confidence',
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.aiBlue,
                  ),
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
    final data = _dashboardData;
    final topArea = data?.topArea;
    final topProduct = data?.topProduct;
    final topSalesperson = data?.topSalesperson;
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
                  name: topArea?.name ?? 'Unavailable',
                  value: _currency(topArea?.value ?? 0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AdminCustomWidgets.performerChip(
                  bg: AppColors.topProductBg,
                  icon: Icons.science_outlined,
                  label: 'Top Product',
                  name: topProduct?.name ?? 'Unavailable',
                  value: _currency(topProduct?.value ?? 0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AdminCustomWidgets.performerChip(
                  bg: AppColors.topSalespersonBg,
                  icon: Icons.star_outline,
                  label: 'Top Salesperson',
                  name: topSalesperson?.name ?? 'Unavailable',
                  value: _currency(topSalesperson?.value ?? 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Sales by Product ----------------

  Widget _buildSalesByCategory() {
    final data = _dashboardData;
    final products = data != null
        ? data.salesByCategory.asMap().entries.map((entry) {
            final category = entry.value;
            final index = entry.key % 4;
            return {
              'name': category.name,
              'value': _currency(category.value),
              'percent': _ratio(category.percentage),
              'label':
                  '${(_ratio(category.percentage) * 100).toStringAsFixed(0)}%',
              'color': [
                AppColors.productChimney,
                AppColors.productHobs,
                AppColors.productWaterPurifiers,
                AppColors.productOvens,
              ][index],
              'icon': [
                Icons.kitchen_outlined,
                Icons.local_fire_department_outlined,
                Icons.water_drop_outlined,
                Icons.microwave_outlined,
              ][index],
            };
          }).toList()
        : _products;
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
                    'Sales by Category',
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
          for (final p in products) ...[
            _productRow(
              icon: p['icon'] as IconData,
              color: p['color'] as Color,
              name: p['name'] as String,
              value: p['value'] as String,
              percent: p['percent'] as double,
              label: p['label'] as String,
            ),
            if (p != products.last) const SizedBox(height: 12),
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
                  color: color.withValues(alpha: 0.12),
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
    final data = _dashboardData;
    final regions = data != null
        ? data.salesByRegion.asMap().entries.map((entry) {
            final region = entry.value;
            return {
              'name': region.name,
              'value': _currency(region.value),
              'percent': region.percentage,
              'target': region.target,
              'color': [
                AppColors.regionBlue,
                AppColors.regionPurple,
                AppColors.regionCyan,
                AppColors.regionOrange,
              ][entry.key % 4],
            };
          }).toList()
        : _regions;
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
                  values: regions.map((r) => r['percent'] as double).toList(),
                  colors: regions.map((r) => r['color'] as Color).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final r in regions) ...[
            _regionLegendRow(
              color: r['color'] as Color,
              name: r['name'] as String,
              value: r['value'] as String,
              percent: '${(r['percent'] as double).toInt()}%',
            ),
            if (r != regions.last) const SizedBox(height: 8),
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
    final data = _dashboardData;
    final team = data != null
        ? data.salesTeamPerformance
              .map(
                (member) => {
                  'name': member.name,
                  'today': _currency(member.today),
                  'month': _currency(member.month),
                  'bg': AppColors.avatarBg1,
                },
              )
              .toList()
        : _team;
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
          for (final t in team) ...[
            _teamRow(
              name: t['name'] as String,
              today: t['today'] as String,
              month: t['month'] as String,
              avatarBg: t['bg'] as Color,
            ),
            if (t != team.last)
              const Divider(height: 18, color: AppColors.line),
          ],
        ],
      ),
    );
  }

  Widget _teamRow({
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

  String _currency(double value) {
    if (value.abs() >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(1)}Cr';
    }
    if (value.abs() >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(1)}L';
    }
    if (value.abs() >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(1)}K';
    }
    return '₹${value.toStringAsFixed(0)}';
  }

  double _ratio(double percentage) {
    return (percentage > 1 ? percentage / 100 : percentage).clamp(0.0, 1.0);
  }
}
