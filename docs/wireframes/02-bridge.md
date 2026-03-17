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

Persistent pill in the app bar across all screens:

```
Connected state:
+---------------------------------------+
| [=]  Agent Chat    [*] (*) Connected  |
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

**Indicators:**
- `(*)` Green dot = connected
- `(~)` Yellow dot = reconnecting (with animated pulse)
- `(!)` Red dot = disconnected

**Offline banner:**
- Appears below app bar when disconnected for >5s
- Tap "Retry" to force reconnect
- Dismissible but reappears if still disconnected
