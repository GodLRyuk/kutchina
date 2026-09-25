import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/core/services/api_services.dart';
import 'package:kutchina/module/salesExe/models/order_model.dart';
import 'package:kutchina/module/salesExe/pages/order/order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  static const int _pageSize = 10;

  List<OrderEntry> _orders = [];
  bool _loading = false;
  String? _error;

  // ---- Client-side pagination ----
  final ScrollController _scrollController = ScrollController();
  int _visibleCount = _pageSize;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadOrders();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final nearBottom =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200;
    if (nearBottom && !_loadingMore && _visibleCount < _orders.length) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    // Small delay so the loader is visible rather than an instant snap —
    // remove this if/when this becomes a real paginated API call.
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _visibleCount = (_visibleCount + _pageSize).clamp(0, _orders.length);
      _loadingMore = false;
    });
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await OrderService.fetchOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _visibleCount = _pageSize.clamp(0, orders.length);
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load orders';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppTopBar.simple(title: 'My Orders'),
      body: RefreshIndicator(onRefresh: _loadOrders, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading && _orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.commandCentreText),
      );
    }
    if (_error != null && _orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.error_outline,
            size: 40,
            color: AppColors.red.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.redDark, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _loadOrders,
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.bold,
                  color: AppColors.red,
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (_orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          Center(
            child: Text(
              'No orders yet',
              style: TextStyle(color: AppColors.steel),
            ),
          ),
        ],
      );
    }

    final visibleOrders = _orders.take(_visibleCount).toList();
    final hasMore = _visibleCount < _orders.length;

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: visibleOrders.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i >= visibleOrders.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.commandCentreText,
                ),
              ),
            ),
          );
        }
        return _orderCard(visibleOrders[i]);
      },
    );
  }

  Widget _orderCard(OrderEntry o) {
    return InkWell(
      borderRadius: BorderRadius.circular(
        AppRadius.md,
      ), // match AppWidgets.buildCard's radius
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailScreen(order: o)),
        );
      },
      child: AppWidgets.buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: order number + status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  o.orderNumber,
                  style: const TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.steel,
                  ),
                ),
                _statusBadge(o.orderStatus),
              ],
            ),
            const SizedBox(height: 8),

            // Product name
            Text(
              o.productName,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),

            // Qty + date
            Text(
              'Qty ${_formatQty(o.quantity)}'
              '${o.createdAt != null ? ' · ${_formatDate(o.createdAt!)}' : ''}',
              style: const TextStyle(fontSize: 11, color: AppColors.steel),
            ),

            // Channel / filter / warranty chips
            if (o.userType.isNotEmpty ||
                o.filterType != null ||
                o.warranty != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (o.userType.isNotEmpty)
                    AppWidgets.buildBadge(
                      o.orderTypeLabel,
                      AppColors.aiBlueChipBg,
                      AppColors.aiBlue,
                    ),
                  if (o.filterType != null)
                    AppWidgets.buildBadge(
                      o.filterType!,
                      AppColors.ash,
                      AppColors.steel,
                    ),
                  if (o.warranty != null)
                    AppWidgets.buildBadge(
                      '${o.warranty} warranty',
                      AppColors.greenLight,
                      AppColors.green,
                    ),
                ],
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.line),
            const SizedBox(height: 10),

            // Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 11, color: AppColors.steel),
                ),
                Text(
                  o.price != null
                      ? '₹${o.total.toStringAsFixed(0)}'
                      : 'Price pending',
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: o.price != null
                        ? AppColors.commandCentreText
                        : AppColors.steel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'placed':
        bg = AppColors.aiBlueChipBg;
        fg = AppColors.aiBlue;
        break;
      case 'delivered':
      case 'completed':
        bg = AppColors.greenLight;
        fg = AppColors.green;
        break;
      case 'cancelled':
      case 'rejected':
        bg = AppColors.redLight;
        fg = AppColors.red;
        break;
      default:
        bg = AppColors.ash;
        fg = AppColors.steel;
    }
    return AppWidgets.buildBadge(status, bg, fg);
  }

  String _formatQty(double q) {
    return q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toString();
  }

  String _formatDate(DateTime d) {
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
    return '${months[d.month - 1]} ${d.day}';
  }
}
