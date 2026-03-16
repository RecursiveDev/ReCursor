# RemoteCLI - Implementation Plan

> Mobile-first AI coding agent controller built in Flutter.
> Control Claude Code, OpenCode, Aider, and other CLI agents from your phone.

---

## Architecture Overview

```
[Flutter Mobile App] <--wss--> [Bridge Server (TypeScript)] <--> [CLI Agent (Claude Code, etc.)]
        |                              |
   Local DB (Drift)             WebSocket Notifications
   Secure Storage               Tailscale/WireGuard tunnel
```

**Core pattern:** WebSocket bridge (proven by CC Pocket, Conduit, Happy/Happier).
**State management:** Riverpod (aligned with Conduit and modern Flutter conventions).
**Architecture:** Feature-based clean architecture with repository pattern.

---

## Phase 1: Foundation

**Goal:** Bootable app with auth, secure connectivity to bridge, and basic agent chat.

### 1.1 Project Scaffolding & CI/CD
- [ ] Initialize Flutter project (iOS + Android targets)
- [ ] Set up directory structure: `lib/core/`, `lib/features/`, `lib/shared/`
- [ ] Configure linting (`flutter_lints`), formatting, analysis options
- [ ] Set up GitHub Actions CI pipeline:
  - `flutter analyze` -> `flutter test` -> `flutter build`
  - PR triggers: test only; `main` push: test + build artifacts
- [ ] Configure Fastlane for iOS (Match for signing) and Android (keystore via secrets)
- [ ] Set up TestFlight (iOS) and Play Store internal track (Android) distribution
- [ ] **Tests:** Verify project builds on both platforms; lint passes

### 1.2 Authentication
- [ ] Implement GitHub OAuth2 flow (using `github_oauth` or custom WebView)
- [ ] Support Personal Access Token (PAT) auth as fallback
- [ ] Secure token storage via `flutter_secure_storage`
- [ ] Auth state management with Riverpod (auth provider, token refresh)
- [ ] Login / logout UI screens
- [ ] **Tests:** Unit test auth provider state transitions; widget test login screen; mock OAuth flow

### 1.3 Bridge Connection & Security
- [ ] Define WebSocket protocol (message types, handshake, heartbeat)
- [ ] Implement WebSocket client service with `web_socket_channel`
- [ ] Connection pairing via QR code (encode bridge URL + auth token)
- [ ] Tailscale integration documentation / setup guide
- [ ] Always use `wss://`; optional certificate pinning via `SecurityContext`
- [ ] Connection state management (connected / disconnected / reconnecting)
- [ ] Auto-reconnect with exponential backoff
- [ ] **Tests:** Unit test WebSocket service with `StreamController` mocks; test reconnect logic; test auth token validation

### 1.4 Basic Agent Chat Interface
- [ ] Chat UI with message list (user messages + agent responses)
- [ ] Streaming text rendering (word-by-word, using `flutter_gen_ai_chat_ui` or custom)
- [ ] Markdown rendering for agent responses
- [ ] Send message -> bridge -> agent -> streamed response flow
- [ ] Session management (start new, resume existing)
- [ ] **Tests:** Widget test chat UI with mock stream; unit test message serialization; integration test with local WebSocket server

### 1.5 Repository Browsing
- [ ] File tree browsing via bridge (agent reads working directory)
- [ ] File viewer with syntax highlighting (content fetched through bridge)
- [ ] **Tests:** Unit test bridge file commands; widget test file tree

**Phase 1 deliverable:** App authenticates via GitHub, connects to bridge server, sends messages to a CLI agent, and displays streamed responses. Users can browse the agent's working directory.

---

## Phase 2: Core Features

**Goal:** Full git operations, code review, and push notifications.

### 2.1 Git Operations
- [ ] Commit creation (message input, file selection)
- [ ] Push / pull / fetch operations via bridge commands
- [ ] Branch listing, switching, creation
- [ ] Merge and conflict indicator (delegate resolution to agent)
- [ ] Operation status feedback (progress, success, error)
- [ ] **Tests:** Unit test git command serialization; mock bridge responses for each operation; widget test commit screen

### 2.2 Code Diff Viewer
- [ ] Syntax-highlighted unified diff view
- [ ] Side-by-side diff option (landscape / tablet)
- [ ] File-by-file navigation for multi-file diffs
- [ ] Inline commenting / annotation (stored locally, sent to agent)
- [ ] **Tests:** Unit test diff parsing; widget test diff renderer with sample diffs; golden tests for visual regression

### 2.3 In-App Notifications
- [ ] WebSocket-based notification system (bridge pushes events over existing connection)
- [ ] Notification types: task complete, approval required, error, agent idle
- [ ] In-app notification center (bell icon, unread count, notification list)
- [ ] Local notifications via `flutter_local_notifications` when app is backgrounded
- [ ] Deep linking from notification to relevant screen (task, diff, chat)
- [ ] Event queue on bridge: stores events while app is disconnected, replays on reconnect
- [ ] **Tests:** Unit test notification event parsing; integration test deep link routing; test event replay on reconnect

### 2.4 Tool Call Approval Flow
- [ ] Display pending tool calls from agent (file writes, shell commands, etc.)
- [ ] Approve / reject / modify UI with clear action descriptions
- [ ] Notification-driven approval (approve from notification action button)
- [ ] Audit log of approved/rejected actions
- [ ] **Tests:** Widget test approval UI; unit test approval state machine; integration test approval -> bridge -> agent flow

