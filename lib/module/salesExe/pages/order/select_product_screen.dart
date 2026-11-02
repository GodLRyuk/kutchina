import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/core/provider/auth_provider.dart';
import 'package:kutchina/core/services/target_milestone_notification_service.dart';
import 'package:kutchina/core/utils/dropdown.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/salesExe/models/category_model.dart';
import 'package:kutchina/module/salesExe/models/product_model.dart'
    hide CategoryModel;
import 'package:kutchina/module/salesExe/pages/notification/notification.dart';
import 'package:kutchina/module/salesExe/pages/order/product_detail_screen.dart';
import 'package:provider/provider.dart';

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
  String? _entityId;
  String _category = 'All';
  List<Product> _selectedProducts = [];

  List<dynamic> _distributors = [];
  List<dynamic> _retailers = [];
  bool _loadingDistributors = false;
  bool _loadingRetailers = false;
  String? _retailerError;
  String? _distributorError;
   List<TargetMilestoneNotification> _targetNotifications = [];

  // Category chip colours, assigned by position (All, 2nd, 3rd, ...).
  static const List<Color> _categoryColors = [
    AppColors.regionBlue,
    AppColors.regionOrange,
    AppColors.regionPurple,
    AppColors.regionCyan,
    AppColors.regionDarkRed,
  ];

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
    //print('product is this ${Product.catalog.length}');
  }

  Future<void> _openTargetNotifications() async {
    
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) return;
    final notifications = await TargetMilestoneNotificationService.markAllRead(
      userId,
    );

    if (!mounted) return;
    setState(() => _targetNotifications = notifications);
    await NotificationScreen.show(context, notifications);
  }


  Future<void> _loadDistributors() async {
    setState(() {
      _loadingDistributors = true;
      _distributorError = null;
    });
    try {
      final list = await MastersApi.fetchDistributors();
      setState(() {
        _distributors = list;
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
        _retailers = list;
        _loadingRetailers = false;
      });
    } catch (e) {
      setState(() {
        _retailerError = 'Could not load retailers';
        _loadingRetailers = false;
      });
    }
  }

  List<dynamic> get _entityList =>
      widget.orderType == 'D' ? _distributors : _retailers;

  List<String> get _entityOptions =>
      _entityList.map<String>((e) => e.name as String).toList();

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

  Future<void> _pickEntity() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => EntityPickerSheet(
        label: widget.orderType == 'D' ? 'Distributors' : 'Retailers',
        options: _entityOptions,
      ),
    );
    if (picked != null) {
      dynamic match;
      for (final e in _entityList) {
        if (e.name == picked) {
          match = e;
          break;
        }
      }
      setState(() {
        _entity = picked;
        _entityId = match?.id?.toString();
      });
    }
  }

  Future<void> _pickProduct() async {
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
    final picked = await showModalBottomSheet<List<Product>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ProductPickerSheet(
        products: _categoryFiltered,
        initiallySelected: _selectedProducts,
      ),
    );
    if (picked != null) setState(() => _selectedProducts = picked);
  }

  void _proceed() {
    if (_entity == null || _entityId == null) {
      AppWidgets.toast(
        context,
        'Select a ${widget.orderType == 'D' ? 'Distributor' : 'Retailer'} first',
      );
      return;
    }
    if (_selectedProducts.isEmpty) {
      AppWidgets.toast(context, 'Select a product to continue');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          products: _selectedProducts,
          orderType: widget.orderType,
          entityName: _entity!,
          entityId: _entityId!,
          channel: widget.channel,
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant SelectProductScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderType == widget.orderType) return;

    setState(() {
      _entity = null;
      _entityId = null;
      _category = 'All';
      _selectedProducts = [];
      _distributorError = null;
      _retailerError = null;
    });

    if (widget.orderType == 'D') {
      _loadDistributors();
    } else if (widget.orderType == 'R') {
      _loadRetailers();
    }
  }

  // ---------------- Design helpers ----------------

  Widget _sectionLabel(String text, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: .3,
          ),
        ),
      ],
    );
  }

  Widget _selectField({
    required String value,
    required bool isPlaceholder,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: accent, width: 1.4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isPlaceholder ? AppColors.steelLight : AppColors.ink,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: AppColors.steel,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entityLabel = widget.orderType == 'D' ? 'Distributor' : 'Retailer';

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar.brand(
        showBackButton: true,
        centerImage: const AssetImage('assets/images/logo.jpg'),
        actions: [
            IconButton(
              onPressed: _openTargetNotifications,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined),
                  if (_targetNotifications.any(
                    (notification) => !notification.isRead,
                  ))
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------- Order + channel pill ----------
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.retailerChannelBg,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.retailerChannelBorder,
                            width: 1.4,
                          ),
                        ),
                        child: Text(
                          '$entityLabel order  •  ${widget.channel}'
                              .toUpperCase(),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.retailerChannelText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ---------- Distributor / Retailer ----------
                      _sectionLabel(
                        entityLabel,
                        Icons.storefront_outlined,
                        AppColors.regionBlue,
                      ),
                      const SizedBox(height: 8),
                      if (widget.orderType == 'D' && _loadingDistributors ||
                          widget.orderType == 'R' && _loadingRetailers)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.9),
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
                              color: AppColors.red.withValues(alpha: 0.3),
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
                        _selectField(
                          value:
                              _entity ??
                              'Select a ${entityLabel.toLowerCase()}',
                          isPlaceholder: _entity == null,
                          accent: AppColors.navActive,
                          onTap: _pickEntity,
                        ),
                      const SizedBox(height: 22),

                      // ---------- Category ----------
                      _sectionLabel(
                        'Category',
                        Icons.category_outlined,
                        AppColors.regionBlue,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: () {
                          final cats = ['All', ...CategoryModel.categories];
                          return List.generate(cats.length, (i) {
                            final c = cats[i];
                            final color =
                                _categoryColors[i % _categoryColors.length];
                            final active = _category == c;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _category = c;
                                _selectedProducts = [];
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width:
                                    (MediaQuery.of(context).size.width -
                                        40 -
                                        16) /
                                    3,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: color.withValues(
                                    alpha: active ? 0.18 : 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  border: Border.all(
                                    color: color,
                                    width: active ? 1.8 : 1.2,
                                  ),
                                ),
                                child: Text(
                                  c.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppFonts.display,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ),
                            );
                          });
                        }(),
                      ),
                      const SizedBox(height: 22),

                      // ---------- Product ----------
                      _sectionLabel(
                        _category == 'All' ? 'Product' : 'Product ($_category)',
                        Icons.inventory_2_outlined,
                        AppColors.green,
                      ),
                      const SizedBox(height: 8),
                      _selectField(
                        value: _selectedProducts.isEmpty
                            ? 'Select a product'
                            : _selectedProducts.length == 1
                            ? _selectedProducts.first.name
                            : '${_selectedProducts.length} products selected',
                        isPlaceholder: _selectedProducts.isEmpty,
                        accent: AppColors.regionCyan,
                        onTap: _pickProduct,
                      ),
                      // for (final p in _selectedProducts) ...[
                      for (int i = 0; i < _selectedProducts.length; i++) ...[
                        const SizedBox(height: 12),
                        Builder(
                          builder: (_) {
                            final p = _selectedProducts[i];
                            final accent = i.isEven
                                ? AppColors.aiBlue
                                : AppColors.dayEndIconBg;
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: accent, width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontFamily: AppFonts.display,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                     
                                    ),
                                  ),
                                  Text(
                                    p.category.name, // need check
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold
                                      
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '₹${p.price.toStringAsFixed(2)}',
                                    style:  TextStyle(
                                      fontFamily: AppFonts.mono,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: accent,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ---------- Bottom button ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: AppWidgets.buildButton(
                  'Submit →',
                  onTap: _proceed,
                  variant: AppButtonVariant.gradient,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  final List<Product> products;
  final List<Product> initiallySelected;
  const _ProductPickerSheet({
    required this.products,
    this.initiallySelected = const [],
  });

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final _searchController = TextEditingController();
  late final Set<Product> _checked = {...widget.initiallySelected};

  void _toggle(Product p) => setState(() {
    _checked.contains(p) ? _checked.remove(p) : _checked.add(p);
  });

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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: AppBackground(child: SizedBox.expand())),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
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
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.ink,
                          ),
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
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),

                                itemBuilder: (context, i) {
                                  final p = _filtered[i];

                                  final accent = i.isEven
                                      ? AppColors.aiBlue
                                      : AppColors.dayEndIconBg;
                                  return Material(
                                    color: AppColors.white.withValues(
                                      alpha: 0.85,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: accent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 2,
                                          ),
                                      title: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 12,
                                          bottom: 12,
                                        ),
                                        child: Text(
                                          p.name,
                                          style: const TextStyle(
                                            fontFamily: AppFonts.display,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.regionBlue,
                                          ),
                                        ),
                                      ),
                                      // subtitle: Text(
                                      //   p.category.name,
                                      //   style: const TextStyle(
                                      //     fontSize: 10.5,
                                      //     color: AppColors.red,
                                      //   ),
                                      // ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '₹${p.price.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontFamily: AppFonts.mono,
                                              fontSize: 12,
                                              color: AppColors.regionCyan,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Checkbox(
                                            value: _checked.contains(p),
                                            onChanged: (_) => _toggle(p),
                                            side: const BorderSide(
                                              color: AppColors.regionBlue,
                                              width: 1.6,
                                            ),
                                            activeColor: AppColors.regionBlue,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                      onTap: () => _toggle(p),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),
                      AppWidgets.buildButton(
                        _checked.isEmpty
                            ? 'Done →'
                            : 'Done (${_checked.length}) →',
                        onTap: () => Navigator.pop(context, _checked.toList()),
                        variant: AppButtonVariant.gradient,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
