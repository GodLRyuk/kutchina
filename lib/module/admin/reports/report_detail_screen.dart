import 'dart:math' as math;

import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/services/report_api.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/admin/reports/report_models.dart';
import 'package:flutter/material.dart';

const bool _kShowPlaceholders = true;

class _C {
  static const bg = Color(0xFFF3F1EC);
  static const ink = Color(0xFF151B2E);
  static const inkSoft = Color(0xFF5E6478);
  static const inkFaint = Color(0xFF9BA0AF);
  static const line = Color(0xFFE7E3DA);
  static const navy = Color(0xFF1C2740);
  static const navy2 = Color(0xFF111830);
  static const primary = Color(0xFF1D4ED8);
  static const primarySoft = Color(0xFFE7EEFE);
  static const good = Color(0xFF178A5E);
  static const goodSoft = Color(0xFFE4F5EE);
  static const risk = Color(0xFFC4341F);
  static const riskSoft = Color(0xFFFBE7E3);
  static const warn = Color(0xFFB9791A);
  static const warnSoft = Color(0xFFFBF0DA);
  static const info = Color(0xFF6D4FD6);
  static const infoSoft = Color(0xFFEFEAFC);

  static const avatarPalette = [
    [primarySoft, primary],
    [goodSoft, good],
    [warnSoft, warn],
    [riskSoft, risk],
    [infoSoft, info],
  ];
}

enum _Tone { good, warn, risk, info, neutral }

extension _ToneColors on _Tone {
  Color get fg => switch (this) {
    _Tone.good => _C.good,
    _Tone.warn => _C.warn,
    _Tone.risk => _C.risk,
    _Tone.info => _C.info,
    _Tone.neutral => _C.inkSoft,
  };
  Color get bg => switch (this) {
    _Tone.good => _C.goodSoft,
    _Tone.warn => _C.warnSoft,
    _Tone.risk => _C.riskSoft,
    _Tone.info => _C.infoSoft,
    _Tone.neutral => _C.bg,
  };
}

class _Kpi {
  final Color color;
  final String label;
  final String value;
  final String sub;
  final _Tone subTone;
  const _Kpi({
    required this.color,
    required this.label,
    required this.value,
    this.sub = '',
    this.subTone = _Tone.neutral,
  });
}

class _Stat {
  final String label;
  final String value;
  final Color? color;
  const _Stat(this.label, this.value, [this.color]);
}

class _Action {
  final String title;
  final String body;
  final String impact;
  final _Tone tone;
  const _Action({
    required this.title,
    required this.body,
    required this.impact,
    this.tone = _Tone.info,
  });
}

class _TargetData {
  final String title;
  final String sub;
  final String avatarText;
  final List<double> trend;
  final double? growth;
  final String badgeText;
  final _Tone badgeTone;
  final List<_Stat> stats;
  final String? extra;
  final String? coachingText;
  final String footLabel;
  final String footValue;
  final String footTag;
  final _Tone footTone;
  const _TargetData({
    required this.title,
    required this.sub,
    required this.avatarText,
    this.trend = const [],
    this.growth,
    required this.badgeText,
    required this.badgeTone,
    required this.stats,
    this.extra,
    this.coachingText,
    required this.footLabel,
    required this.footValue,
    required this.footTag,
    required this.footTone,
  });
}

class _View {
  final String copy;
  final List<String> badges;
  final List<String> filters;
  final List<_Kpi> kpis;
  final List<Widget> sections;
  final List<_Action> actions;
  const _View({
    required this.copy,
    required this.badges,
    required this.filters,
    required this.kpis,
    required this.sections,
    required this.actions,
  });
}

class _Plan {
  final bool hasTarget;
  final bool hasNext;
  final bool met;
  final double achievement;
  final double nextTarget;
  const _Plan({
    required this.hasTarget,
    required this.hasNext,
    required this.met,
    required this.achievement,
    required this.nextTarget,
  });
}

_Plan _plan({
  required double sales,
  required double target,
  required double projNext,
  double stretch = 0.08,
}) {
  if (target <= 0) {
    return const _Plan(
      hasTarget: false,
      hasNext: false,
      met: false,
      achievement: 0,
      nextTarget: 0,
    );
  }
  final ach = sales / target * 100;
  final met = ach >= 100;
  if (projNext <= 0) {
    return _Plan(
      hasTarget: true,
      hasNext: false,
      met: met,
      achievement: ach,
      nextTarget: 0,
    );
  }
  final next = met ? projNext * (1 + stretch) : projNext + (target - sales) / 2;
  return _Plan(
    hasTarget: true,
    hasNext: true,
    met: met,
    achievement: ach,
    nextTarget: next,
  );
}

(String, _Tone) _badgeFor(double? achievement) {
  if (achievement == null) return ('NO TARGET', _Tone.neutral);
  return achievement >= 100
      ? ('TARGET MET', _Tone.good)
      : ('BELOW TARGET', _Tone.risk);
}