**Phase 2 deliverable:** Users can perform git operations, review diffs, approve agent actions, and receive push notifications — all from mobile.

---

## Phase 3: Advanced Features

**Goal:** Voice input, multi-agent support, and offline capability.

### 3.1 Voice Commands
- [ ] Speech-to-text via platform APIs (`speech_to_text` package)
- [ ] Voice input button in chat interface
- [ ] Optional voice activation / wake word
- [ ] Text preview before send (edit transcribed text)
- [ ] **Tests:** Unit test transcription -> message flow with mock STT; widget test voice input UI

### 3.2 Multi-Agent Support
- [ ] Agent registry (configure multiple agents: Claude Code, OpenCode, Aider, Goose)
- [ ] Per-agent connection management (separate bridge instances or multiplexed)
- [ ] Agent switcher UI
- [ ] Parallel session support (git worktree-backed, as in CC Pocket)
- [ ] **Tests:** Unit test agent registry CRUD; test session multiplexing; widget test agent switcher

### 3.3 Terminal Session
- [ ] Embedded terminal view (read-only output stream from bridge)
- [ ] Command input for direct shell access via bridge
- [ ] ANSI color rendering
- [ ] Session history and scrollback
- [ ] **Tests:** Unit test ANSI parsing; widget test terminal rendering; integration test command execution

### 3.4 Offline Mode
- [ ] Local database with Drift (SQLite) for conversations, tasks, agent configs
- [ ] Hive for lightweight caching (UI preferences, session tokens)
- [ ] Repository pattern: read local first, sync remote in background
- [ ] Offline queue for pending messages/commands (synced on reconnect)
- [ ] Conflict resolution: last-write-wins with `updated_at` timestamps
- [ ] Network detection via `connectivity_plus` + bridge reachability ping
- [ ] **Tests:** Unit test sync queue logic; test conflict resolution; integration test offline -> reconnect flow

**Phase 3 deliverable:** Voice-driven coding, multi-agent orchestration, terminal access, and full offline capability.

---

## Phase 4: Optimization & Polish

**Goal:** Performance, accessibility, and platform-specific refinements.

### 4.1 Performance
- [ ] Large repo handling (paginated file trees, lazy loading)
- [ ] WebSocket message compression
- [ ] Image and asset caching strategy
- [ ] Memory profiling and optimization
- [ ] **Tests:** Performance benchmarks for large diffs and file trees; stress test WebSocket throughput

### 4.2 Tablet & Landscape Layouts
- [ ] Responsive layouts with `LayoutBuilder` / `MediaQuery`
- [ ] Split-view for chat + diff on tablets
- [ ] Landscape-optimized terminal view
- [ ] **Tests:** Widget tests at multiple screen sizes; golden tests for tablet layouts

### 4.3 Accessibility
- [ ] Semantic labels for all interactive elements
- [ ] Screen reader compatibility (TalkBack / VoiceOver)
- [ ] Dynamic type / font scaling support
- [ ] High contrast mode
- [ ] **Tests:** Accessibility audit; semantic tree widget tests

### 4.4 Release Preparation
- [ ] App Store metadata, screenshots, descriptions
- [ ] Privacy policy and terms of service
- [ ] Crash reporting (Sentry)
- [ ] Analytics (opt-in, privacy-respecting)
- [ ] Final end-to-end testing on physical devices
- [ ] **Tests:** Full E2E test suite via `patrol`; smoke tests on CI

**Phase 4 deliverable:** Production-ready app on App Store and Google Play.

---

## Testing Strategy Summary

| Level | Tool | What it covers |
|-------|------|----------------|
| **Unit** | `flutter_test` + `mockito` / `mocktail` | Services, providers, models, serialization, business logic |
| **Widget** | `flutter_test` (widget tester) | UI components in isolation with mock dependencies |
| **Golden** | `alchemist` | Visual regression for key screens and states |
| **Integration** | `integration_test` + local WS server | Full flows: auth -> connect -> chat -> git ops |
| **E2E** | `patrol` | Complete user journeys on real/emulated devices |

**Testing conventions:**
- Mock WebSocket via `StreamController<dynamic>` injected through Riverpod overrides
- Use `expectLater` with `emitsInOrder` / `emits` for stream assertions
- Golden baseline screenshots for connection states (connected, disconnected, reconnecting)
- Integration tests spin up a local Dart WebSocket server in `setUpAll()`
- CI runs `flutter test` on every PR; integration/E2E on `main` merges

---

## Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Framework | Flutter | Cross-platform, strong ecosystem, CC Pocket precedent |
| State | Riverpod | Type-safe, testable, used by Conduit |
| Networking | `web_socket_channel` | Standard Flutter WebSocket client |
| Auth | GitHub OAuth2 + PAT | `github_oauth` package or custom |
| Local DB | Drift (SQLite) | Type-safe queries, migrations, reactive streams |
| Cache | Hive | Fast key-value for preferences and ephemeral data |
| Notifications | `flutter_local_notifications` | Local alerts when backgrounded |
| Bridge | TypeScript (Node.js) | CC Pocket pattern, runs alongside agent |
| Tunnel | Tailscale / WireGuard | Zero-config encrypted mesh networking |
| CI/CD | GitHub Actions + Fastlane | Industry standard for Flutter |
| Testing | `flutter_test`, `mockito`, `patrol`, `alchemist` | Full coverage pyramid |
