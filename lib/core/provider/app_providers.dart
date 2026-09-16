import 'package:kutchina/core/provider/auth_provider.dart';
import 'package:kutchina/core/provider/category_provider.dart';
import 'package:kutchina/core/provider/distributor_provider.dart';
import 'package:kutchina/core/provider/retailer_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> appProviders() {
  return [
    ChangeNotifierProvider<DistributorProvider>(
      create: (_) => DistributorProvider(),
    ),

    ChangeNotifierProvider<RetailerProvider>(create: (_) => RetailerProvider()),
    ChangeNotifierProvider<CategoryProvider>(create: (_) => CategoryProvider()),
    ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider()..loadFromStorage(),
    ),
  ];
}
