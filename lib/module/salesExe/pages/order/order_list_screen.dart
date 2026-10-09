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

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  int _visibleCount = _pageSize;
  bool _loadingMore = false;

  // ---- Filter type: 'O' = Order number, 'R' = Retailer, 'D' = Distributor ----
  String _visitType = 'O';
  String? _chosenFilter; // null until the user picks from the filter menu
  final GlobalKey<PopupMenuButtonState<String>> _filterMenuKey = GlobalKey();
  bool _loadingEntities = false;
  String? _entityError;
  List<dynamic> _distributors = [];
  List<dynamic> _retailers = [];

  // Selected retailer / distributor (its id goes to the search API)
  String? _selectedEntityId;
  String? _selectedEntityName;

  String _entityId(dynamic e) => (e as dynamic).id as String;
  String _entityName(dynamic e) => (e as dynamic).name as String;

  // Group by order number
  List<List<OrderEntry>> get _groups {
    final map = <String, List<OrderEntry>>{};
    for (final o in _orders) {
      map.putIfAbsent(o.orderNumber.trim(), () => []).add(o);
    }
    return map.values.toList();
  }

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

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _visibleCount = (_visibleCount + _pageSize).clamp(0, _groups.length);
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
        _visibleCount = _pageSize;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
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

  // Search by order number OR the selected retailer/distributor id.
  Future<void> _searchOrders([String? _]) async {
   
    final search = _searchController.text.trim();

    if (search.isEmpty && _selectedEntityId == null) {
      return _loadOrders();
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      print("i am here");
      final orders = await OrderService.searchOrders(
        search,
        entityId: _selectedEntityId,
        // only send R / D when a name is selected
        entityType: _selectedEntityId == null ? null : _visitType,
      );
      if (!mounted) return;
      if (search != _searchController.text.trim()) return; // stale response

      if (orders.isEmpty) {
        setState(() {
          _orders = [];
          _visibleCount = 0;
          _loading = false;
          _error = null;
        });
        return;
      }
      setState(() {
        _orders = orders;
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

  Future<void> _loadEntities() async {
    final type = _visitType;
    if (type == 'O') return;
    setState(() {
      _loadingEntities = true;
      _entityError = null;
    });
    try {
      if (type == 'D') {
        _distributors = await MastersApi.fetchDistributors();
      } else if (type == 'R') {
        _retailers = await MastersApi.fetchRetailers();
      }
      if (!mounted) return;
      setState(() => _loadingEntities = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _entityError =
            'Could not load ${type == 'D' ? 'Distributors' : 'Retailers'}';
        _loadingEntities = false;
      });
    }
  }

  // Bottom sheet showing the respective list (Retailers or Distributors)
  Future<void> _showEntitySheet() async {
    if (_loadingEntities || _visitType == 'O') return;
    final isDist = _visitType == 'D';
    final List<dynamic> list = isDist ? _distributors : _retailers;

    if (_entityError != null || list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _entityError ?? 'No ${isDist ? 'distributors' : 'retailers'} found',
          ),
        ),
      );
      return;
    }

    final picked = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String q = '';
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final filtered = list
                .where(
                  (e) => _entityName(e).toLowerCase().contains(q.toLowerCase()),
                )
                .toList();
            return SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.7,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isDist ? 'Select distributor' : 'Select retailer',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search name',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: AppColors.ash,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) => setSheet(() => q = v),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) => ListTile(
                          title: Text(_entityName(filtered[i])),
                          selected: _entityId(filtered[i]) == _selectedEntityId,
                          onTap: () => Navigator.pop(ctx, filtered[i]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedEntityId = _entityId(picked);
        _selectedEntityName = _entityName(picked);
      });
      _searchOrders(); // id is sent to the search API here
    }
  }

  // Filter menu selection: Order number / Retailer name / Distributor name
  Future<void> _onFilterTypeTap(String type) async {
    if (_chosenFilter == type) {
      if (type != 'O') _showEntitySheet();
      return;
    }
    setState(() {
      _visitType = type;
      _chosenFilter = type;
      _selectedEntityId = null;
      _selectedEntityName = null;
      _searchController.clear();
    });
    _loadOrders(); // fresh full list for the new filter type
    if (type == 'O') return;
    await _loadEntities();
    if (!mounted) return;
    _showEntitySheet(); // show the list straight away
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppTopBar.simple(title: 'My Orders'),
      body: Column(
        children: [
          _searchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrders,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  static const _filterLabels = {
    'O': 'Order number',
    'R': 'Retailer ',
    'D': 'Distributor',
  };

  // Search bar + round filter icon, with a chip for the active filter
  Widget _searchBar() {
    final isOrder = _visitType == 'O';
    final isDist = _visitType == 'D';
    final hasValue = _selectedEntityName != null;
    final orderHint = _chosenFilter == null
        ? 'Search here'
        : 'Enter order number';
    final entityHint = isDist ? 'Select distributor' : 'Select retailer';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ---- Search field ----
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: isOrder
                      ? TextField(
                          controller: _searchController,
                          // typing is locked until a filter is chosen;
                          // tapping the bar opens the filter menu instead
                          readOnly: _chosenFilter == null,
                          showCursor: _chosenFilter != null,
                          onTap: _chosenFilter == null
                              ? () => _filterMenuKey.currentState
                                    ?.showButtonMenu()
                              : null,
                          textInputAction: TextInputAction.search,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (v) => _searchOrders(v),
                          decoration: InputDecoration(
                            hintText: orderHint,
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
                                      _searchOrders();
                                    },
                                  ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                          ),
                        )
                      : InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: _showEntitySheet,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.search),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedEntityName ?? entityHint,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: hasValue
                                          ? Colors.black87
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                if (_loadingEntities)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else if (hasValue)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedEntityId = null;
                                        _selectedEntityName = null;
                                      });
                                      _searchOrders(); // back to full list
                                    },
                                    child: const Icon(Icons.close, size: 20),
                                  )
                                else
                                  const Icon(Icons.keyboard_arrow_down),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // ---- Round filter icon with menu ----
              PopupMenuButton<String>(
                key: _filterMenuKey,
                onSelected: _onFilterTypeTap,
                offset: const Offset(0, 58),
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem<String>(
                    enabled: false,
                    height: 32,
                    child: Text(
                      'Filter by',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                  ..._filterLabels.entries.map(
                    (e) => PopupMenuItem<String>(
                      value: e.key,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: _chosenFilter == e.key
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (_chosenFilter == e.key)
                            const Icon(Icons.check, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.tune, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
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
      final hasSearch =
          _searchController.text.trim().isNotEmpty || _selectedEntityId != null;
        
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 100),
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
        return _orderCard(visibleOrders[i]);
      },
    );
  }

  Widget _orderCard(List<OrderEntry> group) {
    final o = group.first;
    final total = group.fold<double>(0, (sum, x) => sum + (x.price ?? 0));
    return AppWidgets.buildCard(
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
          if (o.userType.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                AppWidgets.buildBadge(
                  o.orderTypeLabel,
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
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 16,
                        color: AppColors.commandCentreText,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'View invoice',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.aiBlue,
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
