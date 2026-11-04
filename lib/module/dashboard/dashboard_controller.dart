import 'package:flutter/foundation.dart';

abstract class DashboardController extends ChangeNotifier {
  bool get loading;
  Future<void> load();
  Future<void> refresh();
}