({String value, String tag, _Tone tone}) _foot(
  _Plan p, {
  double stretch = 0.08,
  String Function(double)? fmt,
}) {
  final f = fmt ?? _currency;
  if (!p.hasNext) return (value: f(0), tag: 'PENDING', tone: _Tone.neutral);
  return p.met
      ? (
          value: f(p.nextTarget),
          tag: 'STRETCH +${(stretch * 100).round()}%',
          tone: _Tone.good,
        )
      : (value: f(p.nextTarget), tag: 'RECOVERY', tone: _Tone.warn);
}

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

  String _period = 'month';
  String _horizon = 'current';

  ProductDemandReport? _productDemand;
  DealerPotentialReport? _dealerPotential;
  OrderFulfilmentReport? _orderFulfilment;
  SalesProjectionReport? _salesProjection;
  TeamPerformanceReport? _teamPerformance;
  RegionalOpportunityReport? _regionalOpportunity;
  Map<String, dynamic>? _rawBody;

  String? _error;
  bool _loading = false;

  ReportConfig get report => widget.report;

  /// True once the API has returned data for this report at least once.
  bool get _hasResponse {
    switch (report.id) {
      case 'product_demand':
        return _productDemand != null;
      case 'dealer_potential':
        return _dealerPotential != null;
      case 'order_fulfilment':
        return _orderFulfilment != null;
      case 'sales_projection':
        return _salesProjection != null;
      case 'team_performance':
        return _teamPerformance != null;
      case 'regional_opportunity':
        return _regionalOpportunity != null;
      default:
        return _rawBody != null;
    }
  }

  /// "Test" / "00" placeholders only show after loading finished.
  bool get _showPh => _kShowPlaceholders && _hasResponse && !_loading;
  String get _displayPeriodLabel => _periodLabels[_period] ?? _period;

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
        case 'regional_opportunity':
          final result = await AdminReportApi.generateRegionalOpportunity(
            period: _period,
          );
          if (!mounted) return;
          setState(() => _regionalOpportunity = result);
          break;
        default:
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

  _View _buildView() {
    switch (report.id) {
      case 'product_demand':
        return _productView();
      case 'dealer_potential':
        return _dealerView();
      case 'order_fulfilment':
        return _fulfilmentView();
      case 'sales_projection':
        return _projectionView();
      case 'team_performance':
        return _teamView();
      default:
        return _regionalView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = _buildView();
    final hasData = _hasResponse;
    final pending = _loading ? '···' : '--';
    final kpis = hasData
        ? view.kpis
        : [
            for (final k in view.kpis)
              _Kpi(color: k.color, label: k.label, value: pending),
          ];
    return Scaffold(
      backgroundColor: _C.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: _C.bg,
            surfaceTintColor: _C.bg,
            centerTitle: true,
            leadingWidth: 54,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: _IconBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
            title: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'KUTCHINA',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _C.navy,
                  ),
                ),
                Text(
                  'AI REPORT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _C.inkFaint,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: _IconBtn(
                    icon: Icons.ios_share_outlined,
                    onTap: () =>
                        AppWidgets.toast(context, 'Export coming soon'),
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 60),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionLabel(report.title, '· $_displayPeriodLabel', top: 4),
                _Hero(
                  icon: report.icon,
                  copy: (!hasData && _loading)
                      ? 'Generating report…'
                      : view.copy,
                  badges: hasData ? view.badges : const [],
                ),
                const SizedBox(height: 14),
                _PeriodSelector(
                  value: _period,
                  onChanged: _loading ? (_) {} : _onPeriodChanged,
                ),
                if (_period == 'today' || _period == 'week') ...[
                  const SizedBox(height: 8),
                  const Text(
                    "Target-based figures aren't available for this period.",
                    style: TextStyle(
                      fontSize: 10.5,
                      color: _C.inkFaint,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (report.supportsHorizon) ...[
                  const SizedBox(height: 10),
                  _HorizonSelector(
                    value: _horizon,
                    onChanged: _loading ? (_) {} : _onHorizonChanged,
                  ),
                ],
                const SizedBox(height: 12),
                _FilterChips(labels: view.filters),
                const SizedBox(height: 10),
                if (_error != null)
                  _ReportError(message: _error!, onRetry: _loadReport),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      color: _C.navy,
                      backgroundColor: _C.line,
                    ),
                  ),
                _KpiGrid(kpis: kpis),
                ...view.sections,
                ..._actionWidgets(view.actions),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared section helpers
  // ---------------------------------------------------------------------------
  List<Widget> _targetSection(
    String title,
    String span,
    List<_TargetData> real,
    _TargetData placeholder,
  ) {
    final src = real.isNotEmpty
        ? real
        : (_showPh ? [placeholder] : <_TargetData>[]);
    if (src.isEmpty) return const [];
    return [
      _SectionLabel(title, span),
      for (int i = 0; i < src.length; i++) _TargetCard(data: src[i], index: i),
    ];
  }

  List<Widget> _actionWidgets(List<_Action> real) {
    final src = real.isNotEmpty
        ? real
        : (_showPh
              ? const [
                  _Action(
                    title: 'Test action 1',
                    body: 'Test description — AI recommendation appears here.',
                    impact: '00',
                  ),
                  _Action(
                    title: 'Test action 2',
                    body: 'Test description — AI recommendation appears here.',
                    impact: '00',
                  ),
                ]
              : <_Action>[]);
    if (src.isEmpty) return const [];
    return [
      const _SectionLabel('AI recommended actions', ''),
      for (int i = 0; i < src.length; i++)
        _ActionCard(rank: i + 1, action: src[i]),
    ];
  }

  _TargetData _placeholderTarget({
    String fourth = 'NEXT MO. PROJECTED',
    String footLabel = 'NEXT MONTH TARGET',
  }) => _TargetData(
    title: 'Test',
    sub: 'Test — no data yet',
    avatarText: 'TE',
    badgeText: 'NO DATA',
    badgeTone: _Tone.neutral,
    stats: [
      const _Stat('THIS MONTH', '₹0'),
      const _Stat('TARGET', '₹0'),
      const _Stat('ACHIEVEMENT', '00%'),
      _Stat(fourth, '₹0'),
    ],
    footLabel: footLabel,
    footValue: '₹0',
    footTag: 'PENDING',
    footTone: _Tone.neutral,
  );

  String _period3() => 'Period: $_displayPeriodLabel';

  // ---------------------------------------------------------------------------
  // 1. Sales projection
  // ---------------------------------------------------------------------------
  _View _projectionView() {
    final r = _salesProjection;
    final items = r?.items ?? <SalesProjectionItem>[];
    final first = items.isEmpty ? null : items.first;

    final kpis = [
      _Kpi(
        color: _C.primary,
        label: 'CURRENT PERIOD SALES',
        value: first == null ? '₹0' : _currency(first.currentPeriodSales),
        sub: 'so far this period',
      ),
      _Kpi(
        color: _C.info,
        label: 'TARGET',
        value: first == null ? '₹0' : _currency(first.targetValue),
        sub: 'set for the period',
      ),
      _Kpi(
        color: _C.good,
        label: 'PROJECTED SALES',
        value: first == null ? '₹0' : _currency(first.projectedSales),
        sub: first == null
            ? 'no projection yet'
            : (first.projectedGap < 0 ? 'below target' : 'above target'),
        subTone: first == null
            ? _Tone.neutral
            : (first.projectedGap < 0 ? _Tone.risk : _Tone.good),
      ),
      _Kpi(
        color: _C.warn,
        label: 'CONFIDENCE',
        value: first == null
            ? '00%'
            : '${first.confidencePercentage.toStringAsFixed(0)}%',
        sub: 'model confidence',
      ),
    ];

    final cards = <_TargetData>[
      for (final it in items)
        () {
          final title = it.targetPeriod.isEmpty ? it.period : it.targetPeriod;
          final p = _plan(
            sales: it.currentPeriodSales,
            target: it.targetValue,
            projNext: it.projectedSales,
          );
          final f = _foot(p);
          final badge = _badgeFor(p.hasTarget ? p.achievement : null);
          final gapShort = it.projectedGap < 0;
          final extraParts = <String>[
            'Run rate **${_currency(it.dailySalesRunRate)}**',
            'Pending orders **${_currency(it.pendingOrdersValue)}**',
            'Days to target **${it.daysToTarget}**',
            if (it.achievementProbabilityPercentage != null)
              'Achievement probability **${it.achievementProbabilityPercentage!.toStringAsFixed(0)}%**',
            '${gapShort ? 'Shortfall' : 'Surplus'} **${_currency(it.projectedGap.abs())}**',
          ];
          return _TargetData(
            title: title.isEmpty ? 'Test' : title,
            sub:
                '${it.confidencePercentage.toStringAsFixed(0)}% confidence · ${it.daysToTarget} days to target',
            avatarText: _initials(title),
            badgeText: badge.$1,
            badgeTone: badge.$2,
            stats: [
              _Stat('THIS PERIOD SALES', _currency(it.currentPeriodSales)),
              _Stat('TARGET', _currency(it.targetValue)),
              _Stat(
                'ACHIEVEMENT',
                p.hasTarget ? '${p.achievement.round()}%' : '00%',
                p.hasTarget ? (p.met ? _C.good : _C.risk) : null,
              ),
              _Stat('PROJECTED', _currency(it.projectedSales)),
            ],
            extra:
                extraParts.join(' · ') +
                (it.insight.isNotEmpty ? '\n${it.insight}' : ''),
            footLabel: 'RECOMMENDED NEXT TARGET',
            footValue: f.value,
            footTag: f.tag,
            footTone: f.tone,
          );
        }(),
    ];

    final actions = [
      for (final it in items.where((i) => i.insight.isNotEmpty).take(2))
        _Action(
          title: it.targetPeriod.isEmpty ? it.period : it.targetPeriod,
          body: it.insight,
          impact:
              '${it.projectedGap < 0 ? '-' : '+'}${_currency(it.projectedGap.abs())}',
          tone: it.projectedGap < 0 ? _Tone.risk : _Tone.good,
        ),
    ];

    return _View(
      copy: first == null
          ? 'Predicted revenue trajectory vs target will appear here once the report loads.'
          : '**Projected ${_currency(first.projectedSales)}** against a target of **${_currency(first.targetValue)}** — ${first.projectedGap < 0 ? 'a shortfall' : 'a surplus'} of **${_currency(first.projectedGap.abs())}**.',
      badges: [
        '🎯 ${first == null ? '00' : first.confidencePercentage.toStringAsFixed(0)}% confidence',
        '📅 ${_horizon == 'current' ? 'Current horizon' : 'Next 3 months'}',
      ],
      filters: ['Region: All', 'Product: All', 'Team: All'],
      kpis: kpis,
      sections: [
        ..._targetSection(
          'Projection detail',
          '· per target period',
          cards,
          _placeholderTarget(
            fourth: 'PROJECTED',
            footLabel: 'RECOMMENDED NEXT TARGET',
          ),
        ),
        if (r?.forecast != null)
          _Card(
            child: const Text(
              'A forecast breakdown was returned for this horizon — exact layout pending a confirmed field format.',
              style: TextStyle(fontSize: 11, color: _C.inkSoft, height: 1.4),
            ),
          ),
      ],
      actions: actions,
    );
  }

  _View _productView() {
    final r = _productDemand;
    final loaded = r != null;
    final items = r?.items ?? <ProductDemandItem>[];
    final sum = r?.summary;
    final topName = sum?.topSku.productName ?? '';
    final headline = sum?.headline ?? '';

    final missed = sum?.missedTarget.number;
    final avgAch = sum?.averageAchievementPercentage.number;
    final recovery = sum?.needsRecoveryCount.number;

    final kpis = [
      _Kpi(
        color: _C.primary,
        label: 'TOP SKU (SALES VALUE)',
        value: sum == null ? '₹0' : _currency(sum.topSku.salesValue),
        sub: topName.isEmpty ? 'Test' : topName,
      ),
      _Kpi(
        color: _C.risk,
        label: 'MISSED TARGET',
        value: missed == null ? '00' : '${missed.round()} SKUs',
        sub: 'of ${loaded ? sum!.productsTracked : '00'} tracked',
        subTone: (missed ?? 0) > 0 ? _Tone.risk : _Tone.neutral,
      ),
      _Kpi(
        color: _C.good,
        label: 'AVG ACHIEVEMENT',
        value: avgAch == null ? '00%' : '${avgAch.round()}%',
        sub: 'across tracked SKUs',
        subTone: avgAch == null
            ? _Tone.neutral
            : (avgAch >= 100 ? _Tone.good : _Tone.warn),
      ),
      _Kpi(
        color: _C.info,
        label: 'PROJECTED REVENUE (NEXT MO.)',
        value: sum == null ? '₹0' : _currency(sum.projectedRevenueNextMonth),
        sub: 'sum of next-mo. projections',
      ),
    ];

    final cards = <_TargetData>[
      for (final it in items)
        () {
          final target = it.targetValue.number;
          final ach = it.achievementPercentage.number;
          final nextTarget = it.nextMonthTarget.number;
          final badge = _badgeFor(ach);
          final p = _plan(
            sales: it.currentPeriodSales,
            target: target ?? 0,
            projNext: it.nextMonthProjected,
          );
          final f = _foot(p);
          final g = it.growthPercentage;
          final footValue = nextTarget != null
              ? _currency(nextTarget)
              : f.value;
          final footTag = nextTarget != null
              ? (p.hasTarget ? f.tag : 'SET')
              : f.tag;
          final footTone = nextTarget != null
              ? (p.hasTarget ? f.tone : _Tone.info)
              : f.tone;
          return _TargetData(
            title: it.productName,
            sub: it.sku,
            avatarText: _initials(it.productName),
            trend: [for (final t in it.trend) t.value],
            growth: g,
            badgeText: badge.$1,
            badgeTone: badge.$2,
            stats: [
              _Stat('THIS MONTH', _currency(it.currentPeriodSales)),
              _Stat('TARGET', target == null ? '₹0' : _currency(target)),
              _Stat(
                'ACHIEVEMENT',
                ach == null ? '00%' : '${ach.round()}%',
                ach == null ? null : (ach >= 100 ? _C.good : _C.risk),
              ),
              _Stat('NEXT MO. PROJECTED', _currency(it.nextMonthProjected)),
            ],
            extra:
                'Units sold **${it.unitsSold}** · Orders **${it.orderFrequency.round()}** · Avg price **${_currency(it.averageSellingPrice)}**',
            footLabel: 'NEXT MONTH TARGET FOR AGENT',
            footValue: footValue,
            footTag: footTag,
            footTone: footTone,
          );
        }(),
    ];

    final actions = <_Action>[
      if (sum != null)
        for (final a in sum.actions)
          _Action(
            title: a.action.isEmpty ? a.productName : a.action,
            body: a.action.isEmpty
                ? a.reason
                : '${a.productName} — ${a.reason}',
            impact: a.impactType.isEmpty
                ? 'Insight'
                : '${a.impactType[0].toUpperCase()}${a.impactType.substring(1)}',
            tone: switch (a.impactType.toLowerCase()) {
              'good' => _Tone.good,
              'risk' || 'bad' => _Tone.risk,
              'warn' || 'warning' => _Tone.warn,
              _ => _Tone.info,
            },
          ),
    ];

    // headline from API, with the top product name emphasised
    final copy = headline.isEmpty
        ? 'Best/worst sellers, demand trend and stockout risk will appear here once the report loads.'
        : (topName.isNotEmpty && headline.contains(topName)
              ? headline.replaceFirst(topName, '**$topName**')
              : headline);

    return _View(
      copy: copy,
      badges: [
        '📦 ${loaded ? sum!.productsTracked : '00'} SKUs tracked',
        '🎯 ${recovery == null ? '00' : recovery.round()} need recovery targets',
      ],
      filters: ['Category: All', 'Region: All', 'Dealer Segment: All'],
      kpis: kpis,
      sections: _targetSection(
        'Monthly projection & next month\'s target',
        '· per product',
        cards,
        _placeholderTarget(),
      ),
      actions: actions,
    );
  }

  static const _kName = [
    'zone',
    'zone_name',
    'region',
    'region_name',
    'name',
    'label',
  ];
  static const _kAch = [
    'achievement_percentage',
    'achievement_pct',
    'achievement',
    'target_achievement_percentage',
  ];
  static const _kPotential = [
    'market_potential',
    'potential_value',
    'potential',
    'estimated_potential',
  ];
  static const _kGap = ['opportunity_gap', 'gap', 'untapped_value'];
  static const _kDealers = ['active_dealers', 'dealer_count', 'dealers'];
  static const _kSales = [
    'current_period_sales',
    'achieved_sales',
    'sales',
    'sales_value',
    'actual_sales',
  ];
  static const _kTarget = ['target_value', 'target'];
  static const _kGrowth = ['growth_percentage', 'growth'];
  static const _kProj = ['projected_sales', 'next_month_projection'];
  static const _kInsight = ['insight', 'recommendation'];

  _View _regionalView() {
    final r = _regionalOpportunity;
    final items = r?.items ?? <RegionalZoneItem>[];
    final sum = r;
    final bestName = sum?.bestZoneName ?? '';
    final bestAch = sum?.bestZoneAchievement;
    final gapNum = sum?.largestOpportunityGap.number;
    final activeNum = sum?.activeDealers.number;

    final kpis = [
      _Kpi(
        color: _C.good,
        label: 'BEST PERFORMING ZONE',
        value: bestName.isEmpty ? 'Test' : bestName,
        sub: bestAch == null
            ? 'no achievement data'
            : '${bestAch.round()}% of target',
        subTone: bestAch == null
            ? _Tone.neutral
            : (bestAch >= 100 ? _Tone.good : _Tone.warn),
      ),
      _Kpi(
        color: _C.primary,
        label: 'ZONES TRACKED',
        value: sum == null ? '00' : '${sum.zonesTracked}',
        sub: 'this period',
      ),
      _Kpi(
        color: _C.risk,
        label: 'LARGEST OPPORTUNITY GAP',
        value: gapNum == null ? '₹0' : _currency(gapNum),
        sub: gapNum == null ? 'potential not tracked' : 'untapped value',
      ),
      _Kpi(
        color: _C.warn,
        label: 'ACTIVE DEALERS',
        value: activeNum == null ? '00' : '${activeNum.round()}',
        sub: 'across tracked zones',
      ),
    ];

    final heatRows = [
      for (final z in items)
        () {
          final ach = z.achievementPercentage.number;
          final pot = z.marketPotential.number;
          final gap = z.opportunityGap.number;
          final dealers = z.activeDealers.number;
          return _HeatRow(
            name: z.zone,
            ach: ach == null ? '00%' : '${ach.round()}%',
            achTone: ach == null
                ? _Tone.neutral
                : ach < 70
                ? _Tone.risk
                : ach < 100
                ? _Tone.warn
                : _Tone.good,
            potential: _cur(pot),
            gap: _cur(gap),
            gapTone: (gap == null || pot == null || pot <= 0)
                ? _Tone.neutral
                : gap / pot > 0.4
                ? _Tone.risk
                : gap / pot > 0.15
                ? _Tone.warn
                : _Tone.good,
            dealers: dealers == null ? '00' : '${dealers.round()}',
          );
        }(),
    ];
    final heatSrc = heatRows.isNotEmpty
        ? heatRows
        : (_showPh
              ? const [
                  _HeatRow(
                    name: 'Test',
                    ach: '00%',
                    achTone: _Tone.neutral,
                    potential: '₹0',
                    gap: '₹0',
                    gapTone: _Tone.neutral,
                    dealers: '00',
                  ),
                ]
              : <_HeatRow>[]);

    final cards = [
      for (final z in items)
        () {
          final target = z.targetValue.number;
          final ach = z.achievementPercentage.number;
          final p = _plan(
            sales: z.salesValue,
            target: target ?? 0,
            projNext: z.nextMonthProjected,
          );
          final f = _footFromBackend(z.nextMonthTarget, p);
          final badge = _badgeFor(ach);
          final gap = z.opportunityGap.number;
          final dealers = z.activeDealers.number;
          return _TargetData(
            title: z.zone,
            sub:
                '${dealers == null ? '00' : dealers.round()} active dealers · ${_cur(gap)} opportunity gap',
            avatarText: _initials(z.zone),
            trend: [for (final t in z.trend) t.value],
            growth: z.changePercentage,
            badgeText: badge.$1,
            badgeTone: badge.$2,
            stats: [
              _Stat('THIS MONTH SALES', _currency(z.salesValue)),
              _Stat('TARGET', _cur(target)),
              _Stat(
                'ACHIEVEMENT',
                ach == null ? '00%' : '${ach.round()}%',
                ach == null ? null : (ach >= 100 ? _C.good : _C.risk),
              ),
              _Stat('NEXT MO. PROJECTED', _currency(z.nextMonthProjected)),
            ],
            footLabel: 'NEXT MONTH TARGET FOR ZONE',
            footValue: f.value,
            footTag: f.tag,
            footTone: f.tone,
          );
        }(),
    ];

    final headline = sum?.headline ?? '';
    return _View(
      copy: headline.isEmpty
          ? 'Zone-wise achievement against market potential will appear here once the report loads.'
          : _boldFirst(headline, bestName),
      badges: [
        '🗺 ${sum == null ? '00' : sum.zonesTracked} zones tracked',
        '📈 ${bestName.isEmpty ? 'Best zone: --' : 'Best zone: $bestName'}',
      ],
      filters: ['Territory: All', 'Team: All', _period3()],
      kpis: kpis,
      sections: [
        if (heatSrc.isNotEmpty) _HeatCard(rows: heatSrc),
        ..._targetSection(
          'Monthly projection & next month\'s target',
          '· per region',
          cards,
          _placeholderTarget(),
        ),
      ],
      actions: _actionsFrom(sum?.actions ?? const []),
    );
  }

  _Zone _zoneFrom(Map<String, dynamic> m, int i) {
    final name = _str(m, _kName) ?? 'Zone ${i + 1}';
    final sales = _num(m, _kSales);
    final target = _num(m, _kTarget);
    var ach = _num(m, _kAch);
    if (ach == null && sales != null && target != null && target > 0) {
      ach = sales / target * 100;
    }
    final potential = _num(m, _kPotential);
    var gap = _num(m, _kGap);
    if (gap == null && potential != null && sales != null) {
      gap = potential - sales;
    }
    final dealers = _num(m, _kDealers);
    final growth = _num(m, _kGrowth);
    final projNext = _num(m, _kProj);
    final insight = _str(m, _kInsight);

    final p = _plan(
      sales: sales ?? 0,
      target: target ?? 0,
      projNext: projNext ?? 0,
    );
    final f = _foot(p);
    final badge = _badgeFor(ach);

    final consumed = <String>{
      ..._kName,
      ..._kAch,
      ..._kPotential,
      ..._kGap,
      ..._kDealers,
      ..._kSales,
      ..._kTarget,
      ..._kGrowth,
      ..._kProj,
      ..._kInsight,
    };
    final leftovers = m.entries
        .where(
          (e) =>
              !consumed.contains(e.key) &&
              e.value != null &&
              e.value is! Map &&
              e.value is! List &&
              e.value.toString().trim().isNotEmpty,
        )
        .take(3)
        .map((e) => '${_prettify(e.key)} **${_formatValue(e.value)}**')
        .toList();
    final extra = [
      if (leftovers.isNotEmpty) leftovers.join(' · '),
      if (insight != null) insight,
    ].join('\n');

    return _Zone(
      name: name,
      ach: ach,
      potential: potential,
      gap: gap,
      dealers: dealers,
      insight: insight,
      card: _TargetData(
        title: name,
        sub:
            '${dealers == null ? '00' : dealers.round()} active dealers · ${gap == null ? '₹0' : _currency(gap)} opportunity gap',
        avatarText: name.length >= 2
            ? name.substring(0, 2).toUpperCase()
            : name.toUpperCase(),
        growth: growth,
        badgeText: badge.$1,
        badgeTone: badge.$2,
        stats: [
          _Stat('THIS MONTH SALES', _cur(sales)),
          _Stat('OPPORTUNITY TARGET', _cur(target)),
          _Stat(
            'CAPTURE RATE',
            ach == null ? '00%' : '${ach.round()}%',
            ach == null ? null : (ach >= 100 ? _C.good : _C.risk),
          ),
          _Stat('NEXT MO. PROJECTED SALES', _cur(projNext)),
        ],
        extra: extra.isEmpty ? null : extra,
        footLabel: 'NEXT MONTH OPPORTUNITY CAPTURE TARGET',
        footValue: f.value,
        footTag: f.tag,
        footTone: f.tone,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Dealer potential
  // ---------------------------------------------------------------------------
  _View _dealerView() {
    final r = _dealerPotential;
    final sum = r?.summary;
    final loaded = r != null;
    final items = [...(r?.items ?? <DealerPotentialItem>[])]
      ..sort((a, b) {
        final sa = a.salesValue.number ?? -1;
        final sb = b.salesValue.number ?? -1;
        if (sa != sb) return sb.compareTo(sa);
        return (b.daysSinceLastVisit ?? -1).compareTo(
          a.daysSinceLastVisit ?? -1,
        );
      });
    final atRisk = sum?.atChurnRisk.number?.round();
    final high = sum?.highGrowthPotential.number?.round();
    final aov = sum?.averageOrderValue;

    final kpis = [
      _Kpi(
        color: _C.primary,
        label: 'DEALERS TRACKED',
        value: sum == null ? '00' : '${sum.dealersTracked}',
        sub: 'this period',
      ),
      _Kpi(
        color: _C.risk,
        label: 'AT-RISK DEALERS',
        value: atRisk == null ? '00' : '$atRisk',
        sub: 'churn risk',
        subTone: (atRisk ?? 0) > 0 ? _Tone.risk : _Tone.neutral,
      ),
      _Kpi(
        color: _C.good,
        label: 'HIGH-GROWTH POTENTIAL',
        value: high == null ? '00' : '$high',
        sub: high == null ? 'not tracked yet' : 'growth candidates',
        subTone: (high ?? 0) > 0 ? _Tone.good : _Tone.neutral,
      ),
      _Kpi(
        color: _C.warn,
        label: 'AVG ORDER VALUE',
        value: aov == null ? '₹0' : _currency(aov),
        sub: 'per order',
      ),
    ];

    // Visit-recency badge (backend gives no segment; 10+ days = overdue).
    (String, _Tone) recency(int? d) {
      if (d == null) return ('NO VISIT', _Tone.neutral);
      if (d >= 10) return ('VISIT OVERDUE', _Tone.warn);
      return ('RECENTLY VISITED', _Tone.good);
    }

    final cards = [
      for (final it in items)
        () {
          final s = recency(it.daysSinceLastVisit);
          final d = it.daysSinceLastVisit;
          final f = _footFromBackend(
            it.nextMonthTarget.hasValue ? it.nextMonthTarget : it.growthTarget,
            _plan(sales: 0, target: 0, projNext: 0),
          );
          final orders = it.orderCount.number;
          final aovItem = it.averageOrderValue.number;
          final outstanding = it.outstandingAmount.number;
          final extraParts = <String>[
            if (orders != null) 'Orders **${orders.round()}**',
            if (aovItem != null) 'Avg order **${_currency(aovItem)}**',
            if (outstanding != null)
              'Outstanding **${_currency(outstanding)}**',
          ];
          final city = it.city.text;
          return _TargetData(
            title: it.dealerName,
            sub:
                '${it.dealerCategory}${city == null ? '' : ' · $city'} · ${d == null ? 'never visited' : 'last visit ${d}d ago'}',
            avatarText: _initials(it.dealerName),
            trend: [for (final t in it.trend) t.value],
            badgeText: s.$1,
            badgeTone: s.$2,
            stats: [
              _Stat('SALES THIS MONTH', _cur(it.salesValue.number)),
              _Stat('VISITS', '${it.visitFrequency}'),
              _Stat('LAST VISIT', d == null ? '--' : '${d}d ago'),
              _Stat('NEXT MO. PROJECTED', _cur(it.nextMonthProjected.number)),
            ],
            extra: extraParts.isEmpty ? null : extraParts.join(' · '),
            footLabel: 'NEXT MONTH GROWTH TARGET',
            footValue: f.value,
            footTag: f.tag,
            footTone: f.tone,
          );
        }(),
    ];

    final headline = sum?.headline ?? '';
    final firstName = (sum?.actions.isNotEmpty ?? false)
        ? sum!.actions.first.name
        : '';
    return _View(
      copy: headline.isEmpty
          ? 'Dealer revenue, order frequency and churn risk will appear here once the report loads.'
          : _boldFirst(headline, firstName),
      badges: [
        '🏪 ${sum == null ? '00' : sum.dealersTracked} dealers tracked',
        '⚠ ${atRisk ?? '00'} at risk',
      ],
      filters: ['Segment: All', 'Region: All', 'Salesperson: All'],
      kpis: kpis,
      sections: _targetSection(
        'Monthly projection & next month\'s target',
        '· per dealer',
        cards,
        _placeholderTarget(footLabel: 'NEXT MONTH GROWTH TARGET'),
      ),
      actions: _actionsFrom(sum?.actions ?? const []),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Team performance
  // ---------------------------------------------------------------------------
  _View _teamView() {
    final r = _teamPerformance;
    final loaded = r != null;
    final sorted = [...(r?.items ?? <TeamPerformanceItem>[])]
      ..sort((a, b) => b.achievedSales.compareTo(a.achievedSales));
    final top = sorted.isEmpty ? null : sorted.first;
    final teamAch = r?.teamAchievementPercentage;
    final flagged = r?.flaggedForCoaching ?? 0;

    final kpis = [
      _Kpi(
        color: _C.primary,
        label: 'REPS REPORTING',
        value: loaded ? '${r.repsTracked}' : '00',
        sub: loaded ? '${r.visitsCompleted} visits completed' : 'this period',
      ),
      _Kpi(
        color: _C.good,
        label: 'TOTAL ACHIEVED SALES',
        value: loaded ? _currency(r.totalAchievedSales) : '₹0',
        sub: 'all reps combined',
      ),
      _Kpi(
        color: _C.info,
        label: 'TEAM ACHIEVEMENT',
        value: teamAch == null ? '00%' : '${teamAch.toStringAsFixed(0)}%',
        sub: r?.averageAiScore == null
            ? 'vs sales target'
            : 'avg AI score ${r!.averageAiScore!.toStringAsFixed(0)}',
        subTone: teamAch == null
            ? _Tone.neutral
            : (teamAch >= 80 ? _Tone.good : _Tone.warn),
      ),
      _Kpi(
        color: _C.risk,
        label: 'FLAGGED FOR COACHING',
        value: loaded ? '$flagged reps' : '00',
        sub: 'need review',
        subTone: flagged > 0 ? _Tone.risk : _Tone.neutral,
      ),
    ];

    final cards = [
      for (int i = 0; i < sorted.length; i++)
        () {
          final it = sorted[i];
          final target = it.target.number;
          final ach = it.achievementPercentage.number;
          final p = _plan(
            sales: it.achievedSales,
            target: target ?? 0,
            projNext: it.nextMonthProjected,
          );
          final f = _footFromBackend(it.nextMonthTarget, p);
          final badge = _badgeFor(ach);
          final parts = <String>[
            'Dealers covered **${it.dealersCovered}**',
            'Visits **${it.completedVisits}**',
            'Attendance **${it.attendancePct.toStringAsFixed(0)}%**',
            if (it.aiScore != null)
              'AI score **${it.aiScore!.toStringAsFixed(0)}**',
          ];
          return _TargetData(
            title: it.salesperson,
            sub:
                'Rank #${i + 1}${it.zone == null ? '' : ' · ${it.zone}'} · ${it.ordersBooked} orders booked',
            avatarText: _initials(it.salesperson),
            trend: [for (final t in it.trend) t.value],
            growth: it.changePercentage,
            badgeText: badge.$1,
            badgeTone: badge.$2,
            stats: [
              _Stat('THIS MONTH ACHIEVED', _currency(it.achievedSales)),
              _Stat('SALES TARGET', _cur(target)),
              _Stat(
                'ACHIEVEMENT',
                ach == null ? '00%' : '${ach.round()}%',
                ach == null ? null : (ach >= 100 ? _C.good : _C.risk),
              ),
              _Stat('NEXT MO. PROJECTED', _currency(it.nextMonthProjected)),
            ],
            extra: parts.join(' · '),
            coachingText: it.coachingFlag
                ? (it.coachingReason ?? 'Flagged for coaching review.')
                : null,
            footLabel: 'NEXT MONTH SALES TARGET FOR AGENT',
            footValue: f.value,
            footTag: f.tag,
            footTone: f.tone,
          );
        }(),
    ];

    final headline = r?.headline ?? '';
    return _View(
      copy: headline.isNotEmpty
          ? _boldFirst(headline, top?.salesperson ?? '')
          : (top == null
                ? 'Rep-level activity, quota attainment and productivity trends will appear here once the report loads.'
                : '**${top.salesperson}** leads with **${_currency(top.achievedSales)}**.'),
      badges: [
        '👥 ${loaded ? r.repsTracked : '00'} reps tracked',
        '⚠ ${loaded ? flagged : '00'} flagged for coaching',
      ],
      filters: ['Region: All', 'Manager: All', _period3()],
      kpis: kpis,
      sections: _targetSection(
        'Monthly projection & next month\'s target',
        '· per agent',
        cards,
        _placeholderTarget(footLabel: 'NEXT MONTH SALES TARGET FOR AGENT'),
      ),
      actions: _actionsFrom(r?.actions ?? const []),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Order fulfilment
  // ---------------------------------------------------------------------------
  /// Funnel stage from order status. Statuses other than placed / delivered /
  /// cancelled / rejected are matched by keyword — adjust if backend differs.
  int _stage(String status) {
    final v = status.toLowerCase();
    if (v.contains('cancel') || v.contains('reject')) return -1;
    if (v.contains('deliver') || v.contains('complete')) return 3;
    if (v.contains('dispatch') || v.contains('ship') || v.contains('transit')) {
      return 2;
    }
    if (v.contains('confirm') ||
        v.contains('approv') ||
        v.contains('process')) {
      return 1;
    }
    return 0;
  }

  _View _fulfilmentView() {
    final r = _orderFulfilment;
    final loaded = r != null;
    final items = r?.items ?? <FulfilmentOrderItem>[];
    final total = items.length;
    final grossValue = r?.totalGrossValue ?? 0.0;
    final atRiskCount = r?.atRiskCount ?? 0;
    final atRiskValue = r?.totalAtRiskValue ?? 0.0;

    double pctAt(int stage) {
      if (total == 0) return 0;
      if (stage == 0) return 100;
      return items.where((i) => _stage(i.orderStatus) >= stage).length /
          total *
          100;
    }

    final funnel = [
      _FunnelStep('Submitted', pctAt(0), _C.primary),
      _FunnelStep('Confirmed', pctAt(1), const Color(0xFF3A6BEB)),
      _FunnelStep('Dispatched', pctAt(2), _C.info),
      _FunnelStep('Delivered', pctAt(3), _C.good),
    ];

    final atRisk =
        items
            .where(
              (i) =>
                  i.revenueAtRiskValue > 0 ||
                  i.riskLevel.toLowerCase() == 'high' ||
                  i.riskLevel.toLowerCase() == 'medium',
            )
            .toList()
          ..sort(
            (a, b) => b.revenueAtRiskValue.compareTo(a.revenueAtRiskValue),
          );

    final riskRows = [
      for (int i = 0; i < atRisk.length && i < 5; i++)
        () {
          final o = atRisk[i];
          final cancelled = _stage(o.orderStatus) == -1;
          final rl = o.riskLevel.toLowerCase();
          return _RiskRow(
            avatarIdx: i + 2,
            avatarText: o.orderNumber.length >= 2
                ? o.orderNumber.substring(o.orderNumber.length - 2)
                : o.orderNumber,
            title: o.orderNumber,
            sub: o.products,
            insight: o.insight,
            value: _currency(o.revenueAtRiskValue),
            badgeText: cancelled
                ? 'CANCELLED'
                : '${o.riskLevel.toUpperCase()} RISK',
            badgeTone: cancelled || rl == 'high' ? _Tone.risk : _Tone.warn,
          );
        }(),
    ];
    final riskSrc = riskRows.isNotEmpty
        ? riskRows
        : (_showPh
              ? const [
                  _RiskRow(
                    avatarIdx: 2,
                    avatarText: '00',
                    title: 'Test',
                    sub: 'Test — no at-risk orders',
                    insight: '',
                    value: '₹0',
                    badgeText: 'NO DATA',
                    badgeTone: _Tone.neutral,
                  ),
                ]
              : <_RiskRow>[]);

    final kpis = [
      _Kpi(
        color: _C.primary,
        label: 'ORDERS',
        value: loaded ? '$total' : '00',
        sub: 'this period',
      ),
      _Kpi(
        color: _C.good,
        label: 'TOTAL ORDER VALUE',
        value: loaded ? _currency(grossValue) : '₹0',
        sub: 'gross value',
      ),
      _Kpi(
        color: _C.warn,
        label: 'AT-RISK ORDERS',
        value: loaded ? '$atRiskCount' : '00',
        sub: 'delayed or cancelled',
        subTone: atRiskCount > 0 ? _Tone.warn : _Tone.neutral,
      ),
      _Kpi(
        color: _C.risk,
        label: 'REVENUE AT RISK',
        value: loaded ? _currency(atRiskValue) : '₹0',
        sub: 'from delays & cancellations',
        subTone: atRiskValue > 0 ? _Tone.risk : _Tone.neutral,
      ),
    ];

    const zonePlaceholder = _TargetData(
      title: 'Test zone',
      sub: 'Test — ₹0 revenue at risk this month',
      avatarText: 'TE',
      badgeText: 'NO DATA',
      badgeTone: _Tone.neutral,
      stats: [
        _Stat('ON-TIME THIS MONTH', '00%'),
        _Stat('ON-TIME TARGET', '00%'),
        _Stat('vs TARGET', '00%'),
        _Stat('NEXT MO. PROJECTED', '00%'),
      ],
      extra: 'Revenue at risk: **₹0** this month → **₹0** projected next month',
      footLabel: 'NEXT MONTH ON-TIME TARGET FOR ZONE',
      footValue: '00%',
      footTag: 'PENDING',
      footTone: _Tone.neutral,
    );

    final actions = [
      for (final o in atRisk.where((i) => i.insight.isNotEmpty).take(2))
        _Action(
          title: 'Review ${o.orderNumber}',
          body: o.insight,
          impact: '${_currency(o.revenueAtRiskValue)} at risk',
          tone: _Tone.risk,
        ),
    ];

    return _View(
      copy: loaded
          ? '**${_currency(atRiskValue)}** of revenue is at risk from **$atRiskCount orders** out of **$total** placed this period.'
          : 'Delivery performance and where revenue is being lost will appear here once the report loads.',
      badges: [
        '📦 ${loaded ? total : '00'} orders',
        '⚠ ${_currency(atRiskValue)} revenue at risk',
      ],
      filters: ['Status: All', 'Region: All', 'Dealer: All'],
      kpis: kpis,
      sections: [
        if (loaded) _FunnelCard(steps: funnel),
        if (riskSrc.isNotEmpty) _RiskCard(rows: riskSrc),
        ..._targetSection(
          'Monthly projection & next month\'s target',
          '· on-time delivery, per zone',
          const [],
          zonePlaceholder,
        ),
      ],
      actions: actions,
    );
  }
}

// =============================================================================
// Regional helper types
// =============================================================================
class _Zone {
  final String name;
  final double? ach;
  final double? potential;
  final double? gap;
  final double? dealers;
  final String? insight;
  final _TargetData card;
  const _Zone({
    required this.name,
    required this.ach,
    required this.potential,
    required this.gap,
    required this.dealers,
    required this.insight,
    required this.card,
  });
}

extension _TargetDataLabels on _TargetData {
  _TargetData copyWithLabels({
    String? target,
    String? achievement,
    String? footLabel,
  }) {
    return _TargetData(
      title: title,
      sub: sub,
      avatarText: avatarText,
      trend: trend,
      growth: growth,
      badgeText: badgeText,
      badgeTone: badgeTone,
      stats: [
        stats[0],
        _Stat(target ?? stats[1].label, stats[1].value, stats[1].color),
        _Stat(achievement ?? stats[2].label, stats[2].value, stats[2].color),
        stats[3],
      ],
      extra: extra,
      coachingText: coachingText,
      footLabel: footLabel ?? this.footLabel,
      footValue: footValue,
      footTag: footTag,
      footTone: footTone,
    );
  }
}

class _HeatRow {
  final String name;
  final String ach;
  final _Tone achTone;
  final String potential;
  final String gap;
  final _Tone gapTone;
  final String dealers;
  const _HeatRow({
    required this.name,
    required this.ach,
    required this.achTone,
    required this.potential,
    required this.gap,
    required this.gapTone,
    required this.dealers,
  });
}

class _FunnelStep {
  final String label;
  final double pct;
  final Color color;
  const _FunnelStep(this.label, this.pct, this.color);
}

class _RiskRow {
  final int avatarIdx;
  final String avatarText;
  final String title;
  final String sub;
  final String insight;
  final String value;
  final String badgeText;
  final _Tone badgeTone;
  const _RiskRow({
    required this.avatarIdx,
    required this.avatarText,
    required this.title,
    required this.sub,
    required this.insight,
    required this.value,
    required this.badgeText,
    required this.badgeTone,
  });
}

// =============================================================================
// Top bar / hero / selectors / chips
// =============================================================================
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.line),
        ),
        child: Icon(icon, size: 16, color: _C.ink),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final IconData icon;
  final String copy;
  final List<String> badges;
  const _Hero({required this.icon, required this.copy, required this.badges});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_C.navy, _C.navy2],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(19, 19, 19, 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: _RichLine(
                          text: copy,
                          size: 14.5,
                          color: Colors.white,
                          boldColor: Colors.white,
                          height: 1.4,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final b in badges)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            b,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _PeriodSelector({required this.value, required this.onChanged});

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
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onChanged(o[0]),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? _C.navy : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: selected ? _C.navy : _C.line),
                ),
                child: Text(
                  o[1],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : _C.inkSoft,
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
  final ValueChanged<String> onChanged;
  const _HorizonSelector({required this.value, required this.onChanged});

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
              color: selected ? _C.navy : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _C.inkSoft,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.line),
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

class _FilterChips extends StatelessWidget {
  final List<String> labels;
  const _FilterChips({required this.labels});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Row(
        children: [
          for (final l in labels)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => AppWidgets.toast(context, 'Filters coming soon'),
                child: CustomPaint(
                  painter: _DashedRRectPainter(color: _C.line, radius: 999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _C.inkSoft,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedRRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final r = math.min(radius, size.height / 2);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(r)),
      );
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 3), paint);
        d += 6;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
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
            child: Text(message, style: const TextStyle(color: _C.risk)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// =============================================================================
// Text helpers
// =============================================================================
class _SectionLabel extends StatelessWidget {
  final String title;
  final String span;
  final double top;
  const _SectionLabel(this.title, this.span, {this.top = 20});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(2, top, 2, 10),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: _C.inkSoft,
              ),
            ),
            if (span.isNotEmpty)
              TextSpan(
                text: ' $span',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _C.inkFaint,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Renders text where `**bold**` segments are emphasised.
class _RichLine extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final Color boldColor;
  final double height;
  final FontWeight weight;
  const _RichLine({
    required this.text,
    required this.size,
    required this.color,
    required this.boldColor,
    this.height = 1.4,
    this.weight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    final parts = text.split('**');
    return Text.rich(
      TextSpan(
        children: [
          for (int i = 0; i < parts.length; i++)
            if (parts[i].isNotEmpty)
              TextSpan(
                text: parts[i],
                style: TextStyle(
                  fontSize: size,
                  height: height,
                  color: i.isOdd ? boldColor : color,
                  fontWeight: i.isOdd ? FontWeight.w700 : weight,
                ),
              ),
        ],
      ),
    );
  }
}

// =============================================================================
// Cards
// =============================================================================
BoxDecoration _cardDeco([double r = 20]) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(r),
  border: Border.all(color: _C.line),
  boxShadow: [
    BoxShadow(
      color: _C.ink.withValues(alpha: 0.06),
      blurRadius: 22,
      spreadRadius: -12,
      offset: const Offset(0, 8),
    ),
  ],
);

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: child,
    );
  }
}

class _CardHead extends StatelessWidget {
  final String title;
  final String sub;
  const _CardHead(this.title, this.sub);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: _C.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _C.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final _Tone tone;
  const _Badge(this.text, this.tone);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: tone.fg,
        ),
      ),
    );
  }
}

