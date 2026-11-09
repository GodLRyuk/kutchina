import 'package:kutchina/core/network/masters_api.dart';

class CategoryModel {
  static List<String> categories = [];
  static Map<String, String> _categoryNamesById = {};

  static Future<void> loadCategories() async {
    final list = await MastersApi.fetchCategories();
    categories = list.map((c) => c.name).toList();
    _categoryNamesById = {
      for (final category in list) category.id: category.name,
    };
  }

  static String? idForName(String name) {
    for (final entry in _categoryNamesById.entries) {
      if (entry.value == name) return entry.key;
    }
    return null;
  }
}
