# 07 - Tool Call Approval Screens

> Phase 2 — Approve, reject, or modify agent tool calls.

---

## 7A. Approval Card (Inline in Chat)

```
+----------------------------------+
| APPROVAL NEEDED                  |
| Claude Code wants to:            |
|                                  |
| Edit File                        |
| lib/auth/login.dart              |
|                                  |
| - callbackUrl: 'http://...'     |
| + callbackUrl: 'https://...'    |
|                                  |
| [View Full Diff]                 |
|                                  |
| [  Approve  ]  [  Reject  ]     |
| [         Modify         ]      |
+----------------------------------+
```

**Appears inline in chat stream when agent requests a tool call.**

---

## 7B. Approval Detail (Full Screen)

```
+---------------------------------------+
| [<]     Approval Required             |
+---------------------------------------+
|                                       |
|  +----------------------------------+ |
|  | Agent: Claude Code               | |
|  | Session: Fix auth bug            | |
|  | Time: 10:33 AM                   | |
|  +----------------------------------+ |
|                                       |
|  Tool: Edit File                      |
|  File: lib/auth/login.dart            |
|  Lines: 42-45                         |
|                                       |
|  Changes:                             |
|  +----------------------------------+ |
|  | @@ -40,7 +40,8 @@               | |
|  |  40 | final config = OAuthConf.. | |
|  |  41 | clientId: env.clientId,    | |
|  |  42 |- callbackUrl: 'http://..  | |
|  |  42 |+ callbackUrl: 'https://.. | |
|  |  43 |+ redirectValidation: true, | |
|  +----------------------------------+ |
|                                       |
|  Agent reasoning:                     |
|  "The callback URL must use HTTPS     |
|   for OAuth security. I'm also        |
|   adding redirect validation."        |
|                                       |
+---------------------------------------+
| [  Approve  ]           [  Reject  ]  |
| [          Modify & Approve         ] |
+---------------------------------------+
```

**Elements:**
- Full context: agent, session, timestamp
- Complete diff preview
- Agent's reasoning/explanation
- Three actions: Approve, Reject, Modify & Approve

---

## 7C. Modify & Approve Sheet

```
+---------------------------------------+
|                                       |
|   Modify Instructions                 |
|                                       |
|   Tell the agent what to change       |
|   before proceeding:                  |
|                                       |
|   +----------------------------------+|
|   | Also update the staging URL in   ||
|   | config/staging.yaml              ||
|   +----------------------------------+|
|                                       |
|   [  Cancel  ]  [  Send & Approve  ] |
|                                       |
+---------------------------------------+
```

**Behavior:**
- Opens as bottom sheet over approval detail
- User types modification instructions
- "Send & Approve" -> sends instructions to agent, agent adjusts and re-executes

---

## 7D. Approval from Notification

```
+---------------------------------------+
|  RemoteCLI                    now     |
|  Approval needed: Edit login.dart     |
|  Claude Code wants to change the      |
|  OAuth callback URL.                  |
|                                       |
|  [ Approve ]            [ View ]      |
+---------------------------------------+
```

**Behavior:**
- Push notification with action buttons
- [Approve] -> approves directly without opening app
- [View] -> opens app to Approval Detail (7B)

---

## 7E. Audit Log

```
+---------------------------------------+
| [<]     Audit Log          [filter]   |
+---------------------------------------+
|                                       |
|  Today                                |
|  +----------------------------------+ |
|  | [check] Approved                 | |
|  | Edit lib/auth/login.dart         | |
|  | Claude Code  *  10:33 AM        | |
|  +----------------------------------+ |
|  | [check] Approved                 | |
|  | Run: flutter test                | |
|  | Claude Code  *  10:35 AM        | |
|  +----------------------------------+ |
|  | [x] Rejected                     | |
|  | Delete lib/old_auth.dart         | |
|  | Claude Code  *  10:36 AM        | |
|  +----------------------------------+ |
|                                       |
|  Yesterday                            |
|  +----------------------------------+ |
|  | [check] Approved (modified)      | |
|  | Edit pubspec.yaml                | |
|  | OpenCode  *  3:15 PM            | |
|  +----------------------------------+ |
|                                       |
+---------------------------------------+
```

**Elements:**
- Chronological list grouped by day
- Status icons: check (approved), x (rejected), pencil (modified)
- Filter button: by agent, by action type, by status
- Tap entry -> shows full approval detail with outcome
