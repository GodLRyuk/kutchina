class OrderEntry {
  final int id;
  final String orderNumber;
  final int productId;
  final String productName;
  final double quantity;
  final double? lat;
  final double? long;
  final String userType; // 'D' or 'R'
  final String? filterType;
  final String? warranty;
  final double? price;
  final String orderStatus;
  final DateTime? createdAt;

  OrderEntry({
    required this.id,
    required this.orderNumber,
    required this.productId,
    required this.productName,
    required this.quantity,
    this.lat,
    this.long,
    required this.userType,
    this.filterType,
    this.warranty,
    this.price,
    required this.orderStatus,
    this.createdAt,
  });

  String get orderTypeLabel => userType == 'D' ? 'Distributor' : 'Retailer';

  double get total => (price ?? 0);

  factory OrderEntry.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    String? nonEmpty(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    final product = json['product'] is Map
        ? Map<String, dynamic>.from(json['product'] as Map)
        : const <String, dynamic>{};

    return OrderEntry(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      orderNumber: json['order_number']?.toString() ?? '',
      productId:
          int.tryParse(
            (json['product_id'] ?? product['id'])?.toString() ?? '',
          ) ??
          0,
      productName:
          json['product_name']?.toString() ?? product['name']?.toString() ?? '',
      quantity: toDouble(json['quantity']) ?? 0,
      lat: toDouble(json['lat']),
      long: toDouble(json['long']),
      userType: json['user_type']?.toString() ?? '',
      filterType: nonEmpty(json['filter_type']),
      warranty: nonEmpty(json['warranty']),
      price: toDouble(
        json['total_price'] ?? json['total_amount'] ?? json['price'],
      ),
      orderStatus: json['order_status_display']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
