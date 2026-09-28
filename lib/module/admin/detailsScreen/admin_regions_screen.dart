import 'package:flutter/foundation.dart';
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

/// Sales (orders) for one region, from
/// GET /api/v1/orders/regions/{id}/sales/?page=&page_size=
class AdminRegionSalesScreen extends StatefulWidget {
  final Zone zone;
  final Color color;

  const AdminRegionSalesScreen({
    super.key,
    required this.zone,
    required this.color,
  });

  @override
  State<AdminRegionSalesScreen> createState() => _AdminRegionSalesScreenState();
}

class _AdminRegionSalesScreenState extends State<AdminRegionSalesScreen> {
  static const int _pageSize = 10;

  final List<SalesOrder> _orders = [];
  String _regionName = '';
  int _count = 0;
  int _page = 1;
  bool _hasMore = false;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _loadError;

  String get _title => _regionName.isNotEmpty ? _regionName : widget.zone.name;

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
      final data = await RegionOrdersApi.fetch(
        regionId: widget.zone.id,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _orders
          ..clear()
          ..addAll(data.orders);
        _regionName = data.regionName;
        _count = data.count;
        _hasMore = data.hasMore;
        _page = 1;
      });
    } on ApiException catch (error) {
      if (kDebugMode) debugPrint('[RegionSales] ApiException: $error');
      if (!mounted) return;
      setState(() => _loadError = error.message);
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[RegionSales] unexpected error: $error\n$stack');
      }
      if (!mounted) return;
      setState(
        () => _loadError = kDebugMode
            ? 'Unable to load sales\n$error'
            : 'Unable to load sales',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final next = _page + 1;
      final data = await RegionOrdersApi.fetch(
        regionId: widget.zone.id,
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
      _snack('Unable to load more sales');
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
      appBar: AppTopBar.simple(title: _title),
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
      _sectionTitle('Sales', _count),
      const SizedBox(height: 10),
      if (_orders.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Column(
              children: [
                const Text(
                  'No sales in this region',
                  style: TextStyle(color: AppColors.steel),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 6),
                  Text(
                    'region id: ${widget.zone.id}  •  see [RegionSales] in console',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.steelLight,
                    ),
                  ),
                ],
              ],
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
                  child: const Icon(
                    Icons.map_outlined,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title,
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
                        'Sales in this region',
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
                        if (o.createdBy.isNotEmpty)
                          _chip(
                            'By user #${o.createdBy}',
                            color: AppColors.regionBlue,
                            icon: Icons.person_outline,
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
