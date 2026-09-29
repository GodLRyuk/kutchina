import 'package:kutchina/core/services/api_services.dart';

class TrackedValue {
  final dynamic raw;
  final bool notTracked;
  final String? label;
  final String? status;

  const TrackedValue({
    this.raw,
    this.notTracked = true,
    this.label,
    this.status,
  });

  factory TrackedValue.fromJson(dynamic json) {
    if (json is Map) {
      final v = json['value'];
      return TrackedValue(
        raw: v,
        notTracked: json['not_tracked'] == true || v == null,
        label: json['label']?.toString(),
        status: json['status']?.toString(),
      );
    }
    return TrackedValue(raw: json, notTracked: json == null);
  }

  bool get hasValue => !notTracked && raw != null;

  double? get number {
    final v = raw;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  String? get text => raw?.toString();
}

class TrendPoint {
  final DateTime? date;
  final double value;
  const TrendPoint({required this.date, required this.value});

  factory TrendPoint.fromJson(Map<String, dynamic> json) => TrendPoint(
    date: DateTime.tryParse(json['date']?.toString() ?? ''),
    value: _number(json['value']),
  );
}

List<TrendPoint> _trendFrom(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => TrendPoint.fromJson(_asMap(e))).toList()
    : <TrendPoint>[];

/// Action used by dealer / regional / team reports.
class ReportAction {
  final int? id;
  final String name;
  final String action;
  final String reason;
  final String impactType;
  const ReportAction({
    required this.id,
    required this.name,
    required this.action,
    required this.reason,
    required this.impactType,
  });

  factory ReportAction.fromJson(Map<String, dynamic> json) => ReportAction(
    id: _nullableNumber(
      json['dealer_id'] ??
          json['zone_id'] ??
          json['user_id'] ??
          json['product_id'],
    )?.round(),
    name:
        (json['dealer_name'] ??
                json['zone'] ??
                json['salesperson'] ??
                json['product_name'])
            ?.toString() ??
        '',
    action: json['action']?.toString() ?? '',
    reason: json['reason']?.toString() ?? '',
    impactType: json['impact_type']?.toString() ?? '',
  );
}

List<ReportAction> _actionsFromJson(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => ReportAction.fromJson(_asMap(e))).toList()
    : <ReportAction>[];

class ProductDemandReport {
  final String period;
  final DateTime? generatedAt;
  final List<ProductDemandItem> items;
  final ProductDemandSummary summary;

  const ProductDemandReport({
    required this.period,
    required this.generatedAt,
    required this.items,
    required this.summary,
  });

  factory ProductDemandReport.fromJson(Map<String, dynamic> json) {
    final rawItems = json['data'] is List ? json['data'] as List : const [];
    final summary = _asMap(json['summary']);
    return ProductDemandReport(
      period: json['period']?.toString() ?? 'month',
      generatedAt: DateTime.tryParse(json['generated_at']?.toString() ?? ''),
      items: rawItems
          .whereType<Map>()
          .map((item) => ProductDemandItem.fromJson(_asMap(item)))
          .toList(),
      summary: ProductDemandSummary.fromJson(summary),
    );
  }
}

class ProductDemandItem {
  final int productId;
  final String productName;
  final String sku;
  final int unitsSold;
  final double salesValue;
  final double orderFrequency;
  final double currentPeriodSales;
  final double previousPeriodSales;
  final double? growthPercentage;
  final double averageSellingPrice;
  final List<TrendPoint> trend;
  final double nextMonthProjected;
  final TrackedValue targetValue;
  final TrackedValue achievementPercentage;
  final TrackedValue achievementStatus;
  final TrackedValue nextMonthTarget;

