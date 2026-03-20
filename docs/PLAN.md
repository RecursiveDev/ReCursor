# ReCursor — Implementation Plan

> **Flutter mobile app** providing OpenCode-like UI/UX for AI coding agents. Bridge-first, no-login: connects to your user-controlled desktop bridge.

---

## Architecture Overview

```mermaid
flowchart TB
    subgraph Mobile["📱 ReCursor Flutter App"]
        UI["OpenCode-like UI\n(Tool Cards, Diff Viewer, Timeline)"]
        State["Riverpod State Management"]
        WSClient["WebSocket Client"]
    end

    subgraph Desktop["💻 Development Machine"]
        Bridge["ReCursor Bridge Server\n(TypeScript)"]
        
        subgraph Integration["Claude Code Integration"]
            Hooks["Hooks System\n(HTTP Event Observer)"]
            AgentSDK["Agent SDK\n(Parallel Session)"]
            CC["Claude Code CLI"]
        end
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

### Key Constraints

> ⚠️ **Claude Code Remote Control is first-party only** — there is no public API for third-party clients to join or mirror existing Claude Code sessions.

**Supported Integration Paths:**
- **Claude Code Hooks** — HTTP-based event observation (one-way)
- **Agent SDK** — Parallel agent sessions (not mirroring)
- **MCP (Model Context Protocol)** — Tool interoperability

### Bridge-First, No-Login Workflow

ReCursor uses a **bridge-first** connection model with no user accounts:
- **No sign-in required** — the app opens to bridge pairing/restore, not a login screen
- **User-controlled bridge** — the bridge runs on your development machine, not a hosted service
- **Secure device pairing** — QR code pairing with device tokens stored in secure storage
- **Remote access** — optional secure tunneling (Tailscale, WireGuard) to your own bridge

---

## Phase 1: Foundation

**Goal:** Bootable app with direct bridge connectivity (no auth flow) and basic agent chat with OpenCode-style UI.

### 1.1 Project Scaffolding & CI/CD
- [ ] Initialize Flutter project (iOS + Android targets)
- [ ] Set up directory structure: `lib/core/`, `lib/features/`, `lib/shared/`
- [ ] Configure linting (`flutter_lints`), formatting, analysis options
- [ ] Set up GitHub Actions CI pipeline
- [ ] Configure Fastlane for iOS (Match) and Android (keystore)
- [ ] **Tests:** Verify project builds on both platforms

### 1.2 Bridge Connection & Security (First Screen)
- [ ] Define WebSocket protocol (see [bridge-protocol.md](bridge-protocol.md))
- [ ] Implement WebSocket client service with `web_socket_channel`
- [ ] Connection pairing via QR code (encode bridge URL + device pairing token)
- [ ] Manual URL entry fallback for pairing (generic remote URL support)
- [ ] Restore saved bridge pairings on startup before entering the main shell
- [ ] **Health verification** step after WebSocket connection before entering main shell
- [ ] **Connection mode detection**: local-only, private network, secure remote, direct public remote, misconfigured
- [ ] Connection mode UI indicators (green/yellow/red status per mode)
- [ ] Security warning screen for "direct public remote" mode requiring user acknowledgment
- [ ] "Misconfigured" mode detection and blocking (e.g., `ws://` instead of `wss://`)
- [ ] Tailscale/WireGuard integration documentation / setup guide (user-managed, no built-in automation)
- [ ] Always use `wss://`; optional certificate pinning
- [ ] Auto-reconnect with exponential backoff
- [ ] **Tests:** Unit test WebSocket service with mocks, startup restore logic, connection mode detection, and health verification flow

### 1.4 Basic Agent Chat Interface (OpenCode-style)
- [ ] Chat UI with message list (user messages + agent responses)
- [ ] Streaming text rendering (word-by-word)
- [ ] Markdown rendering for agent responses
- [ ] **OpenCode Pattern**: Message part-based rendering (text, tool_use, tool_result)
- [ ] Send message → bridge → Agent SDK → streamed response flow
- [ ] Session management (start new, resume existing)
- [ ] **Tests:** Widget test chat UI with mock stream

