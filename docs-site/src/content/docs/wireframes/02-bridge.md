---
title: "02 - Bridge Connection Screens"
description: "Phase 1 — QR pairing and connection management."
editUrl: "https://github.com/RecursiveDev/ReCursor/edit/main/docs/wireframes/02-bridge.md"
sidebar:
  order: 30
---
# 02 - Bridge Connection Screens

> Phase 1 — QR pairing and connection management.

**Architecture Note:** Bridge connections establish a **Agent SDK session** for controllable, approval-based interactions. Hooks provide one-way observation only (no control) and do not support approvals or bidirectional commands.

---

## 2A. QR Code Pairing

```
+---------------------------------------+
| [<]       Connect to Bridge           |
+---------------------------------------+
|                                       |
|   Scan the QR code shown by your      |
|   bridge server to connect.           |
|                                       |
|  +----------------------------------+ |
|  |                                  | |
|  |                                  | |
|  |       [ Camera Viewfinder ]      | |
|  |                                  | |
|  |          +----------+            | |
|  |          | QR scan  |            | |
|  |          | target   |            | |
|  |          +----------+            | |
|  |                                  | |
|  |                                  | |
|  +----------------------------------+ |
|                                       |
|         ---- or ----                  |
|                                       |
|  Enter bridge URL manually:           |
|  +----------------------------------+ |
|  | wss://100.x.x.x:3000            | |
|  +----------------------------------+ |
|  [        Connect Manually          ] |
|                                       |
+---------------------------------------+
```

**Elements:**
- Camera viewfinder with QR scan target overlay
- Manual URL entry as fallback (expandable)
- QR encodes: `{ "url": "wss://...", "token": "xxx" }`

**States:**
- Scanning: camera active, target pulsing
- Detected: brief green flash, auto-connect
- Manual: text field focused, connect button active
- Error: "Could not reach bridge" message with retry button

---

## 2B. Connecting State

```
+---------------------------------------+
| [<]       Connecting...               |
+---------------------------------------+
|                                       |
|                                       |
|                                       |
|                                       |
|          ( circular spinner )         |
|                                       |
|       Connecting to bridge at         |
|       100.78.42.15:3000               |
|                                       |
|       Establishing secure             |
|       connection...                   |
|                                       |
|                                       |
|                                       |
|                                       |
|                                       |
|                                       |
|  [          Cancel                  ] |
|                                       |
+---------------------------------------+
```

---

## 2C. Connection Status Bar (Global)

Persistent pill in the app bar across all screens showing connection state **and mode**:

```
Connected - Local-only:
+---------------------------------------+
| [=]  Agent Chat    [*] 🏠 Connected   |
+---------------------------------------+

Connected - Private Network:
+---------------------------------------+
| [=]  Agent Chat    [*] 📶 Connected   |
+---------------------------------------+

Connected - Secure Remote:
+---------------------------------------+
| [=]  Agent Chat    [*] 🛡️ Connected   |
+---------------------------------------+

Connected - Direct Public (Warning):
+---------------------------------------+
| [=]  Agent Chat    [*] ⚠️ Connected   |
+---------------------------------------+

Reconnecting state:
+---------------------------------------+
| [=]  Agent Chat    [*] (~) Reconnect..|
+---------------------------------------+

Disconnected state:
+---------------------------------------+
| +-----------------------------------+ |
| |  Bridge disconnected. Tap to      | |
| |  reconnect.                [Retry]| |
| +-----------------------------------+ |
| [=]  Agent Chat    [*] (!) Offline  |
+---------------------------------------+
```

**Connection Indicators:**
- `(*)` Green dot = connected
- `(~)` Yellow dot = reconnecting (with animated pulse)
- `(!)` Red dot = disconnected

**Connection Mode Icons:**
- `🏠` House = Local-only (loopback)
- `📶` WiFi = Private network (LAN)
- `🛡️` Shield = Secure remote (Tailscale/WireGuard)
- `⚠️` Warning = Direct public remote (acknowledged)

**Offline banner:**
- Appears below app bar when disconnected for >5s
- Tap "Retry" to force reconnect
- Dismissible but reappears if still disconnected

---

## 2D. Connection Mode Detail Sheet

Tapping the status bar reveals a bottom sheet with full connection details:

```
+---------------------------------------+
|           [====] Drag handle          |
+---------------------------------------+
|                                       |
|   Connection Details                  |
|                                       |
|   ┌─────────────────────────────┐     |
|   │  🛡️  Secure Remote          │     |
|   │                              │     |
|   │  Bridge URL:                 │     |
|   │  wss://devbox.tailnet.ts.net│     |
|   │                              │     |
|   │  Mode: Tailscale mesh VPN    │     |
|   │  TLS: ✅ Valid certificate   │     |
|   │  Latency: 24ms               │     |
|   │  Connected: 2h 15m           │     |
|   └─────────────────────────────┘     |
|                                       |
|   [   Copy Bridge URL   ]             |
|   [   Disconnect Bridge  ]            |
|                                       |
+---------------------------------------+
```

**Direct Public Remote variant:**
```
|   ┌─────────────────────────────┐     |
|   │  ⚠️  Direct Public Remote    │     |
|   │                              │     |
|   │  Bridge URL:                 │     |
|   │  wss://203.0.113.42:3000    │     |
|   │                              │     |
|   │  ⚠️ No tunnel detected        │     |
|   │  TLS: ✅ Valid certificate   │     |
|   │  Certificate: Let's Encrypt  │     |
|   │  Latency: 45ms               │     |
|   │                              │     |
|   │  [  Setup Tailscale  ]      │     |
|   └─────────────────────────────┘     |
```

**Elements:**
- Mode icon and label
- Full bridge URL
- Security details (TLS status, tunnel type)
- Connection metrics (latency, uptime)
- Action buttons (copy URL, disconnect)
- Setup guidance for insecure modes