  const ProductDemandItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unitsSold,
    required this.salesValue,
    required this.orderFrequency,
    required this.currentPeriodSales,
    required this.previousPeriodSales,
    required this.growthPercentage,
    required this.averageSellingPrice,
    required this.trend,
    required this.nextMonthProjected,
    required this.targetValue,
    required this.achievementPercentage,
    required this.achievementStatus,
    required this.nextMonthTarget,
  });

  factory ProductDemandItem.fromJson(Map<String, dynamic> json) {
    final rawTrend = json['trend'] is List ? json['trend'] as List : const [];
    return ProductDemandItem(
      productId: _number(json['product_id']).round(),
      productName: json['product_name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      unitsSold: _number(json['units_sold']).round(),
      salesValue: _number(json['sales_value']),
      orderFrequency: _number(json['order_frequency']),
      currentPeriodSales: _number(json['current_period_sales']),
      previousPeriodSales: _number(json['previous_period_sales']),
      growthPercentage: _nullableNumber(json['growth_percentage']),
      averageSellingPrice: _number(json['average_selling_price']),
      trend: rawTrend
          .whereType<Map>()
          .map((e) => TrendPoint.fromJson(_asMap(e)))
          .toList(),
      nextMonthProjected: _number(json['next_month_projected']),
      targetValue: TrackedValue.fromJson(json['target_value']),
      achievementPercentage: TrackedValue.fromJson(
        json['achievement_percentage'],
      ),
      achievementStatus: TrackedValue.fromJson(json['achievement_status']),
      nextMonthTarget: TrackedValue.fromJson(json['next_month_target']),
    );
  }
}

class ProductDemandTopSku {
  final int productId;
  final String productName;
  final double salesValue;

  const ProductDemandTopSku({
    required this.productId,
    required this.productName,
    required this.salesValue,
  });

  factory ProductDemandTopSku.fromJson(Map<String, dynamic> json) =>
      ProductDemandTopSku(
        productId: _number(json['product_id']).round(),
        productName: json['product_name']?.toString() ?? '',
        salesValue: _number(json['sales_value']),
      );
}

class ProductDemandAction {
  final int productId;
  final String productName;
  final String action;
  final String reason;
  final String impactType; // good / warn / risk

  const ProductDemandAction({
    required this.productId,
    required this.productName,
    required this.action,
    required this.reason,
    required this.impactType,
  });

  factory ProductDemandAction.fromJson(Map<String, dynamic> json) =>
      ProductDemandAction(
        productId: _number(json['product_id']).round(),
        productName: json['product_name']?.toString() ?? '',
        action: json['action']?.toString() ?? '',
        reason: json['reason']?.toString() ?? '',
        impactType: json['impact_type']?.toString() ?? '',
      );
}

class ProductDemandSummary {
  final int productsTracked;
  final ProductDemandTopSku topSku;
  final TrackedValue missedTarget;
  final TrackedValue averageAchievementPercentage;
  final TrackedValue needsRecoveryCount;
  final double projectedRevenueNextMonth;
  final String headline;
  final List<ProductDemandAction> actions;

  const ProductDemandSummary({
    required this.productsTracked,
    required this.topSku,
    required this.missedTarget,
    required this.averageAchievementPercentage,
    required this.needsRecoveryCount,
    required this.projectedRevenueNextMonth,
    required this.headline,
    required this.actions,
  });

  /// Convenience getters (kept so existing callers don't break).
  String get topProductName => topSku.productName;
  double get topProductSalesValue => topSku.salesValue;

  factory ProductDemandSummary.fromJson(Map<String, dynamic> json) {
    final rawActions = json['actions'] is List
        ? json['actions'] as List
        : const [];
    return ProductDemandSummary(
      productsTracked: _number(json['products_tracked']).round(),
      // key is `top_sku` (was misspelled `top_suk` before)
      topSku: ProductDemandTopSku.fromJson(_asMap(json['top_sku'])),
      missedTarget: TrackedValue.fromJson(json['missed_target']),
      averageAchievementPercentage: TrackedValue.fromJson(
        json['average_achievement_percentage'],
      ),
      needsRecoveryCount: TrackedValue.fromJson(json['needs_recovery_count']),
      projectedRevenueNextMonth: _number(json['projected_revenue_next_month']),
      headline: json['headline']?.toString() ?? '',
      actions: rawActions
          .whereType<Map>()
          .map((e) => ProductDemandAction.fromJson(_asMap(e)))
          .toList(),
    );
  }
}

