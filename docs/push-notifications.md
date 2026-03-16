# In-App Notification Architecture

> How the bridge server notifies the mobile app about agent events — no Firebase, fully WebSocket-based.

---

## Overview

```
Agent Event -> Bridge Server -> WebSocket -> Mobile App -> Local Notification (if backgrounded)
```

All notifications flow through the existing WebSocket connection. No external push services (FCM/APNs) are used.

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

## Notification Types

| Type | Trigger | Priority | Action |
|------|---------|----------|--------|
| Task Complete | Agent finishes a task | Normal | Navigate to result |
| Approval Required | Agent needs tool call approval | High | Approve/reject buttons |
| Error | Agent encounters an error | High | Navigate to chat |
| Agent Idle | Agent waiting for input | Low | Navigate to chat |

## WebSocket Message Format

```json
{
  "type": "notification",
  "id": "notif-001",
  "payload": {
    "session_id": "sess-abc123",
    "notification_type": "approval_required",
    "title": "Approval needed: Edit login.dart",
    "body": "Claude Code wants to change the OAuth callback URL.",
    "priority": "high",
    "data": {
      "tool_call_id": "tool-001",
      "screen": "approval_detail"
    }
  }
}
```

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

## In-App Notification Center

- Bell icon in the app bar with unread count badge.
- Tap to open notification list (grouped by session).
- Each notification is tappable — routes to the relevant screen.
- "Mark all read" action.
- Notifications persist locally in Drift for offline access.

## Reliability

- WebSocket heartbeat ensures connection is alive.
- If heartbeat fails, app shows "disconnected" banner — user knows notifications won't arrive.
- On reconnect, bridge replays full event backlog (bounded by configurable max age, e.g., 24 hours).
- No silent failure — if the connection is down, the user sees it immediately.

## Trade-offs vs. Firebase

| | WebSocket-only | Firebase FCM |
|---|---|---|
| Works when app is killed | No | Yes |
| Requires Google/Apple services | No | Yes |
| Privacy | Full control | Data via Google servers |
| Complexity | Simpler, no external setup | FCM config, APNs certs |
| Reliability when connected | Immediate, guaranteed | Best-effort delivery |

The WebSocket-only approach is chosen because the app's primary value requires an active bridge connection anyway. If the bridge is unreachable, notifications are moot.
