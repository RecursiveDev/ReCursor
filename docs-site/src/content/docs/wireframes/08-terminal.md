---
title: "08 - Terminal Session Screens"
description: "Phase 3 — Embedded terminal with command input."
editUrl: "https://github.com/RecursiveDev/ReCursor/edit/main/docs/wireframes/08-terminal.md"
sidebar:
  order: 90
---
# 08 - Terminal Session Screens

> Phase 3 — Embedded terminal with command input.

---

## 8A. Terminal View

```
+---------------------------------------+
| [<]  Terminal        (*) Connected    |
| session: main  *  /home/user/project  |
+---------------------------------------+
|  $ flutter test                       |
|  00:05 +12: All tests passed!         |
|                                       |
|  $ git status                         |
|  On branch main                       |
|  Changes not staged for commit:       |
|    modified:   lib/features/startup/bridge_setup_screen.dart |
|    modified:   lib/features/startup/splash_screen.dart       |
|                                       |
|  Untracked files:                     |
|    test/auth_test.dart                |
|                                       |
|  $ dart analyze                       |
|  Analyzing project...                 |
|  No issues found!                     |
|                                       |
|  $ _                                  |
|                                       |
|                                       |
+---------------------------------------+
| $ [type command here...]        [ret] |
+---------------------------------------+
```

**Elements:**
- Monospace font, dark background (terminal aesthetic)
- ANSI color support (green for success, red for errors, etc.)
- Auto-scroll to bottom on new output
- Scrollback buffer (swipe up to view history)
- Command input bar with return/enter button
- Current working directory shown in header

**States:**
- Idle: cursor blink at `$ _`
- Running: command output streaming, input disabled
- Disconnected: grayed out with "Reconnect" overlay

---

## 8B. Terminal with Running Command

```
+---------------------------------------+
| [<]  Terminal        (*) Connected    |
| session: main  *  /home/user/project  |
+---------------------------------------+
|  $ flutter build apk --release        |
|                                       |
|  Running Gradle task                  |
|  'assembleRelease'...                 |
|                                       |
|  > Task :app:compileReleaseKotlin     |
|  > Task :app:mergeReleaseResources    |
|  > Task :app:processReleaseManifest   |
|  > Task :app:packageRelease           |
|  ...                                  |
|  BUILD SUCCESSFUL in 2m 34s           |
|  42 actionable tasks: 38 executed     |
|                                       |
|  Built build/app/outputs/flutter-a..  |
|                                       |
|  $ _                                  |
|                                       |
|                                       |
+---------------------------------------+
| $ [type command here...]        [ret] |
| [Ctrl+C]                              |
+---------------------------------------+
```

**Elements:**
- [Ctrl+C] button appears during long-running commands
- Output streams in real-time from bridge
- Tap output text to select/copy

---

## 8C. Terminal Session Picker

```
+---------------------------------------+
| [<]  Terminal Sessions     [+ New]    |
+---------------------------------------+
|                                       |
|  +----------------------------------+ |
|  | main                    [active] | |
|  | /home/user/project               | |
|  | Last: flutter test  *  2m ago   | |
|  +----------------------------------+ |
|                                       |
|  +----------------------------------+ |
|  | feature-branch                   | |
|  | /home/user/project               | |
|  | Last: git log  *  15m ago       | |
|  +----------------------------------+ |
|                                       |
|  +----------------------------------+ |
|  | server-logs                      | |
|  | /var/log                         | |
|  | Last: tail -f app.log  *  1h   | |
|  +----------------------------------+ |
|                                       |
+---------------------------------------+
```

**Elements:**
- Multiple terminal sessions (backed by separate bridge connections or multiplexed)
- Active indicator for running sessions
- [+ New] creates a new terminal session
- Swipe left to close session (with confirmation if command running)
