import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/services/report_api.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/admin/reports/report_models.dart';
import 'package:flutter/material.dart';

/// One screen template shared by every report. `report.id` doubles as the
/// `report_type` sent to the API (see [ReportConfig.apiReportType]), so
/// there's no separate id to keep in sync. Five of the six reports have a
/// confirmed response shape and get a dedicated typed section;
/// regional_opportunity falls back to a generic live-data viewer until its
/// shape is confirmed.
class ReportDetailScreen extends StatefulWidget {
  final ReportConfig report;
  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  static const _periodLabels = {
    'today': 'Today',
    'week': 'Last 7 days',
    'month': 'This month',
    'six_months': 'Last 6 months',
    'year': 'Last 12 months',
  };

  static const _typedIds = {
    'product_demand',
    'dealer_potential',
    'order_fulfilment',
    'sales_projection',
    'team_performance',
  };

  String _period = 'month';
  String _horizon = 'current';

  ProductDemandReport? _productDemand;
  DealerPotentialReport? _dealerPotential;
  OrderFulfilmentReport? _orderFulfilment;
  SalesProjectionReport? _salesProjection;
  TeamPerformanceReport? _teamPerformance;
  Map<String, dynamic>? _rawBody; // generic fallback (regional_opportunity)

  String? _error;
  bool _loading = false;

  ReportConfig get report => widget.report;
  bool get _hasTypedSection => _typedIds.contains(report.id);

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      switch (report.id) {
        case 'product_demand':
          final result = await AdminReportApi.generateProductDemand(
            period: _period,
          );
          if (!mounted) return;
          setState(() => _productDemand = result);
          break;
        case 'dealer_potential':
          final result = await AdminReportApi.generateDealerPotential(
            period: _period,
          );
          if (!mounted) return;
          setState(() => _dealerPotential = result);
          break;
        case 'order_fulfilment':
          final result = await AdminReportApi.generateOrderFulfilment(
            period: _period,
          );
          if (!mounted) return;
          setState(() => _orderFulfilment = result);
          break;
        case 'sales_projection':
          final result = await AdminReportApi.generateSalesProjection(
            period: _period,
            horizon: _horizon,
          );
          if (!mounted) return;
          setState(() => _salesProjection = result);
          break;
        case 'team_performance':
          final result = await AdminReportApi.generateTeamPerformance(
            period: _period,
          );
          if (!mounted) return;
          setState(() => _teamPerformance = result);
          break;
        default:
          // regional_opportunity — no typed model yet
          final body = await AdminReportApi.generate(
            reportType: report.apiReportType,
            period: _period,
          );
          if (!mounted) return;
          setState(() => _rawBody = body);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to generate this report');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onPeriodChanged(String value) {
    if (value == _period) return;
    setState(() => _period = value);
    _loadReport();
  }

  void _onHorizonChanged(String value) {
    if (value == _horizon) return;
    setState(() => _horizon = value);
    _loadReport();
  }

  List<KpiData> get _kpis {
    switch (report.id) {
      case 'product_demand':
        return _productDemand == null
            ? report.kpis
            : _productDemandKpis(_productDemand!);
      case 'dealer_potential':
        return _dealerPotential == null
            ? report.kpis
            : _dealerPotentialKpis(_dealerPotential!);
      case 'order_fulfilment':
        return _orderFulfilment == null
            ? report.kpis
            : _orderFulfilmentKpis(_orderFulfilment!);
      case 'sales_projection':
        return _salesProjection == null
            ? report.kpis
            : _salesProjectionKpis(_salesProjection!);
      case 'team_performance':
        return _teamPerformance == null
            ? report.kpis
            : _teamPerformanceKpis(_teamPerformance!);
      default:
        final summary = _asMap(_rawBody?['summary']);
        final live = _genericKpisFromSummary(summary);
        return live.isNotEmpty ? live : report.kpis;
    }
  }

