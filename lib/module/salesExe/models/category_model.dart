import 'package:kutchina/core/network/masters_api.dart';

class CategoryModel {
  static List<String> categories = [];
  static Future<void> loadCategories() async {
    final list = await MastersApi.fetchCategories();
    categories = list.map((c) => c.name).toList();
  }
}
