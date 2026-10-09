import 'dart:convert';
import 'package:kutchina/core/offline/connectivity_service.dart';
import 'package:kutchina/core/offline/offline_store.dart';
import 'package:kutchina/core/offline/sync_service.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/services/location_service.dart';
import 'package:kutchina/module/salesExe/models/order_model.dart';
import 'package:kutchina/module/salesExe/models/product_model.dart';
import 'package:kutchina/module/salesExe/models/visit_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kutchina/core/services/location_address_service.dart';

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
  static const _kCheckedInDay = 'attendance_checked_in_day';

  static String _today() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  /// Remembered per user + day so the "Check-in required" gate still
  /// works with no network (server value wins whenever it is reachable).
  static String get _dayValue =>
      '${OfflineStore.userScope ?? 'anon'}|${_today()}';

  static Future<void> _rememberCheckedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCheckedInDay, _dayValue);
    } catch (_) {}
  }

  static Future<bool> _checkedInLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kCheckedInDay) == _dayValue;
    } catch (_) {
      return false;
    }
  }

  /// GET current attendance status. Returns true if user is already
  /// checked in for the day (`is_logged_in: true`).
  static Future<bool> getStatus() async {
    // Offline: trust what this phone already knows about today.
    if (!ConnectivityService.instance.isOnline) {
      return _checkedInLocally();
    }
    try {
      final response = await ApiService.instance.get(
        '/api/v1/users/attendance/check-in/',
      );

      if (response.statusCode == 200) {
        final body = response.data; // already a Map, no jsonDecode needed
        final attendance = body['data'];

        if (attendance != null && attendance['is_checked_in'] == true) {
          await _rememberCheckedIn();
          return true;
        }
        return false;
      }

      // If the API errors out, fail safe and force the check-in gate
      return false;
    } on ApiException catch (e) {
      // Connection dropped mid-call: fall back to the local record.
      if (e.isNetworkError) return _checkedInLocally();
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Returns true when the check-in was accepted by the server OR saved
  /// on the phone to be sent when the network returns.
  static Future<bool> checkIn({
    required String locationName,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await SyncService.instance.submitOrQueue(
        kind: 'attendance',
        label: 'Attendance check-in',
        path: '/api/v1/users/attendance/check-in/',
        body: {
          "location_name": locationName,
          "latitude": latitude,
          "longitude": longitude,
        },
      );
      await _rememberCheckedIn();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class MastersApi {
  MastersApi._();
  static Future<List<Distributor>> fetchDistributors() async {
    final res = await ApiService.instance.getCached(
      '/api/v1/masters/distributors/',
    );
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
    final res = await ApiService.instance.getCached(
      '/api/v1/masters/retailers/',
    );
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
    final res = await ApiService.instance.getCached(
      '/api/v1/masters/categories/',
    );
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
    final res = await ApiService.instance.getCached(
      '/api/v1/masters/channels/',
    );
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
    final res = await ApiService.instance.getCached('/api/v1/masters/zones/');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map ? raw['data'] as List? ?? [] : []);

    return list.whereType<Map<String, dynamic>>().map(Zone.fromJson).toList();
  }

  static Future<List<Product>> fetchProducts() async {
    final res = await ApiService.instance.getCached(
      '/api/v1/masters/products/',
    );
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map ? raw['data'] as List? ?? [] : []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  static Future<List<SuggestionModel>> fetchSuggestions(String search) async {
    final res = await ApiService.instance.getCached(
      '/api/v1/orders/visits/purpose-suggestions/?text=$search',
    );
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map ? raw['data'] as List? ?? [] : []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(SuggestionModel.fromJson)
        .toList();
  }
}

class OrderService {
  OrderService._();

  static Future<MonthlyTarget> fetchCurrentTarget({
    required String userId,
  }) async {
    final res = await ApiService.instance.getCached(
      '/api/v1/orders/target/',
      queryParams: {'user_id': int.tryParse(userId) ?? userId},
    );
    final raw = res.data;
    final responseData = raw is Map ? raw['data'] ?? raw : raw;
    final targetRows = responseData is List
        ? responseData
        : responseData is Map
        ? responseData['results'] as List? ??
              responseData['targets'] as List? ??
              [responseData]
        : <dynamic>[];
    final targets = targetRows.whereType<Map>().map(
      (target) => Map<String, dynamic>.from(target),
    );
    final now = DateTime.now();
    Map<String, dynamic>? currentTarget;
    for (final target in targets) {
      final month = DateTime.tryParse(
        (target['month'] ?? target['target_month'])?.toString() ?? '',
      );
      if (month != null && month.year == now.year && month.month == now.month) {
        currentTarget = target;
        break;
      }
    }

    if (currentTarget == null) {
      throw ApiException('Monthly target was not found');
    }

    return MonthlyTarget(
      amount:
          double.tryParse(
            (currentTarget['target_value'] ?? currentTarget['target'])
                    ?.toString() ??
                '',
          ) ??
          0,
      month: DateTime.tryParse(
        (currentTarget['month'] ?? currentTarget['target_month'])?.toString() ??
            '',
      ),
      targetDate: DateTime.tryParse(
        (currentTarget['target_date'] ?? currentTarget['end_date'])
                ?.toString() ??
            '',
      ),
    );
  }

  // static Future<void> placeOrder({
  //   required String orderType,
  //   required String entityName,
  //   required String entityId,
  //   required Product product,
  //   required int qty,
  //   required String price,
  //   String? filter,
  //   String? warranty,
  // }) async {
  //   final position = await LocationService.getCurrentLocation();

  //   final payload = {
  //     'user_type': orderType,
  //     'product_id': product.id,
  //     'quantity': qty,
  //     'price': price,
  //     'filter_type': filter,
  //     'warranty': warranty,
  //     'lat': position.latitude.toString(),
  //     'long': position.longitude.toString(),
  //     'order_for': entityId,
  //   };

  //   await ApiService.instance.post('/api/v1/orders/place/', data: payload);
  // }

  // Add 29-9-2026

  /// Returns [SubmitResult.sent] when the server accepted the order, or
  /// [SubmitResult.queued] when there is no network and it was saved on
  /// the phone to be sent automatically later.
  static Future<SubmitResult> placeOrder({
    required String orderType,
    required String entityId,
    required List<Map<String, dynamic>> items,
  }) async {
    // GPS works without internet, so the order still carries its location.
    final position = await LocationService.getCurrentLocation();

    final payload = items.map((item) {
      final Product p = item['product'];
      final int qty = item['qty'];
      return {
        'user_type': orderType,
        'product_id': p.id,
        'quantity': qty,
        'price': (p.price * qty).toStringAsFixed(2),
        'filter_type': p.filterType,
        'warranty': p.warranty,
        'lat': position.latitude.toString(),
        'long': position.longitude.toString(),
        'order_for': entityId,
      };
    }).toList();

    return SyncService.instance.submitOrQueue(
      kind: 'order',
      label: 'Order: ${items.length} product${items.length == 1 ? '' : 's'}',
      path: '/api/v1/orders/place/',
      body: payload,
    );
  }

  static Future<List<OrderEntry>> fetchOrders() async {
    final res = await ApiService.instance.getCached('/api/v1/orders/place/');

    final raw = res.data;

    // final serverList = raw is List
    //     ? raw
    //     : (raw is Map
    //           ? raw['data'] as List? ?? raw['results'] as List? ?? []
    //           : []);

    final serverList = raw is List
        ? raw
        : (raw is Map
              ? (raw['orders'] ?? raw['data'] ?? raw['results']) as List? ?? []
              : []);
    final orders = <OrderEntry>[];

    for (final value in serverList) {
      if (value is Map) {
        try {
          orders.add(OrderEntry.fromJson(Map<String, dynamic>.from(value)));
        } catch (_) {}
      }
    }

    final queued = await SyncService.instance.listAll();

    for (final request in queued.where(
      (r) =>
          r.kind == 'order' && (r.status == 'pending' || r.status == 'failed'),
    )) {
      final body = request.body;
      if (body is! List) continue;

      for (final value in body) {
        if (value is! Map) continue;

        final item = Map<String, dynamic>.from(value);
        final productId =
            int.tryParse(item['product_id']?.toString() ?? '') ?? 0;

        final quantity =
            double.tryParse(item['quantity']?.toString() ?? '') ?? 0;

        final price = double.tryParse(item['price']?.toString() ?? '');

        orders.add(
          OrderEntry(
            id: -request.id,
            orderNumber: 'OFFLINE-${request.clientId.substring(0, 8)}',
            productId: productId,
            productName:
                item['product_name']?.toString() ?? 'Product #$productId',
            quantity: quantity,
            lat: double.tryParse(item['lat']?.toString() ?? ''),
            long: double.tryParse(item['long']?.toString() ?? ''),
            userType: item['user_type']?.toString() ?? '',
            filterType: item['filter_type']?.toString(),
            warranty: item['warranty']?.toString(),
            price: price,
            orderStatus: request.status == 'failed'
                ? 'Sync Failed'
                : 'Pending Sync',
            createdAt: request.createdAt,
          ),
        );
      }
    }

    // Latest records first.
    orders.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    return orders;
  }

  //  static Future<List<OrderEntry>> searchOrders(String search) async {
  //   final query = search.trim();
  //   if (query.isEmpty) return [];

  //   final res =
  //       await ApiService.instance.getCached('/api/v1/orders/place/$query');
  //   final raw = res.data;
  //   final list = raw is Map ? (raw['orders'] as List? ?? []) : [];

  //   // product_id -> name (the search endpoint doesn't send names)
  //   final names = <String, String>{};
  //   try {
  //     final products = await MastersApi.fetchProducts();
  //     for (final p in products) {
  //       names[p.id.toString()] = p.name;
  //     }
  //   } catch (_) {}

  //   final orders = <OrderEntry>[];
  //   for (final value in list) {
  //     if (value is! Map) continue;
  //     try {
  //       final row = Map<String, dynamic>.from(value);
  //       final pid = row['product_id']?.toString() ?? '';

  //       if ((row['product_name']?.toString() ?? '').isEmpty) {
  //         row['product_name'] = names[pid] ?? 'Product #$pid';
  //       }

  //       orders.add(OrderEntry.fromJson(row));
  //     } catch (e) {
  //       print('Failed to parse order row: $e\nrow: $value');
  //     }
  //   }
  //   return orders;
  // }

  static Future<List<OrderEntry>> searchOrders(
    String search, {
    String? entityId,
    String? entityType, // 'R' or 'D'
  }) async {
    final query = search.trim();
    print(
      "searchOrders: query=$query, entityId=$entityId, entityType=$entityType",
    );
    if (query.isEmpty && entityId == null) return [];

    final res = entityId == null
        ? await ApiService.instance.getCached('/api/v1/orders/place/$query/')
        : await ApiService.instance.getCached(
            '/api/v1/orders/place/',
            queryParams: {
              if (entityType != null) 'user_type': entityType,
              'order_for': entityId,
              if (query.isNotEmpty) 'order_number': query,
            },
          );
    print("searchOrders: res.data=${res.data}");

    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map
              ? (raw['orders'] ?? raw['data'] ?? raw['results']) as List? ?? []
              : []);

    // product_id -> name (the search endpoint doesn't send names)
    final names = <String, String>{};
    try {
      final products = await MastersApi.fetchProducts();
      for (final p in products) {
        names[p.id.toString()] = p.name;
      }
    } catch (_) {}

    final orders = <OrderEntry>[];
    for (final value in list) {
      if (value is! Map) continue;
      try {
        final row = Map<String, dynamic>.from(value);
        final pid = row['product_id']?.toString() ?? '';

        if ((row['product_name']?.toString() ?? '').isEmpty) {
          row['product_name'] = names[pid] ?? 'Product #$pid';
        }

        orders.add(OrderEntry.fromJson(row));
      } catch (e) {
        print('Failed to parse order row: $e\nrow: $value');
      }
    }
    return orders;
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
  /// [payload] holds plain text fields only. Photos are passed as file
  /// paths so they can be copied to app storage and uploaded later if the
  /// phone is offline.
  static Future<SubmitResult> checkIn({
    required Map<String, dynamic> payload,
    List<String> imagePaths = const [],
  }) {
    final who = payload['visitor_name']?.toString().trim() ?? '';
    return SyncService.instance.submitOrQueue(
      kind: 'visit',
      label: who.isEmpty ? 'Visit check-in' : 'Visit: $who',
      path: '/api/v1/orders/visits/',
      body: payload,
      filePaths: imagePaths,
      fileField: 'image',
    );
  }

  static Future<List<VisitEntry>> fetchTodayVisits({
    required String date,
  }) async {
    final res = await ApiService.instance.getCached('/api/v1/orders/visits/');

    final raw = res.data;
    final serverList = raw is List
        ? raw
        : (raw is Map
              ? raw['data'] as List? ?? raw['results'] as List? ?? []
              : []);

    final visits = <VisitEntry>[];

    for (final value in serverList) {
      if (value is Map) {
        visits.add(VisitEntry.fromJson(Map<String, dynamic>.from(value)));
      }
    }

    final queued = await SyncService.instance.listAll();

    for (final request in queued.where(
      (r) =>
          r.kind == 'visit' && (r.status == 'pending' || r.status == 'failed'),
    )) {
      final body = request.body;

      if (body is! Map) continue;

      final created = request.createdAt;
      final localDate =
          '${created.year.toString().padLeft(4, '0')}-'
          '${created.month.toString().padLeft(2, '0')}-'
          '${created.day.toString().padLeft(2, '0')}';

      if (localDate != date) continue;

      final item = Map<String, dynamic>.from(body);

      final lat = item['lat']?.toString() ?? '';
      final long = item['long']?.toString() ?? '';

      final address = item['address']?.toString().trim() ?? '';

      visits.add(
        VisitEntry(
          id: 'offline-${request.id}',
          visitorName: item['visitor_name']?.toString() ?? 'Offline visit',
          address: address.isNotEmpty
              ? address
              : (lat.isNotEmpty && long.isNotEmpty
                    ? '$lat, $long'
                    : 'Address unavailable'),
          purpose: item['visit_purpose']?.toString() ?? '',
          visitType: item['visit_type']?.toString() ?? '',
          note: item['note']?.toString(),
          createdAt: created,
          isPendingSync: request.status == 'pending',
          syncFailed: request.status == 'failed',
        ),
      );
    }

    visits.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    return visits;
  }

  static Future<List<VisitEntry>> fetchAllVisits({required String date}) async {
    final res = await ApiService.instance.getCached(
      '/api/v1/orders/visits/',
      queryParams: {'created_at': date},
    );

    final raw = res.data;
    final serverList = raw is List
        ? raw
        : (raw is Map
              ? raw['data'] as List? ?? raw['results'] as List? ?? []
              : []);

    final visits = <VisitEntry>[];

    for (final value in serverList) {
      if (value is Map) {
        visits.add(VisitEntry.fromJson(Map<String, dynamic>.from(value)));
      }
    }

    final queued = await SyncService.instance.listAll();

    for (final request in queued.where(
      (r) =>
          r.kind == 'visit' && (r.status == 'pending' || r.status == 'failed'),
    )) {
      final body = request.body;

      if (body is! Map) continue;

      final created = request.createdAt;
      final localDate =
          '${created.year.toString().padLeft(4, '0')}-'
          '${created.month.toString().padLeft(2, '0')}-'
          '${created.day.toString().padLeft(2, '0')}';

      if (localDate != date) continue;

      final item = Map<String, dynamic>.from(body);

      final lat = item['lat']?.toString() ?? '';
      final long = item['long']?.toString() ?? '';

      final address = item['address']?.toString().trim() ?? '';

      visits.add(
        VisitEntry(
          id: 'offline-${request.id}',
          visitorName: item['visitor_name']?.toString() ?? 'Offline visit',
          address: address.isNotEmpty
              ? address
              : (lat.isNotEmpty && long.isNotEmpty
                    ? '$lat, $long'
                    : 'Address unavailable'),
          purpose: item['visit_purpose']?.toString() ?? '',
          visitType: item['visit_type']?.toString() ?? '',
          note: item['note']?.toString(),
          createdAt: created,
          isPendingSync: request.status == 'pending',
          syncFailed: request.status == 'failed',
        ),
      );
    }

    visits.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    return visits;
  }
}

class AdminUsersApi {
  AdminUsersApi._();

  static Future<List<AdminUser>> fetchUsers() async {
    final res = await ApiService.instance.getCached(
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
    final res = await ApiService.instance.getCached(
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
    final res = await ApiService.instance.getCached(
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
    final res = await ApiService.instance.getCached(
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
