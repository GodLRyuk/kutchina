import 'dart:convert';

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

class Zone {
  final String id;
  final String name;
  final bool isActive;
  Zone({required this.id, required this.name, required this.isActive});

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString().trim() ?? '',
      // Treat a missing flag as active.
      isActive: json['is_active'] == null ? true : json['is_active'] == true,
    );
  }
}

class AdminUser {
  final String id;
  final String userId;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String locationId;
  final String zoneId;
  final String roleId;
  final bool isActive;
  final bool isStaff;
  final bool isSuperuser;

  AdminUser({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.locationId,
    required this.zoneId,
    required this.roleId,
    required this.isActive,
    required this.isStaff,
    required this.isSuperuser,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    String s(String key) => json[key]?.toString().trim() ?? '';

    return AdminUser(
      id: s('id'),
      userId: s('userid'),
      firstName: s('first_name'),
      middleName: s('middle_name'),
      lastName: s('last_name'),
      email: s('email'),
      phone: s('phone'),
      address: s('address'),
      locationId: s('location_id'),
      zoneId: s('zone_id'),
      roleId: s('role_id'),
      // Treat a missing flag as active.
      isActive: json['is_active'] == null ? true : json['is_active'] == true,
      isStaff: json['is_staff'] == true,
      isSuperuser: json['is_superuser'] == true,
    );
  }

  /// "First Middle Last" without double spaces when middle name is empty.
  String get fullName =>
      [firstName, middleName, lastName].where((p) => p.isNotEmpty).join(' ');

  /// Up to two letters: first letter of first + last name.
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    final result = '$f$l'.toUpperCase();
    if (result.isNotEmpty) return result;
    return userId.isNotEmpty ? userId[0].toUpperCase() : '?';
  }
}

double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

class SalesOrder {
  final String id;
  final String orderNumber;
  final String productId;
  final String productName;
  final double quantity;
  final double price;
  final String userType; // 'R' retailer, 'D' distributor
  final String orderFor;
  final String filterType;
  final String warranty;
  final String status;
  final String createdBy; // id of the user who placed the order
  final DateTime? createdAt;

  SalesOrder({
    required this.id,
    required this.orderNumber,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.userType,
    required this.orderFor,
    required this.filterType,
    required this.warranty,
    required this.status,
    required this.createdBy,
    required this.createdAt,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    String s(String key) => json[key]?.toString().trim() ?? '';

    return SalesOrder(
      id: s('id'),
      orderNumber: s('order_number'),
      productId: s('product_id'),
      productName: s('product_name'),
      quantity: _toDouble(json['quantity']),
      price: _toDouble(json['price']),
      userType: s('user_type'),
      orderFor: s('order_for'),
      filterType: s('filter_type'),
      warranty: s('warranty'),
      status: s('order_status_display'),
      createdBy: s('created_by'),
      createdAt: DateTime.tryParse(s('created_at')),
    );
  }

  /// Price is per unit (matches product price), so total = price x qty.
  double get total => price * quantity;
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

  static Future<List<Zone>> fetchZones() async {
    final res = await ApiService.instance.get('/api/v1/masters/zones/');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map ? raw['data'] as List? ?? [] : []);

    return list.whereType<Map<String, dynamic>>().map(Zone.fromJson).toList();
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

class AdminUsersApi {
  AdminUsersApi._();

  static Future<List<AdminUser>> fetchUsers() async {
    final res = await ApiService.instance.get(
      '/api/v1/users/superadmin/userlist/',
    );
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map
              ? raw['data'] as List? ?? raw['results'] as List? ?? []
              : []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(AdminUser.fromJson)
        .toList();
  }
}

class SalesProduct {
  final String id;
  final String name;
  final double price;
  final int category;
  final String warranty;
  final bool isActive;

  SalesProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.warranty,
    required this.isActive,
  });

  factory SalesProduct.fromJson(Map<String, dynamic> json) {
    return SalesProduct(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString().trim() ?? '',
      price: _toDouble(json['price']),
      category: int.tryParse(json['category']?.toString() ?? '') ?? 0,
      warranty: json['warranty']?.toString().trim() ?? '',
      isActive: json['is_active'] == null ? true : json['is_active'] == true,
    );
  }
}

class SalespersonSales {
  final List<SalesOrder> orders;
  final int ordersCount;
  final bool hasMoreOrders;
  final List<SalesProduct> products;
  final int productsCount;

  SalespersonSales({
    required this.orders,
    required this.ordersCount,
    required this.hasMoreOrders,
    required this.products,
    required this.productsCount,
  });
}

class SalespersonSalesApi {
  SalespersonSalesApi._();

