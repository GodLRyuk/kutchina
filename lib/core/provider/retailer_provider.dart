import 'package:flutter/foundation.dart';
import 'package:kutchina/core/network/masters_api.dart';

enum RetailerLoadState { idle, loading, loaded, error }

class RetailerProvider extends ChangeNotifier {
  RetailerLoadState _state = RetailerLoadState.idle;
  List<Retailer> _retailers = [];
  String? _error;

  RetailerLoadState get state => _state;
  List<Retailer> get retailers => _retailers;
  List<String> get names => _retailers.map((r) => r.name).toList();
  String? get error => _error;
  bool get isLoading => _state == RetailerLoadState.loading;

  Future<void> fetch({bool force = false}) async {
    if (_state == RetailerLoadState.loaded && !force) return;
    _state = RetailerLoadState.loading;
    _error = null;
    notifyListeners();

    try {
      _retailers = await MastersApi.fetchRetailers();
      _state = RetailerLoadState.loaded;
    } catch (e) {
      _error = 'Could not load retailers';
      _state = RetailerLoadState.error;
    }
    notifyListeners();
  }
}
