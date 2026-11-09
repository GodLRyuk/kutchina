import 'package:flutter/material.dart';
import 'package:kutchina/core/provider/auth_provider.dart';
import 'package:kutchina/core/services/target_milestone_notification_service.dart';
import 'package:kutchina/module/salesModule/pages/dashboard/target_screen.dart';
import 'package:kutchina/module/salesModule/pages/notification/notification.dart';
import 'package:provider/provider.dart';

class AdminServices {
  static Future<void> openTargetNotifications({
    required BuildContext context,
    required bool mounted,
    required void Function(List<TargetMilestoneNotification> notifications)
        onUpdate,
  }) async {
    if (!context.mounted) return;

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) return;

    final notifications = await TargetMilestoneNotificationService.markAllRead(
      userId,
    );

    if (!mounted || !context.mounted) return;
    onUpdate(notifications);
    await NotificationScreen.show(context, notifications);
  }

  static void openTarget(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TargetScreen()),
    );
  }
}
