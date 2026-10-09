import 'package:kutchina/core/offline/sync_service.dart';
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
import 'package:kutchina/module/salesExe/pages/visits/today_visits_screen.dart';
import 'package:kutchina/module/salesExe/pages/order/new_order_sheet.dart';
import 'package:kutchina/module/salesExe/pages/order/order_list_screen.dart';
import 'package:kutchina/module/salesExe/pages/dashboard/top_categories_screen.dart';
import 'package:intl/intl.dart';
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
  DateTime? _monthlyTargetMonth;
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

    SyncService.instance.addListener(_onSyncChanged);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkAttendanceStatus(),
    );
    _loadTodayVisits();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTarget());
    loadOverview();
  }

  void _onSyncChanged() {
    if (!mounted || SyncService.instance.isSyncing) return;

    _loadTodayVisits();
    _loadTarget();
    loadOverview();
  }

  @override
  void dispose() {
    SyncService.instance.removeListener(_onSyncChanged);
    super.dispose();
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
    MonthlyTarget? monthlyTarget;
    List<OrderEntry>? orders;
    var targetLoadFailed = false;
    var ordersLoadFailed = false;
    await Future.wait([
      () async {
        try {
          monthlyTarget = await OrderService.fetchCurrentTarget(
            userId: user.id,
          );
        } catch (_) {
          targetLoadFailed = true;
        }
      }(),
      () async {
        try {
          orders = await OrderService.fetchOrders();
        } catch (_) {
          ordersLoadFailed = true;
        }
      }(),
    ]);

    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    final targetMonth = monthlyTarget?.month ?? currentMonth;
    final orderTotal = _calculateOrderTotal(
      orders ?? const [],
      month: targetMonth,
      targetDate: monthlyTarget?.targetDate,
    );
    final targetAmount = monthlyTarget?.amount ?? 0;
    final progress = targetAmount <= 0
        ? 0.0
        : (orderTotal / targetAmount).clamp(0.0, 1.0);
    if (!mounted) return;
    setState(() {
      _monthlyTarget = monthlyTarget?.amount;
      _monthlyTargetMonth = targetMonth;
      _monthlyOrderTotal = orderTotal;
      _targetProgress = progress;
      _targetLoading = false;
    });
    if (targetLoadFailed) {
      AppWidgets.toast(context, 'Could not load monthly target');
    } else if (ordersLoadFailed) {
      AppWidgets.toast(context, 'Could not load monthly orders');
    }
  }

  double _calculateOrderTotal(
    List<OrderEntry> orders, {
    required DateTime month,
    required DateTime? targetDate,
  }) {
    final start = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 1);
    final targetEnd = targetDate == null
        ? monthEnd
        : DateTime(targetDate.year, targetDate.month, targetDate.day + 1);
    final end = targetEnd.isBefore(monthEnd) ? targetEnd : monthEnd;

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

  void _openTodayVisits() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TodayVisitsScreen()),
    );
  }

  void _openTopCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TopCategoriesScreen()),
    );
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Color _categoryColor(int index) {
    const palette = [
      AppColors.regionBlue,
      AppColors.regionCyan,
      AppColors.regionPurple,
      AppColors.regionOrange,
    ];
    return palette[index % palette.length];
  }

  Widget _categorySalesRow(
    int index,
    DashboardCategory category,
    double maxPercentage,
    bool showDivider,
  ) {
    final color = _categoryColor(index);
    final progress = maxPercentage <= 0
        ? 0.0
        : (category.percentage / maxPercentage).clamp(0.0, 1.0).toDouble();

    return Column(
      children: [
        InkWell(
          onTap: _openTopCategories,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                SizedBox(
                  width: 27,
                  child: Text(
                    '${index + 1}'.padLeft(2, '0'),
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 22,
                  margin: const EdgeInsets.only(right: 10),
                  color: AppColors.line,
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 8,
                      color: AppColors.coldBg,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 53,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatAmount(category.value),
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.steel,
                ),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, color: AppColors.line),
      ],
    );
  }

  Widget _metricDivider() => Container(
    width: 1,
    height: 44,
    margin: const EdgeInsets.symmetric(horizontal: 5),
    color: AppColors.line,
  );

  Widget _performanceMetric({
    required IconData icon,
    required Color color,
    required String label,
    required String amount,
  }) {
    return Row(
      children: [
        Icon(icon, size: 26, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: AppColors.steel),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
                    Icons.file_copy_outlined,
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
              // ---- Monthly performance ----
              Builder(
                builder: (context) {
                  final target = _monthlyTarget ?? 0;
                  final achieved = _monthlyOrderTotal;
                  final remaining = (target - achieved)
                      .clamp(0.0, double.infinity)
                      .toDouble();
                  final month = DateFormat(
                    'MMMM yyyy',
                  ).format(_monthlyTargetMonth ?? DateTime.now());

                  return AppWidgets.buildCard(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Monthly performance',
                                style: TextStyle(
                                  fontFamily: AppFonts.display,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.more_horiz,
                              size: 20,
                              color: AppColors.steelLight,
                            ),
                          ],
                        ),
                        Text(
                          month,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.steel,
                          ),
                        ),
                        // SizedBox(height: 20),
                        SizedBox(
                          height: 208,
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey(_refreshTick),
                            tween: Tween(begin: 0.0, end: _targetProgress),
                            duration: const Duration(milliseconds: 1800),
                            curve: Curves.easeOutCubic,
                            builder: (context, animatedProgress, _) {
                              return LayoutBuilder(
                                builder: (context, constraints) => Stack(
                                  children: [
                                    CustomPaint(
                                      size: Size(
                                        constraints.maxWidth,
                                        constraints.maxHeight,
                                      ),
                                      painter: SpeedoPainter(
                                        percent: animatedProgress,
                                      ),
                                    ),
                                    Positioned(
                                      top: 160,
                                      left: 0,
                                      right: 0,
                                      child: Column(
                                        children: [
                                          Text(
                                            _targetLoading
                                                ? '--%'
                                                : '${(animatedProgress * 100).round()}%',
                                            style: const TextStyle(
                                              fontFamily: AppFonts.display,
                                              fontSize: 20,
                                              height: 1,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                          // const SizedBox(height: 3),
                                          const Text(
                                            'of monthly target',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.steel,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.line),

                        Row(
                          children: [
                            Expanded(
                              child: _performanceMetric(
                                icon: Icons.payments_outlined,
                                color: AppColors.regionBlue,
                                label: 'Achieved',
                                amount: _targetLoading
                                    ? '--'
                                    : _formatAmount(achieved),
                              ),
                            ),
                            _metricDivider(),
                            Expanded(
                              child: _performanceMetric(
                                icon: Icons.track_changes,
                                color: AppColors.amber,
                                label: 'Target',
                                amount: _targetLoading
                                    ? '--'
                                    : _formatAmount(target),
                              ),
                            ),
                            _metricDivider(),
                            Expanded(
                              child: _performanceMetric(
                                icon: Icons.bar_chart_rounded,
                                color: AppColors.red,
                                label: 'Remaining',
                                amount: _targetLoading
                                    ? '--'
                                    : _formatAmount(remaining),
                              ),
                            ),
                          ],
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
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Top selling categories',
                            style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _openTopCategories,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.regionCyan,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('View all'),
                              Icon(Icons.chevron_right, size: 21),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                      Column(
                        children: [
                          for (var index = 0; index < topThree.length; index++)
                            _categorySalesRow(
                              index,
                              topThree[index],
                              topThree.first.percentage,
                              index < topThree.length - 1,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppWidgets.buildCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Today's activity",
                            style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _openTodayVisits,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.regionCyan,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('View visits'),
                              Icon(Icons.chevron_right, size: 21),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.achievementIconBg.withValues(
                              alpha: 0.12,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_month_outlined,
                            color: AppColors.achievementIconBg,
                            size: 29,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _visitsLoading
                                    ? 'Loading visits...'
                                    : _todayVisits.isEmpty
                                    ? 'No visits scheduled'
                                    : '${_todayVisits.length} ${_todayVisits.length == 1 ? 'visit' : 'visits'} Completed',
                                style: const TextStyle(
                                  fontFamily: AppFonts.display,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Keep your dealer network active',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.steel,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _openNewVisit,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.regionCyan),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: AppColors.regionCyan,
                              size: 27,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Plan a visit',
                                style: TextStyle(
                                  fontFamily: AppFonts.display,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.regionCyan,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.regionCyan,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: bgColor?.withOpacity(1) ?? AppColors.line,
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(icon, size: 30, color: bgColor),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: bgColor,
                  ),
                ),
              ],
            ),
          ),
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
