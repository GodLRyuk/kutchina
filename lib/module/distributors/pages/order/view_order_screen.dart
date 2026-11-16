import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';

import 'package:kutchina/core/provider/auth_provider.dart';
import 'package:kutchina/core/services/target_milestone_notification_service.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_bottom_nav.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/core/widgets/skeleton_loader.dart';

import 'package:kutchina/module/distributors/models/orders_model.dart';
import 'package:kutchina/module/distributors/pages/order/order_detail_screen.dart';
import 'package:kutchina/module/distributors/pages/order/view_order_screen_service.dart';
import 'package:kutchina/module/salesModule/pages/notification/notification.dart';
import 'package:provider/provider.dart';

class ViewOrderListScreen extends StatefulWidget {
  final bool showBottomNav;

  const ViewOrderListScreen({super.key, this.showBottomNav = true});

  @override
  State<ViewOrderListScreen> createState() => _ViewOrderListScreenState();
}

class _ViewOrderListScreenState extends State<ViewOrderListScreen> {
  static const int _pageSize = 10;
  List<OrdersModel> _orders = [];

  List<List<OrdersModel>> get _groups {
    final map = <String, List<OrdersModel>>{};
    for (final o in _orders) {
      map.putIfAbsent(o.orderNumber, () => []).add(o);
    }
    return map.values.toList();
  }

  bool _loading = false;
  String? _error;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  int _visibleCount = _pageSize;
  bool _loadingMore = false;

  List<TargetMilestoneNotification> _targetNotifications = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final nearBottom =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200;
    if (nearBottom && !_loadingMore && _visibleCount < _groups.length) {
      _loadMore();
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final data = staticOrders;
      if (!mounted) return;
      setState(() {
        _orders = data;
        _visibleCount = _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load orders';
        _loading = false;
      });
    }
  }

  Future<void> _searchOrders([String? _]) async {
    final search = _searchController.text.trim().toLowerCase();
    if (search.isEmpty) return _loadOrders();
    setState(() {
      _orders = staticOrders
          .where((o) => o.orderNumber.toLowerCase().contains(search))
          .toList();
      _visibleCount = _pageSize;
    });
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

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _visibleCount = (_visibleCount + _pageSize).clamp(0, _groups.length);
      _loadingMore = false;
    });
  }

  
  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 22, top: 8),
                child: Text(
                  'Your Orders',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.commandCentreText,
                  ),
                ),
              ),
              _searchBar(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? Container(
              color: Colors.white,
              child: const AppBottomNav(backgroundColor: Colors.white),
            )
          : null,
    );
  }

  // Order number search bar
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          onSubmitted: (v) => _searchOrders(v),
          decoration: InputDecoration(
            hintText: 'Search by order number',
            border: InputBorder.none,
            prefixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _searchOrders(),
            ),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                      _searchOrders(); // back to full list
                    },
                  ),
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [SkeletonLoader(rows: 5)],
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
              onPressed: _searchOrders,
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
      final hasSearch = _searchController.text.trim().isNotEmpty;

      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Center(
            child: Text(
              hasSearch ? 'No orders found for your search' : 'No orders found',
              style: const TextStyle(color: AppColors.steel),
            ),
          ),
        ],
      );
    }

    final groups = _groups;
    final visibleOrders = groups.take(_visibleCount).toList();
    final hasMore = _visibleCount < groups.length;

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
        final accent = i.isEven ? AppColors.aiBlue : AppColors.dayEndIconBg;
        return _orderCard(visibleOrders[i], accent);
      },
    );
  }

  Widget _orderCard(List<OrdersModel> group, Color accent) {
    final o = group.first;
    final total = group.fold<double>(0, (sum, x) => sum + (x.price ?? 0));
    return Container(
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent, width: 1.5),
      ),
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

            // Product names
            for (final p in group)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.productName,
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      'Qty ${_formatQty(p.quantity)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                ),
              ),

            // Channel chip
            if ((o.filterType ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  AppWidgets.buildBadge(
                    o.filterType!,
                    AppColors.aiBlueChipBg,
                    AppColors.aiBlue,
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.line),
            const SizedBox(height: 10),

            // Invoice + total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(orders: group),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, size: 16, color: accent),
                        const SizedBox(width: 4),
                        Text(
                          'View invoice',
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontSize: 11, color: AppColors.steel),
                    ),
                    Text(
                      total > 0
                          ? '₹${total.toStringAsFixed(2)}'
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
}
