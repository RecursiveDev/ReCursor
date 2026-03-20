import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/websocket_messages.dart';
import '../notifications/notification_handler.dart';
import '../notifications/notification_service.dart';
import 'notification_provider.dart';
import 'websocket_provider.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationHandlerProvider = Provider<NotificationHandler>((ref) {
  final handler = NotificationHandler(
    center: ref.watch(notificationCenterProvider),
    service: ref.watch(notificationServiceProvider),
  );
  ref.onDispose(handler.dispose);
  return handler;
});

final notificationBootstrapProvider = Provider<void>((ref) {
  final handler = ref.watch(notificationHandlerProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final webSocketService = ref.watch(webSocketServiceProvider);

  unawaited(notificationService.init());

  final subscription = webSocketService.messages.listen((message) async {
    await handler.handle(message);

    if (message.type != BridgeMessageType.notification) {
      return;
    }

    final notificationId = _notificationIdFromMessage(message);
    if (notificationId == null || notificationId.isEmpty) {
      return;
    }

    webSocketService.send(
      BridgeMessage.notificationAck(notificationIds: [notificationId]),
    );
  });

  ref.onDispose(subscription.cancel);
});

String? _notificationIdFromMessage(BridgeMessage message) {
  final payloadId = message.payload['notification_id'];
  if (payloadId is String && payloadId.isNotEmpty) {
    return payloadId;
  }

  return message.id;
}
