import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/notification_models.dart';

/// Thin wrapper around [FlutterLocalNotificationsPlugin].
/// Handles permission requests and displaying local notifications.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // Request Android 13+ notification permission.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showNotification(AppNotification notification) async {
    final androidDetails = AndroidNotificationDetails(
      'recursor_main',
      'ReCursor',
      channelDescription: 'ReCursor agent notifications',
      importance: _toAndroidImportance(notification.priority),
      priority: _toAndroidPriority(notification.priority),
    );
    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use a stable integer derived from the UUID to identify the notification.
    final id = notification.id.hashCode & 0x7FFFFFFF;

    await _plugin.show(
      id,
      notification.title,
      notification.body,
      details,
      payload: notification.id,
    );
  }

  Future<void> cancelNotification(String id) async {
    await _plugin.cancel(id.hashCode & 0x7FFFFFFF);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Importance _toAndroidImportance(NotificationPriority priority) {
    return switch (priority) {
      NotificationPriority.low => Importance.low,
      NotificationPriority.normal => Importance.defaultImportance,
      NotificationPriority.high => Importance.high,
    };
  }

  Priority _toAndroidPriority(NotificationPriority priority) {
    return switch (priority) {
      NotificationPriority.low => Priority.low,
      NotificationPriority.normal => Priority.defaultPriority,
      NotificationPriority.high => Priority.high,
    };
  }
}