// ---- KPI grid ---------------------------------------------------------------
class _KpiGrid extends StatelessWidget {
  final List<_Kpi> kpis;
  const _KpiGrid({required this.kpis});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < kpis.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 11));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _KpiCard(kpi: kpis[i])),
              const SizedBox(width: 11),
              Expanded(
                child: i + 1 < kpis.length
                    ? _KpiCard(kpi: kpis[i + 1])
                    : const SizedBox(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _KpiCard extends StatelessWidget {
  final _Kpi kpi;
  const _KpiCard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: kpi.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  kpi.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.8,
                    fontWeight: FontWeight.w800,
                    color: _C.inkSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            kpi.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _C.ink,
            ),
          ),
          if (kpi.sub.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              kpi.sub,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.3,
                fontWeight: FontWeight.w600,
                color: kpi.subTone == _Tone.neutral
                    ? _C.inkFaint
                    : kpi.subTone.fg,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---- Target / projection card ----------------------------------------------
class _TargetCard extends StatelessWidget {
  final _TargetData data;
  final int index;
  const _TargetCard({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    final pal = _C.avatarPalette[index % _C.avatarPalette.length];
    final g = data.growth;
    final growthColor = g == null ? _C.inkFaint : (g >= 0 ? _C.good : _C.risk);
    final growthText = g == null ? '00%' : '${g >= 0 ? '+' : ''}${g.round()}%';

    return Container(
      margin: EdgeInsets.only(top: index == 0 ? 0 : 10),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: pal[0],
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  data.avatarText,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: pal[1],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _C.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _C.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
              CustomPaint(
                size: const Size(64, 24),
                painter: _SparkPainter(
                  points: data.trend,
                  color: g == null ? _C.inkFaint : (g >= 0 ? _C.good : _C.risk),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    growthText,
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: growthColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _Badge(data.badgeText, data.badgeTone),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < data.stats.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: _StatCell(stat: data.stats[i])),
              ],
            ],
          ),
          if (data.extra != null && data.extra!.isNotEmpty) ...[
            const SizedBox(height: 9),
            _RichLine(
              text: data.extra!,
              size: 11,
              color: _C.inkFaint,
              boldColor: _C.ink,
              height: 1.5,
            ),
          ],
          if (data.coachingText != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _C.warnSoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.flag_rounded, size: 14, color: _C.warn),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.coachingText!,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: _C.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: data.footTone.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.footLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: data.footTone == _Tone.neutral
                              ? _C.inkFaint
                              : data.footTone.fg,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.footValue,
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _C.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _Badge(data.footTag, data.footTone),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final _Stat stat;
  const _StatCell({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stat.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: _C.inkFaint,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            stat.value,
            maxLines: 1,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: stat.color ?? _C.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> points;
  final Color color;
  const _SparkPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (points.length < 2) {
      // no trend data -> flat placeholder line
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }
    final maxV = points.reduce(math.max);
    final minV = points.reduce(math.min);
    if (maxV == minV) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }
    final range = maxV - minV;
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = i / (points.length - 1) * size.width;
      final y = size.height - ((points[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.points != points || old.color != color;
}

// ---- Action card -------------------------------------------------------------
class _ActionCard extends StatelessWidget {
  final int rank;
  final _Action action;
  const _ActionCard({required this.rank, required this.action});

  @override
  Widget build(BuildContext context) {
    final tone = action.tone;
    return Container(
      margin: const EdgeInsets.only(top: 9),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _C.primarySoft,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _C.primary,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  action.body,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: _C.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: tone.bg,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                action.impact,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: tone.fg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Heat grid (regional) ---------------------------------------------------
class _HeatCard extends StatelessWidget {
  final List<_HeatRow> rows;
  const _HeatCard({required this.rows});

  Widget _cell(String t, Color bg, Color fg) => Expanded(
    child: Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            t,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _head(String t) => Expanded(
    child: Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 3),
      child: Text(
        t,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: _C.inkSoft,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHead(
            'Zone-wise achievement vs market potential',
            'Achievement % · Estimated potential · Opportunity gap · Active dealers',
          ),
          Row(
            children: [
              const SizedBox(width: 70),
              _head('ACH%'),
              _head('POTENTIAL'),
              _head('GAP'),
              _head('DEALERS'),
            ],
          ),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _C.ink,
                      ),
                    ),
                  ),
                  _cell(r.ach, r.achTone.bg, r.achTone.fg),
                  _cell(r.potential, _C.primarySoft, _C.primary),
                  _cell(r.gap, r.gapTone.bg, r.gapTone.fg),
                  _cell(r.dealers, _C.bg, _C.inkSoft),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---- Funnel + at-risk orders (fulfilment) ------------------------------------
class _FunnelCard extends StatelessWidget {
  final List<_FunnelStep> steps;
  const _FunnelCard({required this.steps});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHead(
            'Order-to-delivery funnel',
            'Share of orders reaching each stage',
          ),
          for (int i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 78,
                    child: Text(
                      steps[i].label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _C.inkSoft,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: math.max(steps[i].pct / 100, 0.16),
                        child: Container(
                          height: 34,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: steps[i].color,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            steps[i].pct == 0
                                ? '00%'
                                : '${steps[i].pct.round()}%',
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
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

class _RiskCard extends StatelessWidget {
  final List<_RiskRow> rows;
  const _RiskCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHead('Orders at risk', 'Ranked by revenue-at-risk value'),
          for (int i = 0; i < rows.length; i++)
            Container(
              padding: EdgeInsets.only(top: i == 0 ? 2 : 11, bottom: 11),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : const Border(top: BorderSide(color: _C.line)),
              ),
              child: _riskRow(rows[i]),
            ),
        ],
      ),
    );
  }

  Widget _riskRow(_RiskRow r) {
    final pal = _C.avatarPalette[r.avatarIdx % _C.avatarPalette.length];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: pal[0],
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            r.avatarText,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: pal[1],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                r.sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _C.inkFaint,
                ),
              ),
              if (r.insight.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  r.insight,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    height: 1.35,
                    color: _C.inkSoft,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              r.value,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: _C.risk,
              ),
            ),
            const SizedBox(height: 4),
            _Badge(r.badgeText, r.badgeTone),
          ],
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

double? _num(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is num) return v.toDouble();
    if (v is String) {
      final p = double.tryParse(v);
      if (p != null) return p;
    }
  }
  return null;
}

String? _str(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString();
  }
  return null;
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

String _initials(String s) {
  final w = s.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (w.isEmpty) return '--';
  if (w.length == 1) {
    return w.first.substring(0, w.first.length >= 2 ? 2 : 1).toUpperCase();
  }
  return '${w[0][0]}${w[1][0]}'.toUpperCase();
}

String _cur(double? v) => v == null ? '₹0' : _currency(v);

String _currency(double value) {
  final sign = value < 0 ? '-' : '';
  final v = value.abs();
  if (v >= 10000000) return '$sign₹${(v / 10000000).toStringAsFixed(1)}Cr';
  if (v >= 100000) return '$sign₹${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '$sign₹${(v / 1000).toStringAsFixed(1)}K';
  return '$sign₹${v.toStringAsFixed(0)}';
}

_Tone _toneFor(String impact) => switch (impact.toLowerCase()) {
  'good' => _Tone.good,
  'risk' || 'bad' => _Tone.risk,
  'warn' || 'warning' => _Tone.warn,
  _ => _Tone.info,
};

List<_Action> _actionsFrom(List<ReportAction> src, {int max = 3}) => [
  for (final a in src.take(max))
    _Action(
      title: a.action.isEmpty ? a.name : a.action,
      body: a.action.isEmpty ? a.reason : '${a.name} — ${a.reason}',
      impact: a.impactType.isEmpty
          ? 'Insight'
          : '${a.impactType[0].toUpperCase()}${a.impactType.substring(1)}',
      tone: _toneFor(a.impactType),
    ),
];

String _boldFirst(String text, String name) =>
    (name.isNotEmpty && text.contains(name))
    ? text.replaceFirst(name, '**$name**')
    : text;

/// Footer from the backend's next_month_target ({status,label,value}).
/// Falls back to the client-side plan when the backend has no target.
({String value, String tag, _Tone tone}) _footFromBackend(
  TrackedValue t,
  _Plan fallback,
) {
  final v = t.number;
  if (v == null) return _foot(fallback);
  final label = (t.label ?? '').toLowerCase();
  final m = RegExp(r'stretch_(\d+)pct').firstMatch(label);
  if (m != null) {
    return (
      value: _currency(v),
      tag: 'STRETCH +${m.group(1)}%',
      tone: _Tone.good,
    );
  }
  if (label.contains('recover')) {
    return (value: _currency(v), tag: 'RECOVERY', tone: _Tone.warn);
  }
  return (value: _currency(v), tag: 'SET', tone: _Tone.info);
}
