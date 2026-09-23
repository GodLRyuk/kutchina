import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/services/location_service.dart';
import 'package:kutchina/module/salesExe/models/order_model.dart';
import 'package:kutchina/module/salesExe/models/product_model.dart';
import 'package:kutchina/module/salesExe/models/visit_model.dart';
import 'package:dio/dio.dart';

class Distributor {
  final String id;
  final String name;
  Distributor({required this.id, required this.name});

  factory Distributor.fromJson(Map<String, dynamic> json) {
    return Distributor(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString().trim() ?? '',
    );
  }
}

class Retailer {
  final String id;
  final String name;
  Retailer({required this.id, required this.name});

  factory Retailer.fromJson(Map<String, dynamic> json) {
    return Retailer(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString().trim() ?? '',
    );
  }
}

class Category {
  final String id;
  final String name;
  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString().trim() ?? '',
    );
  }
}

class Channel {
  final String id;
  final String name;
  Channel({required this.id, required this.name});

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString().trim() ?? '',
    );
  }
}

class CheckInService {
  /// GET current attendance status. Returns true if user is already
  /// checked in for the day (`is_logged_in: true`).
  static Future<bool> getStatus() async {
    try {
      final response = await ApiService.instance.get(
        '/api/v1/users/attendance/check-in/',
      );

      if (response.statusCode == 200) {
        final body = response.data; // already a Map, no jsonDecode needed
        final attendance = body['data'];

        if (attendance != null && attendance['is_checked_in'] == true) {
          return true;
        }
        return false;
      }

      // If the API errors out, fail safe and force the check-in gate
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> checkIn({
    required String locationName,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await ApiService.instance.post(
        '/api/v1/users/attendance/check-in/',
        data: {
          "location_name": locationName,
          "latitude": latitude,
          "longitude": longitude,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}

class MastersApi {
  MastersApi._();
  static Future<List<Distributor>> fetchDistributors() async {
    final res = await ApiService.instance.get('/api/v1/masters/distributors/');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map ? raw['data'] as List? ?? [] : []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(Distributor.fromJson)
        .toList();
  }

  static Future<List<Retailer>> fetchRetailers() async {
    final res = await ApiService.instance.get('/api/v1/masters/retailers/');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map ? raw['data'] as List? ?? [] : []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(Retailer.fromJson)
        .toList();
  }

  static Future<List<Category>> fetchCategories() async {
    final res = await ApiService.instance.get('/api/v1/masters/categories/');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map ? raw['data'] as List? ?? [] : []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(Category.fromJson)
        .toList();
  }

  static Future<List<Channel>> fetchChannels() async {
    final res = await ApiService.instance.get('/api/v1/masters/channels/');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map ? raw['data'] as List? ?? [] : []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(Channel.fromJson)
        .toList();
  }

  static Future<List<Product>> fetchProducts() async {
    final res = await ApiService.instance.get('/api/v1/masters/products/');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map ? raw['data'] as List? ?? [] : []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }
}

class OrderService {
  OrderService._();

  static Future<MonthlyTarget> fetchCurrentTarget({
    required String userId,
  }) async {
    final res = await ApiService.instance.get(
      '/api/v1/orders/target/',
      data: {'user_id': int.tryParse(userId) ?? userId},
    );
    final data = res.data is Map ? res.data['data'] : null;
    if (data is! Map) {
      throw ApiException('Monthly target was not found');
    }

    return MonthlyTarget(
      amount: double.tryParse(data['target']?.toString() ?? '') ?? 0,
      month: DateTime.tryParse(data['month']?.toString() ?? ''),
      targetDate: DateTime.tryParse(data['target_date']?.toString() ?? ''),
    );
  }

  static Future<void> placeOrder({
    required String orderType,
    required String entityName,
    required String entityId,
    required Product product,
    required int qty,
    required String price,
    String? filter,
    String? warranty,
  }) async {
    final position = await LocationService.getCurrentLocation();

    final payload = {
      'user_type': orderType,
      'product_id': product.id,
      'quantity': qty,
      'price': price,
      'filter_type': filter,
      'warranty': warranty,
      'lat': position.latitude.toString(),
      'long': position.longitude.toString(),
      'order_for': entityId,
    };

    await ApiService.instance.post('/api/v1/orders/place/', data: payload);
  }

  static Future<List<OrderEntry>> fetchOrders() async {
    final res = await ApiService.instance.get('/api/v1/orders/place/');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map
              ? raw['data'] as List? ?? raw['results'] as List? ?? []
              : []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(OrderEntry.fromJson)
        .toList();
  }
}

class MonthlyTarget {
  final double amount;
  final DateTime? month;
  final DateTime? targetDate;

  const MonthlyTarget({
    required this.amount,
    required this.month,
    required this.targetDate,
  });
}

class VisitService {
  static Future<void> checkIn({required Map<String, dynamic> payload}) async {
    final formData = FormData.fromMap(payload);
    await ApiService.instance.post('/api/v1/orders/visits/', data: formData);
  }

  static Future<List<VisitEntry>> fetchTodayVisits({
    required String date,
  }) async {
    String currentDate = date;
    String dataParam = "?created_at=";
    dataParam = dataParam + currentDate;
    final res = await ApiService.instance.get(
      '/api/v1/orders/visits/$dataParam',
    );
    final raw = res.data;

    final list = raw is List
        ? raw
        : (raw is Map
              ? raw['data'] as List? ?? raw['results'] as List? ?? []
              : []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(VisitEntry.fromJson)
        .toList();
  }
}
