class VisitEntry {
  final String id;
  final String visitorName;
  final String address;
  final String purpose;
  final String visitType;
  final String? note;
  final DateTime? createdAt;

  VisitEntry({
    required this.id,
    required this.visitorName,
    required this.address,
    required this.purpose,
    required this.visitType,
    this.note,
    this.createdAt,
  });

  factory VisitEntry.fromJson(Map<String, dynamic> json) {
    return VisitEntry(
      id: (json['id'] ?? '').toString(),
      visitorName: json['visitor_name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      purpose: json['visit_purpose']?.toString() ?? '',
      visitType: json['visit_type']?.toString() ?? '',
      note: json['note']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// e.g. "10:30 AM" for the visit-card badge
  String get timeLabel {
    if (createdAt == null) return '';
    final hour = createdAt!.hour;
    final minute = createdAt!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:$minute $period';
  }
}
