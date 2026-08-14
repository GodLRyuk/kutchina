import 'package:intl/intl.dart';

class AppHelpers {
  static String formatCurrency(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static void triggerAiAction(String actionName) {
    print('Executing AI Action: $actionName');
  }
}