class DealerPotentialItem {
  final int dealerId;
  final String dealerName;
  final String dealerCategory;
  final DateTime? lastVisitDate;
  final int visitFrequency;
  final int? daysSinceLastVisit;
  final TrackedValue salesValue;
  final TrackedValue orderCount;
  final TrackedValue averageOrderValue;
  final List<TrendPoint> trend;
  final TrackedValue nextMonthProjected;
  final TrackedValue growthTarget;
  final TrackedValue potentialValue;
  final TrackedValue achievementPercentage;
  final TrackedValue achievementStatus;
  final TrackedValue nextMonthTarget;
  final TrackedValue outstandingAmount;
  final TrackedValue city;

  const DealerPotentialItem({
    required this.dealerId,
    required this.dealerName,
    required this.dealerCategory,
    required this.lastVisitDate,
    required this.visitFrequency,
    required this.daysSinceLastVisit,
    required this.salesValue,
    required this.orderCount,
    required this.averageOrderValue,
    required this.trend,
    required this.nextMonthProjected,
    required this.growthTarget,
    required this.potentialValue,
    required this.achievementPercentage,
    required this.achievementStatus,
    required this.nextMonthTarget,
    required this.outstandingAmount,
    required this.city,
  });

  factory DealerPotentialItem.fromJson(Map<String, dynamic> json) {
    return DealerPotentialItem(
      dealerId: _number(json['dealer_id']).round(),
      dealerName: json['dealer_name']?.toString() ?? '',
      dealerCategory: json['dealer_category']?.toString() ?? '',
      lastVisitDate: DateTime.tryParse(
        json['last_visit_date']?.toString() ?? '',
      ),
      visitFrequency: _number(json['visit_frequency']).round(),
      daysSinceLastVisit: _nullableNumber(
        json['days_since_last_visit'],
      )?.round(),
      salesValue: TrackedValue.fromJson(json['sales_value']),
      orderCount: TrackedValue.fromJson(json['order_count']),
      averageOrderValue: TrackedValue.fromJson(json['average_order_value']),
      trend: _trendFrom(json['trend']),
      nextMonthProjected: TrackedValue.fromJson(json['next_month_projected']),
      growthTarget: TrackedValue.fromJson(json['growth_target']),
      potentialValue: TrackedValue.fromJson(json['potential_value']),
      achievementPercentage: TrackedValue.fromJson(
        json['achievement_percentage'],
      ),
      achievementStatus: TrackedValue.fromJson(json['achievement_status']),
      nextMonthTarget: TrackedValue.fromJson(json['next_month_target']),
      outstandingAmount: TrackedValue.fromJson(json['outstanding_amount']),
      city: TrackedValue.fromJson(json['city']),
    );
  }
}

class DealerPotentialSummary {
  final int dealersTracked;
  final TrackedValue atChurnRisk;
  final double? averageOrderValue;
  final TrackedValue highGrowthPotential;
  final TrackedValue outstanding60d;
  final TrackedValue needsRecoveryCount;
  final String headline;
  final List<ReportAction> actions;

  const DealerPotentialSummary({
    required this.dealersTracked,
    required this.atChurnRisk,
    required this.averageOrderValue,
    required this.highGrowthPotential,
    required this.outstanding60d,
    required this.needsRecoveryCount,
    required this.headline,
    required this.actions,
  });

  factory DealerPotentialSummary.fromJson(Map<String, dynamic> json) =>
      DealerPotentialSummary(
        dealersTracked: _number(json['dealers_tracked']).round(),
        atChurnRisk: TrackedValue.fromJson(json['at_churn_risk']),
        averageOrderValue: TrackedValue.fromJson(
          json['average_order_value'],
        ).number,
        highGrowthPotential: TrackedValue.fromJson(
          json['high_growth_potential'],
        ),
        outstanding60d: TrackedValue.fromJson(json['outstanding_60d']),
        needsRecoveryCount: TrackedValue.fromJson(json['needs_recovery_count']),
        headline: json['headline']?.toString() ?? '',
        actions: _actionsFromJson(json['actions']),
      );
}

