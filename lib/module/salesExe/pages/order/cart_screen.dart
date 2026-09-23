import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/utils/dialog_box.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/salesExe/models/product_model.dart';

class CartScreen extends StatefulWidget {
  final String orderType;
  final String entityName;
  final Product product;
  final int qty;
  final String entityId;

  const CartScreen({
    super.key,
    required this.orderType,
    required this.entityName,
    required this.product,
    required this.qty,
    required this.entityId,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _placingOrder = false;

  Future<void> _placeOrder() async {
    if (_placingOrder) return;
    setState(() => _placingOrder = true);

    try {
      await OrderService.placeOrder(
        orderType: widget.orderType,
        entityName: widget.entityName,
        product: widget.product,
        filter: '',
        qty: widget.qty,
        warranty: '',
        price: widget.product.price.toString(),
        entityId: widget.entityId,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      await showCheckInRequiredDialogall(
        context,
        title: 'Order failed',
        message: e.message,
        buttonLabel: 'Retry',
        icon: Icons.error_outline,
      );
      return;
    } catch (_) {
      if (!mounted) return;
      await showCheckInRequiredDialogall(
        context,
        title: 'Order failed',
        message:
            'There was an error while placing your order. Please try again later.',
        buttonLabel: 'Retry',
        icon: Icons.error_outline,
      );
      return;
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }

    if (!mounted) return;
    final ok = await showCheckInRequiredDialogall(
      context,
      title: 'Order placed',
      message:
          'Your order for ${widget.entityName} has been created successfully. You can track it from My Orders.',
      buttonLabel: 'Done',
      icon: Icons.check_circle_outline,
    );
    if (ok && mounted) {
      Navigator.popUntil(context, (r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.product.price * widget.qty;
    final total = subtotal;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Order Details',
        centerImage: const AssetImage('assets/images/logo.jpg'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppWidgets.buildStaticField(
                    label: widget.orderType == 'Distributor'
                        ? 'Ordering for distributor'
                        : 'Ordering for retailer',
                    value: widget.entityName,
                  ),
                  const SizedBox(height: 14),
                  AppWidgets.buildCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: const TextStyle(
                                fontFamily: AppFonts.display,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${widget.product.price.toStringAsFixed(0)} × ${widget.qty}',
                              style: const TextStyle(
                                fontFamily: AppFonts.mono,
                                fontSize: 11,
                                color: AppColors.steel,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₹${subtotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: AppFonts.mono,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  _totalRow('Subtotal', subtotal),
                  const Divider(height: 24, color: AppColors.line),
                  _totalRow(
                    'Total',
                    total,
                    bold: true,
                    color: AppColors.commandCentreText,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 1, 20, 40),
            decoration: const BoxDecoration(
              color: AppColors.paper,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: AppWidgets.buildButton(
              _placingOrder ? 'Placing order...' : 'Place order',
              onTap: _placingOrder ? null : _placeOrder,
              loading: _placingOrder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    String label,
    double value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 13.5 : 11.5,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontFamily: bold ? AppFonts.display : null,
              color: bold ? AppColors.ink : AppColors.steel,
            ),
          ),
          Text(
            '${value < 0 ? '−' : ''}₹${value.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: bold ? 13.5 : 11.5,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppColors.steel,
            ),
          ),
        ],
      ),
    );
  }
}
