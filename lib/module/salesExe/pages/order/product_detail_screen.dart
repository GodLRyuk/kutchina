import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
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
  //int _qty = 1;
  // final Map<int, int> _qtys = {};
  // int _qtyOf(int i) => _qtys[i] ?? 1;
  late List<Product> _products = List.from(widget.products);
  final Map<Product, int> _qtys = {};
  int _qtyOf(Product p) => _qtys[p] ?? 1;

  void _goToCart() {
    final selected = <Map<String, dynamic>>[];
    // for (int i = 0; i < widget.products.length; i++) {
    //   if (widget.products[i].isActive) {
    //     selected.add({
    //       'product': widget.products[i],
    //       'qty': _qtyOf(i),
    //     }); // add product into the selected list
    //   }
    // }
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
    //final products = widget.products;
    final products = _products;

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
            // Expanded(
            //   child: SingleChildScrollView(
            //     padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         AppWidgets.buildBadge(
            //           'Ordering for ${widget.entityName} · ${widget.orderType == 'D' ? 'Distributor' : 'Retailer'}',
            //           AppColors.aiBlueChipBg,
            //           AppColors.aiBlue,
            //         ),
            //         const SizedBox(height: 10),
            //         Text(
            //           p.category.name.toUpperCase(),
            //           style: const TextStyle(
            //             fontFamily: AppFonts.mono,
            //             fontSize: 10,
            //             color: AppColors.steel,
            //           ),
            //         ),
            //         Text(
            //           p.name,
            //           style: const TextStyle(
            //             fontFamily: AppFonts.display,
            //             fontSize: 15,
            //             fontWeight: FontWeight.bold,
            //           ),
            //         ),
            //         const SizedBox(height: 8),
            //         Row(
            //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //           children: [
            //             Text(
            //               '₹${p.price.toStringAsFixed(0)}',
            //               style: const TextStyle(
            //                 fontFamily: AppFonts.mono,
            //                 fontSize: 18,
            //                 fontWeight: FontWeight.bold,
            //                 color: AppColors.red,
            //               ),
            //             ),
            //             if (!p.isActive)
            //               Container(
            //                 padding: const EdgeInsets.symmetric(
            //                   horizontal: 8,
            //                   vertical: 3,
            //                 ),
            //                 decoration: BoxDecoration(
            //                   color: AppColors.redLight,
            //                   borderRadius: BorderRadius.circular(20),
            //                 ),
            //                 child: const Text(
            //                   'Unavailable',
            //                   style: TextStyle(
            //                     fontFamily: AppFonts.display,
            //                     fontSize: 9.5,
            //                     fontWeight: FontWeight.bold,
            //                     color: AppColors.red,
            //                   ),
            //                 ),
            //               ),
            //           ],
            //         ),
            //         const Divider(height: 24, color: AppColors.line),
            //         _spec(
            //           'Filter type',
            //           p.filterType.isNotEmpty ? p.filterType : '—',
            //         ),
            //         _spec('Warranty', p.warranty.isNotEmpty ? p.warranty : '—'),
            //         const SizedBox(height: 12),
            //         if (p.color != null) ...[
            //           const Text(
            //             'COLOUR / VARIANT',
            //             style: TextStyle(
            //               fontFamily: AppFonts.display,
            //               fontSize: 10.5,
            //               color: AppColors.steel,
            //               fontWeight: FontWeight.bold,
            //             ),
            //           ),
            //           const SizedBox(height: 8),
            //         ],
            //         Row(
            //           children: [
            //             if (p.color != null)
            //               Container(
            //                 width: 24,
            //                 height: 24,
            //                 decoration: BoxDecoration(
            //                   color: _resolveColor(p.color!.name),
            //                   shape: BoxShape.circle,
            //                   border: Border.all(
            //                     color: AppColors.line,
            //                     width: 1.5,
            //                   ),
            //                 ),
            //               ),
            //             if (p.color != null) const SizedBox(width: 8),
            //             if (p.color != null)
            //               Text(
            //                 p.color!.name,
            //                 style: const TextStyle(
            //                   fontFamily: AppFonts.display,
            //                   fontSize: 12.5,
            //                   fontWeight: FontWeight.w600,
            //                   color: AppColors.ink,
            //                 ),
            //               ),
            //             const Spacer(),
            //             AppWidgets.buildIconButton(
            //               Icons.remove,
            //               size: 26,
            //               onTap: () =>
            //                   setState(() => _qty = _qty > 1 ? _qty - 1 : 1),
            //             ),
            //             Padding(
            //               padding: const EdgeInsets.symmetric(horizontal: 10),
            //               child: Text(
            //                 '$_qty',
            //                 style: const TextStyle(
            //                   fontSize: 13,
            //                   fontWeight: FontWeight.bold,
            //                 ),
            //               ),
            //             ),
            //             AppWidgets.buildIconButton(
            //               Icons.add,
            //               size: 26,
            //               onTap: () => setState(() => _qty++),
            //             ),
            //           ],
            //         ),
            //         const SizedBox(height: 8),
            //         Text(
            //           'Subtotal: ₹${(p.price * _qty).toStringAsFixed(0)}',
            //           style: const TextStyle(
            //             fontFamily: AppFonts.mono,
            //             fontSize: 13,
            //             fontWeight: FontWeight.bold,
            //             color: AppColors.ink,
            //           ),
            //         ),
            //         const SizedBox(height: 20),
            //       ],
            //     ),
            //   ),
            // ),

            Expanded(
              child: products.isEmpty
                  ? const Center(child: Text('No products found'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                      itemCount: products.length + 1, // +1 for the badge
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: AppWidgets.buildBadge(
                              'Ordering for ${widget.entityName} · ${widget.orderType == 'D' ? 'Distributor' : 'Retailer'}',
                              AppColors.aiBlueChipBg,
                              AppColors.aiBlue,
                            ),
                          );
                        }
                        final i = index - 1;
                        //return _productCard(products[i], i);
                        // print(_productCard(products[i], i));
                        final p = products[i];
                        return Dismissible(
                          key: ObjectKey(p),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => setState(() {
                            _products.removeAt(i);
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
                          child: _productCard(p),
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
              child: AppWidgets.buildButton(
                'Add to order',
                onTap: _goToCart,
                // p.isActive
                //     ? () => Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (_) => CartScreen(
                //             orderType: widget.orderType,
                //             entityName: widget.entityName,
                //             entityId: widget.entityId,
                //             product: p,
                //             qty: _qty,
                //           ),
                //         ),
                //       )
                //     : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // add 28-9-2026 *********************

  // Widget _productCard(Product p, int i) 
  Widget _productCard(Product p) 
  {
    final qty = _qtyOf(p);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.category.name.toUpperCase(),
            style: const TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 10,
              color: AppColors.steel,
            ),
          ),
          Text(
            p.name,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${p.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.red,
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
          const Divider(height: 24, color: AppColors.line),
          _spec('Filter type', p.filterType.isNotEmpty ? p.filterType : '—'),
          _spec('Warranty', p.warranty.isNotEmpty ? p.warranty : '—'),
          const SizedBox(height: 12),
          if (p.color != null) ...[
            const Text(
              'COLOUR / VARIANT',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 10.5,
                color: AppColors.steel,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              if (p.color != null) ...[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _resolveColor(p.color!.name),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line, width: 1.5),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  p.color!.name,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ],
              const Spacer(),
              AppWidgets.buildIconButton(
                Icons.remove,
                size: 26,
                onTap: () => setState(() => _qtys[p] = qty > 1 ? qty - 1 : 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '$qty',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AppWidgets.buildIconButton(
                Icons.add,
                size: 26,
                onTap: () => setState(() => _qtys[p] = qty + 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Subtotal: ₹${(p.price * qty).toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          //const SizedBox(height: 12),
          // AppWidgets.buildButton(
          //   'Add to order',
          //   onTap: p.isActive
          //       ? () => Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //             builder: (_) => CartScreen(
          //               orderType: widget.orderType,
          //               entityName: widget.entityName,
          //               entityId: widget.entityId,
          //               product: p,
          //               qty: qty,
          //             ),
          //           ),
          //         )
          //       : null,
          // ),
        ],
      ),
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
      case 'grey':
      case 'gray':
        return AppColors.steelLight;
      default:
        return AppColors.steel;
    }
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
