import 'package:kutchina/core/services/admin_dashboard_api.dart';
import 'package:kutchina/module/dashboard/dashboard_controller.dart';

class SeDashboardController extends DashboardController {
  bool _loading = true;
  List<DashboardCategory> categories = const [];
  double targetValue = 0;
  double achievedValue = 0;
  double progress = 0;

  @override
  bool get loading => _loading;

  @override
  Future<void> load() async {
    _loading = true;
    notifyListeners();

    try {
      final overview = await AdminDashboardApi.fetchOverview();
      final nextCategories = [...overview.salesByCategory]
        ..sort((a, b) => b.percentage.compareTo(a.percentage));
      categories = nextCategories;
      if (overview.targetValue > 0) {
        targetValue = overview.targetValue;
        achievedValue = overview.totalSalesValue;
        progress = (achievedValue / targetValue).clamp(0.0, 1.0);
      } else {
        targetValue = 0;
        achievedValue = overview.totalSalesValue;
        progress = 0;
      }
    } catch (_) {
      categories = const [];
      targetValue = 0;
      achievedValue = 0;
      progress = 0;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> refresh() => load();
}
