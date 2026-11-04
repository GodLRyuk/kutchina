import 'package:kutchina/core/services/admin_dashboard_api.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/module/dashboard/dashboard_controller.dart';

class HodDashboardController extends DashboardController {
  bool _loading = false;
  AdminDashboardData? _data;
  String? _error;

  @override
  bool get loading => _loading;
  AdminDashboardData? get data => _data;
  String? get error => _error;

  @override
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await AdminDashboardApi.fetchOverview(period: 'year');
    } on ApiException catch (error) {
      _error = error.message;
    } catch (error) {
      _error = 'Unable to load HOD dashboard: $error';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> refresh() => load();
}
