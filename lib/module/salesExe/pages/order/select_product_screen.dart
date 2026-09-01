import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/utils/dropdown.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/salesExe/models/product_model.dart';
import 'package:kutchina/module/salesExe/pages/order/product_detail_screen.dart';

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
  Product? _selected;

  static const _distributors = [
    'Sharma Electronics',
    'Newtown Appliances',
    'Howrah Home Center',
  ];
  static const _retailers = [
    'Baruipur Home Corner',
    'Sonarpur Electric Mart',
    'Garia Kitchen Studio',
  ];

  List<String> get _entityOptions =>
      widget.orderType == 'Distributor' ? _distributors : _retailers;

  List<Product> get _categoryFiltered => Product.catalog
      .where((p) => _category == 'All' || p.category == _category)
      .toList();

  Future<void> _pickEntity() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) =>
          EntityPickerSheet(label: widget.orderType, options: _entityOptions),
    );
    if (picked != null) setState(() => _entity = picked);
  }

  Future<void> _pickProduct() async {
    if (_entity == null) {
      AppWidgets.toast(
        context,
        'Select a ${widget.orderType.toLowerCase()} first',
      );
      return;
    }
    final picked = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ProductPickerSheet(products: _categoryFiltered),
    );
    if (picked != null) setState(() => _selected = picked);
  }

  void _proceed() {
    if (_entity == null) {
      AppWidgets.toast(
        context,
        'Select a ${widget.orderType.toLowerCase()} first',
      );
      return;
    }
    if (_selected == null) {
      AppWidgets.toast(context, 'Select a product to continue');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: _selected!,
          orderType: widget.orderType,
          entityName: _entity!,
          channel: widget.channel,
        ),
      ),
    );
  }

  @override
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
                          '${widget.orderType} order',
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
                    const SizedBox(height: 12),
                    AppWidgets.buildStaticField(
                      label: widget.orderType,
                      value:
                          _entity ?? 'Select ${widget.orderType.toLowerCase()}',
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
                      children: ['All', ...Product.categories].map((c) {
                        final active = _category == c;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _category = c;
                            _selected = null;
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
                      label: 'Product',
                      value: _selected?.name ?? 'Select a product',
                      isPlaceholder: _selected == null,
                      onTap: _pickProduct,
                    ),
                    if (_selected != null) ...[
                      const SizedBox(height: 12),
                      AppWidgets.buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selected!.name,
                                  style: const TextStyle(
                                    fontFamily: AppFonts.display,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selected!.category,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.steel,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${_selected!.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontFamily: AppFonts.mono,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.commandCentreText,
                              ),
                            ),
                          ],
                        ),
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
}

class _ProductPickerSheet extends StatefulWidget {
  final List<Product> products;
  const _ProductPickerSheet({required this.products});

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final _searchController = TextEditingController();

  List<Product> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return widget.products;
    return widget.products
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
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
                const Text(
                  'Select product',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
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
                    maxHeight: MediaQuery.of(context).size.height * .5,
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
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
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
                                p.category,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.steel,
                                ),
                              ),
                              trailing: Text(
                                '₹${p.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: AppFonts.mono,
                                  fontSize: 12,
                                  color: AppColors.regionCyan,
                                ),
                              ),
                              onTap: () => Navigator.pop(context, p),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
