import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/network/masters_api.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/app_widgets.dart';
import 'package:kutchina/module/salesExe/models/visit_model.dart';

class TodayVisitsScreen extends StatefulWidget {
  const TodayVisitsScreen({super.key});

  @override
  State<TodayVisitsScreen> createState() => _TodayVisitsScreenState();
}

class _TodayVisitsScreenState extends State<TodayVisitsScreen> {
  static const int _pageSize = 10;

  List<VisitEntry> _visits = [];
  final ScrollController _scrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();
  int _visibleCount = _pageSize;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadVisits();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loading || _loadingMore) return;
    if (_scrollController.position.extentAfter < 250 &&
        _visibleCount < _visits.length) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _visibleCount = (_visibleCount + _pageSize).clamp(0, _visits.length);
      _loadingMore = false;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (selected == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(selected.year, selected.month, selected.day);
      _visibleCount = _pageSize;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    await _loadVisits();
  }

  Future<void> _loadVisits() async {
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
    });
    try {
      final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final visits = await VisitService.fetchAllVisits(date: date);
      if (!mounted) return;
      setState(() {
        _visits = visits;
        _visibleCount = _pageSize;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load visits.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Your Visits',
        centerImage: const AssetImage('assets/images/logo.jpg'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadVisits,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(DateFormat('d MMM yyyy').format(_selectedDate)),
                ),
              ),
            ),
            Expanded(child: _buildVisitList()),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitList() {
    if (_loading) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 240,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  TextButton(
                    onPressed: _loadVisits,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    if (_visits.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 280,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.event_busy_outlined,
                    size: 42,
                    color: AppColors.steelLight,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No visits recorded on ${DateFormat('d MMM yyyy').format(_selectedDate)}.',
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final visibleCount = _visibleCount.clamp(0, _visits.length);
    final hasMore = visibleCount < _visits.length;
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: visibleCount + (hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= visibleCount) {
          return _loadingMore
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : const SizedBox(height: 1);
        }
        return _visitTile(_visits[index]);
      },
    );
  }

  Widget _visitTile(VisitEntry visit) {
    final status = visit.syncFailed
        ? 'Sync failed'
        : visit.isPendingSync
        ? 'Pending sync'
        : visit.timeLabel.isEmpty
        ? 'Today'
        : visit.timeLabel;
    final statusColor = visit.syncFailed
        ? AppColors.redDark
        : visit.isPendingSync
        ? AppColors.amberDark
        : AppColors.regionCyan;
    final statusBackground = visit.syncFailed
        ? AppColors.redLight
        : visit.isPendingSync
        ? AppColors.amberLight
        : const Color(0xFFE4F8F7);

    return AppWidgets.buildCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.aiBlueBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.regionBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        visit.visitorName.isEmpty
                            ? 'Dealer visit'
                            : visit.visitorName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (visit.purpose.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    visit.purpose,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.steel,
                    ),
                  ),
                ],
                if (visit.address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    visit.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.steel,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
