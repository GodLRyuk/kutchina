import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/provider/auth_provider.dart';
import 'package:kutchina/core/services/target_milestone_notification_service.dart';
import 'package:kutchina/core/utils/admin_services.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_bottom_nav.dart';
import 'package:kutchina/core/widgets/skeleton_loader.dart';
import 'package:kutchina/module/distributors/pages/dashboard/dashboard_elements.dart';
import 'package:provider/provider.dart';

class DistributorDashboard extends StatefulWidget {
  final bool showBottomNav;
  const DistributorDashboard({super.key, this.showBottomNav = true});

  @override
  State<DistributorDashboard> createState() => _DistributorDashboardState();
}

class _DistributorDashboardState extends State<DistributorDashboard> {
  List<TargetMilestoneNotification> _targetNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) return;
    final notifications = await TargetMilestoneNotificationService.load(userId);
    if (!mounted) return;
    setState(() => _targetNotifications = notifications);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(body: SkeletonLoader.dashboard());
    }

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
                  if (_targetNotifications.any((n) => !n.isRead))
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
              onRefresh: _loadNotifications,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.steel,
                      ),
                    ),
                    Text(
                      user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DistributorDashboardElements.topModule(context),
                    const SizedBox(height: 16),
                    DistributorDashboardElements.outStandingBalanceCard(),
                    const SizedBox(height: 16),
                    DistributorDashboardElements.monthlySummaryCard(
                      amount: '₹4.8L',
                      orders: 6,
                      changePercent: 12,
                    ),
                    const SizedBox(height: 16),
                    DistributorDashboardElements.ActiveOrder(),

                    const SizedBox(height: 16),

                    DistributorDashboardElements.volumeReward(
                      done: 32,
                      target: 50,
                      freeHobs: 3,
                    ),
                    const SizedBox(height: 16),
                    DistributorDashboardElements.schemesModule(context),
                    //DistributorDashboardElements.topPurchasedCategory(),

                    const SizedBox(height: 20),
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
}
