import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kutchina/core/constants/app_theme.dart';
import 'package:kutchina/core/services/target_milestone_notification_service.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key, required this.notifications});

  final List<TargetMilestoneNotification> notifications;

  static Future<void> show(
    BuildContext context,
    List<TargetMilestoneNotification> notifications,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: NotificationScreen(notifications: notifications),
        ),
      ),
    );
  }

  

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Notifications',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ),
          Expanded(
            child: notifications.isEmpty
                ? const Center(
                    child: Text(
                      'No notifications yet',
                      style: TextStyle(color: AppColors.steel),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final accent = index.isEven
                          ? AppColors.aiBlue
                          : AppColors.dayEndIconBg;

                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accent, width: 1.5),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.greenLight,
                            child: Icon(
                              Icons.flag_outlined,
                              color: AppColors.green,
                            ),
                          ),
                          title: Text(notification.message),
                          subtitle: Text(
                            DateFormat(
                              'dd MMM yyyy, hh:mm a',
                            ).format(notification.createdAt.toLocal()),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
