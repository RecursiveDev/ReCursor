# 05 - Git Operations Screens

> Phase 2 — Branch management, commit, push/pull.

---

## 5A. Git Overview (Tab Landing)

```
+---------------------------------------+
| [=]     Git Operations    (*) Connected|
+---------------------------------------+
| ReCursor  *  main                    |
+---------------------------------------+
|                                       |
|  Branch: main                    [v]  |
|  Status: 2 modified, 1 untracked     |
|                                       |
|  +----------------------------------+ |
|  |  Quick Actions                   | |
|  |                                  | |
|  |  [Commit]  [Push]  [Pull]       | |
|  |  [Fetch ]  [Stash] [Branch]     | |
|  +----------------------------------+ |
|                                       |
|  Recent Activity                      |
|  +----------------------------------+ |
|  | abc1234  Tighten bridge startup  | |
|  | Nathan  *  2 hours ago           | |
|  +----------------------------------+ |
|  | def5678  Add pairing restore     | |
|  | Nathan  *  5 hours ago           | |
|  +----------------------------------+ |
|  | ghi9012  Initial project setup   | |
|  | Nathan  *  1 day ago             | |
|  +----------------------------------+ |
|                                       |
+---------------------------------------+
|  Agent  |  Repos  |   Git  | Settings |
+---------------------------------------+
```

**Elements:**
- Current branch with dropdown to switch
- Working tree status summary
- Quick action buttons (grid layout)
- Recent commits list (tap for details)

---

## 5B. Branch Manager

```
+---------------------------------------+
| [<]     Branches           [+ New]    |
+---------------------------------------+
| [search branches...]                  |
+---------------------------------------+
|                                       |
|  LOCAL                                |
|  +----------------------------------+ |
|  | * main                           | |
|  |   origin/main  *  up to date    | |
|  +----------------------------------+ |
|  |   feature/voice-input            | |
|  |   origin/feature/voice  *  +3   | |
|  +----------------------------------+ |
|  |   fix/bridge-startup            | |
|  |   (no remote)  *  local only    | |
|  +----------------------------------+ |
|                                       |
|  REMOTE                               |
|  +----------------------------------+ |
|  |   origin/develop                 | |
|  |   Last: "Merge PR #42"  *  1d   | |
|  +----------------------------------+ |
|  |   origin/release/1.0             | |
|  |   Last: "Bump version"  *  3d   | |
|  +----------------------------------+ |
|                                       |
+---------------------------------------+
```

**Elements:**
- Current branch marked with `*`
- Tracking status: up to date, ahead +N, behind -N
- [+ New] opens Create Branch sheet
- Tap branch -> Switch (with confirmation if uncommitted changes)
- Swipe left -> Delete (with confirmation, prevented on main)

---

## 5C. Create Branch Sheet

```
+---------------------------------------+
|                                       |
|   Create New Branch                   |
|                                       |
|   Branch name:                        |
|   +----------------------------------+|
|   | feature/                         ||
|   +----------------------------------+|
|                                       |
|   From:                               |
|   +----------------------------------+|
|   | main                         [v] ||
|   +----------------------------------+|
|                                       |
|   [ ] Switch to new branch after      |
|       creation                        |
|                                       |
|   [  Cancel  ]    [  Create  ]        |
|                                       |
+---------------------------------------+
```

---

## 5D. Commit Screen

```
+---------------------------------------+
| [<]     Create Commit                 |
+---------------------------------------+
|                                       |
|  Commit message:                      |
|  +----------------------------------+ |
|  | Tighten bridge startup          | |
|  +----------------------------------+ |
|  | Require WSS bridge URLs and     | |
|  | keep the saved pairing token    | |
|  | before restoring the session.   | |
|  |                                  | |
|  +----------------------------------+ |
|                                       |
|  Changed files:       [Select All]    |
|  +----------------------------------+ |
|  | [x] M  lib/features/startup/... | |
|  |        +2 -1                [>]  | |
|  +----------------------------------+ |
|  | [x] M  test/startup_restore..   | |
|  |        +15 -3               [>]  | |
|  +----------------------------------+ |
|  | [ ] ?  test/auth_test.dart       | |
|  |        new file             [>]  | |
|  +----------------------------------+ |
|                                       |
|  [         Commit Changes           ] |
|                                       |
+---------------------------------------+
```

**Elements:**
- Subject line (single line, char counter)
- Body (multi-line, optional)
- File list with checkboxes to stage/unstage
- Status indicators: M (modified), A (added), D (deleted), ? (untracked)
- [>] per file -> opens diff viewer for that file
- [Commit Changes] disabled until message entered and files selected

---

## 5E. Push / Pull Status

```
+---------------------------------------+
| [<]     Pushing to origin...          |
+---------------------------------------+
|                                       |
|                                       |
|   Pushing main -> origin/main         |
|                                       |
|   +----------------------------------+|
|   | ████████████░░░░░░░  63%         ||
|   +----------------------------------+|
|                                       |
|   Objects: 3/5                        |
|   Compressing...                      |
|                                       |
|                                       |
|                                       |
|                                       |
|   [          Cancel                 ] |
|                                       |
+---------------------------------------+
```

**Success state:**
```
|   Push complete!                      |
|                                       |
|   3 commits pushed to origin/main     |
|   abc1234  Tighten bridge startup     |
|   def5678  Add session restore        |
|   ghi9012  Update tests               |
|                                       |
|   [           Done                  ] |
```

**Error state:**
```
|   Push failed                         |
|                                       |
|   Remote has changes you don't have.  |
|   Pull first, then push again.        |
|                                       |
|   [  Pull & Retry  ]  [  Cancel  ]   |
```
