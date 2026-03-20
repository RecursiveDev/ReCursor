# ReCursor Documentation

> **ReCursor** — A Flutter mobile app providing OpenCode-like UI/UX for AI coding agents. Bridge-first, no-login workflow: connects to your user-controlled desktop bridge via secure tunnel.

> **Publishing note:** `C:/Repository/ReCursor/docs/` is the canonical source. The Astro Starlight site in `C:/Repository/ReCursor/docs-site/` is generated from this directory.

---

## Quick Navigation

### Getting Started

| Document | Description |
|----------|-------------|
| [idea.md](idea.md) | Project vision and core concept |
| [PLAN.md](PLAN.md) | Implementation roadmap and phases |

### Architecture

| Document | Description |
|----------|-------------|
| [architecture/overview.md](architecture/overview.md) | System architecture and component diagram |
| [architecture/data-flow.md](architecture/data-flow.md) | Message flow between mobile app, bridge, and agent |
| [project-structure.md](project-structure.md) | Flutter directory layout and module organization |
| [data-models.md](data-models.md) | Drift schemas, Hive models, and domain entities |

### Integration

| Document | Description |
|----------|-------------|
| [integration/claude-code-hooks.md](integration/claude-code-hooks.md) | Claude Code Hooks integration (event observation) |
| [integration/agent-sdk.md](integration/agent-sdk.md) | Agent SDK for parallel agent sessions |
| [integration/opencode-ui-patterns.md](integration/opencode-ui-patterns.md) | OpenCode UI component patterns for Flutter |
| [bridge-protocol.md](bridge-protocol.md) | WebSocket message protocol between app and bridge |

### Security & Operations

| Document | Description |
|----------|-------------|
| [security-architecture.md](security-architecture.md) | Network security, auth, cert pinning, bridge authorization, TLS implementation |
| [offline-architecture.md](offline-architecture.md) | Drift/Hive storage, sync queue, conflict resolution |
| [push-notifications.md](push-notifications.md) | WebSocket-based notifications and local alerts |

### Protocol & API Specifications

| Document | Description |
|----------|-------------|
| [bridge-protocol.md](bridge-protocol.md) | WebSocket message protocol between app and bridge |
| [bridge-http-api.md](bridge-http-api.md) | REST endpoints for hooks, health, and control |
| [error-handling.md](error-handling.md) | Error taxonomy, recovery patterns, reconnection strategies |
| [type-mapping.md](type-mapping.md) | Dart↔TypeScript cross-language type contracts |

### Development

| Document | Description |
|----------|-------------|
| [ci-cd.md](ci-cd.md) | GitHub Actions + Fastlane pipeline |
| [testing-strategy.md](testing-strategy.md) | Testing pyramid and CI integration |

### Research

| Document | Description |
|----------|-------------|
| [research/claude-remote-control-2026-03-17.md](research/claude-remote-control-2026-03-17.md) | Claude Code Remote Control protocol research |
| [research/claude-code-integration-feasibility-2026-03-17.md](research/claude-code-integration-feasibility-2026-03-17.md) | Integration options analysis |
| [research.md](research.md) | Ecosystem research — agents, Flutter clients, references |

### UI/UX

| Document | Description |
|----------|-------------|
| [wireframes/README.md](wireframes/README.md) | All screen wireframes organized by feature module |

---

## Architecture at a Glance

```mermaid
flowchart TB
    subgraph Mobile["📱 ReCursor Flutter App"]
        UI["OpenCode-like UI\n(Tool Cards, Diff Viewer, Timeline)"]
        State["Riverpod State Management"]
        WSClient["WebSocket Client"]
    end

    subgraph Desktop["💻 Development Machine"]
        Bridge["ReCursor Bridge Server\n(TypeScript)"]
        Hooks["Claude Code Hooks\n(HTTP Event Observer)"]
        AgentSDK["Agent SDK Session\n(Parallel, Optional)"]
        CC["Claude Code CLI"]
    end

    subgraph Anthropic["☁️ Anthropic API"]
        API["Claude API"]
    end

    UI <--> State
    State <--> WSClient
    WSClient <-->|wss:// (Tailscale/WireGuard)| Bridge
    Bridge <-->|HTTP POST| Hooks
    Hooks -->|Observes| CC
    Bridge <-->|Optional| AgentSDK
    AgentSDK <-->|API Calls| API
    CC <-->|Internal| API
```

**Key Constraint:** Claude Code Remote Control is **first-party only** (claude.ai/code, official mobile apps). Third-party clients must use **Hooks** for event observation and **Agent SDK** for parallel sessions.

---

## Important Notes

> ⚠️ **Claude Code Remote Control Protocol**: The Remote Control feature is designed exclusively for first-party Anthropic clients. There is no public API for third-party clients to join or mirror existing Claude Code sessions.
>
> **Supported Integration Paths:**
> - **Claude Code Hooks** — HTTP-based event observation (one-way)
> - **Agent SDK** — Parallel agent sessions (not mirroring)
> - **MCP (Model Context Protocol)** — Tool interoperability
>
> **Bridge-First Workflow:** ReCursor uses a bridge-first, no-login model. The mobile app connects directly to a user-controlled desktop bridge. No hosted accounts, no sign-in required — just secure device pairing via QR code and optional tunneling for remote access.

---

## Contributing

This documentation is a living document. When making changes:

1. Update the relevant `.md` file in the appropriate section
2. Ensure cross-references use relative paths
3. Add Mermaid diagrams for complex flows
4. Update this README index if adding new documents

---

*Last updated: 2026-03-17*