class DealerPotentialReport {
  final List<DealerPotentialItem> items;
  final DealerPotentialSummary summary;
  const DealerPotentialReport({required this.items, required this.summary});

  factory DealerPotentialReport.fromJson(Map<String, dynamic> json) {
    final rawItems = json['data'] is List ? json['data'] as List : const [];
    return DealerPotentialReport(
      items: rawItems
          .whereType<Map>()
          .map((e) => DealerPotentialItem.fromJson(_asMap(e)))
          .toList(),
      summary: DealerPotentialSummary.fromJson(_asMap(json['summary'])),
    );
  }
}

class FulfilmentOrderItem {
  final int orderId;
  final String orderNumber;
  final DateTime? orderDate;
  final String products;
  final int orderedQuantity;
  final double grossValue;
  final String orderStatus;
  final String channel;
  final String riskLevel; // low / medium / high
  final double revenueAtRiskValue;
  final String insight;

  const FulfilmentOrderItem({
    required this.orderId,
    required this.orderNumber,
    required this.orderDate,
    required this.products,
    required this.orderedQuantity,
    required this.grossValue,
    required this.orderStatus,
    required this.channel,
    required this.riskLevel,
    required this.revenueAtRiskValue,
    required this.insight,
  });

  factory FulfilmentOrderItem.fromJson(Map<String, dynamic> json) {
    return FulfilmentOrderItem(
      orderId: _number(json['order_id']).round(),
      orderNumber: json['order_number']?.toString() ?? '',
      orderDate: DateTime.tryParse(json['order_date']?.toString() ?? ''),
      products: json['products']?.toString() ?? '',
      orderedQuantity: _number(json['ordered_quantity']).round(),
      grossValue: _number(json['gross_value']),
      orderStatus: json['order_status']?.toString() ?? '',
      channel: json['channel']?.toString() ?? '',
      riskLevel: json['risk_level']?.toString() ?? '',
      revenueAtRiskValue: _number(json['revenue_at_risk_value']),
      insight: json['insight']?.toString() ?? 'No Order Item',
    );
  }
}

class OrderFulfilmentReport {
  final List<FulfilmentOrderItem> items;
  const OrderFulfilmentReport({required this.items});

  factory OrderFulfilmentReport.fromJson(Map<String, dynamic> json) {
    final rawItems = json['data'] is List ? json['data'] as List : const [];
    return OrderFulfilmentReport(
      items: rawItems
          .whereType<Map>()
          .map((e) => FulfilmentOrderItem.fromJson(_asMap(e)))
          .toList(),
    );
  }

  double get totalGrossValue => items.fold(0.0, (sum, e) => sum + e.grossValue);
  double get totalAtRiskValue =>
      items.fold(0.0, (sum, e) => sum + e.revenueAtRiskValue);
  int get atRiskCount =>
      items.where((e) => e.riskLevel.toLowerCase() != 'low').length;
}

class SalesProjectionItem {
  final String period;
  final String targetPeriod;
  final double targetValue;
  final double historicalSalesLastPeriod;
  final double currentPeriodSales;
  final double dailySalesRunRate;
  final double pendingOrdersValue;
  final double? achievementProbabilityPercentage;
  final double projectedGap;
  final int daysToTarget;
  final double? opportunityPipelineValue;
  final double? leadConversionProbabilityPct;
  final String? region;
  final String? dealer;
  final String? salesperson;
  final double projectedSales;
  final double confidencePercentage;
  final String insight;

  const SalesProjectionItem({
    required this.period,
    required this.targetPeriod,
    required this.targetValue,
    required this.historicalSalesLastPeriod,
    required this.currentPeriodSales,
    required this.dailySalesRunRate,
    required this.pendingOrdersValue,
    required this.achievementProbabilityPercentage,
    required this.projectedGap,
    required this.daysToTarget,
    required this.opportunityPipelineValue,
    required this.leadConversionProbabilityPct,
    required this.region,
    required this.dealer,
    required this.salesperson,
    required this.projectedSales,
    required this.confidencePercentage,
    required this.insight,
  });

