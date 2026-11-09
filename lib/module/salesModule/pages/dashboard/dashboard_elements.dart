import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/services/admin_dashboard_api.dart';
import 'package:kutchina/core/utils/admin_services.dart';
import 'package:kutchina/core/utils/speedometer.dart';
import 'package:kutchina/core/widgets/admin_widget.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/core/widgets/skeleton_loader.dart';
import 'package:kutchina/module/salesModule/models/visit_model.dart';
import 'package:kutchina/module/salesModule/pages/features/feature_list_screen.dart';
import 'package:kutchina/module/salesModule/pages/order/new_order_sheet.dart';
import 'package:kutchina/module/salesModule/pages/order/order_list_screen.dart';
import 'package:kutchina/module/salesModule/pages/visits/new_visit.dart';

class DashboardElements {
  static Widget topModule(BuildContext context) {
    return Row(
      children: [
        AdminWidget.quickAction(
          Icons.shopping_bag_outlined,
          'New Order',
          () => showNewOrderSheet(context),
          bgColor: AppColors.aiBlue,
        ),
        const SizedBox(width: 8),
        AdminWidget.quickAction(
          Icons.file_copy_outlined,
          'View Order',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OrderListScreen()),
          ),
          bgColor: AppColors.amber,
        ),
        const SizedBox(width: 8),
        AdminWidget.quickAction(
          Icons.location_on_outlined,
          'New Visit',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewVisitScreen()),
          ),
          bgColor: AppColors.regionCyan,
        ),
      ],
    );
  }

  static Widget topSellingCategory({
    required List<DashboardCategory> categories,
    required bool loading,
    String? error,
    required VoidCallback onRetry,
  }) {
    const colors = [
      AppColors.regionBlue,
      AppColors.regionCyan,
      AppColors.regionPurple,
      AppColors.regionOrange,
    ];
    final maxPercentage = categories.isEmpty
        ? 0.0
        : categories.first.percentage;

    return AppWidgets.buildCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 2, bottom: 8),
            child: Text(
              'Top selling categories',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.commandCentreText,
              ),
            ),
          ),
          if (loading)
            const SkeletonLoader(rows: 4)
          else if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Text(error),
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          else if (categories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No category sales yet.')),
            )
          else
            for (var index = 0; index < categories.length; index++) ...[
              if (index > 0) const Divider(height: 1, color: AppColors.line),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${index + 1}'.padLeft(2, '0'),
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors[index % colors.length],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      margin: const EdgeInsets.only(right: 12),
                      color: AppColors.line,
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        categories[index].name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 8,
                          color: AppColors.coldBg,
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: maxPercentage <= 0
                                ? 0.0
                                : (categories[index].percentage / maxPercentage)
                                      .clamp(0.0, 1.0)
                                      .toDouble(),
                            heightFactor: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 62,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          formatAmount(categories[index].value),
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors[index % colors.length],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }

  static Widget performanceBox({
    double? yearlyTarget,
    int? targetYear,
    required double yearlyOrderTotal,
    required double targetProgress,
    required bool targetLoading,
    int refreshTick = 0,
    VoidCallback? onTargetTap,
  }) {
    return Builder(
      builder: (context) {
        final target = yearlyTarget ?? 0;
        final achieved = yearlyOrderTotal;
        final remaining = (target - achieved)
            .clamp(0.0, double.infinity)
            .toDouble();
        final year = targetYear ?? DateTime.now().year;

        return AppWidgets.buildCard(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  IconButton(
                    onPressed:
                        onTargetTap ?? () => AdminServices.openTarget(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.more_horiz,
                      size: 20,
                      color: AppColors.steelLight,
                    ),
                  ),
                ],
              ),
              Text(
                year.toString(),
                style: const TextStyle(fontSize: 13, color: AppColors.steel),
              ),
              SizedBox(
                height: MediaQuery.sizeOf(context).width * 0.50,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(refreshTick),
                  tween: Tween(begin: 0.0, end: targetProgress),
                  duration: const Duration(milliseconds: 1800),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedProgress, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) => Stack(
                        children: [
                          CustomPaint(
                            size: Size(
                              constraints.maxWidth,
                              constraints.maxHeight - 10,
                            ),
                            painter: SpeedoPainter(percent: animatedProgress),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  targetLoading
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
                                const Text(
                                  'of yearly target',
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
              const Divider(height: 2, color: AppColors.line),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: performanceMetric(
                      icon: Icons.payments_outlined,
                      color: AppColors.regionBlue,
                      label: 'Achieved',
                      amount: targetLoading ? '--' : formatAmount(achieved),
                    ),
                  ),
                  metricDivider(),
                  Expanded(
                    child: performanceMetric(
                      icon: Icons.track_changes,
                      color: AppColors.amber,
                      label: 'Target',
                      amount: targetLoading ? '--' : formatAmount(target),
                    ),
                  ),
                  metricDivider(),
                  Expanded(
                    child: performanceMetric(
                      icon: Icons.bar_chart_rounded,
                      color: AppColors.red,
                      label: 'Remaining',
                      amount: targetLoading ? '--' : formatAmount(remaining),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget todaysActivity({
    required bool visitsLoading,
    required List<VisitEntry> todayVisits,
    required VoidCallback onViewVisits,
    required VoidCallback onPlanVisit,
  }) {
    return AppWidgets.buildCard(
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
                onPressed: onViewVisits,
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
                  color: AppColors.achievementIconBg.withValues(alpha: 0.12),
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
                      visitsLoading
                          ? 'Loading visits...'
                          : todayVisits.isEmpty
                          ? 'No visits scheduled'
                          : '${todayVisits.length} ${todayVisits.length == 1 ? 'visit' : 'visits'} Completed',
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
                      style: TextStyle(fontSize: 12, color: AppColors.steel),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onPlanVisit,
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
    );
  }

  static String formatAmount(double amount) {
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

  static Widget metricDivider() => Container(
    width: 1,
    height: 44,
    margin: const EdgeInsets.symmetric(horizontal: 5),
    color: AppColors.line,
  );

  static Widget performanceMetric({
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

  //HOD section starts
  static Widget hodtopModule(BuildContext context) {
    return Row(
      children: [
        AdminWidget.quickAction(
          Icons.shopping_bag_outlined,
          'Approvals',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FeatureListScreen()),
          ),
          bgColor: AppColors.aiBlue,
        ),
        const SizedBox(width: 8),
        AdminWidget.quickAction(
          Icons.file_copy_outlined,
          'Users & Roles',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OrderListScreen()),
          ),
          bgColor: AppColors.amber,
        ),
        const SizedBox(width: 8),
        AdminWidget.quickAction(
          Icons.location_on_outlined,
          'Masters',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewVisitScreen()),
          ),
          bgColor: AppColors.regionPurple,
        ),
      ],
    );
  }

  static Widget hodAllModule(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            AdminWidget.quickAction(
              Icons.shopping_bag_outlined,
              'MIS Reports',
              () => showNewOrderSheet(context),
              bgColor: AppColors.aiBlue,
            ),
            const SizedBox(width: 8),
            AdminWidget.quickAction(
              Icons.file_copy_outlined,
              'Target & Pricing',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderListScreen()),
              ),
              bgColor: AppColors.amber,
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            AdminWidget.quickAction(
              Icons.shopping_bag_outlined,
              'Task Management',
              () => showNewOrderSheet(context),
              bgColor: AppColors.amberDark,
            ),
            const SizedBox(width: 8),
            AdminWidget.quickAction(
              Icons.file_copy_outlined,
              'Broadcasting',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderListScreen()),
              ),
              bgColor: AppColors.buttonGradientStart,
            ),
          ],
        ),
      ],
    );
  }
}
