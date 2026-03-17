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
|  +------------------------+ | login.dart                          |
|  | You         10:32 AM   | |                                     |
|  | Fix the OAuth redirect | | @@ -40,7 +40,8 @@                 |
|  | bug in login.dart      | |                                     |
|  +------------------------+ |  40 | final config = OAu..          |
|                             |  41 | clientId: env.cli..           |
|  +------------------------+ |  42 |- callbackUrl: 'http..         |
|  | Claude Code   10:32 AM | |  42 |+ callbackUrl: 'https..        |
|  |                        | |  43 |+ redirectValidation..         |
|  | I'll fix the OAuth     | |  44 | );                            |
|  | redirect. The issue    | |                                     |
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
|  lib/                       |  login_screen.dart                  |
|    v core/                  |  lib/features/auth/  *  142 lines  |
|    v features/              |                                     |
|      v auth/                |   1 | import 'package:flu..         |
|        > data/              |   2 | import 'package:riv..         |
|        > domain/            |   3 |                               |
|        * login_screen.dart  |   4 | class LoginScreen e..         |
|          auth_provider.dart |   5 |   @override                   |
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
|  Message:                   |  login.dart                        |
|  +------------------------+ |                                     |
|  | Fix OAuth redirect bug | |  @@ -40,7 +40,8 @@               |
|  +------------------------+ |   40 | final config = OA..          |
|  +------------------------+ |   41 | clientId: env.cl..           |
|  | Updated callback URL   | |   42 |- callbackUrl: 'ht..         |
|  | from http to https...  | |   42 |+ callbackUrl: 'ht..         |
|  +------------------------+ |   43 |+ redirectValidati..          |
|                             |                                     |
|  Files:                     |  oauth.dart                        |
|  [x] M login.dart      [>] |                                     |
|  [x] M oauth.dart       [>]|  @@ -12,3 +12,5 @@               |
|  [ ] ? auth_test.dart   [>]|   12 | validateRedirect(..          |
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
|    modified:   lib/auth/login.dart                                |
|    modified:   lib/auth/oauth.dart                                |
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
