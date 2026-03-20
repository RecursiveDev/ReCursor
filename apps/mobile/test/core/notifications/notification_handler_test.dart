import 'package:flutter_test/flutter_test.dart';
import 'package:recursor_mobile/core/models/notification_models.dart';
import 'package:recursor_mobile/core/network/websocket_messages.dart';
import 'package:recursor_mobile/core/notifications/notification_center.dart';
import 'package:recursor_mobile/core/notifications/notification_handler.dart';
import 'package:recursor_mobile/core/notifications/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationHandler', () {
    test('adds bridge notifications to the in-app center', () async {
      final center = NotificationCenter();
      final service = FakeNotificationService();
      final handler = NotificationHandler(center: center, service: service);

      await handler.handle(
        BridgeMessage(
          type: BridgeMessageType.notification,
          id: 'notif-1',
          timestamp: DateTime.now().toUtc(),
          payload: {
            'notification_id': 'notif-1',
            'session_id': 'sess-1',
            'notification_type': 'approval_required',
            'title': 'Approval needed',
            'body': 'Review tool call',
            'priority': 'high',
            'data': {'screen': 'approval_detail'},
          },
        ),
      );

      expect(center.currentNotifications, hasLength(1));
      expect(center.currentNotifications.single.type,
          NotificationType.approvalRequired);
      expect(center.currentNotifications.single.priority,
          NotificationPriority.high);
      expect(service.shownNotifications, hasLength(1));

      handler.dispose();
      center.dispose();
    });
  });
}

class FakeNotificationService extends NotificationService {
  final List<AppNotification> shownNotifications = <AppNotification>[];

  @override
  Future<void> showNotification(AppNotification notification) async {
    shownNotifications.add(notification);
  }
}