  factory SalesProjectionItem.fromJson(Map<String, dynamic> json) {
    return SalesProjectionItem(
      period: json['period']?.toString() ?? '',
      targetPeriod: json['target_period']?.toString() ?? '',
      targetValue: _number(json['target_value']),
      historicalSalesLastPeriod: _number(json['historical_sales_last_period']),
      currentPeriodSales: _number(json['current_period_sales']),
      dailySalesRunRate: _number(json['daily_sales_run_rate']),
      pendingOrdersValue: _number(json['pending_orders_value']),
      achievementProbabilityPercentage: _nullableNumber(
        json['achievement_probability_percentage'],
      ),
      projectedGap: _number(json['projected_gap']),
      daysToTarget: _number(json['days_to_target']).round(),
      opportunityPipelineValue: _nullableNumber(
        json['opportunity_pipeline_value'],
      ),
      leadConversionProbabilityPct: _nullableNumber(
        json['lead_conversion_probability_pct'],
      ),
      region: json['region']?.toString(),
      dealer: json['dealer']?.toString(),
      salesperson: json['salesperson']?.toString(),
      projectedSales: _number(json['projected_sales']),
      confidencePercentage: _number(json['confidence_percentage']),
      insight: json['insight']?.toString() ?? 'No Sales Projection',
    );
  }
}

class SalesProjectionReport {
  final List<SalesProjectionItem> items;

  final Map<String, dynamic>? forecast;

  const SalesProjectionReport({required this.items, this.forecast});

  factory SalesProjectionReport.fromJson(Map<String, dynamic> json) {
    final rawItems = json['data'] is List ? json['data'] as List : const [];
    final summary = _asMap(json['summary']);
    return SalesProjectionReport(
      items: rawItems
          .whereType<Map>()
          .map((e) => SalesProjectionItem.fromJson(_asMap(e)))
          .toList(),
      forecast: summary['forecast'] is Map ? _asMap(summary['forecast']) : null,
    );
  }
}

class TeamPerformanceItem {
  final int userId;
  final String salesperson;
  final String? zone;
  final TrackedValue target;
  final double achievedSales;
  final int ordersBooked;
  final TrackedValue achievementPercentage;
  final String? achievementStatus;
  final double? changePercentage;
  final List<TrendPoint> trend;
  final double nextMonthProjected;
  final TrackedValue nextMonthTarget;
  final int dealersCovered;
  final int completedVisits;
  final double attendancePct;
  final double? aiScore;
  final bool coachingFlag;
  final String? coachingReason;

  const TeamPerformanceItem({
    required this.userId,
    required this.salesperson,
    required this.zone,
    required this.target,
    required this.achievedSales,
    required this.ordersBooked,
    required this.achievementPercentage,
    required this.achievementStatus,
    required this.changePercentage,
    required this.trend,
    required this.nextMonthProjected,
    required this.nextMonthTarget,
    required this.dealersCovered,
    required this.completedVisits,
    required this.attendancePct,
    required this.aiScore,
    required this.coachingFlag,
    required this.coachingReason,
  });

  factory TeamPerformanceItem.fromJson(Map<String, dynamic> json) {
    return TeamPerformanceItem(
      userId: _number(json['user_id']).round(),
      salesperson: json['salesperson']?.toString() ?? '',
      zone: json['zone']?.toString(),
      target: TrackedValue.fromJson(json['target']),
      achievedSales: _number(json['achieved_sales']),
      ordersBooked: _number(json['orders_booked']).round(),
      achievementPercentage: TrackedValue.fromJson(
        json['achievement_percentage'],
      ),
      achievementStatus: json['achievement_status']?.toString(),
      changePercentage: _nullableNumber(json['change_percentage']),
      trend: _trendFrom(json['trend']),
      nextMonthProjected: _number(json['next_month_projected']),
      nextMonthTarget: TrackedValue.fromJson(json['next_month_target']),
      dealersCovered: _number(json['dealers_covered']).round(),
      completedVisits: _number(json['completed_visits']).round(),
      attendancePct: _number(json['attendance_pct']),
      aiScore: _nullableNumber(json['ai_score']),
      coachingFlag: json['coaching_flag'] == true,
      coachingReason: json['coaching_reason']?.toString(),
    );
  }
}

