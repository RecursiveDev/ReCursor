---
title: "03 - Agent Chat Screens"
description: "Phase 1 (basic chat), Phase 3 (voice input, multi-session)."
editUrl: "https://github.com/RecursiveDev/ReCursor/edit/main/docs/wireframes/03-chat.md"
sidebar:
  order: 40
---
# 03 - Agent Chat Screens

> Phase 1 (basic chat), Phase 3 (voice input, multi-session).

---

## 3A. Session List

```
+---------------------------------------+
| [=]     Sessions          [+ New]     |
+---------------------------------------+
|                                       |
|  +----------------------------------+ |
|  | Improve bridge reconnect banner  | |
|  | Claude Code  *  2 min ago        | |
|  | "I've updated the reconnect..." | |
|  +----------------------------------+ |
|                                       |
|  +----------------------------------+ |
|  | Add unit tests for API client    | |
|  | OpenCode  *  15 min ago          | |
|  | "Created 12 test cases for..."   | |
|  +----------------------------------+ |
|                                       |
|  +----------------------------------+ |
|  | Refactor database layer          | |
|  | Aider  *  1 hour ago             | |
|  | "Migrated from raw SQL to..."    | |
|  +----------------------------------+ |
|                                       |
|  +----------------------------------+ |
|  | Deploy to staging                | |
|  | Claude Code  *  3 hours ago      | |
|  | "Deployment complete. All..."    | |
|  +----------------------------------+ |
|                                       |
+---------------------------------------+
|  Agent  |  Repos  |   Git  | Settings |
+---------------------------------------+
```

**Elements:**
- Each card: session title (auto-generated from first message), agent name, timestamp, preview
- [+ New] button to start a fresh session
- Swipe left to delete session (with confirmation)
- Tap to open session

---

## 3B. Chat Screen

```
+---------------------------------------+
| [<] Bridge reconnect   (*) Connected  |
| Claude Code  *  main branch           |
+---------------------------------------+
|                                       |
|  +----------------------------------+ |
|  |  You            10:32 AM         | |
|  |  Tighten the bridge startup      | |
|  |  validation in                   | |
|  |  lib/features/startup/...        | |
|  +----------------------------------+ |
|                                       |
|        +-----------------------------+|
|        | Claude Code      10:32 AM   ||
|        |                             ||
|        | I'll tighten the bridge     ||
|        | validation in the startup   ||
|        | screen. The saved URL must  ||
|        | continue using `wss://`     ||
|        | before the app reconnects.  ||
|        |                             ||
|        | ```dart                     ||
|        | // Before                   ||
|        | bridgeUrl: 'ws://...'       ||
|        | // After                    ||
|        | callbackUrl: 'https://...'  ||
|        | ```                         ||
|        |                             ||
|        | [View Diff]                 ||
|        +-----------------------------+|
|                                       |
+---------------------------------------+
| +-----------------------------------+ |
| | Ask the agent...              [>] | |
| +-----------------------------------+ |
| [mic]                     [attach]    |
+---------------------------------------+
```

**Elements:**
- User messages: left-aligned, muted background
- Agent messages: right-aligned, primary background, with markdown rendering
- [View Diff] inline button when agent makes file changes
- Input bar: text field, send button [>], mic button, attach button
- Header: session name, agent name, branch, connection status

**Streaming state:**
```
        +-----------------------------+
        | Claude Code      10:33 AM   |
        |                             |
        | Analyzing the codebase to   |
        | find all references to the  |
        | old callback URL_           |
        |                             |
        | ( ... typing indicator )    |
        +-----------------------------+
```
- Cursor blink `_` at end of streaming text
- Typing indicator dots while waiting for first token

---

## 3C. Chat with Tool Call (Approval Needed)

```
+---------------------------------------+
| [<] Bridge startup     (*) Connected  |
+---------------------------------------+
|                                       |
|  ... (previous messages) ...          |
|                                       |
|        +-----------------------------+|
|        | Claude Code      10:33 AM   ||
|        |                             ||
|        | I need to edit this file:    ||
|        |                             ||
|        | +-------------------------+ ||
|        | | TOOL: Edit File         | ||
|        | | File: startup/splash... | ||
|        | | Lines: 42-45            | ||
|        | |                         | ||
|        | | - allowWs(url);         | ||
|        | | + requireWss(url);      | ||
|        | |                         | ||
|        | | [Approve] [Reject]      | ||
|        | | [View Full]  [Modify]   | ||
|        | +-------------------------+ ||
|        +-----------------------------+|
|                                       |
+---------------------------------------+
| +-----------------------------------+ |
| | Ask the agent...              [>] | |
| +-----------------------------------+ |
+---------------------------------------+
```

**See also:** [07-approvals.md](/wireframes/07-approvals/) for full approval flow.

---

## 3D. Voice Input Mode (Phase 3)

```
+---------------------------------------+
| [<] Bridge startup     (*) Connected  |
+---------------------------------------+
|                                       |
|  ... (previous messages) ...          |
|                                       |
+---------------------------------------+
|                                       |
|                                       |
|       (( large mic animation ))       |
|       ((    pulsing rings     ))      |
|                                       |
|   "Add error handling for the         |
|    network timeout case"              |
|                                       |
|   [ Cancel ]          [ Send ]        |
|                                       |
+---------------------------------------+
```

**Behavior:**
- Tap mic button -> expands to voice overlay (bottom sheet)
- Live transcription displayed as user speaks
- Pulsing rings indicate active listening
- User can edit transcribed text before sending
- [Send] dispatches the transcribed text as a chat message
- [Cancel] discards and returns to normal input
