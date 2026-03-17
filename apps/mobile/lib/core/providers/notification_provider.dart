import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_models.dart';
import '../notifications/notification_center.dart';

final notificationCenterProvider = Provider<NotificationCenter>((ref) {
  final center = NotificationCenter();
  ref.onDispose(center.dispose);
  return center;
});

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationCenterProvider).notifications;
});

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationCenterProvider).unreadCount;
});