  String get _displayPeriodLabel => _periodLabels[_period] ?? _period;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.ash,
            surfaceTintColor: AppColors.ash,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                size: 16,
                color: AppColors.ink,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              report.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.ios_share_outlined,
                  size: 20,
                  color: AppColors.ink,
                ),
                onPressed: () =>
                    AppWidgets.toast(context, 'Export coming soon'),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _Hero(report: report, periodLabel: _displayPeriodLabel),
                const SizedBox(height: 14),

                _PeriodSelector(
                  value: _period,
                  accent: report.accent,
                  onChanged: _loading ? (_) {} : _onPeriodChanged,
                ),
                if (_period == 'today' || _period == 'week') ...[
                  const SizedBox(height: 8),
                  Text(
                    "Target-based figures aren't available for this period.",
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.steel.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (report.supportsHorizon) ...[
                  const SizedBox(height: 10),
                  _HorizonSelector(
                    value: _horizon,
                    accent: report.accent,
                    onChanged: _loading ? (_) {} : _onHorizonChanged,
                  ),
                ],
                const SizedBox(height: 14),

                if (_error != null)
                  _ReportError(message: _error!, onRetry: _loadReport),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.55,
                  children: _kpis
                      .map((k) => _KpiCard(kpi: k, accent: report.accent))
                      .toList(),
                ),

                // ---- Typed sections ----
                if (report.id == 'product_demand' &&
                    _productDemand != null) ...[
                  const SizedBox(height: 14),
                  _ProductDemandSection(report: _productDemand!),
                ],
                if (report.id == 'dealer_potential' &&
                    _dealerPotential != null) ...[
                  const SizedBox(height: 14),
                  _DealerPotentialSection(
                    report: _dealerPotential!,
                    accent: report.accent,
                  ),
                ],
                if (report.id == 'order_fulfilment' &&
                    _orderFulfilment != null) ...[
                  const SizedBox(height: 14),
                  _OrderFulfilmentSection(
                    report: _orderFulfilment!,
                    accent: report.accent,
                  ),
                ],
                if (report.id == 'sales_projection' &&
                    _salesProjection != null) ...[
                  const SizedBox(height: 14),
                  _SalesProjectionSection(
                    report: _salesProjection!,
                    accent: report.accent,
                  ),
                ],
                if (report.id == 'team_performance' &&
                    _teamPerformance != null) ...[
                  const SizedBox(height: 14),
                  _TeamPerformanceSection(
                    report: _teamPerformance!,
                    accent: report.accent,
                  ),
                ],

                // ---- Region bars — only populated if a report defines
                // report.regionStats (none currently do; kept for when
                // regional_opportunity gets a typed model) ----
                if (report.regionStats != null &&
                    report.regionStats!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: report.regionStatsTitle ?? 'Breakdown',
                    accent: report.accent,
                    child: Column(
                      children: report.regionStats!
                          .map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _RegionBar(stat: r, accent: report.accent),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],

                // ---- Generic live view — only for regional_opportunity ----
                if (!_hasTypedSection && _rawBody != null) ...[
                  const SizedBox(height: 14),
                  // const _LiveDataBanner(),
                  if (_rawBody!['data'] is List &&
                      (_rawBody!['data'] as List).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _GenericListSection(
                      title: report.rankedListTitle ?? 'Live report data',
                      accent: report.accent,
                      items: _rawBody!['data'] as List,
                    ),
                  ],
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ---- KPI builders ----

  List<KpiData> _productDemandKpis(ProductDemandReport r) {
    final topProduct = r.summary.topProductName.isEmpty
        ? 'Unavailable'
        : r.summary.topProductName;
    return [
      KpiData(label: 'Top Product', value: topProduct),
      KpiData(
        label: 'Average Growth',
        value: _percent(r.summary.averageGrowthPercentage),
        changePercent: r.summary.averageGrowthPercentage,
      ),
      KpiData(label: 'Slow Movers', value: '${r.summary.slowMoversCount}'),
      KpiData(label: 'Products Analyzed', value: '${r.items.length}'),
    ];
  }

  List<KpiData> _dealerPotentialKpis(DealerPotentialReport r) => [
    KpiData(label: 'Dealer Visits Tracked', value: '${r.items.length}'),
    KpiData(label: 'At-Risk Dealers', value: '${r.atRiskCount}'),
    KpiData(label: 'High-Potential Dealers', value: '${r.highPotentialCount}'),
    KpiData(
      label: 'Avg Visit Frequency',
      value: r.avgVisitFrequency.toStringAsFixed(1),
    ),
  ];

  List<KpiData> _orderFulfilmentKpis(OrderFulfilmentReport r) => [
    KpiData(label: 'Orders', value: '${r.items.length}'),
    KpiData(label: 'Total Order Value', value: _currency(r.totalGrossValue)),
    KpiData(label: 'At-Risk Orders', value: '${r.atRiskCount}'),
    KpiData(label: 'Revenue At Risk', value: _currency(r.totalAtRiskValue)),
  ];

  List<KpiData> _salesProjectionKpis(SalesProjectionReport r) {
    if (r.items.isEmpty) return report.kpis;
    final item = r.items.first;
    return [
      KpiData(
        label: 'Current Period Sales',
        value: _currency(item.currentPeriodSales),
      ),
      KpiData(label: 'Target', value: _currency(item.targetValue)),
      KpiData(label: 'Projected Sales', value: _currency(item.projectedSales)),
      KpiData(
        label: 'Confidence',
        value: '${item.confidencePercentage.toStringAsFixed(0)}%',
      ),
    ];
  }

  List<KpiData> _teamPerformanceKpis(TeamPerformanceReport r) => [
    KpiData(label: 'Reps Reporting', value: '${r.items.length}'),
    KpiData(
      label: 'Total Achieved Sales',
      value: _currency(r.totalAchievedSales),
    ),
    KpiData(
      label: 'Avg Achievement',
      value: '${r.avgAchievementPercentage.toStringAsFixed(0)}%',
    ),
    KpiData(label: 'Flagged for Coaching', value: '${r.coachingFlagCount}'),
  ];

  String _percent(double? value) =>
      value == null ? '--' : '${value.toStringAsFixed(1)}%';

  List<KpiData> _genericKpisFromSummary(Map<String, dynamic> summary) {
    final entries = summary.entries
        .where(
          (e) =>
              e.value != null &&
              e.value is! Map &&
              e.value is! List &&
              e.value.toString().trim().isNotEmpty,
        )
        .take(4)
        .toList();
    return entries
        .map(
          (e) => KpiData(label: _prettify(e.key), value: _formatValue(e.value)),
        )
        .toList();
  }
}

class _ReportError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ReportError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(message, style: const TextStyle(color: AppColors.red)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// =============================================================================
// 2. Product demand section
// =============================================================================
class _ProductDemandSection extends StatelessWidget {
  final ProductDemandReport report;
  const _ProductDemandSection({required this.report});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Product demand',
      accent: AppColors.green,
      child: Column(
        children: [
          for (int i = 0; i < report.items.length; i++) ...[
            _ProductDemandRow(item: report.items[i]),
            if (i != report.items.length - 1)
              const Divider(height: 22, color: AppColors.line),
          ],
          if (report.items.isEmpty)
            const Text(
              'No product demand data returned for this period.',
              style: TextStyle(fontSize: 12, color: AppColors.steel),
            ),
        ],
      ),
    );
  }
}

class _ProductDemandRow extends StatelessWidget {
  final ProductDemandItem item;
  const _ProductDemandRow({required this.item});

  @override
  Widget build(BuildContext context) {
    // demand_direction comes back lowercase ("rising" / "falling" / "stable")
    final direction = item.demandDirection.toLowerCase();
    final directionColor = direction == 'rising'
        ? AppColors.green
        : direction == 'falling'
        ? AppColors.red
        : AppColors.steel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.productName,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              direction.isEmpty ? '--' : direction,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: directionColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _Metric(label: 'Sold', value: '${item.unitsSold} units'),
            _Metric(label: 'Sales', value: _currency(item.salesValue)),
            _Metric(
              label: 'Projected',
              value: '${item.projectedDemandUnits.toStringAsFixed(0)} units',
            ),
            _Metric(
              label: 'Confidence',
              value: '${(item.confidence * 100).toStringAsFixed(0)}%',
            ),
          ],
        ),
        if (item.insight.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            item.insight,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.35,
              color: AppColors.steel,
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// 4. Dealer potential section
// =============================================================================
class _DealerPotentialSection extends StatelessWidget {
  final DealerPotentialReport report;
  final Color accent;
  const _DealerPotentialSection({required this.report, required this.accent});

  @override
  Widget build(BuildContext context) {
    const priority = {'at_risk': 0, 'high_potential': 1, 'steady': 2};
    final sorted = [...report.items]
      ..sort(
        (a, b) => (priority[a.dealerSegment] ?? 3).compareTo(
          priority[b.dealerSegment] ?? 3,
        ),
      );

    return _SectionCard(
      title: 'Dealer visit & potential detail',
      accent: accent,
      child: Column(
        children: [
          for (int i = 0; i < sorted.length; i++) ...[
            _DealerPotentialRow(item: sorted[i]),
            if (i != sorted.length - 1)
              const Divider(height: 22, color: AppColors.line),
          ],
          if (sorted.isEmpty)
            const Text(
              'No dealer visit data returned for this period.',
              style: TextStyle(fontSize: 12, color: AppColors.steel),
            ),
        ],
      ),
    );
  }
}

class _DealerPotentialRow extends StatelessWidget {
  final DealerPotentialItem item;
  const _DealerPotentialRow({required this.item});

  Color get _segmentColor {
    switch (item.dealerSegment) {
      case 'at_risk':
        return AppColors.red;
      case 'high_potential':
        return AppColors.green;
      default:
        return AppColors.aiBlue;
    }
  }

  String get _segmentLabel {
    switch (item.dealerSegment) {
      case 'at_risk':
        return 'At risk';
      case 'high_potential':
        return 'High potential';
      case 'steady':
        return 'Steady';
      default:
        return item.dealerSegment.isEmpty ? '--' : item.dealerSegment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.dealerName,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _Badge(text: item.dealerCategory, color: AppColors.steel),
                ],
              ),
            ),
            _Badge(text: _segmentLabel, color: _segmentColor),
          ],
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _Metric(label: 'Visit freq', value: '${item.visitFrequency}'),
            _Metric(
              label: 'Last visit',
              value: '${item.daysSinceLastVisit}d ago',
            ),
            _Metric(label: 'Engagement', value: item.visitEngagementLevel),
          ],
        ),
        if (item.insight.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            item.insight,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.35,
              color: AppColors.steel,
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// 6. Order fulfilment section
// =============================================================================
class _OrderFulfilmentSection extends StatelessWidget {
  final OrderFulfilmentReport report;
  final Color accent;
  const _OrderFulfilmentSection({required this.report, required this.accent});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Order-level fulfilment & risk',
      accent: accent,
      child: Column(
        children: [
          for (int i = 0; i < report.items.length; i++) ...[
            _OrderFulfilmentRow(item: report.items[i]),
            if (i != report.items.length - 1)
              const Divider(height: 22, color: AppColors.line),
          ],
          if (report.items.isEmpty)
            const Text(
              'No orders returned for this period.',
              style: TextStyle(fontSize: 12, color: AppColors.steel),
            ),
        ],
      ),
    );
  }
}

