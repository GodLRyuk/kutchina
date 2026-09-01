import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/salesExe/models/order_model.dart';
import 'package:kutchina/module/salesExe/pages/order/order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  String _filter = 'All';
  static const _filters = ['All', 'Confirmed', 'Dispatched', 'Delivered'];

  OrderStatus? get _statusFilter => switch (_filter) {
    'Confirmed' => OrderStatus.confirmed,
    'Dispatched' => OrderStatus.dispatched,
    'Delivered' => OrderStatus.delivered,
    _ => null,
  };

  List<KOrder> get _filtered => _statusFilter == null
      ? KOrder.mockList
      : KOrder.mockList.where((o) => o.status == _statusFilter).toList();

  ({Color bg, Color fg, String label}) _badgeFor(OrderStatus s) => switch (s) {
    OrderStatus.placed => (
      bg: AppColors.coldBg,
      fg: AppColors.coldText,
      label: 'Placed',
    ),
    OrderStatus.confirmed => (
      bg: AppColors.amberLight,
      fg: AppColors.amberDark,
      label: 'Confirmed',
    ),
    OrderStatus.dispatched => (
      bg: AppColors.amberLight,
      fg: AppColors.amberDark,
      label: 'Dispatched',
    ),
    OrderStatus.delivered => (
      bg: AppColors.greenLight,
      fg: AppColors.green,
      label: 'Delivered',
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My orders',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => AppWidgets.buildChip(
                  _filters[i],
                  isActive: _filter == _filters[i],
                  onTap: () => setState(() => _filter = _filters[i]),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No orders in this status',
                      style: TextStyle(color: AppColors.steel, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) {
                      final o = _filtered[i];
                      final badge = _badgeFor(o.status);
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(order: o),
                          ),
                        ),
                        child: AppWidgets.buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    o.id,
                                    style: const TextStyle(
                                      fontFamily: 'IBM Plex Mono',
                                      fontSize: 11,
                                      color: AppColors.steel,
                                    ),
                                  ),
                                  AppWidgets.buildBadge(
                                    badge.label,
                                    badge.bg,
                                    badge.fg,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                o.entityName,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${o.date} · ${o.items.length} items · ${o.orderType}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.steel,
                                    ),
                                  ),
                                  Text(
                                    '₹${o.amount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontFamily: 'IBM Plex Mono',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