### 1.5 Repository Browsing
- [ ] File tree browsing via bridge
- [ ] File viewer with syntax highlighting
- [ ] **Tests:** Unit test bridge file commands

**Phase 1 Deliverable:** App connects directly to bridge (no auth flow), sends messages to Agent SDK session, displays streamed responses with OpenCode-style UI.

---

## Phase 2: Core Features

**Goal:** Claude Code Hooks integration, tool cards, diff viewer, and push notifications.

### 2.1 Claude Code Hooks Integration
- [ ] Bridge `/hooks/event` endpoint to receive Claude Code events
- [ ] Configure Claude Code to POST events to bridge
- [ ] Event validation and queuing
- [ ] Forward events to connected mobile clients
- [ ] **Tests:** Integration test hook event flow

### 2.2 Tool Cards (OpenCode Pattern)
- [ ] **OpenCode-style Tool Cards**: Rich cards for tool use and results
- [ ] Tool icons based on tool type (edit_file, read_file, run_command, etc.)
- [ ] Expandable tool results with syntax highlighting
- [ ] Tool status indicators (pending, running, completed, error)
- [ ] **Tests:** Widget test tool card states

### 2.3 Code Diff Viewer (OpenCode Pattern)
- [ ] **OpenCode-style Diff Viewer**: Syntax-highlighted unified diff
- [ ] Side-by-side diff option (landscape / tablet)
- [ ] File-by-file navigation for multi-file diffs
- [ ] Inline file status indicators (added, modified, deleted)
- [ ] **Tests:** Golden tests for diff rendering

### 2.4 Session Timeline (OpenCode Pattern)
- [ ] **OpenCode-style Timeline**: Visual timeline of session events
- [ ] Event types: tool use, user messages, agent responses
- [ ] Timeline navigation (jump to specific event)
- [ ] **Tests:** Widget test timeline rendering

### 2.5 Tool Call Approval Flow
- [ ] Display pending tool calls from Hooks (`PreToolUse` events)
- [ ] Approve / reject / modify UI with clear action descriptions
- [ ] Forward approval to Agent SDK session (parallel execution)
- [ ] Audit log of approved/rejected actions
- [ ] **Tests:** Unit test approval state machine

### 2.6 In-App Notifications
- [ ] WebSocket-based notification system
- [ ] Notification types: task complete, approval required, error
- [ ] In-app notification center (bell icon, unread count)
- [ ] Local notifications via `flutter_local_notifications` when backgrounded
- [ ] Event queue on bridge: stores events while app disconnected
- [ ] **Tests:** Integration test event replay on reconnect

**Phase 2 Deliverable:** Users see Claude Code activity via Hooks, view tool cards and diffs with OpenCode-style UI, approve actions, and receive push notifications.

---

## Phase 3: Advanced Features

**Goal:** Voice input, multi-agent support, terminal access, and offline capability.

### 3.1 Voice Commands
- [ ] Speech-to-text via platform APIs (`speech_to_text` package)
- [ ] Voice input button in chat interface
- [ ] Text preview before send (edit transcribed text)
- [ ] **Tests:** Unit test transcription → message flow

### 3.2 Multi-Agent Support
- [ ] Agent registry (Claude Code, OpenCode, Aider, Goose)
- [ ] Per-agent connection management
- [ ] Agent switcher UI
- [ ] Parallel session support
- [ ] **Tests:** Unit test agent registry CRUD

### 3.3 Terminal Session
- [ ] Embedded terminal view (read-only output from bridge)
- [ ] Command input for direct shell access via Agent SDK
- [ ] ANSI color rendering
- [ ] Session history and scrollback
- [ ] **Tests:** Unit test ANSI parsing

