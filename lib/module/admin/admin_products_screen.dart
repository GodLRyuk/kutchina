import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_bar.dart';

// ─────────────────────────── helpers ───────────────────────────

/// Indian digit grouping: 1234567 -> ₹12,34,567
String _money(double v) {
  final n = v.round();
  final s = n.abs().toString();
  String out;
  if (s.length <= 3) {
    out = s;
  } else {
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    out = '${parts.join(',')},$last3';
  }
  return '${n < 0 ? '-' : ''}₹$out';
}

/// Compact form for stat tiles: ₹1.2Cr / ₹4.5L / ₹8.1K
String _compactMoney(double v) {
  if (v.abs() >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
  if (v.abs() >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
  if (v.abs() >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
  return '₹${v.toStringAsFixed(0)}';
}

String _qty(double q) =>
    q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

String _fmtDate(DateTime? d) {
  if (d == null) return '';
  final l = d.toLocal();
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
  final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
  final min = l.minute.toString().padLeft(2, '0');
  final ap = l.hour >= 12 ? 'PM' : 'AM';
  return '${l.day} ${months[l.month - 1]} ${l.year}, $h:$min $ap';
}

// ─────────────────────── categories list screen ───────────────────────

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _searchController = TextEditingController();
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _loadError;

  static const List<Color> _colors = [
    AppColors.productChimney,
    AppColors.productHobs,
    AppColors.productWaterPurifiers,
    AppColors.productOvens,
  ];

  static const List<IconData> _icons = [
    Icons.kitchen_outlined,
    Icons.local_fire_department_outlined,
    Icons.water_drop_outlined,
    Icons.microwave_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final data = await MastersApi.fetchCategories();
      if (!mounted) return;
      setState(() => _categories = data);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Unable to load categories');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Categories filtered by the search box. Keeps the original index so
  /// each category keeps the same color/icon while filtering.
  List<MapEntry<int, Category>> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    final entries = _categories.asMap().entries.toList();
    if (query.isEmpty) return entries;
    return entries
        .where((e) => e.value.name.toLowerCase().contains(query))
        .toList();
  }

  void _openCategory(Category category, Color color, IconData icon) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminCategoryProductsScreen(
          category: category,
          color: color,
          icon: icon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: false,
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar.brand(
        showBackButton: true,
        centerImage: AssetImage('assets/images/logo.jpg'),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Products',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.commandCentreText,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Select a category to view its orders',
                  style: TextStyle(fontSize: 12, color: AppColors.steel),
                ),
                const SizedBox(height: 14),
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
                      hintText: 'Search categories',
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
                const SizedBox(height: 14),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.steel),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadCategories, child: const Text('Retry')),
          ],
        ),
      );
    }

    final items = _filtered;
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No categories found',
          style: TextStyle(color: AppColors.steel),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final entry = items[i];
          return _categoryCard(entry.value, entry.key);
        },
      ),
    );
  }

  Widget _categoryCard(Category category, int index) {
    final color = _colors[index % _colors.length];
    final icon = _icons[index % _icons.length];

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _openCategory(category, color, icon),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.steelLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── category orders screen ───────────────────────

/// Orders placed for products in one category, from
/// GET /api/v1/masters/categories/{id}/products/?page=&page_size=
class AdminCategoryProductsScreen extends StatefulWidget {
  final Category category;
  final Color color;
  final IconData icon;

  const AdminCategoryProductsScreen({
    super.key,
    required this.category,
    required this.color,
    required this.icon,
  });

  @override
  State<AdminCategoryProductsScreen> createState() =>
      _AdminCategoryProductsScreenState();
}

class _AdminCategoryProductsScreenState
    extends State<AdminCategoryProductsScreen> {
  static const int _pageSize = 10;

  final List<SalesOrder> _orders = [];
  int _count = 0;
  int _page = 1;
  bool _hasMore = false;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final data = await CategoryOrdersApi.fetch(
        categoryId: widget.category.id,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _orders
          ..clear()
          ..addAll(data.orders);
        _count = data.count;
        _hasMore = data.hasMore;
        _page = 1;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Unable to load orders');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final next = _page + 1;
      final data = await CategoryOrdersApi.fetch(
        categoryId: widget.category.id,
        page: next,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _orders.addAll(data.orders);
        _count = data.count;
        _hasMore = data.hasMore;
        _page = next;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      _snack(error.message);
    } catch (_) {
      if (!mounted) return;
      _snack('Unable to load more orders');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Totals over the orders loaded so far.
  double get _loadedUnits => _orders.fold(0.0, (a, o) => a + o.quantity);
  double get _loadedValue => _orders.fold(0.0, (a, o) => a + o.total);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: false,
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar.brand(
        showBackButton: true,
        centerImage: AssetImage('assets/images/logo.jpg'),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.category.name,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.commandCentreText,
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                    children: [
                      _hero(),
                      const SizedBox(height: 16),
                      ..._content(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content() {
    if (_isLoading) {
      return const [
        SizedBox(height: 48),
        Center(child: CircularProgressIndicator()),
      ];
    }

    if (_loadError != null) {
      return [
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.steel),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      ];
    }

    final partial = _orders.length < _count;

    return [
      _statsRow(),
      if (partial)
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text(
            'Units and value count ${_orders.length} of $_count loaded orders',
            style: const TextStyle(fontSize: 10, color: AppColors.steelLight),
          ),
        ),
      const SizedBox(height: 22),
      _sectionTitle('Orders', _count),
      const SizedBox(height: 10),
      if (_orders.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'No orders in this category',
              style: TextStyle(color: AppColors.steel),
            ),
          ),
        )
      else
        for (final o in _orders) ...[_orderCard(o), const SizedBox(height: 10)],
      if (_hasMore) _loadMoreButton(),
    ];
  }

  // ───────────────────────── hero ─────────────────────────

  Widget _hero() {
    final color = widget.color;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ink, color],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(right: -40, top: -40, child: _circle(150, 0.07)),
          Positioned(right: 30, bottom: -50, child: _circle(110, 0.06)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(widget.icon, size: 28, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Orders placed in this category',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }

  // ───────────────────────── stats ─────────────────────────

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(
          child: _statTile(
            icon: Icons.receipt_long_outlined,
            label: 'Orders',
            value: '$_count',
            color: AppColors.regionBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            icon: Icons.inventory_2_outlined,
            label: 'Units',
            value: _qty(_loadedUnits),
            color: AppColors.regionOrange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            icon: Icons.payments_outlined,
            label: 'Value',
            value: _compactMoney(_loadedValue),
            color: AppColors.regionCyan,
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: AppColors.steel),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, int count) {
    final color = widget.color;
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── orders ─────────────────────────

  Widget _orderCard(SalesOrder o) {
    final isRetailer = o.userType == 'R';
    final isDistributor = o.userType == 'D';
    final typeColor = isRetailer
        ? AppColors.regionCyan
        : isDistributor
        ? AppColors.regionPurple
        : AppColors.steel;
    final typeLabel = isRetailer
        ? 'Retailer'
        : isDistributor
        ? 'Distributor'
        : o.userType;
    final typeIcon = isDistributor
        ? Icons.local_shipping_outlined
        : Icons.storefront_outlined;

    final extras = [
      if (o.filterType.isNotEmpty) 'Filter: ${o.filterType}',
      if (o.warranty.isNotEmpty) 'Warranty: ${o.warranty}',
    ].join('  •  ');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: typeColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            o.orderNumber,
                            style: const TextStyle(
                              fontFamily: AppFonts.mono,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.steel,
                            ),
                          ),
                        ),
                        Text(
                          _fmtDate(o.createdAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.steelLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            o.productName,
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _money(o.total),
                              style: const TextStyle(
                                fontFamily: AppFonts.mono,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              '${_qty(o.quantity)} × ${_money(o.price)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.steel,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _chip(typeLabel, color: typeColor, icon: typeIcon),
                        if (o.status.isNotEmpty)
                          _chip(
                            o.status,
                            color: AppColors.regionOrange,
                            icon: Icons.check_circle_outline,
                          ),
                      ],
                    ),
                    if (extras.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        extras,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.steel,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, {required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadMoreButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _isLoadingMore ? null : _loadMore,
          icon: _isLoadingMore
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.expand_more, size: 18),
          label: Text(
            _isLoadingMore
                ? 'Loading...'
                : 'Load more (${_orders.length} of $_count)',
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: AppColors.line, width: 1.3),
            foregroundColor: AppColors.ink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      ),
    );
  }
}
