import 'dart:async';
import 'dart:ui';

import 'package:flutter/scheduler.dart';

import '../models/notification_models.dart';
import '../network/websocket_messages.dart';
import 'notification_center.dart';
import 'notification_service.dart';

/// Routes incoming bridge [BridgeMessage] notifications.
/// - Foreground: adds to [NotificationCenter].
/// - Background: calls [NotificationService.showNotification].
class NotificationHandler {
  NotificationHandler({
    required NotificationCenter center,
    required NotificationService service,
  })  : _center = center,
        _service = service;

  final NotificationCenter _center;
  final NotificationService _service;

  final _controller =
      StreamController<AppNotification>.broadcast();

  Stream<AppNotification> get notificationStream => _controller.stream;

  Future<void> handle(BridgeMessage message) async {
    if (message.type != BridgeMessageType.notification) return;

    final payload = message.payload;
    final notification = _parseNotification(message.id, payload);
    if (notification == null) return;

    _controller.add(notification);

    // Determine if the app is in the foreground.
    final lifecycleState = SchedulerBinding.instance?.lifecycleState;
    final isForeground = lifecycleState == AppLifecycleState.resumed;

    if (isForeground) {
      _center.addNotification(notification);
    } else {
      _center.addNotification(notification);
      await _service.showNotification(notification);
    }
  }

  AppNotification? _parseNotification(
      String? id, Map<String, dynamic> payload) {
    try {
      final typeString =
          payload['notification_type'] as String? ?? 'info';
      final type = _parseType(typeString);
      final priorityString = payload['priority'] as String? ?? 'normal';
      final priority = _parsePriority(priorityString);

      return AppNotification(
        id: id ?? payload['notification_id'] as String? ?? '',
        sessionId: payload['session_id'] as String?,
        type: type,
        title: payload['title'] as String? ?? '',
        body: payload['body'] as String? ?? '',
        priority: priority,
        data: payload['data'] as Map<String, dynamic>?,
        timestamp: DateTime.now().toUtc(),
      );
    } catch (_) {
      return null;
    }
  }

  NotificationType _parseType(String value) {
    return switch (value) {
      'approval_required' => NotificationType.approvalRequired,
      'task_complete' => NotificationType.taskComplete,
      'error' => NotificationType.error,
      _ => NotificationType.info,
    };
  }

  NotificationPriority _parsePriority(String value) {
    return switch (value) {
      'low' => NotificationPriority.low,
      'high' => NotificationPriority.high,
      _ => NotificationPriority.normal,
    };
  }

  void dispose() {
    _controller.close();
  }
}
