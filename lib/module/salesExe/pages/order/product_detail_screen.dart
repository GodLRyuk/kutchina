import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/salesExe/pages/order/select_product_screen.dart'
    show CartItem;

class ProductDetailScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final String orderType;
  final String entityName;
  final String channel;

  const ProductDetailScreen({
    super.key,
    required this.cartItems,
    required this.orderType,
    required this.entityName,
    required this.channel,
    Object? product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late List<CartItem> _items;

  @override
  void initState() {
    super.initState();
    // Work off a local copy so qty edits here don't mutate the caller's map
    // unless you want them to.
    _items = widget.cartItems;
  }

  double get _total =>
      _items.fold(0.0, (sum, item) => sum + item.product.price * item.quantity);

  void _incrementQty(int index) {
    setState(() => _items[index].quantity++);
  }

  void _decrementQty(int index) {
    setState(() {
      if (_items[index].quantity <= 1) {
        _items.removeAt(index);
      } else {
        _items[index].quantity--;
      }
    });
  }

  void _submitOrder() {
    if (_items.isEmpty) {
      AppWidgets.toast(context, 'No products in the order');
      return;
    }
    // TODO: call your order-creation API with widget.entityName,
    // widget.orderType, widget.channel, and _items.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Order summary',
        centerImage: const AssetImage('assets/images/logo.jpg'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _items.isEmpty
                  ? const Center(
                      child: Text(
                        'No products selected',
                        style: TextStyle(color: AppColors.steel),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final item = _items[i];
                        return AppWidgets.buildCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(
                                        fontFamily: AppFonts.display,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${item.product.price.toStringAsFixed(0)} × ${item.quantity}',
                                      style: const TextStyle(
                                        fontFamily: AppFonts.mono,
                                        fontSize: 12,
                                        color: AppColors.steel,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 20,
                                ),
                                onPressed: () => _decrementQty(i),
                              ),
                              Text('${item.quantity}'),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 20,
                                ),
                                onPressed: () => _incrementQty(i),
                              ),
                              Text(
                                '₹${(item.product.price * item.quantity).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: AppFonts.mono,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.commandCentreText,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.paper,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.bold,
                          color: AppColors.steel,
                        ),
                      ),
                      Text(
                        '₹${_total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: AppFonts.mono,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.commandCentreText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppWidgets.buildButton('Submit order', onTap: _submitOrder),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
