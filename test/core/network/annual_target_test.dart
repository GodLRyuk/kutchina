import 'package:flutter_test/flutter_test.dart';
import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/module/salesExe/models/order_model.dart';

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

  test('annual achieved sales only include the logged-in user orders', () {
    final orders = [
      OrderEntry.fromJson({
        'id': 1,
        'created_by': 7,
        'created_at': '2026-10-15T12:00:00+05:30',
        'total_price': '1000.00',
      }),
      OrderEntry.fromJson({
        'id': 2,
        'created_by': 2,
        'created_at': '2026-10-15T12:00:00+05:30',
        'total_price': '5000.00',
      }),
      OrderEntry.fromJson({
        'id': 3,
        'user': {'id': 7},
        'created_at': '2025-12-31T12:00:00+05:30',
        'total_price': '9000.00',
      }),
      OrderEntry(
        id: -4,
        orderNumber: 'OFFLINE-1',
        productId: 1,
        productName: 'Offline order',
        quantity: 1,
        userType: 'R',
        orderStatus: 'Pending Sync',
        price: 250,
        createdAt: DateTime(2026, 10, 15),
      ),
    ];

    expect(
      OrderService.calculateAnnualSales(orders, userId: '7', year: 2026),
      1250,
    );
  });
}
