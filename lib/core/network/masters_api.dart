import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/module/salesExe/models/product_model.dart';

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
