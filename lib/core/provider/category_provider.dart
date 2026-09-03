import 'package:flutter/foundation.dart' hide Category;
import 'package:kutchina/core/network/masters_api.dart';

enum CategoryLoadState { idle, loading, loaded, error }

class CategoryProvider extends ChangeNotifier {
  CategoryLoadState _state = CategoryLoadState.idle;
  List<Category> _categories = [];
  String? _error;

  CategoryLoadState get state => _state;
  List<Category> get categories => _categories;
  String? get error => _error;
  bool get isLoading => _state == CategoryLoadState.loading;

  Future<void> fetch({bool force = false}) async {
    if (_state == CategoryLoadState.loaded && !force) return;
    _state = CategoryLoadState.loading;
    _error = null;
    notifyListeners();

    try {
      _categories = await MastersApi.fetchCategories();
      _state = CategoryLoadState.loaded;
    } catch (e) {
      _error = 'Could not load categories';
      _state = CategoryLoadState.error;
    }
    notifyListeners();
  }
}
