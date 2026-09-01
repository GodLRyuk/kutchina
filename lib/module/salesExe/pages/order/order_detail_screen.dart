import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/salesExe/models/order_model.dart';

class OrderDetailScreen extends StatelessWidget {
  final KOrder order;
  const OrderDetailScreen({super.key, required this.order});

  static const _stages = [
    OrderStatus.placed,
    OrderStatus.confirmed,
    OrderStatus.dispatched,
    OrderStatus.delivered,
  ];
  static const _stageLabels = [
    'Placed',
    'Confirmed',
    'Dispatched',
    'Delivered',
  ];

  int get _stageIndex => _stages.indexOf(order.status);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          order.id,
          style: const TextStyle(
            fontFamily: 'Sora',
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppWidgets.buildCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CURRENT STATUS',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.steel,
                              fontWeight: FontWeight.bold,
                              letterSpacing: .4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _stageLabels[_stageIndex],
                            style: const TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.redLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _stageIndex == _stages.length - 1
                              ? Icons.check_circle_outline
                              : Icons.local_shipping_outlined,
                          color: AppColors.redDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_stageIndex + 1) / _stages.length,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFEDEBE6),
                      color: AppColors.red,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Step ${_stageIndex + 1} of ${_stages.length}',
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Mono',
                      fontSize: 10,
                      color: AppColors.steel,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.entityName} · ${order.orderType}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.steel,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppWidgets.buildCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_stages.length, (i) {
                  final done = i < _stageIndex;
                  final active = i == _stageIndex;
                  final color = done
                      ? AppColors.green
                      : (active ? AppColors.amber : AppColors.steelLight);
                  return Expanded(
                    child: Column(
                      children: [
                        Icon(
                          done
                              ? Icons.check_circle
                              : (active
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked),
                          color: color,
                          size: 18,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _stageLabels[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: active
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Items',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...order.items.map(
              (i) => AppWidgets.buildCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${i.product.name} ×${i.qty}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      '₹${i.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Mono',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            AppWidgets.buildCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹${order.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Mono',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppWidgets.buildButton(
              'Download invoice',
              variant: AppButtonVariant.outline,
              onTap: () =>
                  AppWidgets.toast(context, 'Invoice download coming soon'),
            ),
          ],
        ),
      ),
    );
  }
}
