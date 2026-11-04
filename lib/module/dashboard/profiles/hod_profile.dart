import 'package:flutter/material.dart';
import 'package:kutchina/core/auth/app_roles.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/services/admin_dashboard_api.dart';
import 'package:kutchina/core/utils/speedometer.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/core/widgets/skeleton_loader.dart';
import 'package:kutchina/module/admin/admin_products_screen.dart';
import 'package:kutchina/module/admin/admin_team_screen.dart';
import 'package:kutchina/module/admin/reports/reports_hub_screen.dart';
import 'package:kutchina/module/dashboard/dashboard_controller.dart';
import 'package:kutchina/module/dashboard/dashboard_profile.dart';
import 'package:kutchina/module/dashboard/hod_dashboard_controller.dart';
import 'package:kutchina/module/salesExe/pages/dashboard/target_screen.dart';
import 'package:kutchina/module/salesExe/pages/dashboard/top_categories_screen.dart';

class HodProfile extends DashboardProfile {
  @override
  AppRole get role => AppRole.hod;

  @override
  DashboardController createController() => HodDashboardController();

  @override
  List<QuickActionItem> quickActions(
    BuildContext context,
    DashboardController controller,
  ) {
    return [
      QuickActionItem(
        icon: Icons.check_circle_outline,
        label: 'Approvals',
        backgroundColor: AppColors.regionBlue,
        onTap: () => AppWidgets.toast(context, 'Approvals coming soon'),
      ),
      QuickActionItem(
        icon: Icons.people_outline,
        label: 'Users & Roles',
        backgroundColor: AppColors.regionOrange,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminTeamScreen()),
        ),
      ),
      QuickActionItem(
        icon: Icons.inventory_2_outlined,
        label: 'Masters',
        backgroundColor: AppColors.regionPurple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminProductsScreen()),
        ),
      ),
    ];
  }

  @override
  List<Widget> sections(BuildContext context, DashboardController controller) {
    final dashboard = controller as HodDashboardController;
    final data = dashboard.data;
    if (dashboard.loading) {
      return const [SkeletonLoader.dashboard()];
    }
    if (dashboard.error != null && data == null) {
      return [
        _DashboardError(message: dashboard.error!, onRetry: dashboard.load),
      ];
    }
    if (data == null) return const [];
    final targetProgress = (data.targetAchievedPercentage / 100)
        .clamp(0.0, 1.0)
        .toDouble();
    final categories = [...data.salesByCategory]
      ..sort((a, b) => b.value.compareTo(a.value));

    return [
      _HodPerformanceCard(data: data, progress: targetProgress),
      _HodModulesSection(
        modules: [
          _ModuleItem(
            title: 'MIS',
            icon: Icons.receipt_long_outlined,
            color: AppColors.regionCyan,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ReportsHubScreen(showBottomNav: false),
              ),
            ),
          ),
          _ModuleItem(
            title: 'Target & Pricing',
            icon: Icons.receipt_long_outlined,
            color: AppColors.amber,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TargetScreen()),
            ),
          ),
          _ModuleItem(
            title: 'Task Tracker',
            icon: Icons.receipt_long_outlined,
            color: AppColors.regionDarkRed,
            onTap: () => AppWidgets.toast(context, 'Task tracker coming soon'),
          ),
          _ModuleItem(
            title: 'Broadcast & System',
            icon: Icons.receipt_long_outlined,
            color: AppColors.regionBlue,
            onTap: () =>
                AppWidgets.toast(context, 'Broadcast and system coming soon'),
          ),
        ],
      ),
      _HodCategoriesCard(
        categories: categories.take(3).toList(),
        onViewAll: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TopCategoriesScreen()),
        ),
      ),
      if (dashboard.error != null)
        _DashboardError(message: dashboard.error!, onRetry: dashboard.load),
      const SizedBox(height: 12),
    ];
  }
}

class _HodPerformanceCard extends StatelessWidget {
  final AdminDashboardData data;
  final double progress;

  const _HodPerformanceCard({required this.data, required this.progress});

