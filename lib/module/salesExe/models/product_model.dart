import 'package:kutchina/core/network/masters_api.dart';

class ProductColor {
  final String id;
  final String name;
  ProductColor({required this.id, required this.name});

  factory ProductColor.fromJson(Map<String, dynamic> json) {
    return ProductColor(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString().trim() ?? '',
    );
  }
}

class Product {
  final String id;
  final String name;
  final Category
  category; // reuses Category from masters_api.dart — no duplicate model
  final ProductColor? color;
  final double price;
  final String filterType;
  final String warranty;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    this.color,
    required this.price,
    this.filterType = '',
    this.warranty = '',
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString().trim() ?? '',
      category: Category.fromJson(json['category'] ?? {}),
      color: json['color'] != null
          ? ProductColor.fromJson(json['color'])
          : null,
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      filterType: json['filter_type']?.toString() ?? '',
      warranty: json['warranty']?.toString() ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  static List<Product> catalog = [];
  static bool _loaded = false;

  static Future<void> loadCatalog({bool force = false}) async {
    if (_loaded && !force) return;
    catalog = await MastersApi.fetchProducts();
    _loaded = true;
  }
}

class CategoryModel {
  static List<String> categories = [];
  static Future<void> loadCategories() async {
    final list = await MastersApi.fetchCategories();
    categories = list.map((c) => c.name).toList();
  }
}
