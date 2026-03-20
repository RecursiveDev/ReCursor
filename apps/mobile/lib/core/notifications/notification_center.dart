import 'dart:async';

import '../models/notification_models.dart';

/// In-memory notification center.
/// Maintains the list of [AppNotification] items and broadcasts changes.
class NotificationCenter {
  final _notifications = <AppNotification>[];
  final _controller =
      StreamController<List<AppNotification>>.broadcast();

  Stream<List<AppNotification>> get notifications => _controller.stream;

  List<AppNotification> get currentNotifications =>
      List.unmodifiable(_notifications);

  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  void addNotification(AppNotification n) {
    // Deduplicate by id.
    _notifications.removeWhere((existing) => existing.id == n.id);
    _notifications.insert(0, n);
    _emit();
  }

  void markRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    _emit();
  }

  void markAllRead() {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _emit();
  }

  void _emit() {
    _controller.add(List.unmodifiable(_notifications));
  }

  void dispose() {
    _controller.close();
  }
}
