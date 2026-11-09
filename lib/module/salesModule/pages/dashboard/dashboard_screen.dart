import 'package:kutchina/core/offline/sync_service.dart';
import 'package:kutchina/core/services/admin_dashboard_api.dart';
import 'package:kutchina/core/services/target_milestone_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kutchina/core/auth/app_roles.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/core/provider/auth_provider.dart';
import 'package:kutchina/core/utils/admin_services.dart';
import 'package:kutchina/core/utils/dialog_box.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_bottom_nav.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/core/widgets/skeleton_loader.dart';
import 'package:kutchina/module/salesModule/models/order_model.dart';
import 'package:kutchina/module/salesModule/models/visit_model.dart';
import 'package:kutchina/module/salesModule/pages/dashboard/dashboard_elements.dart';
import 'package:kutchina/module/salesModule/pages/visits/new_visit.dart';
import 'package:kutchina/module/salesModule/pages/visits/today_visits_screen.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  final bool showBottomNav;

  const DashboardScreen({super.key, this.showBottomNav = true});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _refreshTick = 0;
  List<VisitEntry> _todayVisits = [];
  bool _visitsLoading = true;
  double? _yearlyTarget;
  int? _targetYear;
  double _yearlyOrderTotal = 0;
  double _targetProgress = 0;
  bool _targetLoading = true;
  List<TargetMilestoneNotification> _targetNotifications = [];
  List<DashboardCategory> _categories = [];
  bool _categoriesLoading = true;
  String? _categoriesError;

  @override
  void initState() {
    super.initState();

    SyncService.instance.addListener(_onSyncChanged);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkAttendanceStatus(),
    );
    _loadTodayVisits();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTarget());
    _loadCategories();
  }

  void _onSyncChanged() {
    if (!mounted || SyncService.instance.isSyncing) return;

    _loadTodayVisits();
    _loadTarget();
    _loadCategories();
  }

  @override
  void dispose() {
    SyncService.instance.removeListener(_onSyncChanged);
    super.dispose();
  }

  Future<void> _loadTarget() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      if (mounted) setState(() => _targetLoading = false);
      return;
    }
    AnnualTarget? annualTarget;
    List<OrderEntry>? orders;
    var targetLoadFailed = false;
    var ordersLoadFailed = false;
    await Future.wait([
      () async {
        try {
          annualTarget = await OrderService.fetchAnnualTarget(
            userId: user.id,
            year: DateTime.now().year,
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

    final targetYear = annualTarget?.year ?? DateTime.now().year;
    final orderTotal = OrderService.calculateAnnualSales(
      orders ?? const [],
      userId: user.id,
      year: targetYear,
    );
    final targetAmount = annualTarget?.amount ?? 0;
    final progress = targetAmount <= 0
        ? 0.0
        : (orderTotal / targetAmount).clamp(0.0, 1.0);
    final userId = user.id;
    final notificationUpdate = userId.isEmpty
        ? const TargetMilestoneUpdate(notifications: [], newlyReached: [])
        : await TargetMilestoneNotificationService.recordProgress(
            userId: userId,
            targetMonth: DateTime(targetYear),
            progress: progress,
          );
    if (!mounted) return;
    setState(() {
      _yearlyTarget = annualTarget?.amount;
      _targetYear = targetYear;
      _yearlyOrderTotal = orderTotal;
      _targetProgress = progress;
      _targetLoading = false;
      _targetNotifications = notificationUpdate.notifications;
    });
    if (targetLoadFailed) {
      AppWidgets.toast(context, 'Could not load yearly target');
    } else if (ordersLoadFailed) {
      AppWidgets.toast(context, 'Could not load yearly orders');
    }
    if (userId.isNotEmpty) {
      for (final notification in notificationUpdate.newlyReached) {
        AppWidgets.toast(context, notification.message);
      }
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesLoading = true;
      _categoriesError = null;
    });
    try {
      final overview = await AdminDashboardApi.fetchOverview();
      final categories = [...overview.salesByCategory]
        ..sort((a, b) => b.percentage.compareTo(a.percentage));
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoriesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categoriesError = 'Could not load category sales.';
        _categoriesLoading = false;
      });
    }
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
    _loadCategories();
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

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      return const Scaffold(body: SkeletonLoader.dashboard());
    }
    final isSalesExecutive = auth.role == AppRole.salesExec;
    final isHod = auth.role == AppRole.hod;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // extendBody: true,
        extendBody: false,
        extendBodyBehindAppBar: true,
        appBar: AppTopBar.brand(
          centerImage: const AssetImage('assets/images/logo.jpg'),
          actions: [
            IconButton(
              onPressed: () => AdminServices.openTargetNotifications(
                context: context,
                mounted: mounted,
                onUpdate: (notifications) {
                  setState(() => _targetNotifications = notifications);
                },
              ),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined),
                  if (_targetNotifications.any(
                    (notification) => !notification.isRead,
                  ))
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        body: AppBackground(
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + kToolbarHeight,
            ),
            child: RefreshIndicator(
              backgroundColor: Colors.transparent,
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16),
                // padding: EdgeInsets.fromLTRB(
                //   16,
                //   MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
                //   16,
                //   16,
                // ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getGreeting(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.steel,
                      ),
                    ),
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    if (isSalesExecutive) ...[
                      const SizedBox(height: 12),
                      DashboardElements.topModule(context),
                      const SizedBox(height: 12),
                      DashboardElements.performanceBox(
                        yearlyTarget: _yearlyTarget,
                        targetYear: _targetYear,
                        yearlyOrderTotal: _yearlyOrderTotal,
                        targetProgress: _targetProgress,
                        targetLoading: _targetLoading,
                        refreshTick: _refreshTick,
                        onTargetTap: () => AdminServices.openTarget(context),
                      ),
                      const SizedBox(height: 12),
                      DashboardElements.topSellingCategory(
                        categories: _categories,
                        loading: _categoriesLoading,
                        error: _categoriesError,
                        onRetry: _loadCategories,
                      ),
                      const SizedBox(height: 16),
                      DashboardElements.todaysActivity(
                        visitsLoading: _visitsLoading,
                        todayVisits: _todayVisits,
                        onViewVisits: _openTodayVisits,
                        onPlanVisit: _openNewVisit,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (isHod) ...[
                      DashboardElements.hodtopModule(context),
                      const SizedBox(height: 12),
                      DashboardElements.performanceBox(
                        yearlyTarget: _yearlyTarget,
                        targetYear: _targetYear,
                        yearlyOrderTotal: _yearlyOrderTotal,
                        targetProgress: _targetProgress,
                        targetLoading: _targetLoading,
                        refreshTick: _refreshTick,
                        onTargetTap: () => AdminServices.openTarget(context),
                      ),
                      const SizedBox(height: 0),
                      DashboardElements.hodAllModule(context),
                      const SizedBox(height: 12),
                      DashboardElements.topSellingCategory(
                        categories: _categories,
                        loading: _categoriesLoading,
                        error: _categoriesError,
                        onRetry: _loadCategories,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: widget.showBottomNav
            ? Container(
                color: Colors.white,
                child: const AppBottomNav(backgroundColor: Colors.white),
              )
            : null,
      ),
    );
  }

  Future<void> _showCheckInGate() async {
    final result = await showCheckInRequiredDialog(context);
    if (!mounted) return;
    if (result) {
      _loadTodayVisits();
      _loadTarget();
    }
  }
}
