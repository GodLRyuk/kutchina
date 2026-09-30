import 'package:flutter/material.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/offline/connectivity_service.dart';
import 'package:kutchina/core/offline/sync_service.dart';

/// Wraps the whole app (via MaterialApp.builder) and shows a slim status
/// strip on every screen while offline, or while queued items are waiting
/// or syncing. Tap it to open the queue screen.
///
/// The tree shape never changes between states, so the Navigator below it
/// keeps its state when the banner appears or disappears.
class OfflineShell extends StatelessWidget {
  final Widget child;
  final VoidCallback onOpenQueue;

  const OfflineShell({
    super.key,
    required this.child,
    required this.onOpenQueue,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ConnectivityService.instance,
        SyncService.instance,
      ]),
      builder: (context, _) {
        final conn = ConnectivityService.instance;
        final sync = SyncService.instance;
        final info = _describe(conn.isOnline, sync);

        return Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: info == null
                  ? const SizedBox(width: double.infinity)
                  : Material(
                      color: info.color,
                      child: InkWell(
                        onTap: onOpenQueue,
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                if (sync.isSyncing)
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                else
                                  Icon(info.icon, size: 14, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    info.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            Expanded(
              // The banner already covers the status bar, so the screen
              // below must not add its own top inset again.
              child: MediaQuery.removePadding(
                context: context,
                removeTop: info != null,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }

  _BannerInfo? _describe(bool online, SyncService sync) {
    final n = sync.totalCount;
    if (!online) {
      return _BannerInfo(
        n > 0
            ? 'Offline mode  •  $n item${n == 1 ? '' : 's'} waiting to sync'
            : 'Offline mode  •  showing saved data',
        AppColors.amberDark,
        Icons.cloud_off_outlined,
      );
    }
    if (sync.isSyncing) {
      return _BannerInfo(
        'Syncing $n item${n == 1 ? '' : 's'}…',
        AppColors.navActive,
        Icons.sync,
      );
    }
    if (sync.needsLogin && n > 0) {
      return _BannerInfo(
        '$n item${n == 1 ? '' : 's'} waiting. Log in again to sync',
        AppColors.red,
        Icons.lock_outline,
      );
    }
    if (sync.failedCount > 0) {
      return _BannerInfo(
        '${sync.failedCount} item${sync.failedCount == 1 ? '' : 's'} could not be sent. Tap to review',
        AppColors.red,
        Icons.error_outline,
      );
    }
    if (sync.pendingCount > 0) {
      return _BannerInfo(
        '${sync.pendingCount} item${sync.pendingCount == 1 ? '' : 's'} waiting to sync',
        AppColors.navActive,
        Icons.sync,
      );
    }
    if (sync.message != null) {
      return _BannerInfo(sync.message!, AppColors.green, Icons.check_circle);
    }
    return null;
  }
}

class _BannerInfo {
  final String text;
  final Color color;
  final IconData icon;
  const _BannerInfo(this.text, this.color, this.icon);
}
