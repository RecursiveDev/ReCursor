# 11 - Tablet & Landscape Layouts

> Phase 4 — Responsive split views and landscape optimizations.

---

## 11A. Tablet: Chat + Diff Split View

```
+-------------------------------------------------------------------+
| [=]  ReCursor                            (*) Connected   [agents] |
+-------------------------------------------------------------------+
|                             |                                     |
|  CHAT                       |  DIFF / FILE VIEWER                |
|                             |                                     |
|  +------------------------+ | bridge_setup_screen.dart            |
|  | You         10:32 AM   | |                                     |
|  | Tighten bridge startup | | @@ -40,7 +40,8 @@                 |
|  | validation flow        | |                                     |
|  +------------------------+ |  40 | final validator = Br..       |
|                             |  41 | if (url.isEmpty) re..        |
|  +------------------------+ |  42 |- return allowWs(url);        |
|  | Claude Code   10:32 AM | |  42 |+ return requireWss(url);    |
|  |                        | |  43 |+ ensureTokenPresent();      |
|  | I'll tighten the       | |  44 | );                            |
|  | bridge startup flow.   | |                                     |
|  | is on line 42...       | |                                     |
|  |                        | |                                     |
|  | [View Diff]            | |                                     |
|  +------------------------+ |                                     |
|                             |                                     |
+-----------------------------+-------------------------------------+
| Ask the agent...                                            [>]   |
+-------------------------------------------------------------------+
```

**Behavior:**
- Left pane: chat (always visible)
- Right pane: context panel (diff, file viewer, or approval detail)
- Tapping [View Diff] loads diff in right pane without leaving chat
- Draggable divider to resize panes
- Collapses to single-pane on phone-width screens

---

## 11B. Tablet: Repo Browser + File Viewer

```
+-------------------------------------------------------------------+
| [=]  ReCursor / Repositories                          [search]   |
+-------------------------------------------------------------------+
|                             |                                     |
|  FILE TREE                  |  FILE VIEWER                        |
|                             |                                     |
|  lib/                       |  bridge_setup_screen.dart           |
|    v core/                  |  lib/features/startup/ * 196 lines  |
|    v features/              |                                     |
|      v startup/             |   1 | import 'package:flu..         |
|        > domain/            |   2 | import 'package:riv..         |
|        * bridge_setup_..    |   3 |                               |
|        * splash_screen.dart |   4 | class BridgeSetupScreen..     |
|          bridge_startup..   |   5 |   @override                   |
|      > chat/                |   6 |   Widget build(Buil..         |
|      > repos/               |   7 |     return Scaffold(          |
|    > shared/                |   8 |       appBar: AppBar(         |
|  test/                      |   9 |         title: Text(..        |
|  pubspec.yaml               |  10 |       ),                      |
|  README.md                  |  .. |                               |
|                             |                                     |
+-----------------------------+-------------------------------------+
|  Agent  |  Repos   |  Git   |  Terminal  |  Settings              |
+-------------------------------------------------------------------+
```

**Behavior:**
- Left pane: persistent file tree
- Right pane: file content viewer
- `*` marks currently viewed file in tree
- Tap file in tree -> loads in right pane
- Bottom nav gains "Terminal" tab on tablet (extra space)

---

## 11C. Tablet: Git Operations + Diff

```
+-------------------------------------------------------------------+
| [=]  Git Operations                    (*) Connected  [branch: v] |
+-------------------------------------------------------------------+
|                             |                                     |
|  COMMIT                     |  DIFF PREVIEW                      |
|                             |                                     |
|  Message:                   |  bridge_setup_screen.dart          |
|  +------------------------+ |                                     |
|  | Tighten bridge startup | |  @@ -40,7 +40,8 @@               |
|  +------------------------+ |   40 | final validator = Br..       |
|  +------------------------+ |   41 | if (url.isEmpty) re..        |
|  | Require WSS and a      | |   42 |- return allowWs(url);       |
|  | pairing token first... | |   42 |+ return requireWss(url);    |
|  +------------------------+ |   43 |+ ensureTokenPresent();      |
|                             |                                     |
|  Files:                     |  bridge_setup_screen.dart          |
|  [x] M splash_screen.. [>] |                                     |
|  [x] M bridge_setup..  [>]|  @@ -12,3 +12,5 @@               |
|  [ ] ? startup_test..  [>]|   12 | requireWss(..                |
|                             |   13 |+ if (!uri.isScheme..         |
|  [ Commit ]                 |                                     |
|                             |                                     |
+-----------------------------+-------------------------------------+
|  Agent  |  Repos   |  Git   |  Terminal  |  Settings              |
+-------------------------------------------------------------------+
```

**Behavior:**
- Left pane: commit form with file checklist
- Right pane: live diff preview of selected file
- Tapping [>] on a file loads its diff in the right pane
- Checked/unchecked files update the commit scope in real time

---

## 11D. Landscape Phone: Terminal

```
+-------------------------------------------------------------------+
| [<] Terminal  *  main  *  /home/user/project     (*) Connected    |
+-------------------------------------------------------------------+
|  $ flutter test                                                   |
|  00:05 +12: All tests passed!                                     |
|                                                                   |
|  $ git status                                                     |
|  On branch main                                                   |
|  Changes not staged for commit:                                   |
|    modified:   lib/features/startup/bridge_setup_screen.dart      |
|    modified:   lib/features/startup/splash_screen.dart            |
|                                                                   |
|  $ _                                                              |
+-------------------------------------------------------------------+
| $ [type command here...]                                    [ret] |
+-------------------------------------------------------------------+
```

**Behavior:**
- Full-width terminal utilizes landscape screen real estate
- Compact header (single line)
- More visible lines of output
- Virtual keyboard appears at bottom, pushing terminal up

---

## Responsive Breakpoints

| Width | Layout | Nav Style |
|-------|--------|-----------|
| < 600dp | Phone portrait | Bottom nav (4 tabs) |
| 600-839dp | Phone landscape | Bottom nav, full-width content |
| 840-1199dp | Small tablet | Split view, bottom nav (5 tabs) |
| >= 1200dp | Large tablet | Split view, side rail navigation |

**Implementation:**
- Use `LayoutBuilder` + `MediaQuery` to detect breakpoints
- `AdaptiveLayout` widget wraps each screen with responsive behavior
- Content panes are independent widgets; layout shell arranges them
