import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/salesExe/models/product_model.dart';
import 'package:kutchina/module/salesExe/pages/order/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final List<Product> products;
  final String orderType;
  final String entityName;
  final String entityId;
  final String channel;

  const ProductDetailScreen({
    super.key,
    required this.products,
    required this.orderType,
    required this.entityName,
    required this.entityId,
    required this.channel,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final List<Product> _products = List.from(widget.products);
  final Map<Product, int> _qtys = {};
  int _qtyOf(Product p) => _qtys[p] ?? 1;

  // Card accent colours: blue, green, purple, cyan (repeats).
  static const List<Color> _cardColors = [
    AppColors.regionBlue,
    AppColors.green,
    AppColors.regionPurple,
    AppColors.regionCyan,
  ];

  void _goToCart() {
    final selected = <Map<String, dynamic>>[];
    for (final p in _products) {
      if (p.isActive) selected.add({'product': p, 'qty': _qtyOf(p)});
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          orderType: widget.orderType,
          entityName: widget.entityName,
          entityId: widget.entityId,
          items: selected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _products;

    final topBar = AppTopBar.brand(
      showBackButton: true,
      centerImage: const AssetImage('assets/images/logo.jpg'),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => AppWidgets.toast(context, 'No new notifications'),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: topBar,
      body: AppBackground(
        child: Padding(
          padding: EdgeInsets.only(
            top:
                MediaQuery.of(context).padding.top +
                topBar.preferredSize.height,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                _banner(),
                Expanded(
                  child: products.isEmpty
                      ? const Center(child: Text('No products found'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                          itemCount: products.length + 1, // +1 for the pill
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _orderingForPill(),
                                ),
                              );
                            }
                            final i = index - 1;
                            final p = products[i];
                            final color = _cardColors[i % _cardColors.length];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Dismissible(
                                  key: ObjectKey(p),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (_) => setState(() {
                                    _products.remove(p);
                                    _qtys.remove(p);
                                  }),
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 24),
                                    color: AppColors.red,
                                    child: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.white,
                                    ),
                                  ),
                                  child: _productCard(p, color),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: AppWidgets.buildButton(
                    'Add to order  →',
                    onTap: _goToCart,
                    variant: AppButtonVariant.gradient,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Banner (dark strip with store icon) ----------------
  Widget _banner() {
    return Container(
      height: 170,
      width: double.infinity,
      color: AppColors.charcoal.withValues(alpha: 0.85),
      alignment: Alignment.center,
      child: const Icon(
        Icons.storefront_outlined,
        color: Colors.white,
        size: 64,
      ),
    );
  }

  // ---------------- "Ordering for ABCD - Distributor" pill ----------------
  Widget _orderingForPill() {
    final typeLabel = widget.orderType == 'D' ? 'Distributor' : 'Retailer';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.regionPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.regionPurple, width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.storefront_outlined,
            size: 20,
            color: AppColors.regionPurple,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.regionPurple,
                ),
                children: [
                  const TextSpan(text: 'Ordering for '),
                  TextSpan(
                    text: widget.entityName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' - $typeLabel'),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Product card ----------------
  Widget _productCard(Product p, Color color) {
    final qty = _qtyOf(p);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name (+ unavailable tag)
          Row(
            children: [
              Icon(Icons.storefront_outlined, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              if (!p.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.redLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Unavailable',
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.red,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Price
          Text(
            '₹ ${p.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 15,
              color: AppColors.steel,
            ),
          ),
          const Divider(height: 22, color: AppColors.line),

          // Filter Type | Warranty | Color / Variant
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _column(
                  'Filter Type',
                  Text(
                    p.filterType.isNotEmpty ? p.filterType : '----',
                    style: _valueStyle,
                  ),
                  CrossAxisAlignment.start,
                ),
              ),
              Expanded(
                child: _column(
                  'Warranty',
                  Text(
                    p.warranty.isNotEmpty ? p.warranty : '----',
                    style: _valueStyle,
                  ),
                  CrossAxisAlignment.center,
                ),
              ),
              Expanded(
                child: _column(
                  'Color / Variant',
                  p.color != null
                      ? Container(
                          width: 28,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _resolveColor(p.color!.name),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.line,
                              width: 1.2,
                            ),
                          ),
                        )
                      : const Text('----', style: _valueStyle),
                  CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Subtotal + stepper
          Row(
            children: [
              const Text(
                'Subtotal  ',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              Expanded(
                child: Text(
                  '₹${(p.price * qty).toStringAsFixed(2)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.red,
                  ),
                ),
              ),
              AppWidgets.buildIconButton(
                Icons.remove,
                size: 28,
                onTap: () => setState(() => _qtys[p] = qty > 1 ? qty - 1 : 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '$qty',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AppWidgets.buildIconButton(
                Icons.add,
                size: 28,
                onTap: () => setState(() => _qtys[p] = qty + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const TextStyle _valueStyle = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.steel,
  );

  Widget _column(String label, Widget value, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        value,
      ],
    );
  }

  Color _resolveColor(String name) {
    switch (name.toLowerCase().trim()) {
      case 'black':
        return AppColors.charcoal;
      case 'white':
        return AppColors.white;
      case 'red':
        return AppColors.red;
      case 'blue':
        return AppColors.regionBlue;
      case 'grey':
      case 'gray':
        return AppColors.steelLight;
      default:
        return AppColors.steel;
    }
  }
}
