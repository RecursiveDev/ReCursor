# 04 - Repository Browsing Screens

> Phase 1 — Repo list, file tree, and file viewer.

---

## 4A. Repository List

```
+---------------------------------------+
| [=]     Repositories      [search]    |
+---------------------------------------+
| [My Repos] [Starred] [Recent]         |
+---------------------------------------+
|                                       |
|  +----------------------------------+ |
|  | RecursiveDev/RemoteCLI           | |
|  | Mobile AI coding agent controller| |
|  | Dart  *  12  fork 3  *  2h ago   | |
|  +----------------------------------+ |
|                                       |
|  +----------------------------------+ |
|  | RecursiveDev/pasahe-app          | |
|  | Cross-platform transit app       | |
|  | Dart  *  89  fork 12  *  1d ago  | |
|  +----------------------------------+ |
|                                       |
|  +----------------------------------+ |
|  | user/dotfiles                    | |
|  | Personal configuration files     | |
|  | Shell  *  3  fork 0  *  5d ago   | |
|  +----------------------------------+ |
|                                       |
|  +----------------------------------+ |
|  | user/blog                        | |
|  | Personal blog source             | |
|  | MDX  *  15  fork 2  *  2w ago    | |
|  +----------------------------------+ |
|                                       |
|         ( pull to refresh )           |
|                                       |
+---------------------------------------+
|  Agent  |  Repos  |   Git  | Settings |
+---------------------------------------+
```

**Elements:**
- Tab bar: My Repos, Starred, Recent (last opened in app)
- Each card: owner/name, description, language, stars, forks, last updated
- Search icon opens search bar with type-ahead
- Pull to refresh
- Tap card -> File Tree (4B)

---

## 4B. File Tree Browser

```
+---------------------------------------+
| [<]  RemoteCLI          [branch: main]|
+---------------------------------------+
| lib/                                  |
|   > core/                             |
|   v features/                         |
|     v auth/                           |
|       > data/                         |
|       > domain/                       |
|         login_screen.dart             |
|         auth_provider.dart            |
|     > chat/                           |
|     > repos/                          |
|   > shared/                           |
| test/                                 |
|   > auth/                             |
|   > chat/                             |
| android/                              |
| ios/                                  |
| pubspec.yaml                          |
| README.md                             |
| .gitignore                            |
|                                       |
|                                       |
+---------------------------------------+
|  Agent  |  Repos  |   Git  | Settings |
+---------------------------------------+
```

**Elements:**
- Tree view with expand/collapse chevrons (`>` / `v`)
- Folders sorted first, then files alphabetically
- File icons by type (dart, yaml, md, etc.)
- [branch: main] dropdown to switch branches
- Tap file -> File Viewer (4C)
- Tap folder -> expand inline

---

## 4C. File Viewer

```
+---------------------------------------+
| [<]  login_screen.dart      [...]     |
| lib/features/auth/  *  142 lines      |
+---------------------------------------+
|  1 | import 'package:flutter/mat..    |
|  2 | import 'package:riverpod/ri..    |
|  3 |                                  |
|  4 | class LoginScreen extends St..   |
|  5 |   @override                      |
|  6 |   Widget build(BuildContext c..  |
|  7 |     return Scaffold(             |
|  8 |       appBar: AppBar(            |
|  9 |         title: Text('Login'),    |
| 10 |       ),                         |
| 11 |       body: Padding(             |
| 12 |         padding: EdgeInsets...   |
| 13 |         child: Column(           |
| 14 |           children: [            |
| 15 |             ElevatedButton(      |
| .. |             ...                  |
| 42 |   callbackUrl: 'https://...'    |
| .. |             ...                  |
|    |                                  |
+---------------------------------------+
|  Agent  |  Repos  |   Git  | Settings |
+---------------------------------------+
```

**Elements:**
- Syntax-highlighted code with line numbers
- Horizontal scroll for long lines
- [...] menu: Copy path, Open in agent chat, View blame, View history
- "Open in agent chat" pre-fills chat with "Look at [file path]"
- Line numbers are tappable (for future annotation features)
- Pinch to zoom for readability
