import 'package:kutchina/core/services/api_services.dart';

// ===========================================================================
// Product demand
// ===========================================================================
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
  final String demandDirection;
  final double confidence;
  final double projectedDemandUnits;
  final double projectedRevenue;
  final String insight;

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
    required this.demandDirection,
    required this.confidence,
    required this.projectedDemandUnits,
    required this.projectedRevenue,
    required this.insight,
  });

  factory ProductDemandItem.fromJson(Map<String, dynamic> json) {
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
      demandDirection: json['demand_direction']?.toString() ?? '',
      confidence: _number(json['confidence']),
      projectedDemandUnits: _number(json['projected_demand_units']),
      projectedRevenue: _number(json['projected_revenue']),
      insight: json['insight']?.toString() ?? 'No Product Demand',
    );
  }
}

class ProductDemandSummary {
  final String topProductName;
  final double topProductSalesValue;
  final int slowMoversCount;
  final double? averageGrowthPercentage;

  const ProductDemandSummary({
    required this.topProductName,
    required this.topProductSalesValue,
    required this.slowMoversCount,
    required this.averageGrowthPercentage,
  });

  factory ProductDemandSummary.fromJson(Map<String, dynamic> json) {
    final topProduct = _asMap(json['top_product']);
    return ProductDemandSummary(
      topProductName: topProduct['product_name']?.toString() ?? '',
      topProductSalesValue: _number(topProduct['sales_value']),
      slowMoversCount: _number(json['slow_movers_count']).round(),
      averageGrowthPercentage: _nullableNumber(
        json['average_growth_percentage'],
      ),
    );
  }
}

// ===========================================================================
// Dealer potential — no `summary` block; KPIs are computed client-side
// ===========================================================================
class DealerPotentialItem {
  final int dealerId;
  final String dealerName;
  final String dealerCategory; // Distributor / Retailer
  final DateTime? lastVisitDate;
  final int visitFrequency;
  final int daysSinceLastVisit;
  final String dealerSegment; // steady / at_risk / high_potential
  final String visitEngagementLevel; // low / medium / high
  final String insight;

  const DealerPotentialItem({
    required this.dealerId,
    required this.dealerName,
    required this.dealerCategory,
    required this.lastVisitDate,
    required this.visitFrequency,
    required this.daysSinceLastVisit,
    required this.dealerSegment,
    required this.visitEngagementLevel,
    required this.insight,
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
      daysSinceLastVisit: _number(json['days_since_last_visit']).round(),
      dealerSegment: json['dealer_segment']?.toString() ?? '',
      visitEngagementLevel: json['visit_engagement_level']?.toString() ?? '',
      insight: json['insight']?.toString() ?? 'No Dealer Potential',
    );
  }
}

class DealerPotentialReport {
  final List<DealerPotentialItem> items;
  const DealerPotentialReport({required this.items});

  factory DealerPotentialReport.fromJson(Map<String, dynamic> json) {
    final rawItems = json['data'] is List ? json['data'] as List : const [];
    return DealerPotentialReport(
      items: rawItems
          .whereType<Map>()
          .map((e) => DealerPotentialItem.fromJson(_asMap(e)))
          .toList(),
    );
  }

  int get atRiskCount =>
      items.where((e) => e.dealerSegment == 'at_risk').length;
  int get highPotentialCount =>
      items.where((e) => e.dealerSegment == 'high_potential').length;
  int get steadyCount => items.where((e) => e.dealerSegment == 'steady').length;
  double get avgVisitFrequency => items.isEmpty
      ? 0
      : items.map((e) => e.visitFrequency).reduce((a, b) => a + b) /
            items.length;
}

// ===========================================================================
// Order fulfilment — no `summary` block; KPIs are computed client-side
// ===========================================================================
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

// ===========================================================================
// Sales projection — usually one aggregate row per period; `summary.forecast`
// only appears for horizon=next_3_months and its shape isn't confirmed yet.
// ===========================================================================
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

  /// Raw forecast block — only present for horizon=next_3_months. Shape not
  /// confirmed yet, kept as a raw map until a sample response is available.
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

// ===========================================================================
// Team performance — no `summary` block; KPIs are computed client-side
// ===========================================================================
class TeamPerformanceItem {
  final int userId;
  final String salesperson;
  final double target;
  final double achievedSales;
  final int ordersBooked;
  final double achievementPercentage;
  final int dealersCovered;
  final int completedVisits;
  final double attendancePct;
  final double? aiPerformanceScore;
  final bool coachingFlag;
  final String? coachingReason;
  final String insight;

  const TeamPerformanceItem({
    required this.userId,
    required this.salesperson,
    required this.target,
    required this.achievedSales,
    required this.ordersBooked,
    required this.achievementPercentage,
    required this.dealersCovered,
    required this.completedVisits,
    required this.attendancePct,
    required this.aiPerformanceScore,
    required this.coachingFlag,
    required this.coachingReason,
    required this.insight,
  });

  factory TeamPerformanceItem.fromJson(Map<String, dynamic> json) {
    return TeamPerformanceItem(
      userId: _number(json['user_id']).round(),
      salesperson: json['salesperson']?.toString() ?? '',
      target: _number(json['target']),
      achievedSales: _number(json['achieved_sales']),
      ordersBooked: _number(json['orders_booked']).round(),
      achievementPercentage: _number(json['achievement_percentage']),
      dealersCovered: _number(json['dealers_covered']).round(),
      completedVisits: _number(json['completed_visits']).round(),
      attendancePct: _number(json['attendance_pct']),
      aiPerformanceScore: _nullableNumber(json['ai_performance_score']),
      coachingFlag: json['coaching_flag'] == true,
      coachingReason: json['coaching_reason']?.toString(),
      insight: json['insight']?.toString() ?? 'No Team Perfomance',
    );
  }
}

class TeamPerformanceReport {
  final List<TeamPerformanceItem> items;
  const TeamPerformanceReport({required this.items});

  factory TeamPerformanceReport.fromJson(Map<String, dynamic> json) {
    final rawItems = json['data'] is List ? json['data'] as List : const [];
    return TeamPerformanceReport(
      items: rawItems
          .whereType<Map>()
          .map((e) => TeamPerformanceItem.fromJson(_asMap(e)))
          .toList(),
    );
  }

  double get totalAchievedSales =>
      items.fold(0.0, (sum, e) => sum + e.achievedSales);
  double get avgAchievementPercentage => items.isEmpty
      ? 0
      : items.map((e) => e.achievementPercentage).reduce((a, b) => a + b) /
            items.length;
  int get coachingFlagCount => items.where((e) => e.coachingFlag).length;
}

// ===========================================================================
// API
// ===========================================================================
class AdminReportApi {
  AdminReportApi._();

  /// Generic call shared by every report type — same endpoint, different
  /// `report_type` (and optionally `period` / `horizon`). Returns the raw
  /// decoded body; used directly only for report types without a typed
  /// model yet (e.g. regional_opportunity).
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