  @override
  Widget build(BuildContext context) {
    final remaining = (data.targetValue - data.totalSalesValue).clamp(
      0.0,
      double.infinity,
    );
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your performance',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const Icon(Icons.more_horiz, color: AppColors.steelLight),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            DateTime.now().year.toString(),
            style: const TextStyle(fontSize: 15, color: AppColors.steel),
          ),
          SizedBox(
            height: MediaQuery.sizeOf(context).width * .42,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: SpeedoPainter(percent: progress)),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${data.targetAchievedPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      const Text(
                        'of yearly target',
                        style: TextStyle(fontSize: 13, color: AppColors.steel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 18, color: AppColors.line),
          Row(
            children: [
              Expanded(
                child: _PerformanceMetric(
                  icon: Icons.payments_outlined,
                  color: AppColors.regionBlue,
                  label: 'Achieved',
                  value: _money(data.totalSalesValue),
                ),
              ),
              const SizedBox(height: 54, child: VerticalDivider(width: 1)),
              Expanded(
                child: _PerformanceMetric(
                  icon: Icons.track_changes_outlined,
                  color: AppColors.amber,
                  label: 'Target',
                  value: _money(data.targetValue),
                ),
              ),
              const SizedBox(height: 54, child: VerticalDivider(width: 1)),
              Expanded(
                child: _PerformanceMetric(
                  icon: Icons.bar_chart,
                  color: AppColors.red,
                  label: 'Remaining',
                  value: _money(remaining),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _PerformanceMetric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 7),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.steel),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

class _HodModulesSection extends StatelessWidget {
  final List<_ModuleItem> modules;

  const _HodModulesSection({required this.modules});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(left: 2, top: 28, bottom: 10),
        child: Text(
          'All Modules',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
      ),
      _ModuleGrid(modules: modules),
    ],
  );
}

class _HodCategoriesCard extends StatelessWidget {
  final List<DashboardCategory> categories;
  final VoidCallback onViewAll;

  const _HodCategoriesCard({required this.categories, required this.onViewAll});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 22, bottom: 8),
    padding: const EdgeInsets.fromLTRB(14, 12, 12, 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.retailerChannelBorder, width: 1.5),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.article_outlined, color: AppColors.regionPurple),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Top Selling Categories',
                style: TextStyle(fontSize: 16, color: AppColors.black),
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.green,
                padding: EdgeInsets.zero,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text('View All'), Icon(Icons.chevron_right)],
              ),
            ),
          ],
        ),
        if (categories.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: _EmptyMessage('No category sales for this period yet.'),
          )
        else
          for (var index = 0; index < categories.length; index++)
            _CategoryRankRow(
              rank: index + 1,
              category: categories[index],
              color: [
                AppColors.regionBlue,
                AppColors.regionCyan,
                AppColors.regionPurple,
              ][index],
              maxValue: categories.first.value,
            ),
      ],
    ),
  );
}

class _ModuleItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModuleItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ModuleGrid extends StatelessWidget {
  final List<_ModuleItem> modules;

  const _ModuleGrid({required this.modules});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: modules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.55,
      ),
      itemBuilder: (context, index) {
        final module = modules[index];
        return Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: module.onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: module.color, width: 1.3),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: module.color.withValues(alpha: .12),
                    child: Icon(module.icon, size: 20, color: module.color),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: module.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.steel),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryRankRow extends StatelessWidget {
  final int rank;
  final DashboardCategory category;
  final Color color;
  final double maxValue;

  const _CategoryRankRow({
    required this.rank,
    required this.category,
    required this.color,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  rank.toString().padLeft(2, '0'),
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ),
              Container(width: 1, height: 26, color: AppColors.line),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.commandCentreText,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: maxValue <= 0
                        ? 0
                        : (category.value / maxValue).clamp(0.0, 1.0),
                    minHeight: 9,
                    backgroundColor: const Color(0xFFE6EAF2),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                _money(category.value),
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
        if (rank < 3) const Divider(height: 1, color: AppColors.line),
      ],
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String message;

  const _EmptyMessage(this.message);

  @override
  Widget build(BuildContext context) =>
      Text(message, style: const TextStyle(color: AppColors.steel));
}

class _DashboardError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(color: AppColors.redDark)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onRetry, child: const Text('Retry')),
          ),
        ],
      ),
    );
  }
}

String _money(double value) {
  if (value.abs() >= 10000000) {
    return '₹${(value / 10000000).toStringAsFixed(1)}Cr';
  }
  if (value.abs() >= 100000) {
    return '₹${(value / 100000).toStringAsFixed(1)}L';
  }
  if (value.abs() >= 1000) {
    return '₹${(value / 1000).toStringAsFixed(0)}K';
  }
  return '₹${value.toStringAsFixed(0)}';
}
