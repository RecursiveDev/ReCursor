# ReCursor - UI/UX Wireframes

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
                          +--------v---------+
                          |   Bridge Setup   |
                          |   (QR Pairing)   |
                          +--------+---------+
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

**Key:** No login screen, no user accounts — the app opens directly to bridge pairing restoration or setup.

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
| [`01-startup.md`](01-startup.md) | Splash, Saved Pairing Restore, Startup Fallback | 1 |
| [`02-bridge.md`](02-bridge.md) | QR Pairing, Connection Status | 1 |
| [`03-chat.md`](03-chat.md) | Chat, Session List, Streaming, Voice Input | 1, 3 |
| [`04-repos.md`](04-repos.md) | Repo List, File Tree, File Viewer | 1 |
| [`05-git.md`](05-git.md) | Branch Manager, Commit, Push/Pull | 2 |
| [`06-diff.md`](06-diff.md) | Unified Diff, Side-by-Side, File Nav | 2 |
| [`07-approvals.md`](07-approvals.md) | Tool Call Approval, Audit Log | 2 |
| [`08-terminal.md`](08-terminal.md) | Terminal View, Command Input | 3 |
| [`09-agents.md`](09-agents.md) | Agent Registry, Agent Switcher | 3 |
| [`10-settings.md`](10-settings.md) | Settings, Notifications, Offline Status | 1-4 |
| [`11-tablet.md`](11-tablet.md) | Tablet Split Views, Landscape Layouts | 4 |

## Design Conventions

- **Primary action:** Bottom-right FAB or prominent button
- **Status indicators:** Top bar connection pill (green/yellow/red)
- **Streaming text:** Word-by-word render with cursor blink
- **Destructive actions:** Red text, confirmation dialog required
- **Offline indicator:** Persistent banner at top when disconnected
