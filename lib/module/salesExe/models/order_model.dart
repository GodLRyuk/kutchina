class OrderEntry {
  final String id;
  final String productId;
  final String productName;
  final double quantity;
  final String userType; // 'D' = Distributor, 'R' = Retailer
  final String filterType;
  final String warranty;
  final double? price; // nullable — API sends null sometimes (see id:1 above)
  final String createdBy;
  final bool isActive;
  final DateTime? createdAt;

  const OrderEntry({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.userType,
    required this.filterType,
    required this.warranty,
    this.price,
    required this.createdBy,
    required this.isActive,
    this.createdAt,
  });

  double get total => (price ?? 0) * quantity;
  String get orderTypeLabel => userType == 'D' ? 'Distributor' : 'Retailer';

  factory OrderEntry.fromJson(Map<String, dynamic> json) {
    return OrderEntry(
      id: (json['id'] ?? '').toString(),
      productId: (json['product_id'] ?? '').toString(),
      productName: json['product_name']?.toString().trim() ?? '',
      quantity: double.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      userType: json['user_type']?.toString() ?? '',
      filterType: json['filter_type']?.toString() ?? '',
      warranty: json['warranty']?.toString() ?? '',
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      createdBy: (json['created_by'] ?? '').toString(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}
