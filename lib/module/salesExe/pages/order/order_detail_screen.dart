import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/salesExe/models/order_model.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderEntry order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '#${order.id}',
          style: const TextStyle(
            fontFamily: AppFonts.display,
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
            // ---- Summary card ----
            AppWidgets.buildCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PRODUCT',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.steel,
                                fontWeight: FontWeight.bold,
                                letterSpacing: .4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.productName,
                              style: const TextStyle(
                                fontFamily: AppFonts.display,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: order.isActive
                              ? AppColors.greenLight
                              : AppColors.redLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          order.isActive
                              ? Icons.check_circle_outline
                              : Icons.pause_circle_outline,
                          color: order.isActive
                              ? AppColors.green
                              : AppColors.redDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppWidgets.buildBadge(
                    order.orderTypeLabel,
                    AppColors.aiBlueChipBg,
                    AppColors.aiBlue,
                  ),
                  const SizedBox(height: 10),
                  if (order.createdAt != null)
                    Text(
                      'Placed on ${_formatDate(order.createdAt!)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.steel,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ---- Item detail card ----
            AppWidgets.buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Product ID', order.productId),
                  const Divider(height: 20, color: AppColors.line),
                  _row('Quantity', order.quantity.toStringAsFixed(0)),
                  const Divider(height: 20, color: AppColors.line),
                  _row(
                    'Filter type',
                    order.filterType.isNotEmpty ? order.filterType : '—',
                  ),
                  const Divider(height: 20, color: AppColors.line),
                  _row(
                    'Warranty',
                    order.warranty.isNotEmpty ? order.warranty : '—',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ---- Total ----
            AppWidgets.buildCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    order.price != null
                        ? '₹${order.total.toStringAsFixed(0)}'
                        : 'Price pending',
                    style: TextStyle(
                      fontFamily: AppFonts.mono,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: order.price != null
                          ? AppColors.red
                          : AppColors.steel,
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

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.steel),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
