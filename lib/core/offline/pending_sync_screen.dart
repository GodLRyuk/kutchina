import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/offline/connectivity_service.dart';
import 'package:kutchina/core/offline/offline_store.dart';
import 'package:kutchina/core/offline/sync_service.dart';

/// Lists everything saved on the phone that has not reached the server yet.
/// Failed items (server rejected them) can be retried or discarded.
class PendingSyncScreen extends StatefulWidget {
  const PendingSyncScreen({super.key});

  @override
  State<PendingSyncScreen> createState() => _PendingSyncScreenState();
}

class _PendingSyncScreenState extends State<PendingSyncScreen> {
  List<PendingRequest> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    SyncService.instance.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    SyncService.instance.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final list = await SyncService.instance.listAll();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  IconData _icon(String kind) {
    switch (kind) {
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'visit':
        return Icons.storefront_outlined;
      case 'attendance':
        return Icons.how_to_reg_outlined;
      default:
        return Icons.upload_outlined;
    }
  }

  String _time(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)}  ${two(t.hour)}:${two(t.minute)}';
  }

  Future<void> _confirmDiscard(PendingRequest r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard this item?'),
        content: Text(
          '"${r.label}" will be deleted from this phone and never sent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Discard',
              style: TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await SyncService.instance.discard(r);
  }

  @override
  Widget build(BuildContext context) {
    final online = ConnectivityService.instance.isOnline;
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppBar(
        title: const Text(
          'Offline queue',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sync now',
            icon: const Icon(Icons.sync),
            onPressed: () => SyncService.instance.syncNow(manual: true),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_done_outlined,
                      size: 48,
                      color: AppColors.green,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      online
                          ? 'Everything is synced.'
                          : 'Nothing waiting. You are offline.',
                      style: const TextStyle(color: AppColors.steel),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => SyncService.instance.syncNow(manual: true),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _card(_items[i]),
              ),
            ),
    );
  }

  Widget _card(PendingRequest r) {
    final failed = r.isFailed;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: failed ? AppColors.red : AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _icon(r.kind),
                size: 20,
                color: failed ? AppColors.red : AppColors.navActive,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  r.label,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: failed ? AppColors.redLight : AppColors.amberLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  failed ? 'Failed' : 'Waiting',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: failed ? AppColors.red : AppColors.amberDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Saved ${_time(r.createdAt)}'
            '${r.filePaths.isNotEmpty ? '  •  ${r.filePaths.length} photo(s)' : ''}',
            style: const TextStyle(fontSize: 11, color: AppColors.steel),
          ),
          if (r.lastError != null) ...[
            const SizedBox(height: 6),
            Text(
              r.lastError!,
              style: TextStyle(
                fontSize: 11.5,
                color: failed ? AppColors.red : AppColors.steel,
              ),
            ),
          ],
          if (failed) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _confirmDiscard(r),
                  child: const Text(
                    'Discard',
                    style: TextStyle(color: AppColors.red),
                  ),
                ),
                TextButton(
                  onPressed: () => SyncService.instance.retry(r),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