class TeamPerformanceReport {
  final List<TeamPerformanceItem> items;
  final int repsTracked;
  final double? teamAchievementPercentage;
  final double? averageAiScore;
  final int visitsCompleted;
  final int flaggedForCoaching;
  final String headline;
  final List<ReportAction> actions;

  const TeamPerformanceReport({
    required this.items,
    required this.repsTracked,
    required this.teamAchievementPercentage,
    required this.averageAiScore,
    required this.visitsCompleted,
    required this.flaggedForCoaching,
    required this.headline,
    required this.actions,
  });

  factory TeamPerformanceReport.fromJson(Map<String, dynamic> json) {
    final rawItems = json['data'] is List ? json['data'] as List : const [];
    final s = _asMap(json['summary']);
    final items = rawItems
        .whereType<Map>()
        .map((e) => TeamPerformanceItem.fromJson(_asMap(e)))
        .toList();
    return TeamPerformanceReport(
      items: items,
      repsTracked: s['reps_tracked'] == null
          ? items.length
          : _number(s['reps_tracked']).round(),
      teamAchievementPercentage: _nullableNumber(
        s['team_achievement_percentage'],
      ),
      averageAiScore: _nullableNumber(s['average_ai_score']),
      visitsCompleted: _number(s['visits_completed']).round(),
      flaggedForCoaching: s['flagged_for_coaching'] == null
          ? items.where((e) => e.coachingFlag).length
          : _number(s['flagged_for_coaching']).round(),
      headline: s['headline']?.toString() ?? '',
      actions: _actionsFromJson(s['actions']),
    );
  }

  double get totalAchievedSales =>
      items.fold(0.0, (sum, e) => sum + e.achievedSales);
}

class RegionalZoneItem {
  final int zoneId;
  final String zone;
  final double salesValue;
  final TrackedValue targetValue;
  final TrackedValue achievementPercentage;
  final double? changePercentage;
  final List<TrendPoint> trend;
  final String? achievementStatus;
  final double nextMonthProjected;
  final TrackedValue nextMonthTarget;
  final TrackedValue marketPotential;
  final TrackedValue opportunityGap;
  final TrackedValue activeDealers;
  final TrackedValue inactiveDealers;

  const RegionalZoneItem({
    required this.zoneId,
    required this.zone,
    required this.salesValue,
    required this.targetValue,
    required this.achievementPercentage,
    required this.changePercentage,
    required this.trend,
    required this.achievementStatus,
    required this.nextMonthProjected,
    required this.nextMonthTarget,
    required this.marketPotential,
    required this.opportunityGap,
    required this.activeDealers,
    required this.inactiveDealers,
  });

  factory RegionalZoneItem.fromJson(Map<String, dynamic> json) =>
      RegionalZoneItem(
        zoneId: _number(json['zone_id']).round(),
        zone: json['zone']?.toString() ?? '',
        salesValue: _number(json['sales_value']),
        targetValue: TrackedValue.fromJson(json['target_value']),
        achievementPercentage: TrackedValue.fromJson(
          json['achievement_percentage'],
        ),
        changePercentage: _nullableNumber(json['change_percentage']),
        trend: _trendFrom(json['trend']),
        achievementStatus: json['achievement_status']?.toString(),
        nextMonthProjected: _number(json['next_month_projected']),
        nextMonthTarget: TrackedValue.fromJson(json['next_month_target']),
        marketPotential: TrackedValue.fromJson(json['market_potential']),
        opportunityGap: TrackedValue.fromJson(json['opportunity_gap']),
        activeDealers: TrackedValue.fromJson(json['active_dealers']),
        inactiveDealers: TrackedValue.fromJson(json['inactive_dealers']),
      );
}

