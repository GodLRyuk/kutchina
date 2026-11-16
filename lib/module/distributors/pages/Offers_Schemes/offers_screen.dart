import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/provider/auth_provider.dart';
import 'package:kutchina/core/services/target_milestone_notification_service.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/skeleton_loader.dart';
import 'package:kutchina/module/distributors/models/scheme_model.dart';
import 'package:kutchina/module/distributors/pages/Offers_Schemes/offers_elements.dart';
import 'package:kutchina/module/distributors/pages/Offers_Schemes/scheme_service.dart';
import 'package:kutchina/module/distributors/pages/order/new_order_screen.dart';
import 'package:kutchina/module/distributors/pages/order/view_order_screen.dart'
    show ViewOrderListScreen;
import 'package:kutchina/module/salesModule/pages/notification/notification.dart';
import 'package:provider/provider.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  List<TargetMilestoneNotification> _targetNotifications = [];
  SchemeFilter _filter = SchemeFilter.active;

  List<SchemeModel> _schemes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOfferScheme();
  }

  Future<void> _fetchOfferScheme() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await SchemeService.fetchSchemes();
      if (!mounted) return;
      setState(() {
        _schemes = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load schemes';
        _loading = false;
      });
    }
  }

  

  SchemeCardData _toCard(SchemeModel s) {
    final style = switch (s.type) {
      'launch' => (AppColors.regionCyan, Icons.rocket_launch, 'New launch'),
      'volume' => (
        AppColors.regionOrange,
        Icons.card_giftcard,
        'Volume reward',
      ),
      _ => (AppColors.regionBlue, Icons.celebration, 'Festive scheme'),
    };

    final period = s.period;

    return SchemeCardData(
      label: style.$3,
      title: s.title,
      subtitle: s.description ?? '',
      status: switch (period) {
        SchemeFilter.expired => 'Expired',
        SchemeFilter.upcoming => 'Starts soon',
        _ =>
          s.type == 'volume'
              ? '${s.achievedQty ?? 0} of ${s.targetQty ?? 0} done'
              : (s.isEligible ? 'You are eligible ✓' : 'Not eligible'),
      },
      actionText: period == SchemeFilter.active
          ? switch (s.type) {
              'launch' => 'View range',
              'volume' => 'Track',
              _ => 'Order now',
            }
          : '',
      color: style.$1,
      icon: style.$2,
      period: period,
      progress: s.progress,
      // Button navigation
      onAction: () {
        switch (s.type) {
          case 'launch':
          case 'volume':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ViewOrderListScreen()),
            );
            break;
          default:
            showNewOrderSheet(context);
        }
      },
    );
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

  String get _emptyText {
    switch (_filter) {
      case SchemeFilter.active:
        return 'No active schemes right now';
      case SchemeFilter.upcoming:
        return 'No upcoming schemes';
      case SchemeFilter.expired:
        return 'No expired schemes';
    }
  }

  Widget _centerMessage(Widget child) => Padding(
    padding: const EdgeInsets.only(top: 48),
    child: Center(child: child),
  );

  List<Widget> _buildContent() {
    if (_loading) {
      return const [SkeletonLoader(rows: 5)];
    }

    if (_error != null) {
      return [
        _centerMessage(
          Column(
            children: [
              Text(
                _error!,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 14,
                  color: AppColors.steel,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _fetchOfferScheme,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ];
    }

    final visible = _schemes.where((s) => s.period == _filter).toList();

    if (visible.isEmpty) {
      return [
        _centerMessage(
          Text(
            _emptyText,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 14,
              color: AppColors.steel,
            ),
          ),
        ),
      ];
    }

    return [
      for (final s in visible) ...[
        SchemeCard(data: _toCard(s)),
        const SizedBox(height: 12),
      ],
    ];
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
                if (_targetNotifications.any((n) => !n.isRead))
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
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + kToolbarHeight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 22, top: 8),
                child: Text(
                  'Offers & Schemes',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.commandCentreText,
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  backgroundColor: Colors.transparent,
                  onRefresh: _fetchOfferScheme,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      Row(
                        children: [
                          SchemeFilterChip(
                            text: 'Active',
                            selected: _filter == SchemeFilter.active,
                            onTap: () =>
                                setState(() => _filter = SchemeFilter.active),
                          ),
                          SchemeFilterChip(
                            text: 'Upcoming',
                            selected: _filter == SchemeFilter.upcoming,
                            onTap: () =>
                                setState(() => _filter = SchemeFilter.upcoming),
                          ),
                          SchemeFilterChip(
                            text: 'Expired',
                            selected: _filter == SchemeFilter.expired,
                            onTap: () =>
                                setState(() => _filter = SchemeFilter.expired),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._buildContent(),
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
}
