import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/core/services/api_services.dart';
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

// ─────────────────────────── screen ───────────────────────────

class AdminSalespersonDetailScreen extends StatefulWidget {
  final AdminUser user;

  const AdminSalespersonDetailScreen({super.key, required this.user});

  @override
  State<AdminSalespersonDetailScreen> createState() =>
      _AdminSalespersonDetailScreenState();
}

class _AdminSalespersonDetailScreenState
    extends State<AdminSalespersonDetailScreen> {
  static const int _pageSize = 10;

  final List<SalesOrder> _orders = [];
  List<SalesProduct> _products = [];
  int _ordersCount = 0;
  int _productsCount = 0;
  int _salesPage = 1;
  bool _hasMore = false;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _loadError;

  static const List<Color> _categoryColors = [
    AppColors.productChimney,
    AppColors.productHobs,
    AppColors.productWaterPurifiers,
    AppColors.productOvens,
  ];

  static const List<IconData> _categoryIcons = [
    Icons.kitchen_outlined,
    Icons.local_fire_department_outlined,
    Icons.water_drop_outlined,
    Icons.microwave_outlined,
  ];

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
      final data = await SalespersonSalesApi.fetch(
        userId: widget.user.id,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _orders
          ..clear()
          ..addAll(data.orders);
        _products = data.products;
        _ordersCount = data.ordersCount;
        _productsCount = data.productsCount;
        _hasMore = data.hasMoreOrders;
        _salesPage = 1;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Unable to load sales data');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final next = _salesPage + 1;
      final data = await SalespersonSalesApi.fetch(
        userId: widget.user.id,
        pageSize: _pageSize,
        salesPage: next,
      );
      if (!mounted) return;
      setState(() {
        _orders.addAll(data.orders);
        _ordersCount = data.ordersCount;
        _hasMore = data.hasMoreOrders;
        _salesPage = next;
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
      backgroundColor: AppColors.ash,
      appBar: const AppTopBar.simple(title: 'Salesperson'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [_hero(), const SizedBox(height: 16), ..._content()],
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

    final partial = _orders.length < _ordersCount;

    return [
      _statsRow(),
      if (partial)
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text(
            'Units and value count ${_orders.length} of $_ordersCount loaded orders',
            style: const TextStyle(fontSize: 10, color: AppColors.steelLight),
          ),
        ),
      const SizedBox(height: 22),
      _sectionTitle('Products', _productsCount, AppColors.regionPurple),
      const SizedBox(height: 10),
      _productsStrip(),
      const SizedBox(height: 22),
      _sectionTitle('Orders', _ordersCount, AppColors.regionBlue),
      const SizedBox(height: 10),
      if (_orders.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'No orders yet',
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
    final u = widget.user;
    final name = u.fullName.isEmpty ? u.userId : u.fullName;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ink, AppColors.regionBlue],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.regionBlue.withValues(alpha: 0.30),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          u.initials,
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _pill(
                                u.userId,
                                mono: true,
                                bg: Colors.white.withValues(alpha: 0.18),
                                fg: Colors.white,
                              ),
                              _pill(
                                u.isActive ? 'Active' : 'Inactive',
                                dot: true,
                                bg: Colors.white.withValues(alpha: 0.18),
                                fg: Colors.white,
                                dotColor: u.isActive
                                    ? const Color(0xFF4ADE80)
                                    : const Color(0xFFFCA5A5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (u.email.isNotEmpty ||
                    u.phone.isNotEmpty ||
                    u.address.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 14),
                  if (u.email.isNotEmpty)
                    _contactRow(Icons.mail_outline, u.email),
                  if (u.phone.isNotEmpty)
                    _contactRow(Icons.phone_outlined, u.phone),
                  if (u.address.isNotEmpty)
                    _contactRow(Icons.location_on_outlined, u.address),
                ],
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

  Widget _pill(
    String text, {
    required Color bg,
    required Color fg,
    bool mono = false,
    bool dot = false,
    Color? dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor ?? fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: mono ? AppFonts.mono : null,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.75)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
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
            value: '$_ordersCount',
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

  // ───────────────────────── sections ─────────────────────────

  Widget _sectionTitle(String title, int count, Color color) {
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

  Widget _productsStrip() {
    if (_products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No products',
          style: TextStyle(fontSize: 12, color: AppColors.steel),
        ),
      );
    }

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _productCard(_products[i]),
      ),
    );
  }

  Widget _productCard(SalesProduct p) {
    final idx = (p.category > 0 ? p.category - 1 : 0) % _categoryColors.length;
    final color = _categoryColors[idx];
    final icon = _categoryIcons[idx];

    return Container(
      width: 158,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const Spacer(),
              if (p.warranty.isNotEmpty)
                Text(
                  p.warranty,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.steelLight,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              p.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            _money(p.price),
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
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
                : 'Load more (${_orders.length} of $_ordersCount)',
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
