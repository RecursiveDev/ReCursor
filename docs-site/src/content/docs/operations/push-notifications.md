---
title: "In-App Notification Architecture"
description: "How the ReCursor bridge server notifies the mobile app about agent events — no Firebase, fully WebSocket-based."
sidebar:
  order: 30
  label: "Push notifications"
---
> How the ReCursor bridge server notifies the mobile app about agent events — no Firebase, fully WebSocket-based.

---

## Overview

```
Agent Event -> Bridge Server -> WebSocket -> Mobile App -> Local Notification (if backgrounded)
```

All notifications flow through the existing WebSocket connection. No external push services (FCM/APNs) are used.

---

## Notification Delivery

### When App is Connected (Foreground)

- Bridge sends a `notification` message over the WebSocket.
- App displays an in-app banner/toast or updates the notification center badge.
- No OS-level notification needed — the user is already in the app.

### When App is Backgrounded

- If the WebSocket connection is still alive (kept by OS background mode), the app receives the event and displays a **local notification** via `flutter_local_notifications`.
- Local notifications support action buttons (e.g., "Approve" / "View").

### When App is Disconnected

- Bridge stores events in a **pending event queue**.
- On reconnect, bridge replays all unacknowledged events.
- App processes the backlog and shows relevant notifications.

---

## Notification Types

| Type | Trigger | Priority | Action |
|------|---------|----------|--------|
| Task Complete | Agent finishes a task | Normal | Navigate to result |
| Approval Required | Agent needs tool call approval | High | Approve/reject buttons |
| Error | Agent encounters an error | High | Navigate to chat |
| Agent Idle | Agent waiting for input | Low | Navigate to chat |

---

## WebSocket Message Format

```json
{
  "type": "notification",
  "id": "notif-001",
  "payload": {
    "session_id": "sess-abc123",
    "notification_type": "approval_required",
    "title": "Approval needed: Update bridge_setup_screen.dart",
    "body": "Claude Code wants to tighten bridge URL validation before pairing.",
    "priority": "high",
    "data": {
      "tool_call_id": "tool-001",
      "screen": "approval_detail"
    }
  }
}
```

---

## Acknowledgment

```json
{
  "type": "notification_ack",
  "payload": {
    "notification_ids": ["notif-001", "notif-002"]
  }
}
```

The bridge removes acknowledged events from the pending queue.

---

## In-App Notification Center

- Bell icon in the app bar with unread count badge.
- Tap to open notification list (grouped by session).
- Each notification is tappable — routes to the relevant screen.
- "Mark all read" action.
- Notifications persist locally in Drift for offline access.

---

## Reliability

- WebSocket heartbeat ensures connection is alive.
- If heartbeat fails, app shows "disconnected" banner — user knows notifications won't arrive.
- On reconnect, bridge replays full event backlog (bounded by configurable max age, e.g., 24 hours).
- No silent failure — if the connection is down, the user sees it immediately.

---

## Trade-offs vs. Firebase

| | WebSocket-only | Firebase FCM |
|---|---|---|
| Works when app is killed | No | Yes |
| Requires Google/Apple services | No | Yes |
| Privacy | Full control | Data via Google servers |
| Complexity | Simpler, no external setup | FCM config, APNs certs |
| Reliability when connected | Immediate, guaranteed | Best-effort delivery |

The WebSocket-only approach is chosen because the app's primary value requires an active bridge connection anyway. If the bridge is unreachable, notifications are moot.

---

## Local Notification Configuration

```dart
// Initialize local notifications
final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
const iosSettings = DarwinInitializationSettings(
  requestAlertPermission: true,
  requestBadgePermission: true,
  requestSoundPermission: true,
);

await flutterLocalNotificationsPlugin.initialize(
  const InitializationSettings(android: androidSettings, iOS: iosSettings),
  onDidReceiveNotificationResponse: (response) {
    // Handle notification tap
    _handleNotificationTap(response.payload);
  },
);

// Show local notification
Future<void> showLocalNotification(AppNotification notification) async {
  const androidDetails = AndroidNotificationDetails(
    'recursor_channel',
    'ReCursor Notifications',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
  );
  
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  
  await flutterLocalNotificationsPlugin.show(
    notification.id.hashCode,
    notification.title,
    notification.body,
    const NotificationDetails(android: androidDetails, iOS: iosDetails),
    payload: jsonEncode(notification.data),
  );
}
```

---

## Related Documentation

- [Bridge Protocol](../../architecture/bridge-protocol/) — WebSocket message specification
- [Architecture Overview](../../architecture/system-overview/) — System architecture
- [Data Flow](../../architecture/data-flow/) — Message sequence diagrams

---

*Last updated: 2026-03-17*
