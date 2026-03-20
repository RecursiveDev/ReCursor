# 01 - Startup & Bridge Restore

> Phase 1 — bridge-first launch, saved pairing restore, and handoff to bridge setup.

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
- If a valid saved pairing reconnects successfully -> navigate to Main Shell
- If no pairing exists or reconnect fails -> navigate to Bridge Setup
- Duration: 1-2s max while restore runs

---

## 1B. Restore Failure Handoff

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
+---------------------------------------+
```

**Elements:**
- Error banner explaining why startup fell back to setup
- Saved bridge URL prefilled for quick correction
- Secure pairing token field with masked value
- Primary reconnect button

**States:**
- Restore failed: error copy visible and fields prefilled
- Missing pairing: no error, blank fields
- Loading: reconnect button shows spinner, inputs disabled
- Success: navigate directly to Sessions list
