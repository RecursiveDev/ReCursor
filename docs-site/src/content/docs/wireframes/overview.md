---
title: "ReCursor - UI/UX Wireframes"
description: "Modular ASCII wireframes for every screen in the mobile app. Each file maps to a feature module. Screens are ordered by the bridge-first, no-login user flow."
editUrl: "https://github.com/RecursiveDev/ReCursor/edit/main/docs/wireframes/README.md"
sidebar:
  order: 10
  label: "Wireframes overview"
---
> Modular ASCII wireframes for every screen in the mobile app.
> Each file maps to a feature module. Screens are ordered by the bridge-first, no-login user flow.

---

## Navigation Architecture (Bridge-First, No-Login)

```
                          +------------------+
                          |  Splash / Restore |
                          | (No login screen) |
                          +--------+---------+
                                   |
                    +--------------v--------------+
                    |     Saved Pairing?          |
                    |  (Restore or New Pairing)  |
                    +--------------+--------------+
                                   |
              +--------------------+--------------------+
              |                                         |
     +--------v---------+                       +-------v--------+
     |   Bridge Setup   |                       | Health Verify  |
     |   (QR Pairing)   |                       | (Post-connect) |
     +--------+---------+                       +-------+--------+
              |                                         |
              +--------------------+--------------------+
                                   |
                    +--------------v--------------+
                    |     Main Shell (Bottom Nav)  |
                    +-+--------+--------+--------+-+
                      |        |        |        |
                  +---v--+ +---v--+ +---v--+ +---v------+ 
                  | Chat | | Repos| |  Git | | Settings |
                  +---+--+ +---+--+ +---+--+ +----------+
                      |        |        |
                 +----v--+ +---v----+ +-v--------+
                 |Session| |File    | |Diff      |
                 |List   | |Browser | |Viewer    |
                 +-------+ +-------+ +----------+
```

**Key:** No login screen, no user accounts — the app opens directly to bridge pairing restoration or setup. **Health Verification** is a mandatory step after connection before entering the main shell.

## Bottom Navigation Tabs

```
+============+============+============+============+
|   Agent    |   Repos    |    Git     |  Settings  |
|   (chat)   |  (browse)  | (operations)|  (config) |
+============+============+============+============+
```

## Wireframe Files

| File | Screens | Phase |
|------|---------|-------|
| [`01-startup.md`](/wireframes/01-startup/) | Splash, Saved Pairing Restore, Startup Fallback | 1 |
| [`02-bridge.md`](/wireframes/02-bridge/) | QR Pairing, Connection Status | 1 |
| [`03-chat.md`](/wireframes/03-chat/) | Chat, Session List, Streaming, Voice Input | 1, 3 |
| [`04-repos.md`](/wireframes/04-repos/) | Repo List, File Tree, File Viewer | 1 |
| [`05-git.md`](/wireframes/05-git/) | Branch Manager, Commit, Push/Pull | 2 |
| [`06-diff.md`](/wireframes/06-diff/) | Unified Diff, Side-by-Side, File Nav | 2 |
| [`07-approvals.md`](/wireframes/07-approvals/) | Tool Call Approval, Audit Log | 2 |
| [`08-terminal.md`](/wireframes/08-terminal/) | Terminal View, Command Input | 3 |
| [`09-agents.md`](/wireframes/09-agents/) | Agent Registry, Agent Switcher | 3 |
| [`10-settings.md`](/wireframes/10-settings/) | Settings, Notifications, Offline Status | 1-4 |
| [`11-tablet.md`](/wireframes/11-tablet/) | Tablet Split Views, Landscape Layouts | 4 |

## Design Conventions

- **Primary action:** Bottom-right FAB or prominent button
- **Status indicators:** Top bar connection pill (green/yellow/red)
- **Streaming text:** Word-by-word render with cursor blink
- **Destructive actions:** Red text, confirmation dialog required
- **Offline indicator:** Persistent banner at top when disconnected
