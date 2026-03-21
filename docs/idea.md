# ReCursor — Project Concept

> **Mobile-first AI coding agent companion** — Connect to your user-controlled desktop bridge to observe and interact with Claude Code and other AI coding assistants from your mobile device (iOS/Android) with an OpenCode-inspired UI. Bridge-first, no-login workflow.

---

## Vision

Enable developers to leverage AI-powered coding agents from anywhere, without requiring a desktop environment. Full agentic coding workflows on mobile — plan, code, test, and deploy applications using only your phone or tablet.

The UI/UX mirrors **OpenCode** (terminal-native AI coding agent) with its rich tool cards, diff viewer, and session timeline, while the underlying events come from **Claude Code** running on your development machine via supported integration mechanisms.

---

## Why This Matters

As developers who build mobile apps, we understand the mobile developer experience. A mobile app for controlling AI coding agents enables:

- 📱 **Coding on-the-go** — Review code, approve changes, chat with agents from anywhere
- 🚀 **Remote productivity** — No laptop required for code review and simple fixes
- 🤖 **AI-first workflow** — Voice commands to AI agents while away from desk
- 🔄 **Continuous context** — Start coding at your desk, continue from your phone

---

## Core Features

| Feature | Description | Phase |
|---------|-------------|-------|
| Agent Chat Interface | Mobile chat UI with OpenCode-style tool cards | 1 |
| Tool Call Approval | Approve/reject agent actions with rich context | 1 |
| Code Diff Viewer | Syntax-highlighted diffs with OpenCode patterns | 2 |
| Git Operations | Commit, push, pull, merge from mobile | 2 |
| Session Timeline | Visual timeline of agent actions and decisions | 2 |
| Push Notifications | Real-time alerts for agent events via WebSocket | 2 |
| Voice Commands | Speech-to-code capabilities | 3 |
| Offline Mode | Work without connectivity, sync on reconnect | 3 |

---

## Architecture Overview

```mermaid
flowchart LR
    subgraph Phone["📱 Mobile Device"]
        App["ReCursor Flutter App\n(OpenCode-like UI)"]
    end

    subgraph DevMachine["💻 User-Controlled Development Machine"]
        Bridge["ReCursor Bridge Server"]
        AgentHooks["Agent Hooks\n(Event Observer)"]
        Agent["Coding Agent (Claude Code)"]
    end

    App <-->|WebSocket (wss://)| Bridge
    Bridge <-->|HTTP POST| AgentHooks
    AgentHooks -->|Observes| Agent
```

**Integration Strategy:**
- **Bridge-First**: Mobile app connects directly to user-controlled bridge (no hosted service, no login)
- **Event Source**: Agent hooks POST events to the bridge server (one-way observation)
- **UI Pattern**: OpenCode-style tool cards, diff viewer, session timeline
- **Session Model**: Parallel Agent SDK sessions (not mirroring existing agent sessions)
- **Remote Access**: Secure tunnel (Tailscale, WireGuard) to your own bridge

**Current Integration:** Claude Code is the first supported agent, with future support planned for OpenCode, Gemini CLI, Codex CLI, and others.

---

## Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Framework | Flutter | Cross-platform, CC Pocket precedent |
| State | Riverpod | Type-safe, testable, Conduit pattern |
| Networking | `web_socket_channel` | Standard Flutter WebSocket |
| Device Pairing | QR code + token | Bridge-first connection |
| Local DB | Drift (SQLite) | Type-safe queries, migrations |
| Cache | Hive | Fast key-value for ephemeral data |
| Bridge | TypeScript (Node.js) | CC Pocket pattern |
| Tunnel | Tailscale / WireGuard | Zero-config mesh VPN |

---

## Related Resources

- **OpenCode**: [opencode-ai/opencode](https://github.com/opencode-ai/opencode) — UI/UX reference
- **CC Pocket**: [K9i-0/ccpocket](https://github.com/K9i-0/ccpocket) — Flutter bridge pattern reference
- **Conduit**: [cogwheel0/conduit](https://github.com/cogwheel0/conduit) — Riverpod + WebSocket pattern

---

## Status

**Phase**: Architecture specification complete, implementation pending

---

*Last updated: 2026-03-17*
