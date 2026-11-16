class OrdersModel {
  final int id;
  final String orderNumber;
  final int productId;
  final String productName;
  final double quantity;
  final double? lat;
  final double? long;
  final String? filterType;
  final String? warranty;
  final double? price;
  final String orderStatus;
  final String createdBy;
  final DateTime? createdAt;

  OrdersModel({
    required this.id,
    required this.orderNumber,
    required this.productId,
    required this.productName,
    required this.quantity,
    this.lat,
    this.long,
    this.filterType,
    this.warranty,
    this.price,
    required this.orderStatus,
    this.createdBy = '',
    this.createdAt,
  });


  double get total => (price ?? 0);

  static OrdersModel fromJson(Map<String, dynamic> json) {
    return OrdersModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      orderNumber: json['order_number']?.toString() ?? '',
      productId: int.tryParse(json['product_id']?.toString() ?? '') ?? 0,
      productName: json['product_name']?.toString() ?? '',
      quantity: double.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      lat: double.tryParse(json['lat']?.toString() ?? ''),
      long: double.tryParse(json['long']?.toString() ?? ''),
      filterType: json['filter_type']?.toString(),
      warranty: json['warranty']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? ''),
      orderStatus: json['order_status']?.toString() ?? '',
      createdBy: json['created_by']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}