import 'package:kutchina/module/distributors/models/scheme_model.dart';

class SchemeService {
  static Future<List<SchemeModel>> fetchSchemes() async{
     await Future.delayed(const Duration(milliseconds: 500));

     return[
      SchemeModel(
        id: '1',
        type: 'festive',
        title: 'Extra 2% on orders above ₹1,00,000',
        description: 'Valid till 30 Nov · All categories',
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 30, 23, 59),
        isEligible: true,
      ),
      SchemeModel(
        id: '2',
        type: 'launch',
        title: 'Early-bird pricing on new range',
        description: 'Order before 20 Nov',
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 20, 23, 59),
      ),
      SchemeModel(
        id: '3',
        type: 'volume',
        title: 'Buy 50 hobs, get 3 free',
        description: 'Valid till 15 Dec',
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 12, 15, 23, 59),
        targetQty: 50,
        achievedQty: 32,
      ),
      SchemeModel(
        id: '4',
        type: 'festive',
        title: 'Extra 3% on orders above ₹2,00,000',
        description: 'Starts 1 Dec · All categories',
        startDate: DateTime(2026, 12, 1),
        endDate: DateTime(2026, 12, 31, 23, 59),
      ),
      SchemeModel(
        id: '5',
        type: 'festive',
        title: 'Extra 3% on orders above ₹2,00,000',
        description: 'Ended 5 Nov',
        startDate: DateTime(2026, 10, 15),
        endDate: DateTime(2026, 11, 5, 23, 59),
      ),
     ];
    
  }
}
