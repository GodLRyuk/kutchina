import 'package:kutchina/core/services/admin_dashboard_api.dart';
import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/core/provider/auth_provider.dart';
import 'package:kutchina/core/utils/dialog_box.dart';
import 'package:kutchina/core/utils/speedometer.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_bottom_nav.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/salesExe/models/order_model.dart';
import 'package:kutchina/module/salesExe/models/visit_model.dart';
import 'package:kutchina/module/salesExe/pages/visits/new_visit.dart';
import 'package:kutchina/module/salesExe/pages/order/new_order_sheet.dart';
import 'package:kutchina/module/salesExe/pages/order/order_list_screen.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _checkedIn = false;
  int _refreshTick = 0;
  List<VisitEntry> _todayVisits = [];
  bool _visitsLoading = true;
  double? _monthlyTarget;
  double _monthlyOrderTotal = 0;
  double _targetProgress = 0;
  bool _targetLoading = true;

  // Top-selling categories, straight from AdminDashboardData.salesByCategory
  // — already parsed into DashboardCategory objects by AdminDashboardApi,
  // no need to re-parse them.
  List<DashboardCategory> _topCategories = [];
  bool _overviewLoading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkAttendanceStatus(),
    );
    _loadTodayVisits();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTarget());
    loadOverview();
  }

  Future<void> loadOverview() async {
    setState(() => _overviewLoading = true);
    try {
      final raw = await AdminDashboardApi.fetchOverview();
      final categories = [...raw.salesByCategory]
        ..sort((a, b) => b.percentage.compareTo(a.percentage));

      if (!mounted) return;
      setState(() {
        _topCategories = categories;
        _overviewLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _overviewLoading = false);
    }
  }

  Future<void> _loadTarget() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      if (mounted) setState(() => _targetLoading = false);
      return;
    }
    try {
      final results = await Future.wait([
        OrderService.fetchCurrentTarget(userId: user.id),
        OrderService.fetchOrders(),
      ]);
      final monthlyTarget = results[0] as MonthlyTarget;
      final orders = results[1] as List<OrderEntry>;
      final orderTotal = _calculateOrderTotal(
        orders,
        month: monthlyTarget.month,
        targetDate: monthlyTarget.targetDate,
      );
      final progress = monthlyTarget.amount <= 0
          ? 0.0
          : (orderTotal / monthlyTarget.amount).clamp(0.0, 1.0);
      if (!mounted) return;
      setState(() {
        _monthlyTarget = monthlyTarget.amount;
        _monthlyOrderTotal = orderTotal;
        _targetProgress = progress;
        _targetLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _targetLoading = false);
      AppWidgets.toast(context, 'Could not load monthly target');
    }
  }

  double _calculateOrderTotal(
    List<OrderEntry> orders, {
    required DateTime? month,
    required DateTime? targetDate,
  }) {
    if (month == null || targetDate == null) return 0;

    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(targetDate.year, targetDate.month, targetDate.day + 1);

    return orders
        .where((order) {
          final createdAt = order.createdAt;
          if (createdAt == null) return false;
          final orderDate = DateTime(
            createdAt.toLocal().year,
            createdAt.toLocal().month,
            createdAt.toLocal().day,
          );
          return !orderDate.isBefore(start) && orderDate.isBefore(end);
        })
        .fold<double>(0, (total, order) => total + order.total);
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    }
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  Future<void> _loadTodayVisits() async {
    try {
      final now = DateTime.now();
      final today =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      final visits = await VisitService.fetchTodayVisits(date: today);
      if (!mounted) return;
      setState(() {
        _todayVisits = visits;
        _visitsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _visitsLoading = false);
      AppWidgets.toast(context, 'Could not load visits');
    }
  }

  Future<void> _checkAttendanceStatus() async {
    final isLoggedIn = await CheckInService.getStatus();
    if (!mounted) return;

    setState(() {
      _checkedIn = isLoggedIn;
    });
    if (!isLoggedIn) {
      _showCheckInGate();
    }
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _refreshTick++);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkAttendanceStatus(),
    );
    _loadTodayVisits();
    _loadTarget();
    loadOverview();
  }

  /// Opens the visit check-in screen and, if a check-in was actually
  /// submitted (the screen pops with a non-null payload), refreshes
  /// today's visit list — and the target/order progress, since a new
  /// visit can follow an order.
  Future<void> _openNewVisit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewVisitScreen()),
    );
    if (!mounted) return;
    if (result != null) {
      _loadTodayVisits();
      _loadTarget();
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  IconData _categoryIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('built')) return Icons.kitchen_outlined;
    if (c.contains('chy') || c.contains('chimney')) {
      return Icons.local_fire_department_outlined;
    }
    if (c.contains('dws') || c.contains('dish')) {
      return Icons.water_drop_outlined;
    }
    if (c.contains('hob')) return Icons.whatshot_outlined;
    if (c.contains('bbq')) return Icons.outdoor_grill_outlined;
    if (c.contains('fry')) return Icons.brunch_dining_outlined;
    return Icons.category_outlined;
  }

  Color _categoryColor(int index) {
    const palette = [
      AppColors.productChimney,
      AppColors.productHobs,
      AppColors.productWaterPurifiers,
      AppColors.regionCyan,
    ];
    return palette[index % palette.length];
  }

  Color _categoryBadgeColor(int index) {
    const palette = [
      AppColors.amber,
      AppColors.steelLight,
      AppColors.amberDark,
      AppColors.regionBlue,
    ];
    return palette[index % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final topThree = _topCategories.take(3).toList();

    return Scaffold(
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
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _quickAction(
                    Icons.shopping_bag_outlined,
                    'New Order',
                    () => showNewOrderSheet(context),
                    bgColor: AppColors.aiBlue,
                  ),
                  const SizedBox(width: 8),
                  _quickAction(
                    Icons.shopping_bag_outlined,
                    'View Order',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrderListScreen(),
                      ),
                    ),
                    bgColor: AppColors.amber,
                  ),
                  const SizedBox(width: 8),
                  _quickAction(
                    Icons.location_on_outlined,
                    'New Visit',
                    _openNewVisit,
                    bgColor: AppColors.regionCyan,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ---- Monthly Target Card (redesigned) ----
              Builder(
                builder: (context) {
                  final target = _monthlyTarget ?? 0;
                  final targetLabel = _targetLoading
                      ? 'Loading target...'
                      : '${_formatAmount(target)} target';
                  final milestone = target / 4;
                  final progressLabel = _targetLoading
                      ? 'Loading...'
                      : '${_formatAmount(_monthlyOrderTotal)} Achieved';

                  return AppWidgets.buildCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Text(
                                'Monthly target',
                                style: TextStyle(
                                  fontFamily: AppFonts.display,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.line),
                                borderRadius: BorderRadius.circular(6),
                                color: AppColors.regionBlue,
                              ),
                              child: const Icon(
                                Icons.more_horiz,
                                size: 20,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _targetLoading
                              ? 'Fetching your monthly target...'
                              : 'Your monthly target is $targetLabel.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.steel,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(
                          height: 240,
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey(_refreshTick),
                            tween: Tween(begin: 0.0, end: _targetProgress),
                            duration: const Duration(milliseconds: 2300),
                            curve: Curves.easeOutCubic,
                            builder: (context, animatedPercent, _) {
                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  final w = constraints.maxWidth;
                                  final arcRadius = w / 2 - 30;
                                  final arcCenter = Offset(w / 2, 228);
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      CustomPaint(
                                        size: Size(w, 210),
                                        painter: SpeedoPainter(
                                          percent: animatedPercent,
                                        ),
                                      ),
                                      AppWidgets.milestoneDot(
                                        fraction: 0.0,
                                        percent: animatedPercent,
                                        arcRadius: arcRadius,
                                        arcCenter: arcCenter,
                                        label: '₹0',
                                      ),
                                      AppWidgets.milestoneDot(
                                        fraction: 0.25,
                                        percent: animatedPercent,
                                        arcRadius: arcRadius,
                                        arcCenter: arcCenter,
                                        label: _formatAmount(milestone),
                                      ),
                                      AppWidgets.milestoneDot(
                                        fraction: 0.5,
                                        percent: animatedPercent,
                                        arcRadius: arcRadius,
                                        arcCenter: arcCenter,
                                        label: _formatAmount(milestone * 2),
                                      ),
                                      AppWidgets.milestoneDot(
                                        fraction: 0.75,
                                        percent: animatedPercent,
                                        arcRadius: arcRadius,
                                        arcCenter: arcCenter,
                                        label: _formatAmount(milestone * 3),
                                      ),
                                      AppWidgets.milestoneDot(
                                        fraction: 1.0,
                                        percent: animatedPercent,
                                        arcRadius: arcRadius,
                                        arcCenter: arcCenter,
                                        label: _formatAmount(target),
                                      ),
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        top: 220,
                                        child: Text(
                                          progressLabel,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontFamily: AppFonts.display,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),
              AppWidgets.buildCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top selling Product',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_overviewLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else if (topThree.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No category sales for this period yet.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.steel,
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          for (int i = 0; i < topThree.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(
                              child: AppWidgets.topProductTile(
                                rank: i + 1,
                                icon: _categoryIcon(topThree[i].name),
                                name: topThree[i].name,
                                units:
                                    '${topThree[i].percentage.toStringAsFixed(1)}%',
                                color: _categoryColor(i),
                                badgeColor: _categoryBadgeColor(i),
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Today's visits · ${_todayVisits.length}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.aiBlueChipBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '✦ Yours Visit',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 9.5,
                        color: AppColors.aiBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_visitsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_todayVisits.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No visits scheduled for today.'),
                )
              else
                SizedBox(
                  height: 320,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _todayVisits.length,
                    itemBuilder: (context, index) {
                      final visit = _todayVisits[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _visitCard(
                          context,
                          visit.visitorName,
                          visit.address,
                          visit.address,
                          visit.timeLabel,
                          AppColors.amberLight,
                          AppColors.amberDark,
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }

  Widget _quickAction(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? bgColor,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 25),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              Icon(icon, size: 30, color: AppColors.white),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _visitCard(
    BuildContext context,
    String name,
    String location,
    String address,
    String time,
    Color badgeBg,
    Color badgeColor,
  ) {
    return InkWell(
      onTap: _openNewVisit,
      child: AppWidgets.buildCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.steel,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppWidgets.buildBadge(time, badgeBg, badgeColor),
          ],
        ),
      ),
    );
  }

  Future<void> _showCheckInGate() async {
    final result = await showCheckInRequiredDialog(context);
    if (!mounted) return;
    if (result) setState(() => _checkedIn = true);
  }
}