  /// GET /api/v1/orders/salespersons/{userId}/sales/?page=1&page_size=10
  ///
  /// Orders are paginated with `sales_page` (see the `next` link in the
  /// response). Pass [salesPage] > 1 to load more orders.
  static Future<SalespersonSales> fetch({
    required String userId,
    int page = 1,
    int pageSize = 10,
    int salesPage = 1,
  }) async {
    final res = await ApiService.instance.get(
      '/api/v1/orders/salespersons/$userId/sales/',
      queryParams: {
        'page': page,
        'page_size': pageSize,
        if (salesPage > 1) 'sales_page': salesPage,
      },
    );

    final raw = res.data;
    final body = raw is Map ? (raw['data'] is Map ? raw['data'] : raw) : {};
    final sales = body['sales'] is Map ? body['sales'] as Map : const {};
    final products = body['products'] is Map
        ? body['products'] as Map
        : const {};

    List<T> parse<T>(Map section, T Function(Map<String, dynamic>) fromJson) {
      final results = section['results'];
      if (results is! List) return <T>[];
      return results.whereType<Map<String, dynamic>>().map(fromJson).toList();
    }

    final orders = parse<SalesOrder>(sales, SalesOrder.fromJson);
    final prods = parse<SalesProduct>(products, SalesProduct.fromJson);

    return SalespersonSales(
      orders: orders,
      ordersCount:
          int.tryParse(sales['count']?.toString() ?? '') ?? orders.length,
      hasMoreOrders: sales['next'] != null,
      products: prods,
      productsCount:
          int.tryParse(products['count']?.toString() ?? '') ?? prods.length,
    );
  }
}

class CategoryOrdersPage {
  final List<SalesOrder> orders;
  final int count;
  final bool hasMore;

  CategoryOrdersPage({
    required this.orders,
    required this.count,
    required this.hasMore,
  });
}

class CategoryOrdersApi {
  CategoryOrdersApi._();

  /// GET /api/v1/masters/categories/{categoryId}/products/?page=1&page_size=10
  ///
  /// Despite the "products" in the path, each result is an order for a
  /// product in that category. Paginated with `page` / `page_size`.
  static Future<CategoryOrdersPage> fetch({
    required String categoryId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final res = await ApiService.instance.get(
      '/api/v1/masters/categories/$categoryId/products/',
      queryParams: {'page': page, 'page_size': pageSize},
    );

    final raw = res.data;
    final Map body = raw is Map
        ? (raw['data'] is Map ? raw['data'] as Map : raw)
        : const {};
    final results = raw is List
        ? raw
        : (body['results'] is List ? body['results'] as List : const []);

    final orders = results
        .whereType<Map<String, dynamic>>()
        .map(SalesOrder.fromJson)
        .toList();

    return CategoryOrdersPage(
      orders: orders,
      count: int.tryParse(body['count']?.toString() ?? '') ?? orders.length,
      hasMore: body['next'] != null,
    );
  }
}

class RegionOrdersPage {
  final String regionName;
  final List<SalesOrder> orders;
  final int count;
  final bool hasMore;

  RegionOrdersPage({
    required this.regionName,
    required this.orders,
    required this.count,
    required this.hasMore,
  });
}

class RegionOrdersApi {
  RegionOrdersApi._();

  /// GET /api/v1/orders/regions/{regionId}/sales/?page=1&page_size=10
  ///
  /// Response: `{region: {id, name}, count, next, previous, results: [orders]}`.
  /// Paginated with `page` / `page_size`. Reuses the [SalesOrder] model.
  ///
  /// Also accepts the same body wrapped in `data`. In debug builds it prints
  /// `[RegionSales]` lines with the URL, status and parsed item count.
  static Future<RegionOrdersPage> fetch({
    required String regionId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final res = await ApiService.instance.get(
      '/api/v1/orders/regions/$regionId/sales/',
      queryParams: {'page': page, 'page_size': pageSize},
    );

    dynamic raw = res.data;
    // Some servers send JSON with a text content-type; decode it ourselves.
    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {}
    }

    dynamic node = raw;
    if (node is Map && node['data'] is Map) node = node['data'];

    final Map meta = node is Map ? node : const {};
    final dynamic rawList = node is List ? node : meta['results'];
    final List list = rawList is List ? rawList : const [];

    final orders = <SalesOrder>[];
    for (final item in list) {
      if (item is! Map) continue;
      try {
        orders.add(SalesOrder.fromJson(Map<String, dynamic>.from(item)));
      } catch (e) {}
    }

    final region = meta['region'];
    final regionName = region is Map
        ? region['name']?.toString().trim() ?? ''
        : '';

    return RegionOrdersPage(
      regionName: regionName,
      orders: orders,
      count: int.tryParse(meta['count']?.toString() ?? '') ?? orders.length,
      hasMore: meta['next'] != null,
    );
  }
}
