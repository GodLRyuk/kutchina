import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/admin_widget.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/core/widgets/coming_soon_tab.dart';
import 'package:kutchina/module/distributors/pages/Offers_Schemes/offers_screen.dart';
import 'package:kutchina/module/distributors/pages/ledger/ledger_screen.dart';
import 'package:kutchina/module/distributors/pages/order/new_order_screen.dart';
import 'package:kutchina/module/distributors/pages/order/view_order_screen.dart';
import 'package:kutchina/module/distributors/pages/supports/support_screen.dart';


class DistributorDashboardElements {
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
          Icons.local_shipping,
          'Track Order',
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ViewOrderListScreen(),
            ),
          ),
          bgColor: AppColors.amber,
        ),
        const SizedBox(width: 8),
        AdminWidget.quickAction(
          Icons.help_outline,
          'Support',
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SupportScreen(),
            ),
          ),
          bgColor: AppColors.regionCyan,
        ),
      ],
    );
  }

 static Widget schemesModule(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Schemes & Offers',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.commandCentreText,
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OffersScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See all',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.viewAllButton,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.viewAllButton),
                ],
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 10),

      // Horizontal scheme cards (height adapts to content)
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _schemeCard(
                title: 'Festive scheme',
                description: 'Extra 2% on orders above ₹1,00,000',
                validity: 'Valid till 30 Nov',
                color: AppColors.highPerformersBg,
                icon: Icons.celebration_outlined,
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _schemeCard(
                title: 'New launch',
                description: 'Early-bird pricing on new range',
                validity: 'Order before 20 Nov',
                color: AppColors.topProductBg,
                icon: Icons.new_releases_outlined,
                urgent: true,
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _schemeCard(
                title: 'Special offer',
                description: 'Get exciting discounts on orders',
                validity: 'Limited period offer',
                color: AppColors.achievementIconBg,
                icon: Icons.local_offer_outlined,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

static Widget _schemeCard({
  required String title,
  required String description,
  required String validity,
  required Color color,
  IconData icon = Icons.local_offer_outlined,
  bool urgent = false,
  VoidCallback? onTap,
}) {
  final lighter = Color.lerp(color, AppColors.white, 0.16)!;
  final pillBg =
      urgent ? AppColors.amber : AppColors.white.withOpacity(0.16);
  final pillFg = urgent ? AppColors.amberDark : AppColors.white;

  return Container(
    width: 260,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.md),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, lighter],
      ),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.25),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Material(
      type: MaterialType.transparency,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(icon, size: 14, color: AppColors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        color: AppColors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (urgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Closing soon',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: pillFg,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Main message
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  color: AppColors.white,
                  fontSize: 15,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),
              const Spacer(),

              Container(
                  height: 1, color: AppColors.white.withOpacity(0.16)),

              const SizedBox(height: 10),

              // Footer
              Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 14, color: AppColors.white.withOpacity(0.78)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      validity,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        color: AppColors.white.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AppColors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
  static Widget topPurchasedCategory() {
    const names = ['Category A', 'Category B', 'Category C', 'Category D'];
    const values = [12.4, 9.1, 5.6, 3.9];
    const colors = [
      AppColors.regionBlue,
      AppColors.regionCyan,
      AppColors.regionPurple,
      AppColors.regionOrange,
    ];
    const trackColor = Color(0xFFEEF0F4);
    const maxValue = 12.4;

    return AppWidgets.buildCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              'Top purchased categories',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.commandCentreText,
              ),
            ),
          ),
          for (var i = 0; i < names.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  names[i],
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '₹${values[i].toStringAsFixed(1)}L',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 8,
                color: trackColor,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: values[i] / maxValue,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors[i],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget ActiveOrder() {
    const stats = [
      (2, 'Pending', Color(0xFFFFF4E0), Color(0xFF7A4A00)),
      (1, 'Processing', Color(0xFFE8F0FD), Color(0xFF173F86)),
      (3, 'Dispatched', Color(0xFFEFE9FB), Color(0xFF4B2A94)),
      (14, 'Delivered', Color(0xFFE3F6EC), Color(0xFF0B5B36)),
    ];

    return AppWidgets.buildCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Orders',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.commandCentreText,
                  ),
                ),
                Text(
                  'Track All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF006B70),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),

          Row(
            children: [
              for (int i = 0; i < stats.length; i++) ...[
                Expanded(
                  child: _statusBox(
                    count: stats[i].$1,
                    label: stats[i].$2,
                    bg: stats[i].$3,
                    fg: stats[i].$4,
                    onTap: () {
                      // open orders list filtered by stats[i].$2
                    },
                  ),
                ),
                if (i != stats.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static Widget _statusBox({
    required int count,
    required String label,
    required Color bg,
    required Color fg,
    VoidCallback? onTap,
  }) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: TextStyle(fontSize: 12, color: fg)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget outStandingBalanceCard() {
  return Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias, // clips the watermark at the rounded corners
    decoration: BoxDecoration(
      gradient: AppColors.buttonGradient,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Stack(
      children: [
        // Watermark icon
        Positioned(
          right: -8,
          // top: 0,
          child: Transform.rotate(
            angle: 0.14,
            child: Icon(
              Icons.currency_rupee_rounded,
              size: 112,
              color: AppColors.white.withOpacity(0.16),
            ),
          ),
        ),

        // Content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Outstanding Balance',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '₹1,84,500',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.37,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '37% of ₹5,00,000 limit used',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Available ₹3,15,500',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  static Widget volumeReward({
    required int done,
    required int target,
    required int freeHobs,
  }) {
    final double progress = (done / target).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF6B2D0F), Color(0xFF8B3A12)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'VOLUME REWARD',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$done of $target hobs done · $freeHobs free on completion',
            style: const TextStyle(
              fontSize: 16,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  static Widget monthlySummaryCard({
  required String amount,        // e.g. '₹4.8L'
  required int orders,           // e.g. 6
  required double changePercent, // e.g. 12 or -8
  DateTime? now,
}) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final date = now ?? DateTime.now();
  final thisMonth = months[date.month - 1];
  final lastMonth = months[(date.month - 2) % 12];

  final up = changePercent >= 0;
  final trendColor = up ? AppColors.green : AppColors.red;
  final trendBg = up ? AppColors.greenLight : AppColors.redLight;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.line),
      boxShadow: [
        BoxShadow(
          color: AppColors.charcoal.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.shopping_bag_outlined,
                size: 15, color: AppColors.steel),
            const SizedBox(width: 6),
            Text(
              'Ordered in $thisMonth',
              style: const TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.steel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: AppColors.commandCentreText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'across $orders ${orders == 1 ? 'order' : 'orders'}',
                  style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12.5,
                    color: AppColors.steel,
                  ),
                ),
              ],
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: trendBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    up
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 14,
                    color: trendColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${changePercent.abs().toStringAsFixed(0)}% ${up ? 'more' : 'less'} than $lastMonth',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
}
