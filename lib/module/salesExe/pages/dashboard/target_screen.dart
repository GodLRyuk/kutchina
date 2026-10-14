import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';

class TargetScreen extends StatefulWidget {
  const TargetScreen({super.key});

  @override
  State<TargetScreen> createState() => _TargetScreenState();
}

class _TargetScreenState extends State<TargetScreen> {
  bool _targetLoading = true;
  String? _error;
  List<MonthlyTarget> _targets = [];

  @override
  void initState() {
    super.initState();
    _loadTarget();
  }

  Future<void> _loadTarget() async {
    setState(() {
      if (_targets.isEmpty) _targetLoading = true;
      _error = null;
    });
    try {
      final response = await OrderService.fetchAllTargets();
      if (!mounted) return;
      setState(() {
        _targets = response;
        _targetLoading = false;
      });
    } catch (e) {
      debugPrint("error is $e");
      if (!mounted) return;
      setState(() {
        _targets = [];
        _error = e.toString();
        _targetLoading = false;
      });
    }
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
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => AppWidgets.toast(context, 'No new notifications'),
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
                  'Your Targets',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.commandCentreText,
                  ),
                ),
              ),
              Expanded(child: _displayTargetDesign()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _displayTargetDesign() {
    if (_targetLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_targets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.flag_outlined,
                size: 48,
                color: AppColors.steelLight,
              ),
              const SizedBox(height: 12),
              Text(
                _error != null
                    ? 'Could not load targets'
                    : 'No target assigned yet',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.steel),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadTarget,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final money = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return RefreshIndicator(
      onRefresh: _loadTarget,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _targets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) => _TargetCard(
          target: _targets[i],
          money: money,
          accent: i.isEven ? AppColors.aiBlue : AppColors.dayEndIconBg,
        ),
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  final MonthlyTarget target;
  final NumberFormat money;
  final Color accent;

  const _TargetCard({
    required this.target,
    required this.money,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final monthText = target.month != null
        ? DateFormat('MMMM yyyy').format(target.month!)
        : '-';
    final endText = target.targetDate != null
        ? DateFormat('dd MMM yyyy').format(target.targetDate!)
        : '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + month + amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                ),
                child: const Icon(
                  Icons.track_changes,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthText,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      money.format(target.amount),
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.commandCentreText,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: AppColors.line),
          const SizedBox(height: 12),

          // Target end date
          Row(
            children: [
              Icon(Icons.event_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              const Text(
                'Target end date',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12.5,
                  color: AppColors.steel,
                ),
              ),
              const Spacer(),
              Text(
                endText,
                style: const TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
