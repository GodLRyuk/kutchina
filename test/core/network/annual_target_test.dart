import 'package:flutter_test/flutter_test.dart';
import 'package:kutchina/core/network/masters_api.dart';

void main() {
  test('sums current-year assignments across locations for the user', () {
    final assignments = [
      TargetAssignment.fromJson({
        'id': 14,
        'user': {'id': 7, 'userid': 'KUTC120'},
        'location_id': 1,
        'amount': '190000.00',
        'FY_date': '2026-10-01',
      }),
      TargetAssignment.fromJson({
        'id': 15,
        'user': {'id': 7, 'userid': 'KUTC120'},
        'location_id': 2,
        'amount': '25000.00',
        'FY_date': '2026-10-01',
      }),
      TargetAssignment.fromJson({
        'id': 3,
        'user': {'id': 2, 'userid': 'KUTC510'},
        'location_id': 1,
        'amount': '1.00',
        'FY_date': '2026-10-01',
      }),
      TargetAssignment.fromJson({
        'id': 16,
        'user': {'id': 7, 'userid': 'KUTC120'},
        'location_id': 1,
        'amount': '50000.00',
        'FY_date': '2025-10-01',
      }),
    ];

    final target = AnnualTarget.fromAssignments(
      assignments,
      userId: '7',
      year: 2026,
    );

    expect(target, isNotNull);
    expect(target!.amount, 215000);
    expect(target.year, 2026);
  });

  test(
    'returns no annual target when the user has no assignment that year',
    () {
      final target = AnnualTarget.fromAssignments(
        [
          TargetAssignment.fromJson({
            'user': {'id': 7},
            'amount': '190000.00',
            'FY_date': '2025-10-01',
          }),
        ],
        userId: '7',
        year: 2026,
      );

      expect(target, isNull);
    },
  );
}
