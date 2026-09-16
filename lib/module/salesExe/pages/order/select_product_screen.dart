import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/core/utils/dropdown.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/salesExe/models/category_model.dart';
import 'package:kutchina/module/salesExe/models/product_model.dart'
    hide CategoryModel;
import 'package:kutchina/module/salesExe/pages/order/product_detail_screen.dart';

/// A product paired with the quantity chosen in the multi-select cart.
class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
}

class SelectProductScreen extends StatefulWidget {
  final String orderType;
  final String channel;
  const SelectProductScreen({
    super.key,
    required this.orderType,
    required this.channel,
  });

  @override
  State<SelectProductScreen> createState() => _SelectProductScreenState();
}

class _SelectProductScreenState extends State<SelectProductScreen> {
  String? _entity;
  String _category = 'All';

  // Cart keyed by product id so quantities persist across category filtering.
  final Map<String, CartItem> _cart = {};

  List<String> _distributorNames = [];
  bool _loadingDistributors = false;
  bool _loadingRetailers = false;
  String? _retailerError;
  String? _distributorError;
  List<String> _retailers = [];

  @override
  void initState() {
    super.initState();
    if (widget.orderType == 'D') {
      _loadDistributors();
    } else if (widget.orderType == 'R') {
      _loadRetailers();
    }
    CategoryModel.loadCategories().then((_) {
      setState(() {});
    });
    Product.loadCatalog().then((_) => setState(() {}));
  }

  Future<void> _loadDistributors() async {
    setState(() {
      _loadingDistributors = true;
      _distributorError = null;
    });
    try {
      final list = await MastersApi.fetchDistributors();
      setState(() {
        _distributorNames = list.map((d) => d.name).toList();
        _loadingDistributors = false;
      });
    } catch (e) {
      setState(() {
        _distributorError = 'Could not load distributors';
        _loadingDistributors = false;
      });
    }
  }

  Future<void> _loadRetailers() async {
    setState(() {
      _loadingRetailers = true;
      _retailerError = null;
    });
    try {
      final list = await MastersApi.fetchRetailers();
      setState(() {
        _retailers = list.map((d) => d.name).toList();
        _loadingRetailers = false;
      });
    } catch (e) {
      setState(() {
        _retailerError = 'Could not load retailers';
        _loadingRetailers = false;
      });
    }
  }

  List<String> get _entityOptions =>
      widget.orderType == 'D' ? _distributorNames : _retailers;

  List<Product> get _categoryFiltered {
    final categoryId = CategoryModel.idForName(_category);
    return Product.catalog
        .where(
          (p) =>
              _category == 'All' ||
              p.category.name == _category ||
              p.category.id == categoryId,
        )
        .toList();
  }

  double get _cartTotal => _cart.values.fold(
    0.0,
    (sum, item) => sum + item.product.price * item.quantity,
  );

  int get _cartCount =>
      _cart.values.fold(0, (sum, item) => sum + item.quantity);