### 3.4 Offline Mode
- [ ] Local database with Drift (SQLite) for conversations, tasks, agent configs
- [ ] Hive for lightweight caching (UI preferences, session tokens)
- [ ] Repository pattern: read local first, sync remote in background
- [ ] Offline queue for pending messages/commands
- [ ] Conflict resolution: last-write-wins with `updated_at` timestamps
- [ ] **Tests:** Integration test offline → reconnect flow

**Phase 3 Deliverable:** Voice-driven coding, multi-agent orchestration, terminal access, and full offline capability.

---

## Phase 4: Optimization & Polish

**Goal:** Performance, accessibility, and platform-specific refinements.

### 4.1 Performance
- [ ] Large repo handling (paginated file trees, lazy loading)
- [ ] WebSocket message compression
- [ ] Image and asset caching strategy
- [ ] Memory profiling and optimization
- [ ] **Tests:** Performance benchmarks for large diffs

### 4.2 Tablet & Landscape Layouts
- [ ] Responsive layouts with `LayoutBuilder` / `MediaQuery`
- [ ] Split-view for chat + diff on tablets
- [ ] Landscape-optimized terminal view
- [ ] **Tests:** Widget tests at multiple screen sizes

### 4.3 Accessibility
- [ ] Semantic labels for all interactive elements
- [ ] Screen reader compatibility (TalkBack / VoiceOver)
- [ ] Dynamic type / font scaling support
- [ ] High contrast mode
- [ ] **Tests:** Accessibility audit

### 4.4 Release Preparation
- [ ] App Store metadata, screenshots, descriptions
- [ ] Privacy policy and terms of service
- [ ] Crash reporting (Sentry)
- [ ] Analytics (opt-in, privacy-respecting)
- [ ] Final end-to-end testing on physical devices
- [ ] **Tests:** Full E2E test suite via `patrol`

**Phase 4 Deliverable:** Production-ready app on App Store and Google Play.

---

## Testing Strategy Summary

| Level | Tool | Coverage |
|-------|------|----------|
| **Unit** | `flutter_test` + `mockito` | Services, providers, models, serialization |
| **Widget** | `flutter_test` | UI components with mock dependencies |
| **Golden** | `alchemist` | Visual regression for key screens |
| **Integration** | `integration_test` | Full flows: connect → chat → hooks |
| **E2E** | `patrol` | Complete user journeys on real devices |

---

## Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Framework | Flutter | Cross-platform, CC Pocket precedent |
| State | Riverpod | Type-safe, testable, Conduit pattern |
| Networking | `web_socket_channel` | Standard Flutter WebSocket |
| UI State | Riverpod | Type-safe state management |
| Local DB | Drift (SQLite) | Type-safe queries, migrations |
| Cache | Hive | Fast key-value for ephemeral data |
| Notifications | `flutter_local_notifications` | Local alerts when backgrounded |
| Bridge | TypeScript (Node.js) | CC Pocket pattern |
| Tunnel | Tailscale / WireGuard | Zero-config mesh VPN |
| CI/CD | GitHub Actions + Fastlane | Industry standard |
| Testing | `flutter_test`, `mockito`, `patrol`, `alchemist` | Full coverage pyramid |

---

## Documentation References

- [Architecture Overview](architecture/overview.md) — System architecture
- [Data Flow](architecture/data-flow.md) — Message sequence diagrams
- [Claude Code Hooks Integration](integration/claude-code-hooks.md) — Event observation
- [Agent SDK Integration](integration/agent-sdk.md) — Parallel sessions
- [OpenCode UI Patterns](integration/opencode-ui-patterns.md) — UI component mapping
- [Bridge Protocol](bridge-protocol.md) — WebSocket specification
- [Security Architecture](security-architecture.md) — Security implementation
- [Offline Architecture](offline-architecture.md) — Sync and storage

---

*Last updated: 2026-03-17*
