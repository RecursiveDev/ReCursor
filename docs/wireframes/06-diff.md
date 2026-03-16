# 06 - Code Diff Viewer Screens

> Phase 2 — Unified diff, side-by-side, and file navigation.

---

## 6A. Diff Overview (Multi-File)

```
+---------------------------------------+
| [<]  Changes           3 files changed|
| abc1234 Fix OAuth redirect            |
+---------------------------------------+
|                                       |
|  +5 -2  across 3 files               |
|                                       |
|  +----------------------------------+ |
|  |  lib/auth/login.dart             | |
|  |  +2 -1                           | |
|  |  ████████░░  80% changed         | |
|  +----------------------------------+ |
|                                       |
|  +----------------------------------+ |
|  |  lib/auth/oauth.dart             | |
|  |  +2 -1                           | |
|  |  ██░░░░░░░░  20% changed         | |
|  +----------------------------------+ |
|                                       |
|  +----------------------------------+ |
|  |  test/auth_test.dart             | |
|  |  +1 -0  (new file)               | |
|  |  ██████████  100% new             | |
|  +----------------------------------+ |
|                                       |
|  [     Ask Agent About Changes     ]  |
|                                       |
+---------------------------------------+
```

**Elements:**
- Summary: total additions/deletions, file count
- Per-file card: file path, +/- counts, change bar
- Tap file card -> Unified Diff (6B)
- "Ask Agent" pre-fills chat with "Explain the changes in commit abc1234"

---

## 6B. Unified Diff View

```
+---------------------------------------+
| [<]  login.dart   [Unified|Split]     |
| File 1 of 3            [< prev][next >]|
+---------------------------------------+
|                                       |
|  @@ -40,7 +40,8 @@ class LoginScr...  |
|                                       |
|  40 |   final config = OAuthConfig(   |
|  41 |     clientId: env.clientId,      |
|  42 |- callbackUrl: 'http://localhost' |
|  42 |+ callbackUrl: 'https://localhos' |
|  43 |+ redirectValidation: true,       |
|  44 |   );                             |
|  45 |                                  |
|                                       |
|  @@ -78,4 +79,4 @@ void _handleRe...  |
|                                       |
|  78 |   if (uri.scheme != 'https') {   |
|  79 |-   throw AuthError('Invalid');   |
|  79 |+   throw AuthError('Invalid pr.. |
|  80 |   }                              |
|                                       |
|                                       |
+---------------------------------------+
| [Comment on line...]                  |
+---------------------------------------+
```

**Elements:**
- Toggle: [Unified | Split] view modes
- File navigation: [< prev] [next >] arrows
- Syntax-highlighted diff with line numbers
- Removed lines: red background with `-` prefix
- Added lines: green background with `+` prefix
- Hunk headers: `@@` lines in muted blue
- Horizontal scroll for long lines
- Tap a line -> opens comment input (6D)

---

## 6C. Side-by-Side Diff (Landscape / Tablet)

```
+-------------------------------------------------------------------+
| [<]  login.dart              [Unified|Split]   [< prev] [next >]  |
+-------------------------------------------------------------------+
|  OLD                         |  NEW                               |
+------------------------------+------------------------------------+
|  40 | final config = OAuth.. | 40 | final config = OAuth..        |
|  41 | clientId: env.client.. | 41 | clientId: env.client..        |
|  42 | callbackUrl: 'http://. | 42 | callbackUrl: 'https://.       |
|     |                        | 43 | redirectValidation: true,     |
|  43 | );                     | 44 | );                            |
|     |                        |                                    |
|  78 | if (uri.scheme != ...  | 79 | if (uri.scheme != ...         |
|  79 | throw AuthError('Inv.. | 79 | throw AuthError('Invalid p..  |
|  80 | }                      | 80 | }                             |
+------------------------------+------------------------------------+
```

**Behavior:**
- Available in landscape orientation or on tablets
- Synchronized scrolling between left and right panes
- Added/removed lines aligned with blank spacers on opposite side

---

## 6D. Line Comment (Bottom Sheet)

```
+---------------------------------------+
|                                       |
|   Comment on line 42:                 |
|   login.dart                          |
|                                       |
|   +----------------------------------+|
|   | Should we also update the        ||
|   | staging environment URL?         ||
|   +----------------------------------+|
|                                       |
|   [ ] Send to agent as instruction    |
|                                       |
|   [  Cancel  ]    [  Add Comment  ]   |
|                                       |
+---------------------------------------+
```

**Behavior:**
- Comments stored locally by default
- Check "Send to agent" -> dispatches as a chat message
- Comments appear as yellow markers on the diff line numbers