  Future<void> _pickEntity() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => EntityPickerSheet(
        label: widget.orderType == 'D' ? 'Distributors' : 'Retailers',
        options: _entityOptions,
      ),
    );
    if (picked != null) setState(() => _entity = picked);
  }

  Future<void> _pickProducts() async {
    if (_entity == null) {
      AppWidgets.toast(
        context,
        'Select a ${widget.orderType == 'D' ? 'Distributor' : 'Retailer'} first',
      );
      return;
    }
    if (_categoryFiltered.isEmpty) {
      AppWidgets.toast(context, 'No products found');
      return;
    }
    final picked = await showModalBottomSheet<Set<Product>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ProductPickerSheet(
        products: _categoryFiltered,
        initiallySelected: _cart.values.map((item) => item.product).toSet(),
      ),
    );
    if (picked == null) return;

    setState(() {
      // Remove products that were unchecked (only within the current
      // category filter, so items from other categories stay untouched).
      final filteredIds = _categoryFiltered.map((p) => p.id).toSet();
      _cart.removeWhere(
        (id, _) => filteredIds.contains(id) && !picked.any((p) => p.id == id),
      );
      // Add newly checked products with a default quantity of 1.
      for (final p in picked) {
        _cart.putIfAbsent(p.id, () => CartItem(product: p, quantity: 1));
      }
    });
  }

  void _incrementQty(String productId) {
    setState(() => _cart[productId]!.quantity++);
  }

  void _decrementQty(String productId) {
    setState(() {
      final item = _cart[productId]!;
      if (item.quantity <= 1) {
        _cart.remove(productId);
      } else {
        item.quantity--;
      }
    });
  }

  void _removeItem(String productId) {
    setState(() => _cart.remove(productId));
  }

  void _proceed() {
    if (_entity == null) {
      AppWidgets.toast(
        context,
        'Select a ${widget.orderType == 'D' ? 'Distributor' : 'Retailer'} first',
      );
      return;
    }
    if (_cart.isEmpty) {
      AppWidgets.toast(context, 'Select at least one product to continue');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        // NOTE: ProductDetailScreen needs to accept a list of CartItem
        // (or Map<Product,int>) instead of a single `product` now.
        // e.g. `required List<CartItem> cartItems` in its constructor.
        builder: (_) => ProductDetailScreen(
          cartItems: _cart.values.toList(),
          orderType: widget.orderType,
          entityName: _entity!,
          channel: widget.channel,
          product: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'New order',
        centerImage: const AssetImage('assets/images/logo.jpg'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        AppWidgets.buildBadge(
                          '${widget.orderType == 'D' ? 'Distributor' : 'Retailer'} order',
                          AppColors.rupeeIconBg,
                          AppColors.commandCentreText,
                        ),
                        AppWidgets.buildBadge(
                          widget.channel,
                          AppColors.aiBlueChipBg,
                          AppColors.aiBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (widget.orderType == 'D' && _loadingDistributors ||
                        widget.orderType == 'R' && _loadingRetailers)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          border: Border.all(color: AppColors.line),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.commandCentreText,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Loading ${widget.orderType.toLowerCase()}s…',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.steel,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (widget.orderType == 'D' &&
                            _distributorError != null ||
                        widget.orderType == 'R' && _retailerError != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.redLight,
                          border: Border.all(
                            color: AppColors.red.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 16,
                              color: AppColors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _distributorError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.redDark,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _loadDistributors,
                              child: const Text(
                                'Retry',
                                style: TextStyle(
                                  fontFamily: AppFonts.display,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      AppWidgets.buildStaticField(
                        label: widget.orderType == 'D'
                            ? 'Distributor'
                            : 'Retailer',
                        value:
                            _entity ??
                            'Select ${widget.orderType == 'D' ? 'Distributor' : 'Retailer'}',
                        isPlaceholder: _entity == null,
                        onTap: _pickEntity,
                      ),
                    const SizedBox(height: 14),
                    const Text(
                      'CATEGORY',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 10.5,
                        color: AppColors.steel,
                        fontWeight: FontWeight.bold,
                        letterSpacing: .4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['All', ...CategoryModel.categories].map((c) {
                        final active = _category == c;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _category = c;
                          }),
                          child: Container(
                            width:
                                (MediaQuery.of(context).size.width - 40 - 16) /
                                3,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.rupeeIconBg
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: active
                                    ? AppColors.commandCentreText
                                    : AppColors.line,
                                width: active ? 1.6 : 1,
                              ),
                            ),
                            child: Text(
                              c,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppFonts.display,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? AppColors.commandCentreText
                                    : AppColors.steel,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    AppWidgets.buildStaticField(
                      label: _category == 'All'
                          ? 'Products'
                          : 'Products ($_category)',
                      value: _cart.isEmpty
                          ? 'Select products'
                          : '$_cartCount item${_cartCount == 1 ? '' : 's'} selected',
                      isPlaceholder: _cart.isEmpty,
                      onTap: _pickProducts,
                    ),
                    if (_cart.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'SELECTED PRODUCTS',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 10.5,
                          color: AppColors.steel,
                          fontWeight: FontWeight.bold,
                          letterSpacing: .4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._cart.values.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppWidgets.buildCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        style: const TextStyle(
                                          fontFamily: AppFonts.display,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.product.category.name,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.steel,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '₹${item.product.price.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontFamily: AppFonts.mono,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.commandCentreText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    _qtyButton(
                                      icon: Icons.remove,
                                      onTap: () =>
                                          _decrementQty(item.product.id),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontFamily: AppFonts.mono,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    _qtyButton(
                                      icon: Icons.add,
                                      onTap: () =>
                                          _incrementQty(item.product.id),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: AppColors.steel,
                                  ),
                                  onPressed: () => _removeItem(item.product.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.steel,
                            ),
                          ),
                          Text(
                            '₹${_cartTotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontFamily: AppFonts.mono,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.commandCentreText,
                            ),
                          ),
                        ],
                      ),
                    ],
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
              child: AppWidgets.buildButton('Proceed', onTap: _proceed),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.rupeeIconBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: AppColors.commandCentreText),
      ),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  final List<Product> products;
  final Set<Product> initiallySelected;
  const _ProductPickerSheet({
    required this.products,
    this.initiallySelected = const {},
  });

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final _searchController = TextEditingController();
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.initiallySelected.map((p) => p.id).toSet();
  }

  List<Product> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return widget.products;
    return widget.products
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
  }

  void _toggle(Product p) {
    setState(() {
      if (_selectedIds.contains(p.id)) {
        _selectedIds.remove(p.id);
      } else {
        _selectedIds.add(p.id);
      }
    });
  }

  void _confirm() {
    final selected = widget.products
        .where((p) => _selectedIds.contains(p.id))
        .toSet();
    Navigator.pop(context, selected);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select products',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedIds.isNotEmpty)
                      Text(
                        '${_selectedIds.length} selected',
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.commandCentreText,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.line, width: 1.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 13, color: AppColors.ink),
                    decoration: const InputDecoration(
                      icon: Icon(
                        Icons.search,
                        size: 18,
                        color: AppColors.steel,
                      ),
                      hintText: 'Search products',
                      hintStyle: TextStyle(
                        color: AppColors.steelLight,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * .45,
                  ),
                  child: _filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No products found',
                            style: TextStyle(
                              color: AppColors.steel,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: AppColors.line),
                          itemBuilder: (context, i) {
                            final p = _filtered[i];
                            final checked = _selectedIds.contains(p.id);
                            return CheckboxListTile(
                              value: checked,
                              onChanged: (_) => _toggle(p),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              activeColor: AppColors.commandCentreText,
                              title: Text(
                                p.name,
                                style: const TextStyle(
                                  fontFamily: AppFonts.display,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.regionBlue,
                                ),
                              ),
                              subtitle: Text(
                                p.category.name,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.steel,
                                ),
                              ),
                              secondary: Text(
                                '₹${p.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: AppFonts.mono,
                                  fontSize: 12,
                                  color: AppColors.regionCyan,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                AppWidgets.buildButton(
                  _selectedIds.isEmpty
                      ? 'Select products'
                      : 'Add ${_selectedIds.length} product${_selectedIds.length == 1 ? '' : 's'}',
                  onTap: _selectedIds.isEmpty ? null : _confirm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