class _OrderFulfilmentRow extends StatelessWidget {
  final FulfilmentOrderItem item;
  const _OrderFulfilmentRow({required this.item});

  Color get _statusColor {
    switch (item.orderStatus.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return AppColors.green;
      case 'cancelled':
      case 'rejected':
        return AppColors.red;
      case 'placed':
        return AppColors.aiBlue;
      default:
        return AppColors.steel;
    }
  }

  Color get _riskColor {
    switch (item.riskLevel.toLowerCase()) {
      case 'high':
        return AppColors.red;
      case 'medium':
        return const Color(0xFFB8860B);
      default:
        return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.orderNumber,
                    style: const TextStyle(
                      fontFamily: AppFonts.mono,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.products,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.steel,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Badge(text: item.orderStatus, color: _statusColor),
                const SizedBox(height: 4),
                _Badge(text: '${item.riskLevel} risk', color: _riskColor),
              ],
            ),
          ],
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _Metric(label: 'Channel', value: item.channel),
            _Metric(label: 'Qty', value: '${item.orderedQuantity}'),
            _Metric(label: 'Value', value: _currency(item.grossValue)),
            if (item.revenueAtRiskValue > 0)
              _Metric(
                label: 'At risk',
                value: _currency(item.revenueAtRiskValue),
              ),
          ],
        ),
        if (item.insight.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            item.insight,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.35,
              color: AppColors.steel,
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// 1. Sales projection section
// =============================================================================
class _SalesProjectionSection extends StatelessWidget {
  final SalesProjectionReport report;
  final Color accent;
  const _SalesProjectionSection({required this.report, required this.accent});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Projection detail',
      accent: accent,
      child: Column(
        children: [
          for (int i = 0; i < report.items.length; i++) ...[
            _SalesProjectionCard(item: report.items[i], accent: accent),
            if (i != report.items.length - 1) const SizedBox(height: 14),
          ],
          if (report.items.isEmpty)
            const Text(
              'No projection data returned for this period.',
              style: TextStyle(fontSize: 12, color: AppColors.steel),
            ),
          if (report.forecast != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.aiBlueChipBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'A forecast breakdown was returned for this horizon — exact layout pending a confirmed field format.',
                style: TextStyle(fontSize: 11, color: AppColors.steel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SalesProjectionCard extends StatelessWidget {
  final SalesProjectionItem item;
  final Color accent;
  const _SalesProjectionCard({required this.item, required this.accent});

  @override
  Widget build(BuildContext context) {
    final gapIsShortfall = item.projectedGap < 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.ash,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.targetPeriod.isEmpty ? item.period : item.targetPeriod,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              _Badge(
                text:
                    '${item.confidencePercentage.toStringAsFixed(0)}% confidence',
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _Metric(label: 'Target', value: _currency(item.targetValue)),
              _Metric(
                label: 'Current sales',
                value: _currency(item.currentPeriodSales),
              ),
              _Metric(
                label: 'Projected',
                value: _currency(item.projectedSales),
              ),
              _Metric(
                label: 'Daily run rate',
                value: _currency(item.dailySalesRunRate),
              ),
              _Metric(
                label: 'Pending orders',
                value: _currency(item.pendingOrdersValue),
              ),
              _Metric(label: 'Days to target', value: '${item.daysToTarget}'),
              if (item.achievementProbabilityPercentage != null)
                _Metric(
                  label: 'Achievement',
                  value:
                      '${item.achievementProbabilityPercentage!.toStringAsFixed(0)}%',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                gapIsShortfall ? Icons.trending_down : Icons.trending_up,
                size: 13,
                color: gapIsShortfall ? AppColors.red : AppColors.green,
              ),
              const SizedBox(width: 4),
              Text(
                '${gapIsShortfall ? 'Shortfall' : 'Surplus'} of ${_currency(item.projectedGap.abs())}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: gapIsShortfall ? AppColors.red : AppColors.green,
                ),
              ),
            ],
          ),
          if (item.insight.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.insight,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.4,
                color: AppColors.steel,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// 5. Team performance section
// =============================================================================
class _TeamPerformanceSection extends StatelessWidget {
  final TeamPerformanceReport report;
  final Color accent;
  const _TeamPerformanceSection({required this.report, required this.accent});

  @override
  Widget build(BuildContext context) {
    final sorted = [...report.items]
      ..sort((a, b) => b.achievedSales.compareTo(a.achievedSales));

    return _SectionCard(
      title: 'Rep-level performance',
      accent: accent,
      child: Column(
        children: [
          for (int i = 0; i < sorted.length; i++) ...[
            _TeamPerformanceRow(item: sorted[i], rank: i + 1, accent: accent),
            if (i != sorted.length - 1)
              const Divider(height: 22, color: AppColors.line),
          ],
          if (sorted.isEmpty)
            const Text(
              'No rep performance data returned for this period.',
              style: TextStyle(fontSize: 12, color: AppColors.steel),
            ),
        ],
      ),
    );
  }
}

class _TeamPerformanceRow extends StatelessWidget {
  final TeamPerformanceItem item;
  final int rank;
  final Color accent;
  const _TeamPerformanceRow({
    required this.item,
    required this.rank,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final achievedTarget = item.achievementPercentage >= 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withValues(alpha: 0.85), accent],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.salesperson,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
            ),
            _Badge(
              text:
                  '${item.achievementPercentage.toStringAsFixed(0)}% of target',
              color: achievedTarget ? AppColors.green : const Color(0xFFB8860B),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _Metric(label: 'Achieved', value: _currency(item.achievedSales)),
            _Metric(label: 'Orders', value: '${item.ordersBooked}'),
            _Metric(label: 'Dealers covered', value: '${item.dealersCovered}'),
            _Metric(label: 'Visits', value: '${item.completedVisits}'),
            _Metric(
              label: 'Attendance',
              value: '${item.attendancePct.toStringAsFixed(0)}%',
            ),
          ],
        ),
        if (item.coachingFlag) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFCF3D9),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.flag_rounded,
                  size: 14,
                  color: Color(0xFFB8860B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.coachingReason ?? 'Flagged for coaching review.',
                    style: const TextStyle(
                      fontSize: 10.5,
                      height: 1.35,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (item.insight.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            item.insight,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.35,
              color: AppColors.steel,
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// Small shared building blocks
// =============================================================================
class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 10, color: AppColors.steel),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: const TextStyle(
              fontFamily: AppFonts.mono,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// =============================================================================
// 3. Generic live-data section — only used for regional_opportunity, which
// has no typed model yet
// =============================================================================
// class _LiveDataBanner extends StatelessWidget {
//   const _LiveDataBanner();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
//       decoration: BoxDecoration(
//         color: AppColors.greenLight,
//         borderRadius: BorderRadius.circular(11),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.podcasts_rounded, size: 14, color: AppColors.green),
//           const SizedBox(width: 7),
//           const Expanded(
//             child: Text(
//               'Live data from the report API',
//               style: TextStyle(
//                 fontSize: 10.5,
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.green,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class _GenericListSection extends StatelessWidget {
  final String title;
  final Color accent;
  final List<dynamic> items;
  const _GenericListSection({
    required this.title,
    required this.accent,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final rows = items.take(10).toList();
    return _SectionCard(
      title: title,
      accent: accent,
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _GenericRow(item: _asMap(rows[i])),
            if (i != rows.length - 1)
              const Divider(height: 18, color: AppColors.line),
          ],
        ],
      ),
    );
  }
}

class _GenericRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _GenericRow({required this.item});

  static const _titleKeys = [
    'name',
    'title',
    'product_name',
    'dealer_name',
    'rep_name',
    'region',
    'zone',
    'label',
    'reason',
  ];

  @override
  Widget build(BuildContext context) {
    final titleKey = _titleKeys.firstWhere(
      (k) => item[k] != null && item[k].toString().trim().isNotEmpty,
      orElse: () => '',
    );
    final title = titleKey.isEmpty ? 'Item' : item[titleKey].toString();
    final otherEntries = item.entries
        .where(
          (e) =>
              e.key != titleKey &&
              e.value is! Map &&
              e.value is! List &&
              e.value != null &&
              e.value.toString().trim().isNotEmpty,
        )
        .take(4)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: otherEntries
                .map(
                  (e) => _Metric(
                    label: _prettify(e.key),
                    value: _formatValue(e.value),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Period / horizon selectors
// =============================================================================
class _PeriodSelector extends StatelessWidget {
  final String value;
  final Color accent;
  final ValueChanged<String> onChanged;
  const _PeriodSelector({
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  static const _options = [
    ['today', 'Today'],
    ['week', 'Week'],
    ['month', 'Month'],
    ['six_months', '6M'],
    ['year', 'Year'],
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _options.map((o) {
          final selected = value == o[0];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(o[0]),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? accent : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? accent : AppColors.line),
                ),
                child: Text(
                  o[1],
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : AppColors.steel,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HorizonSelector extends StatelessWidget {
  final String value;
  final Color accent;
  final ValueChanged<String> onChanged;
  const _HorizonSelector({
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget seg(String v, String label) {
      final selected = value == v;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(v),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : AppColors.steel,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.ash,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          seg('current', 'Current'),
          seg('next_3_months', 'Next 3 months (slower)'),
        ],
      ),
    );
  }
}

// =============================================================================
// Gradient hero header
// =============================================================================
class _Hero extends StatelessWidget {
  final ReportConfig report;
  final String periodLabel;
  const _Hero({required this.report, required this.periodLabel});

  @override
  Widget build(BuildContext context) {
    final darker = Color.lerp(report.accent, Colors.black, 0.28)!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [report.accent, darker],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: report.accent.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(report.icon, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 12, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        periodLabel,
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Shared shadowed section card
// =============================================================================
class _SectionCard extends StatelessWidget {
  final String title;
  final Color accent;
  final IconData? titleIcon;
  final Widget? headerTrailing;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.accent,
    required this.child,
  }) : headerTrailing = null,
       titleIcon = null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (titleIcon != null) ...[
                Icon(titleIcon, size: 15, color: accent),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
              ?headerTrailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// =============================================================================
// KPI card
// =============================================================================
class _KpiCard extends StatelessWidget {
  final KpiData kpi;
  final Color accent;
  const _KpiCard({required this.kpi, required this.accent});

  @override
  Widget build(BuildContext context) {
    final change = kpi.changePercent;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  kpi.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.steel,
                    letterSpacing: .3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            kpi.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          if (change != null) ...[
            const SizedBox(height: 6),
            _TrendPill(percent: change),
          ],
        ],
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  final double percent;
  const _TrendPill({required this.percent});

  @override
  Widget build(BuildContext context) {
    final isUp = percent >= 0;
    final color = isUp ? AppColors.green : AppColors.red;
    final bg = isUp ? AppColors.greenLight : AppColors.redLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward : Icons.arrow_downward,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${percent.abs().toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Region / coverage bar — currently unused (no config defines regionStats
// data), kept for when regional_opportunity gets a typed model
// =============================================================================
class _RegionBar extends StatelessWidget {
  final RegionStat stat;
  final Color accent;
  const _RegionBar({required this.stat, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              stat.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            Text(
              '${stat.percent}%',
              style: TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            children: [
              Container(height: 8, color: AppColors.ash),
              FractionallySizedBox(
                widthFactor: (stat.percent / 100).clamp(0, 1),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent.withValues(alpha: 0.75), accent],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Small local helpers
// =============================================================================
Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _prettify(String key) => key
    .replaceAll('_', ' ')
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

String _formatValue(dynamic value) {
  if (value is double) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
  return value.toString();
}

String _currency(double value) {
  final sign = value < 0 ? '-' : '';
  final v = value.abs();
  if (v >= 10000000) return '$sign₹${(v / 10000000).toStringAsFixed(1)}Cr';
  if (v >= 100000) return '$sign₹${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '$sign₹${(v / 1000).toStringAsFixed(1)}K';
  return '$sign₹${v.toStringAsFixed(0)}';
}