class RegionalOpportunityReport {
  final List<RegionalZoneItem> items;
  final int zonesTracked;
  final String? bestZoneName;
  final double? bestZoneAchievement;
  final TrackedValue largestOpportunityGap;
  final TrackedValue activeDealers;
  final TrackedValue inactiveDealers;
  final String headline;
  final List<ReportAction> actions;

  const RegionalOpportunityReport({
    required this.items,
    required this.zonesTracked,
    required this.bestZoneName,
    required this.bestZoneAchievement,
    required this.largestOpportunityGap,
    required this.activeDealers,
    required this.inactiveDealers,
    required this.headline,
    required this.actions,
  });

  factory RegionalOpportunityReport.fromJson(Map<String, dynamic> json) {
    final rawItems = json['data'] is List ? json['data'] as List : const [];
    final s = _asMap(json['summary']);
    final best = _asMap(s['best_performing_zone']);
    final items = rawItems
        .whereType<Map>()
        .map((e) => RegionalZoneItem.fromJson(_asMap(e)))
        .toList();
    return RegionalOpportunityReport(
      items: items,
      zonesTracked: s['zones_tracked'] == null
          ? items.length
          : _number(s['zones_tracked']).round(),
      bestZoneName: best['zone']?.toString(),
      bestZoneAchievement: _nullableNumber(best['achievement_percentage']),
      largestOpportunityGap: TrackedValue.fromJson(
        s['largest_opportunity_gap'],
      ),
      activeDealers: TrackedValue.fromJson(s['active_dealers']),
      inactiveDealers: TrackedValue.fromJson(s['inactive_dealers']),
      headline: s['headline']?.toString() ?? '',
      actions: _actionsFromJson(s['actions']),
    );
  }
}

class AdminReportApi {
  AdminReportApi._();
  static Future<Map<String, dynamic>> generate({
    required String reportType,
    String period = 'month',
    String? horizon,
  }) async {
    final response = await ApiService.instance.post(
      '/api/v1/reports/generate/',
      data: {'report_type': reportType, 'period': period, 'horizon': ?horizon},
    );
    final body = _asMap(response.data);
    if (body['success'] != true) {
      throw ApiException(
        body['message']?.toString() ?? 'Unable to generate report',
      );
    }
    return body;
  }

  static Future<ProductDemandReport> generateProductDemand({
    String period = 'month',
  }) async {
    final body = await generate(reportType: 'product_demand', period: period);
    return ProductDemandReport.fromJson(body);
  }

  static Future<DealerPotentialReport> generateDealerPotential({
    String period = 'month',
  }) async {
    final body = await generate(reportType: 'dealer_potential', period: period);
    return DealerPotentialReport.fromJson(body);
  }

  static Future<OrderFulfilmentReport> generateOrderFulfilment({
    String period = 'month',
  }) async {
    final body = await generate(reportType: 'order_fulfilment', period: period);
    return OrderFulfilmentReport.fromJson(body);
  }

  static Future<SalesProjectionReport> generateSalesProjection({
    String period = 'month',
    String horizon = 'current',
  }) async {
    final body = await generate(
      reportType: 'sales_projection',
      period: period,
      horizon: horizon,
    );
    return SalesProjectionReport.fromJson(body);
  }

  static Future<TeamPerformanceReport> generateTeamPerformance({
    String period = 'month',
  }) async {
    final body = await generate(reportType: 'team_performance', period: period);
    return TeamPerformanceReport.fromJson(body);
  }

  static Future<RegionalOpportunityReport> generateRegionalOpportunity({
    String period = 'month',
  }) async {
    final body = await generate(
      reportType: 'regional_opportunity',
      period: period,
    );
    return RegionalOpportunityReport.fromJson(body);
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

double _number(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _nullableNumber(dynamic value) => value == null ? null : _number(value);
