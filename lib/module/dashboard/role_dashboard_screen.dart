import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kutchina/core/auth/app_roles.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/provider/auth_provider.dart';
import 'package:kutchina/core/services/target_milestone_notification_service.dart';
import 'package:kutchina/core/widgets/app_background.dart';
import 'package:kutchina/core/widgets/app_bar.dart';
import 'package:kutchina/core/widgets/coming_soon_tab.dart';
import 'package:kutchina/module/dashboard/dashboard_controller.dart';
import 'package:kutchina/module/dashboard/dashboard_profile.dart';
import 'package:kutchina/module/dashboard/dashboard_profile_factory.dart';
import 'package:kutchina/module/salesExe/pages/dashboard/dashboard_screen.dart';
import 'package:kutchina/module/salesExe/pages/notification/notification.dart';
import 'package:kutchina/module/salesExe/pages/profile/profile.dart';
import 'package:provider/provider.dart';

class RoleDashboardScreen extends StatefulWidget {
  const RoleDashboardScreen({super.key});

  @override
  State<RoleDashboardScreen> createState() => _RoleDashboardScreenState();
}

class _RoleDashboardScreenState extends State<RoleDashboardScreen> {
  late final AppRole _role;
  late final DashboardProfile _profile;
  late final DashboardController _controller;
  List<TargetMilestoneNotification> _targetNotifications = [];

  @override
  void initState() {
    super.initState();
    _role = context.read<AuthProvider>().role;
    _profile = forRole(_role);
    _controller = _profile.createController();
    _controller.load();
    _loadTargetNotifications();
  }

  Future<void> _loadTargetNotifications() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) return;
    final notifications = await TargetMilestoneNotificationService.load(userId);
    if (!mounted) return;
    setState(() => _targetNotifications = notifications);
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_role == AppRole.salesExec) {
      return DashboardScreen(showBottomNav: false);
    }

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final user = context.watch<AuthProvider>().user;
        final actions = _profile.quickActions(context, _controller);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemStatusBarContrastEnforced: false,
            systemNavigationBarContrastEnforced: false,
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            // extendBody: true,
            extendBody: false,
            extendBodyBehindAppBar: true,
            appBar: AppTopBar.brand(
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
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + kToolbarHeight,
                ),
                child: RefreshIndicator(
                  backgroundColor: Colors.transparent,
                  onRefresh: _controller.refresh,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user != null && _role != AppRole.hod) ...[
                          const SizedBox(height: 3),
                          Text(
                            _greeting(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.steel,
                            ),
                          ),
                          Text(
                            user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                        if (actions.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              for (
                                var index = 0;
                                index < actions.length;
                                index++
                              ) ...[
                                if (index > 0) const SizedBox(width: 10),
                                Expanded(
                                  child: _QuickActionButton(
                                    item: actions[index],
                                    compact: _role == AppRole.hod,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                        ..._profile.sections(context, _controller),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class PlaceholderRoleScreen extends StatelessWidget {
  final String title;
  const PlaceholderRoleScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoonTab(title: title);
  }
}

class _QuickActionButton extends StatelessWidget {
  final QuickActionItem item;
  final bool compact;

  const _QuickActionButton({required this.item, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 8,
          vertical: compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: item.backgroundColor.withValues(alpha: .035),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: item.backgroundColor, width: 1.4),
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.icon, size: 20, color: item.backgroundColor),
                  // const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppColors.ink,
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                children: [
                  Icon(item.icon, size: 24, color: item.backgroundColor),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
