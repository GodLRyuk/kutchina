import 'package:flutter/foundation.dart';
import 'package:kutchina/core/network/masters_api.dart';

enum DistributorLoadState { idle, loading, loaded, error }

class DistributorProvider extends ChangeNotifier {
  DistributorLoadState _state = DistributorLoadState.idle;
  List<Distributor> _distributors = [];
  String? _error;

  DistributorLoadState get state => _state;
  List<Distributor> get distributors => _distributors;
  List<String> get names => _distributors.map((d) => d.name).toList();
  String? get error => _error;
  bool get isLoading => _state == DistributorLoadState.loading;

  Future<void> fetch({bool force = false}) async {
    if (_state == DistributorLoadState.loaded && !force) return;
    _state = DistributorLoadState.loading;
    _error = null;
    notifyListeners();

    try {
      _distributors = await MastersApi.fetchDistributors();
      _state = DistributorLoadState.loaded;
    } catch (e) {
      _error = 'Could not load distributors';
      _state = DistributorLoadState.error;
    }
    notifyListeners();
  }
}
