import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TargetMilestoneNotification {
  final String id;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  const TargetMilestoneNotification({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory TargetMilestoneNotification.fromJson(Map<String, dynamic> json) {
    return TargetMilestoneNotification(
      id: json['id'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
  };

  TargetMilestoneNotification copyWith({bool? isRead}) {
    return TargetMilestoneNotification(
      id: id,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class TargetMilestoneUpdate {
  final List<TargetMilestoneNotification> notifications;
  final List<TargetMilestoneNotification> newlyReached;

  const TargetMilestoneUpdate({
    required this.notifications,
    required this.newlyReached,
  });
}

class TargetMilestoneNotificationService {
  static const _milestones = [25, 50, 75, 100];

  static String _storageKey(String userId) =>
      'target_milestone_notifications_$userId';

  static Future<List<TargetMilestoneNotification>> load(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    return _readNotifications(preferences, userId);
  }

  static Future<TargetMilestoneUpdate> recordProgress({
    required String userId,
    required DateTime targetMonth,
    required double progress,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final notifications = _readNotifications(preferences, userId);
    final monthKey =
        '${targetMonth.year}-${targetMonth.month.toString().padLeft(2, '0')}';
    final existingIds = notifications.map((notification) => notification.id).toSet();
    final newlyReached = <TargetMilestoneNotification>[];
    final now = DateTime.now();

    for (final milestone in _milestones) {
      if (progress < milestone / 100) continue;
      final id = '$monthKey-$milestone';
      if (existingIds.contains(id)) continue;
      final notification = TargetMilestoneNotification(
        id: id,
        message: 'You have reached $milestone% of your target.',
        createdAt: now,
        isRead: false,
      );
      notifications.insert(0, notification);
      newlyReached.add(notification);
    }

    if (newlyReached.isNotEmpty) {
      await _writeNotifications(preferences, userId, notifications);
    }
    return TargetMilestoneUpdate(
      notifications: notifications,
      newlyReached: newlyReached,
    );
  }

  static Future<List<TargetMilestoneNotification>> markAllRead(
    String userId,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final notifications = _readNotifications(preferences, userId)
        .map((notification) => notification.copyWith(isRead: true))
        .toList();
    await _writeNotifications(preferences, userId, notifications);
    return notifications;
  }

  static List<TargetMilestoneNotification> _readNotifications(
    SharedPreferences preferences,
    String userId,
  ) {
    final encoded = preferences.getString(_storageKey(userId));
    if (encoded == null) return [];
    final decoded = jsonDecode(encoded) as List<dynamic>;
    return decoded
        .map(
          (item) => TargetMilestoneNotification.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  static Future<void> _writeNotifications(
    SharedPreferences preferences,
    String userId,
    List<TargetMilestoneNotification> notifications,
  ) async {
    await preferences.setString(
      _storageKey(userId),
      jsonEncode(notifications.map((notification) => notification.toJson()).toList()),
    );
  }
}
