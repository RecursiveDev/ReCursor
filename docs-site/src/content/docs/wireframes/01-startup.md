---
title: "01 - Startup, Health Verification & Bridge Restore"
description: "Phase 1 — bridge-first launch, saved pairing restore, health verification, and handoff to bridge setup."
editUrl: "https://github.com/RecursiveDev/ReCursor/edit/main/docs/wireframes/01-startup.md"
sidebar:
  order: 20
---
> Phase 1 — bridge-first launch, saved pairing restore, health verification, and handoff to bridge setup.

---

## 1A. Splash / Restore Screen

```
+---------------------------------------+
|                                       |
|                                       |
|                                       |
|                                       |
|            [ App Logo ]               |
|                                       |
|            ReCursor                   |
|     Restore Bridge Session            |
|                                       |
|   Checking for a saved bridge pair... |
|                                       |
|           ( loading spinner )         |
|                                       |
|                                       |
|                                       |
+---------------------------------------+
```

**Behavior:**
- Auto-checks for a saved bridge URL and bridge pairing token
- If a valid saved pairing reconnects successfully -> navigate to Health Verification (1C)
- If no pairing exists or reconnect fails -> navigate to Bridge Setup
- Duration: 1-2s max while restore runs

---

## 1B. Restore Failure / Bridge Setup Handoff

```
+---------------------------------------+
|          Bridge Setup                 |
+---------------------------------------+
|                                       |
|  Unable to reconnect to the saved     |
|  bridge. Check the URL or pairing     |
|  token below and try again.           |
|                                       |
|  Bridge URL                           |
|  +-------------------------------+    |
|  | wss://devbox.tailnet.ts.net  |    |
|  +-------------------------------+    |
|                                       |
|  Bridge Pairing Token                 |
|  +-------------------------------+    |
|  | •••••••••••••••••••••••••••• |    |
|  +-------------------------------+    |
|                                       |
|       [ Reconnect to Bridge ]         |
|                                       |
|  ───────────  or  ───────────         |
|                                       |
|  [    Scan QR Code to Pair    ]       |
|                                       |
+---------------------------------------+
```

**Elements:**
- Error banner explaining why startup fell back to setup (if restore failed)
- Saved bridge URL prefilled for quick correction
- Secure pairing token field with masked value
- Primary reconnect button
- **QR-first option**: Prominent "Scan QR Code" button for new pairing

**States:**
- Restore failed: error copy visible and fields prefilled
- Missing pairing: no error, blank fields, QR option emphasized
- Loading: reconnect button shows spinner, inputs disabled
- Success: navigate to Health Verification (1C)

---

## 1C. Health Verification

Shown after successful WebSocket connection, before entering the main shell.

```
+---------------------------------------+
|       Health Verification             |
+---------------------------------------+
|                                       |
|   +-------------------------------+   |
|   |                               |   |
|   |    ( checkmark animation )    |   |
|   |                               |   |
|   |      Connection Verified      |   |
|   |                               |   |
|   +-------------------------------+   |
|                                       |
|   Connection Mode                     |
|   ┌─────────────────────────────┐     |
|   │ [🏠]  Local-only             │     |
|   │     127.0.0.1:3000          │     |
|   │     ✅ Secure                │     |
|   └─────────────────────────────┘     |
|                                       |
|   Health Checks                       |
|   ✅ TLS certificate valid             |
|   ✅ Clock synchronized                |
|   ✅ Bridge version compatible         |
|   ✅ Token permissions verified        |
|                                       |
|       [   Enter ReCursor   ]          |
|                                       |
+---------------------------------------+
```

**Connection Mode Variants:**

**Private Network:**
```
|   ┌─────────────────────────────┐     |
|   │ [📶]  Private Network        │     |
|   │     192.168.1.42:3000       │     |
|   │     ✅ Secure (LAN)         │     |
|   └─────────────────────────────┘     |
```

**Secure Remote (Tailscale/WireGuard):**
```
|   ┌─────────────────────────────┐     |
|   │ [🛡️]  Secure Remote         │     |
|   │     devbox.tailnet.ts.net   │     |
|   │     ✅ Tailscale mesh        │     |
|   └─────────────────────────────┘     |
```

**Direct Public Remote (Warning):**
```
+---------------------------------------+
|       ⚠️ Security Warning             |
+---------------------------------------+
|                                       |
|   +-------------------------------+   |
|   |       ( warning icon )        |   |
|   |                               |   |
|   |    Direct Public Connection   |   |
|   |                               |   |
|   +-------------------------------+   |
|                                       |
|   You are connecting directly over    |
|   the public internet without a       |
|   secure tunnel (Tailscale/WireGuard). |
|                                       |
|   Risks:                              |
|   • Traffic may be intercepted        |
|   • Certificate must be validated     |
|   • Verify the bridge is yours        |
|                                       |
|   [  I understand the risks  ]        |
|   [      Cancel Connection    ]         |
|                                       |
+---------------------------------------+
```

**Misconfigured (Error):**
```
+---------------------------------------+
|       ❌ Connection Blocked             |
+---------------------------------------+
|                                       |
|   +-------------------------------+   |
|   |        ( error icon )         |   |
|   |                               |   |
|   |    Insecure Configuration     |   |
|   |                               |   |
|   +-------------------------------+   |
|                                       |
|   This bridge uses an unencrypted     |
|   connection (ws://). ReCursor only   |
|   supports secure WebSocket (wss://). |
|                                       |
|   To fix:                             |
|   1. Enable TLS on your bridge        |
|   2. Use wss:// URLs only              |
|                                       |
|   [    Learn More    ]  [  Cancel  ]  |
|                                       |
+---------------------------------------+
```

**Elements:**
- Connection mode card with icon, label, and security status
- Health check list with pass/fail indicators
- "Enter ReCursor" primary action (enabled when all checks pass)
- Security warning screen for direct public mode (requires acknowledgment)
- Error screen for misconfigured mode (blocks entry)

**States:**
- Verifying: health checks in progress, spinner shown
- Verified: all checks passed, mode indicator green
- Warning: direct public mode, requires acknowledgment
- Blocked: misconfigured, connection refused
