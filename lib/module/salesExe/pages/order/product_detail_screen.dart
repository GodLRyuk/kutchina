import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/salesExe/models/product_model.dart';
import 'package:kutchina/module/salesExe/pages/order/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final String orderType;
  final String entityName;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.orderType,
    required this.entityName,
    required String channel,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  int _colorIndex = 0;
  static const _colors = [
    AppColors.charcoal,
    AppColors.red,
    AppColors.steelLight,
  ];

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      backgroundColor: AppColors.ash,
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 190,
                  width: double.infinity,
                  color: AppColors.charcoal,
                  child: const Icon(
                    Icons.deck_outlined,
                    color: Color(0xFF8D8F96),
                    size: 60,
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: AppWidgets.buildIconButton(
                    Icons.arrow_back,
                    ghost: true,
                    darkBg: true,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppWidgets.buildBadge(
                      'Ordering for ${widget.entityName} · ${widget.orderType}',
                      AppColors.aiBlueChipBg,
                      AppColors.aiBlue,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      p.category.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Mono',
                        fontSize: 10,
                        color: AppColors.steel,
                      ),
                    ),
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${p.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: 'IBM Plex Mono',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.red,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.line),
                    _spec('Suction capacity', p.suction),
                    _spec('Filter type', p.filter),
                    _spec('Warranty', p.warranty),
                    const SizedBox(height: 12),
                    const Text(
                      'COLOUR / VARIANT',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.steel,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ...List.generate(_colors.length, (i) {
                          final active = _colorIndex == i;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _colorIndex = i),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _colors[i],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: active
                                        ? AppColors.red
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        const Spacer(),
                        AppWidgets.buildIconButton(
                          Icons.remove,
                          size: 26,
                          onTap: () =>
                              setState(() => _qty = _qty > 1 ? _qty - 1 : 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '$_qty',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        AppWidgets.buildIconButton(
                          Icons.add,
                          size: 26,
                          onTap: () => setState(() => _qty++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.paper,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: AppWidgets.buildButton(
                'Add to order',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CartScreen(
                      orderType: widget.orderType,
                      entityName: widget.entityName,
                      product: p,
                      qty: _qty,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _spec(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: AppColors.steel),
          ),
          Text(value, style: const TextStyle(fontSize: 11.5)),
        ],
      ),
    );
  }
}
