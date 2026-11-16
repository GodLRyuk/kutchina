import 'package:kutchina/module/distributors/pages/Offers_Schemes/offers_elements.dart';

class SchemeModel {
  final String id;
  final String type; 
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final bool isEligible;
  final int? targetQty;
  final int? achievedQty;

  const SchemeModel({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
     this.isEligible = false,
    this.targetQty,
    this.achievedQty,
  });

  factory SchemeModel.fromJson(Map<String, dynamic> json) {
    return SchemeModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isEligible: json['isEligible'] as bool? ?? false,
      targetQty: json['targetQty'] as int?,
      achievedQty: json['achievedQty'] as int?,
    );
  }

  SchemeFilter get period{
    final now = DateTime.now();
    if(now.isBefore(startDate)) return SchemeFilter.upcoming;
    if(now.isAfter(endDate)) return SchemeFilter.expired;
    return SchemeFilter.active;
  }

  double? get progress {
    if(targetQty != null && achievedQty != null && targetQty! > 0) {
      return achievedQty! / targetQty!;
    }
    return null;
  }

}