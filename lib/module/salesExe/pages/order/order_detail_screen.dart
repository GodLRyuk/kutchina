import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/salesExe/models/order_model.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderEntry order;
  const OrderDetailScreen({super.key, required this.order});

  static const List<String> _trackerSteps = [
    'Placed',
    'Processing',
    'Shipped',
    'Delivered',
  ];

  bool get _isCancelled =>
      order.orderStatus.toLowerCase() == 'cancelled' ||
      order.orderStatus.toLowerCase() == 'rejected';

  int get _currentStepIndex {
    final status = order.orderStatus.toLowerCase();
    switch (status) {
      case 'placed':
        return 0;
      case 'processing':
      case 'confirmed':
        return 1;
      case 'shipped':
      case 'dispatched':
        return 2;
      case 'delivered':
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Order Number: ${order.orderNumber}",
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
                          color: _statusIconBg(order.orderStatus),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _statusIcon(order.orderStatus),
                          color: _statusIconFg(order.orderStatus),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      AppWidgets.buildBadge(
                        order.orderTypeLabel,
                        AppColors.aiBlueChipBg,
                        AppColors.aiBlue,
                      ),
                      AppWidgets.buildBadge(
                        order.orderStatus,
                        _statusIconBg(order.orderStatus),
                        _statusIconFg(order.orderStatus),
                      ),
                    ],
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

            // ---- Status tracker card ----
            AppWidgets.buildCard(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: _isCancelled ? _cancelledTracker() : _statusTracker(),
            ),
            const SizedBox(height: 14),

            // ---- Item detail card ----
            AppWidgets.buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Order number', order.orderNumber),
                  const Divider(height: 20, color: AppColors.line),
                  _row('Quantity', _formatQty(order.quantity)),
                  const Divider(height: 20, color: AppColors.line),
                  _row('Filter type', order.filterType ?? '—'),
                  const Divider(height: 20, color: AppColors.line),
                  _row('Warranty', order.warranty ?? '—'),
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

  /// Horizontal step tracker: filled circles up to the current step,
  /// connected by a line that's also filled up to that point.
  Widget _statusTracker() {
    final current = _currentStepIndex;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_trackerSteps.length * 2 - 1, (i) {
        // Even indices are step circles, odd indices are connector lines.
        if (i.isEven) {
          final stepIndex = i ~/ 2;
          final done = stepIndex <= current;
          return _stepCircle(
            label: _trackerSteps[stepIndex],
            done: done,
            isCurrent: stepIndex == current,
          );
        } else {
          final connectorIndex = i ~/ 2; // connector after this step
          final filled = connectorIndex < current;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 11,
              ), // align with circle center
              child: Container(
                height: 2,
                color: filled ? AppColors.commandCentreText : AppColors.line,
              ),
            ),
          );
        }
      }),
    );
  }

  Widget _stepCircle({
    required String label,
    required bool done,
    required bool isCurrent,
  }) {
    final color = done ? AppColors.commandCentreText : AppColors.line;
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.commandCentreText : AppColors.white,
            border: Border.all(color: color, width: 2),
          ),
          child: done
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 60,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              color: done ? AppColors.ink : AppColors.steelLight,
            ),
          ),
        ),
      ],
    );
  }

  /// Terminal state shown instead of the normal tracker when an order
  /// was cancelled or rejected — no point implying a "Delivered" step ahead.
  Widget _cancelledTracker() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.redLight,
          ),
          child: const Icon(Icons.close, color: AppColors.red, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.orderStatus,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.redDark,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'This order will not be processed further',
                style: TextStyle(fontSize: 11, color: AppColors.steel),
              ),
            ],
          ),
        ),
      ],
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

  String _formatQty(double q) {
    return q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toString();
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel_outlined;
      case 'placed':
        return Icons.hourglass_top_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _statusIconBg(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return AppColors.greenLight;
      case 'cancelled':
      case 'rejected':
        return AppColors.redLight;
      case 'placed':
        return AppColors.aiBlueChipBg;
      default:
        return AppColors.ash;
    }
  }

  Color _statusIconFg(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return AppColors.green;
      case 'cancelled':
      case 'rejected':
        return AppColors.redDark;
      case 'placed':
        return AppColors.aiBlue;
      default:
        return AppColors.steel;
    }
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
