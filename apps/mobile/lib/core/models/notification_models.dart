import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_models.freezed.dart';
part 'notification_models.g.dart';

enum NotificationType { approvalRequired, taskComplete, error, info }

enum NotificationPriority { low, normal, high }

@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    String? sessionId,
    required NotificationType type,
    required String title,
    required String body,
    @Default(NotificationPriority.normal) NotificationPriority priority,
    Map<String, dynamic>? data,
    required DateTime timestamp,
    @Default(false) bool isRead,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}
