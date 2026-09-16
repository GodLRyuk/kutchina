import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/provider/auth_provider.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/utils/dialog_box.dart';
import 'package:kutchina/core/utils/speedometer.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_bottom_nav.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
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
  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) => _showCheckInGate());
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _refreshTick++);
    AppWidgets.toast(context, 'Dashboard refreshed');
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
    return Scaffold(
      appBar: AppTopBar.greeting(
        greeting: getGreeting(),
        subtitle: user!.fullName,
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
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NewVisitScreen()),
                    ),
                    bgColor: AppColors.regionCyan,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ---- Monthly Target Card (redesigned) ----
              AppWidgets.buildCard(
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
                    const Text(
                      'Your monthly target progress and see how close you are.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.steel,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(
                      height: 240,
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(_refreshTick),
                        tween: Tween(begin: 0.0, end: 0.25), // target percent
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
                                    label: '₹3L',
                                  ),
                                  AppWidgets.milestoneDot(
                                    fraction: 0.5,
                                    percent: animatedPercent,
                                    arcRadius: arcRadius,
                                    arcCenter: arcCenter,
                                    label: '₹6L',
                                  ),
                                  AppWidgets.milestoneDot(
                                    fraction: 0.75,
                                    percent: animatedPercent,
                                    arcRadius: arcRadius,
                                    arcCenter: arcCenter,
                                    label: '₹9L',
                                  ),
                                  AppWidgets.milestoneDot(
                                    fraction: 1.0,
                                    percent: animatedPercent,
                                    arcRadius: arcRadius,
                                    arcCenter: arcCenter,
                                    label: '₹12L',
                                  ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: 220,
                                    child: Text(
                                      '₹3.8L left',
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
              ),

              const SizedBox(height: 12),
              AppWidgets.buildCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top selling products',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppWidgets.topProductTile(
                            rank: 1,
                            icon: Icons.kitchen_outlined,
                            name: 'Chimney',
                            units: '142 units',
                            color: AppColors.productChimney,
                            badgeColor: AppColors.amber,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppWidgets.topProductTile(
                            rank: 2,
                            icon: Icons.local_fire_department_outlined,
                            name: 'Hobs',
                            units: '98 units',
                            color: AppColors.productHobs,
                            badgeColor: AppColors.steelLight,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppWidgets.topProductTile(
                            rank: 3,
                            icon: Icons.water_drop_outlined,
                            name: 'Water Purifier',
                            units: '71 units',
                            color: AppColors.productWaterPurifiers,
                            badgeColor: AppColors.amberDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              AppWidgets.aiRecommendCard(
                'Call Ananya Das before noon — score 92, highest close-probability lead this week. '
                'Behala Kitchen World is 18 days without a visit — at risk of churn.',
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's visits · 3",
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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
                      '✦ AI-sequenced route',
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
              _visitCard(
                context,
                'Sharma Electronics',
                'Salt Lake, Kolkata',
                '42 Salt Lake Sector V, Kolkata 700091',
                '10:30 AM',
                AppColors.amberLight,
                AppColors.amberDark,
              ),
              const SizedBox(height: 8),
              _visitCard(
                context,
                'Newtown Appliances',
                'Newtown, Kolkata',
                'Newtown, Kolkata 700156',
                '1:00 PM',
                AppColors.coldBg,
                AppColors.coldText,
              ),
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
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NewVisitScreen()),
      ),
      child: AppWidgets.buildCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.steel,
                  ),
                ),
              ],
            ),
            AppWidgets.buildBadge(time, badgeBg, badgeColor),
          ],
        ),
      ),
    );
  }

  Future<void> _showCheckInGate() async {
    final result = await showCheckInRequiredDialog(context);
    if (result) setState(() => _checkedIn = true);
  }
}
