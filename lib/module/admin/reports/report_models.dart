import 'package:kutchina/core/constants/app_theme.dart';
import 'package:flutter/material.dart';

class KpiData {
  final String label;
  final String value;
  final double? changePercent;
  const KpiData({required this.label, required this.value, this.changePercent});
}

class ChartData {
  final List<String> labels;
  final List<double> values;
  final List<double?>? forecastValues;
  final String unit;

  const ChartData({
    required this.labels,
    required this.values,
    this.forecastValues,
    this.unit = '',
  });
}

class RegionStat {
  final String label;
  final int percent;
  const RegionStat({required this.label, required this.percent});
}

class RankedItem {
  final int rank;
  final String name;
  final String metric;
  final double? changePercent;
  const RankedItem({
    required this.rank,
    required this.name,
    required this.metric,
    this.changePercent,
  });
}

class ReportConfig {
  /// Matches the `report_type` value sent in the API payload — used both
  /// as the identifier in this catalog and as the value passed to
  /// POST /api/v1/reports/generate/, so there is only one place this can
  /// drift out of sync.
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color accentBg;
  final String periodLabel;

  final List<KpiData> kpis;

  final String? chartTitle;
  final ChartData? chart;

  final String? regionStatsTitle;
  final List<RegionStat>? regionStats;

  final String? rankedListTitle;
  final List<RankedItem>? rankedList;

  final String? insightsTitle;
  final List<String>? insights;

  /// Only `sales_projection` currently supports the `horizon` param.
  final bool supportsHorizon;

  const ReportConfig({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.accentBg,
    required this.periodLabel,
    required this.kpis,
    this.chartTitle,
    this.chart,
    this.regionStatsTitle,
    this.regionStats,
    this.rankedListTitle,
    this.rankedList,
    this.insightsTitle,
    this.insights,
    this.supportsHorizon = false,
  });

  /// `id` doubles as the `report_type` sent to the API.
  String get apiReportType => id;
}

class ReportCategory {
  final String name;
  final List<ReportConfig> reports;
  const ReportCategory({required this.name, required this.reports});
}

class ReportCatalog {
  /// The six live reports, in the requested order.
  static final List<ReportCategory> categories = [
    ReportCategory(
      name: 'Reports',
      reports: [
        salesProjection, // 1. AI Sales Projection and Target Forecast Report
        productDemand, // 2. Product Performance and Demand Forecast Report
        regionalOpportunity, // 3. Regional Performance and Market Opportunity Report
        dealerPotential, // 4. Dealer Performance and Growth Potential Report
        teamPerformance, // 5. Sales Team Performance and Productivity Report
        orderFulfilment, // 6. Order Fulfilment and Revenue Leakage Report
      ],
    ),
  ];

  // 1. ---------------------------------------------------------------------
  static final salesProjection = ReportConfig(
    id: 'sales_projection',
    title: 'AI Sales Projection and Target Forecast Report',
    subtitle: 'Predicted revenue trajectory vs target, with confidence scoring',
    icon: Icons.auto_graph_rounded,
    accent: AppColors.aiBlue,
    accentBg: AppColors.aiBlueChipBg,
    periodLabel: 'This month',
    supportsHorizon: true,
    kpis: const [
      KpiData(label: 'Current Period Sales', value: '--'),
      KpiData(label: 'Target', value: '--'),
      KpiData(label: 'Projected Sales', value: '--'),
      KpiData(label: 'Confidence', value: '--'),
    ],
  );

  // 2. ---------------------------------------------------------------------
  static final productDemand = ReportConfig(
    id: 'product_demand',
    title: 'Product Performance and Demand Forecast Report',
    subtitle: 'Best/worst sellers, demand trend and stockout risk by SKU',
    icon: Icons.inventory_2_outlined,
    accent: AppColors.green,
    accentBg: AppColors.greenLight,
    periodLabel: 'This month',
    kpis: const [
      KpiData(label: 'Top Product', value: '--'),
      KpiData(label: 'Average Growth', value: '--'),
      KpiData(label: 'Slow Movers', value: '--'),
      KpiData(label: 'Products Analyzed', value: '--'),
    ],
  );

  // 3. ---------------------------------------------------------------------
  static final regionalOpportunity = ReportConfig(
    id: 'regional_opportunity',
    title: 'Regional Performance and Market Opportunity Report',
    subtitle: 'Zone-wise achievement against market potential',
    icon: Icons.public_outlined,
    accent: AppColors.commandCentreText,
    accentBg: AppColors.aiBlueChipBg,
    periodLabel: 'This month',
    kpis: const [
      KpiData(label: 'Leading Region', value: '--'),
      KpiData(label: 'Underserved Region', value: '--'),
      KpiData(label: 'Market Penetration', value: '--'),
      KpiData(label: 'Opportunity Score', value: '--'),
    ],
    regionStatsTitle: 'Target achievement by zone',
  );

  // 4. ---------------------------------------------------------------------
  static final dealerPotential = ReportConfig(
    id: 'dealer_potential',
    title: 'Dealer Performance and Growth Potential Report',
    subtitle: 'Dealer revenue, order frequency and churn risk',
    icon: Icons.storefront_outlined,
    accent: AppColors.aiBlue,
    accentBg: AppColors.aiBlueChipBg,
    periodLabel: 'This month',
    kpis: const [
      KpiData(label: 'Dealer Visits Tracked', value: '--'),
      KpiData(label: 'At-Risk Dealers', value: '--'),
      KpiData(label: 'High-Potential Dealers', value: '--'),
      KpiData(label: 'Avg Visit Frequency', value: '--'),
    ],
  );

  // 5. ---------------------------------------------------------------------
  static final teamPerformance = ReportConfig(
    id: 'team_performance',
    title: 'Sales Team Performance and Productivity Report',
    subtitle: 'Rep-level activity, quota attainment and productivity trends',
    icon: Icons.groups_2_outlined,
    accent: AppColors.aiBlue,
    accentBg: AppColors.aiBlueChipBg,
    periodLabel: 'This month',
    kpis: const [
      KpiData(label: 'Reps Reporting', value: '--'),
      KpiData(label: 'Total Achieved Sales', value: '--'),
      KpiData(label: 'Avg Achievement', value: '--'),
      KpiData(label: 'Flagged for Coaching', value: '--'),
    ],
  );

  // 6. ---------------------------------------------------------------------
  static final orderFulfilment = ReportConfig(
    id: 'order_fulfilment',
    title: 'Order Fulfilment and Revenue Leakage Report',
    subtitle: 'Delivery performance and where revenue is being lost',
    icon: Icons.local_shipping_outlined,
    accent: const Color(0xFFB8860B),
    accentBg: const Color(0xFFFCF3D9),
    periodLabel: 'This month',
    kpis: const [
      KpiData(label: 'Orders', value: '--'),
      KpiData(label: 'Total Order Value', value: '--'),
      KpiData(label: 'At-Risk Orders', value: '--'),
      KpiData(label: 'Revenue At Risk', value: '--'),
    ],
  );
}
