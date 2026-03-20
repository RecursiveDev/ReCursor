---
title: "07 - Tool Call Approval Screens"
description: "Phase 2 — Approve, reject, or modify agent tool calls."
editUrl: "https://github.com/RecursiveDev/ReCursor/edit/main/docs/wireframes/07-approvals.md"
sidebar:
  order: 80
---
# 07 - Tool Call Approval Screens

> Phase 2 — Approve, reject, or modify agent tool calls.

**Architecture Note:** Tool call approvals apply to the **Agent SDK session** — the controllable bridge-side session where ReCursor has execution authority. Hooks provide one-way observation only and do not require or support approvals.

---

## 7A. Approval Card (Inline in Chat)

```
+----------------------------------+
| APPROVAL NEEDED                  |
| Claude Code wants to:            |
|                                  |
| Edit File                        |
| lib/features/startup/bridge_...  |
|                                  |
| - allowWs: true                 |
| + requireWss: true              |
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
|  | Session: Bridge startup          | |
|  | Time: 10:33 AM                   | |
|  +----------------------------------+ |
|                                       |
|  Tool: Edit File                      |
|  File: lib/features/startup/...       |
|  Lines: 42-45                         |
|                                       |
|  Changes:                             |
|  +----------------------------------+ |
|  | @@ -40,7 +40,8 @@               | |
|  |  40 | final validator = Bridge.. | |
|  |  41 | if (url.isEmpty) return... | |
|  |  42 |- return wsAllowed(url);    | |
|  |  42 |+ return wssRequired(url);  | |
|  |  43 |+ ensureTokenPresent();     | |
|  +----------------------------------+ |
|                                       |
|  Agent reasoning:                     |
|  "The bridge URL must use WSS and    |
|   the pairing token cannot be empty. |
|   I'm tightening startup validation."|
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
|  ReCursor                    now     |
|  Approval needed: Bridge setup edit   |
|  Claude Code wants to tighten the     |
|  startup bridge validation.           |
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
|  | Edit bridge_setup_screen.dart   | |
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
