import 'package:kutchina/core/services/api_services.dart';

class AdminDashboardData {
  final String period;
  final double totalSalesValue;
  final double? totalSalesGrowthPercentage;
  final int ordersCount;
  final double? averageOrderValue;
  final double dayEndSalesValue;
  final int dayEndOrdersCount;
  final double targetValue;
  final double targetAchievedPercentage;
  final DashboardLeader? topProduct;
  final DashboardLeader? topSalesperson;
  final DashboardLeader? topArea;
  final DashboardLeader? topZone;
  final List<DashboardCategory> salesByCategory;
  final List<DashboardRegion> salesByRegion;
  final List<DashboardTeamMember> salesTeamPerformance;
  final double forecastTomorrowValue;
  final double forecastTomorrowConfidencePercentage;

  const AdminDashboardData({
    required this.period,
    required this.totalSalesValue,
    required this.totalSalesGrowthPercentage,
    required this.ordersCount,
    required this.averageOrderValue,
    required this.dayEndSalesValue,
    required this.dayEndOrdersCount,
    required this.targetValue,
    required this.targetAchievedPercentage,
    required this.topProduct,
    required this.topSalesperson,
    required this.topArea,
    required this.topZone,
    required this.salesByCategory,
    required this.salesByRegion,
    required this.salesTeamPerformance,
    required this.forecastTomorrowValue,
    required this.forecastTomorrowConfidencePercentage,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    final data = _map(json['data']) ?? json;
    return AdminDashboardData(
      period: _string(data['period'], fallback: 'month'),
      totalSalesValue: _number(data['total_sales_value']),
      totalSalesGrowthPercentage: _nullableNumber(
        data['total_sales_growth_percentage'],
      ),
      ordersCount: _number(data['orders_count']).round(),
      averageOrderValue: _nullableNumber(data['average_order_value']),
      dayEndSalesValue: _number(data['day_end_sales_value']),
      dayEndOrdersCount: _number(data['day_end_orders_count']).round(),
      targetValue: _number(data['target_value']),
      targetAchievedPercentage: _number(data['target_achieved_percentage']),
      topProduct: DashboardLeader.fromDynamic(data['top_product']),
      topSalesperson: DashboardLeader.fromDynamic(data['top_salesperson']),
      topArea: DashboardLeader.fromDynamic(data['top_area']),
      topZone: DashboardLeader.fromDynamic(data['top_zone']),
      salesByCategory: _list(
        data['sales_by_category'],
      ).map(DashboardCategory.fromJson).toList(),
      salesByRegion: _list(
        data['sales_by_zone'],
      ).map(DashboardRegion.fromJson).toList(),
      salesTeamPerformance: _list(
        data['sales_team_performance'],
      ).map(DashboardTeamMember.fromJson).toList(),
      forecastTomorrowValue: _number(data['forecast_tomorrow_value']),
      forecastTomorrowConfidencePercentage: _number(
        data['forecast_tomorrow_confidence_percentage'],
      ),
    );
  }
}

class DashboardLeader {
  final String name;
  final double value;

  const DashboardLeader({required this.name, required this.value});

  static DashboardLeader? fromDynamic(dynamic raw) {
    final map = _map(raw);
    if (map == null) return null;
    return DashboardLeader(
      name: _string(
        map['region'] ?? map['product_name'] ?? map['salesperson'],
        fallback: 'Unavailable',
      ),
      value: _number(
        map['value'] ??
            map['sales_value'] ??
            map['total_sales_value'] ??
            map['amount'],
      ),
    );
  }
}

class DashboardCategory {
  final int categoryId;
  final String name;
  final double value;
  final double percentage;

  const DashboardCategory({
    required this.categoryId,
    required this.name,
    required this.value,
    required this.percentage,
  });

  factory DashboardCategory.fromJson(Map<String, dynamic> json) {
    return DashboardCategory(
      categoryId: _number(json['category_id']).round(),
      name: _string(
        json['category'] ?? json['category_name'] ?? json['product_name'],
        fallback: 'Other',
      ),
      value: _number(json['sales_value'] ?? json['total_sales_value']),
      percentage: _number(
        json['percentage'] ?? json['percent'] ?? json['share_percentage'],
      ),
    );
  }
}

class DashboardRegion {
  final String name;
  final double value;
  final double percentage;
  final double target;

  const DashboardRegion({
    required this.name,
    required this.value,
    required this.percentage,
    required this.target,
  });

  factory DashboardRegion.fromJson(Map<String, dynamic> json) {
    print("Region Json ${json}");
    return DashboardRegion(
      name: _string(
        json['zone'] ?? json['region_name'] ?? json['zone'],
        fallback: 'Other',
      ),
      value: _number(json['sales_value']),
      // percentage: _number(json['achievement_percentage']),
      percentage: _number(26.77),
      target: _number(json['target_value']),
    );
  }
}

class DashboardTeamMember {
  final String name;
  final double today;
  final double month;

  const DashboardTeamMember({
    required this.name,
    required this.today,
    required this.month,
  });

  factory DashboardTeamMember.fromJson(Map<String, dynamic> json) {
    final name = _string(
      json['name'] ?? json['salesperson'] ?? json['user_name'],
      fallback: 'Unknown',
    );
    return DashboardTeamMember(
      name: name,
      today: _number(
        json['today'] ?? json['sales_today'] ?? json['today_value'],
      ),
      month: _number(
        json['month'] ?? json['sales_this_period'] ?? json['month_value'],
      ),
    );
  }
}

class AdminDashboardApi {
  AdminDashboardApi._();

  static Future<AdminDashboardData> fetchOverview({
    String period = 'month',
  }) async {
    final response = await ApiService.instance.get('/api/v1/reports/overview/');
    final body = _map(response.data);
    if (body == null || body['success'] != true) {
      throw ApiException(
        body?['message']?.toString() ?? 'Unable to load dashboard overview',
      );
    }
    return AdminDashboardData.fromJson(body);
  }
}

Map<String, dynamic>? _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is! List) return const [];
  return value.map(_map).whereType<Map<String, dynamic>>().toList();
}

double _number(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _nullableNumber(dynamic value) => value == null ? null : _number(value);

String _string(dynamic value, {required String fallback}) {
  final result = value?.toString().trim() ?? '';
  return result.isEmpty ? fallback : result;
}
