# 09 - Multi-Agent Management Screens

> Phase 3 — Agent registry, switcher, and parallel sessions.

---

## 9A. Agent Registry

```
+---------------------------------------+
| [<]     My Agents          [+ Add]    |
+---------------------------------------+
|                                       |
|  +----------------------------------+ |
|  | [Claude]  Claude Code            | |
|  | Bridge: 100.78.42.15:3000        | |
|  | Status: (*) Connected            | |
|  | Sessions: 2 active               | |
|  +----------------------------------+ |
|                                       |
|  +----------------------------------+ |
|  | [OC]  OpenCode                   | |
|  | Bridge: 100.78.42.15:3001        | |
|  | Status: (*) Connected            | |
|  | Sessions: 1 active               | |
|  +----------------------------------+ |
|                                       |
|  +----------------------------------+ |
|  | [A]  Aider                       | |
|  | Bridge: 100.78.42.15:3002        | |
|  | Status: (!) Disconnected         | |
|  | Sessions: 0                      | |
|  +----------------------------------+ |
|                                       |
|  +----------------------------------+ |
|  | [G]  Goose                       | |
|  | Bridge: Not configured           | |
|  | Status: -- Inactive              | |
|  +----------------------------------+ |
|                                       |
+---------------------------------------+
```

**Elements:**
- Each agent card: icon/avatar, name, bridge URL, connection status, active sessions
- Status indicators: green (connected), red (disconnected), gray (inactive/unconfigured)
- Tap card -> Agent Detail/Config (9B)
- [+ Add] -> Add Agent screen (9C)

---

## 9B. Agent Configuration

```
+---------------------------------------+
| [<]     Claude Code        [Delete]   |
+---------------------------------------+
|                                       |
|  Display name:                        |
|  +----------------------------------+ |
|  | Claude Code                      | |
|  +----------------------------------+ |
|                                       |
|  Agent type:                          |
|  +----------------------------------+ |
|  | Claude Code                  [v] | |
|  +----------------------------------+ |
|                                       |
|  Bridge URL:                          |
|  +----------------------------------+ |
|  | wss://100.78.42.15:3000         | |
|  +----------------------------------+ |
|                                       |
|  Auth token:                          |
|  +----------------------------------+ |
|  | ******************************** | |
|  +----------------------------------+ |
|  [Scan QR]  [Test Connection]         |
|                                       |
|  Working directory:                   |
|  +----------------------------------+ |
|  | /home/user/project              | |
|  +----------------------------------+ |
|                                       |
|  Connection status: (*) Connected     |
|  Last connected: 2 min ago            |
|  Uptime: 4h 23m                       |
|                                       |
|  [          Save Changes            ] |
|                                       |
+---------------------------------------+
```

**Elements:**
- Editable fields: name, type, bridge URL, token, working directory
- [Scan QR] -> opens camera to re-pair
- [Test Connection] -> validates bridge reachability
- [Delete] -> removes agent (with confirmation)
- Agent type dropdown: Claude Code, OpenCode, Aider, Goose, Custom

---

## 9C. Add Agent

```
+---------------------------------------+
| [<]     Add Agent                     |
+---------------------------------------+
|                                       |
|  Choose agent type:                   |
|                                       |
|  +----------------------------------+ |
|  | [Claude]                         | |
|  | Claude Code                      | |
|  | Anthropic's AI coding agent      | |
|  +----------------------------------+ |
|                                       |
|  +----------------------------------+ |
|  | [OC]                             | |
|  | OpenCode                         | |
|  | Open-source, 75+ LLM providers  | |
|  +----------------------------------+ |
|                                       |
|  +----------------------------------+ |
|  | [A]                              | |
|  | Aider                            | |
|  | Git-native AI pair programmer    | |
|  +----------------------------------+ |
|                                       |
|  +----------------------------------+ |
|  | [G]                              | |
|  | Goose                            | |
|  | Block's extensible AI agent      | |
|  +----------------------------------+ |
|                                       |
|  +----------------------------------+ |
|  | [?]                              | |
|  | Custom Agent                     | |
|  | Any WebSocket-compatible agent   | |
|  +----------------------------------+ |
|                                       |
+---------------------------------------+
```

**Behavior:**
- Tap agent type -> opens Agent Configuration (9B) pre-filled with defaults
- Custom Agent allows full manual configuration

---

## 9D. Agent Switcher (Quick Access)

Accessible from chat screen header via long-press on agent name:

```
+---------------------------------------+
| Switch Agent                          |
+---------------------------------------+
|                                       |
|  (*) Claude Code        Connected     |
|  ( ) OpenCode           Connected     |
|  ( ) Aider              Disconnected  |
|                                       |
+---------------------------------------+
```

**Behavior:**
- Bottom sheet overlay
- Radio selection to switch active agent in current chat
- Disconnected agents are grayed but selectable (triggers reconnect)
- Switching agent in an existing session starts a new session with the selected agent
