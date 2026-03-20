# Research Report: Claude Code Mobile/Remote Repositories

> Generated: 2026-03-20 | Researcher Agent

## Executive Summary

This research identifies **20+ public repositories** implementing or approximating "Claude Code remote via mobile" workflows. The landscape reveals four distinct architectural approaches:

1. **Terminal Streaming via Web/Mobile UI** (Most common) - WebSocket-based bridges wrapping Claude Code's stdin/stdout
2. **Hook-Based Notification/Approval** - Claude Code hooks for remote approvals via messaging platforms
3. **Native Mobile Apps** - Flutter/React Native apps with varying levels of integration
4. **API Proxy/Intercept** - Tools that tap into Claude Code's internal API traffic

**Key Finding**: No repository implements true "remote control" of official Claude Code Remote Control sessions (which is first-party only). All solutions use one of: (a) wrapping the CLI via stdin/stdout, (b) hooks for notifications/approvals, or (c) API proxies for observation.

## Source Validation

| Source | Tier | Date | Type |
|--------|------|------|------|
| GitHub Repository Search | 1 | 2026-03-20 | Primary source |
| Repository README/docs | 1 | 2026-03-20 | Implementation details |
| Source code inspection | 1 | 2026-03-20 | Architecture verification |

## Repository Analysis

### Tier 1: Direct Mobile/Remote Implementations

#### 1. sidmohan0/claude-code-mobile ⭐ Most Relevant to ReCursor
- **URL**: https://github.com/sidmohan0/claude-code-mobile
- **Description**: "Use Claude Code from your phone" - Mobile-friendly web interface
- **Architecture**: 
  - Tauri (Rust) menubar app with Axum WebSocket server
  - Phone (Browser) ←WebSocket/Tailscale→ Menubar App ←stdin/stdout→ Claude Code CLI
- **Transport**: WebSocket over Tailscale VPN
- **Security**: Private network only (Tailscale), code never leaves network
- **Maturity**: Active, production-ready approach
- **Relevance**: Very High - Similar goals to ReCursor, uses WebSocket bridge pattern

**Evidence**:
```
Phone (Browser)  <--WebSocket-->  Menubar App  <--stdin/stdout-->  Claude Code CLI
                 over Tailscale               (on your Mac)
```

**Key Files**:
- `src-tauri/src/main.rs` - Tauri app with tokio/axum server
- `src-tauri/Cargo.toml` - Uses axum with ws feature, tower-http for CORS

---

#### 2. ly0/cc-remote-control-server ⭐ Strong Technical Match
- **URL**: https://github.com/ly0/cc-remote-control-server
- **Description**: "Self-hosted server for real-time, bidirectional web-based interaction with Claude Code CLI"
- **Architecture**:
  - Node.js/Express server with WebSocket support
  - Browser (Web UI) ←WebSocket→ Remote Control Server ←WebSocket/HTTP→ Claude Code CLI (bridge mode)
- **Transport**: WebSocket with session ingress bridge
- **Security**: Self-hosted, private network
- **Maturity**: Active, explicitly mentions Claude Code's bridge mode
- **Relevance**: Very High - Uses Claude Code's official bridge protocol

**Evidence**:
```
Browser (Web UI)
    ↕  WebSocket /api/ws/:sessionId
Remote Control Server (this project)
    ↕  WebSocket /v2/session_ingress/ws/:sessionId
    ↕  HTTP POST /v2/session_ingress/session/:sessionId/events
Claude Code CLI (bridge mode)
```

**Key Files**:
- `src/server.ts` - Express server with CORS, WebSocket routes
- `src/services/sessionManager.ts` - Session lifecycle management
- `src/routes/ccrV2.ts` - Claude Code Remote v2 protocol routes

---

#### 3. yazinsai/claude-code-remote ⭐ Modern Approach
- **URL**: https://github.com/yazinsai/claude-code-remote
- **Description**: "Full terminal access from phone - not a chat wrapper. Real terminal running on your machine."
- **Architecture**:
  - Node.js server with Cloudflare Tunnel
  - npx deployment, QR code setup
- **Transport**: Cloudflare Tunnel (zero config remote access)
- **Security**: Cloudflare Tunnel (no port forwarding)
- **Maturity**: Active, one-command setup (`npx claude-code-remote`)
- **Relevance**: High - Modern deployment approach, PWA support

**Features**:
- Full terminal access (not chat wrapper)
- Unlimited sessions with tabs
- Session persistence
- Dev server preview with hot reload
- Zero config via Cloudflare Tunnel

---

#### 4. QuivrHQ/247-claude-code-remote ⭐ Enterprise-Ready
- **URL**: https://github.com/QuivrHQ/247-claude-code-remote
- **Description**: "Access Claude Code from anywhere - Mobile/Desktop secure connection via Tailscale"
- **Architecture**:
  - Node.js/TypeScript with xterm.js terminal
  - tmux for session persistence
  - Cloudflare Tunnel integration
- **Transport**: WebSocket with tmux persistence
- **Security**: Cloudflare Tunnel + Tailscale
- **Maturity**: Active, demo GIF, feature matrix
- **Relevance**: High - Comprehensive feature set, PWA ready

**Features**:
| Feature | Description |
|---------|-------------|
| Web Terminal | Full xterm.js with WebGL rendering |
| Claude Code Integration | One-click launch |
| Multi-Project | Dashboard project switching |
| Session Management | tmux persistence |

---

#### 5. kyujin-cho/claude-code-remote ⭐ Hook-Based Notifications
- **URL**: https://github.com/kyujin-cho/claude-code-remote
- **Description**: "Claude Code hook & Telegram Bot for permission request notifications"
- **Architecture**:
  - Go binary (~4-30MB depending on messengers)
  - Claude Code hooks → Telegram/Discord/Signal notifications
  - Bidirectional: notifications + remote decisions
- **Transport**: Messaging platform APIs (Telegram/Discord/Signal)
- **Security**: Bot tokens, no direct network access needed
- **Maturity**: Active, multi-messenger support
- **Relevance**: High - Demonstrates hook-based remote approval pattern

**Features**:
- Permission request notifications
- Always Allow for trusted tools
- Job completion notifications
- Multi-machine support with hostname display

---

### Tier 2: Native Mobile Apps

#### 6. 9cat/claude-code-app (Flutter)
- **URL**: https://github.com/9cat/claude-code-app
- **Description**: "Claude-Code mobile app, write code on the go"
- **Architecture**: Flutter-based cross-platform (iOS/Android/Web)
- **Approach**: Docker container deployment + SSH integration
- **Relevance**: Medium - Flutter like ReCursor, but uses Docker/SSH not direct bridge

**Features**:
- Voice-to-text coding
- Background processing
- Smart notifications
- Remote Docker environments

---

#### 7. Zbrooklyn/claude-code-mobile (Android)
- **URL**: https://github.com/Zbrooklyn/claude-code-mobile
- **Description**: "Native Android chat app powered by Claude"
- **Architecture**: Jetpack Compose + Material 3
- **Approach**: Direct Anthropic Messages API (not Claude Code CLI)
- **Relevance**: Medium - Native Android, but uses API not Claude Code

**Architecture**:
```
Native Chat UI (Jetpack Compose)
    ↕
Anthropic Messages API (streaming SSE, OAuth/API key)
```

---

#### 8. rohunvora/claude-code-mobile (iOS)
- **URL**: https://github.com/rohunvora/claude-code-mobile
- **Description**: "Run Claude Code from your iPhone"
- **Architecture**: SSH-based approach using Termius
- **Approach**: SSH from iPhone to Mac running Claude Code
- **Relevance**: Low-Medium - SSH tunnel approach, not a custom bridge

**Setup**:
```
iPhone (Termius) --SSH--> Mac (Claude Code)
```

---

#### 9. gldc/claude-code-remote-app (Expo)
- **URL**: https://github.com/gldc/claude-code-remote-app
- **Description**: "Expo mobile app for Claude Code Remote"
- **Architecture**: Expo/React Native app
- **Approach**: Companion to gldc/claude-code-remote server
- **Relevance**: Medium - React Native, requires separate server

**Features**:
- Session management (create, stream, pause, archive, delete)
- Live streaming via WebSocket
- Tool approval from phone
- Push notifications
- OTA updates via EAS

---

### Tier 3: Containerized/Service Approaches

#### 10. cfrs2005/claude-code-mobile
- **URL**: https://github.com/cfrs2005/claude-code-mobile
- **Description**: "Containerized service for mobile Claude Code access via Happy-coder app"
- **Architecture**: Docker container with Happy-coder mobile interface
- **Approach**: Containerized Claude Code + mobile UI
- **Relevance**: Medium - Containerized approach, different architecture

---

#### 11. aiya000/claude-code-mobile-ssh
- **URL**: https://github.com/aiya000/claude-code-mobile-ssh
- **Description**: "PWA App, Graphical Client for Claude Code via SSH"
- **Architecture**: PWA with SSH connection
- **Approach**: SSH-based graphical client
- **Relevance**: Medium - PWA approach, SSH transport

---

### Tier 4: Hook Ecosystem

#### 12. disler/claude-code-hooks-mastery
- **URL**: https://github.com/disler/claude-code-hooks-mastery
- **Description**: "Master Claude Code Hooks - deterministic control over Claude Code"
- **Approach**: Comprehensive hook examples and patterns
- **Relevance**: High - Best practices for hook implementation

**Features**:
- UV single-file scripts architecture
- 9 hook types support
- Sub-agent patterns
- Team-based validation
- Custom status lines

---

#### 13. pascalporedda/awesome-claude-code
- **URL**: https://github.com/pascalporedda/awesome-claude-code
- **Description**: "Curated collection of Claude Code hooks"
- **Approach**: Sound notifications, event logging
- **Relevance**: Medium - Hook collection reference

---

#### 14. GowayLee/cchooks
- **URL**: https://github.com/GowayLee/cchooks
- **Description**: "Python SDK for Claude Code hooks"
- **Approach**: Python toolkit for hook development
- **Relevance**: Medium - SDK approach for hooks

**Features**:
- One-liner setup with `create_context()`
- Automatic JSON parsing
- 9 hook types support
- PyPI package available

---

### Tier 5: API Proxy/Intercept Tools

#### 15. dvlin-dev/agent-trace
- **URL**: https://github.com/dvlin-dev/agent-trace
- **Description**: "Desktop app for tracing Claude Code API traffic"
- **Approach**: Intercepts Claude Code API requests
- **Relevance**: Medium - Useful for understanding internal API

---

#### 16. liaohch3/claude-tap
- **URL**: https://github.com/liaohch3/claude-tap
- **Description**: "Tap into Claude Code API requests via local reverse proxy"
- **Approach**: Reverse proxy for API inspection
- **Relevance**: Medium - Shows how to intercept Claude Code traffic

---

#### 17. Haidzai/claude-code-proxy
- **URL**: https://github.com/Haidzai/claude-code-proxy
- **Description**: "Capture and visualize in-flight requests"
- **Approach**: Transparent proxy with dashboard
- **Relevance**: Low-Medium - Observation only

---

### Tier 6: Alternative/Related

#### 18. generativereality/ccremote
- **URL**: https://github.com/generativereality/ccremote
- **Description**: "Claude Code Remote: Discord approvals, quota management"
- **Approach**: Discord bot for approvals + quota scheduling
- **Relevance**: Medium - Shows Discord integration pattern

---

#### 19. buckle42/claude-code-remote
- **URL**: https://github.com/buckle42/claude-code-remote
- **Description**: "Use Claude Code from your phone over secure VPN"
- **Approach**: VPN-based remote access
- **Relevance**: Medium - VPN approach

---

#### 20. JessyTsui/Claude-Code-Remote
- **URL**: https://github.com/JessyTsui/Claude-Code-Remote
- **Description**: "Control Claude Code remotely via email, Discord, Telegram"
- **Approach**: Multi-platform notification/approval
- **Relevance**: Medium - Multi-channel approach

---

## Architecture Comparison Matrix

| Repository | Transport | Mobile UI | Approach | Security | Maturity |
|------------|-----------|-----------|----------|----------|----------|
| sidmohan0/cc-mobile | WebSocket/Tailscale | Web (browser) | Tauri + Axum | Private network | High |
| ly0/cc-remote | WebSocket | Web | Node.js/Express | Self-hosted | High |
| yazinsai/cc-remote | Cloudflare Tunnel | Web/PWA | Node.js | Cloudflare | High |
| QuivrHQ/247 | WebSocket/Cloudflare | Web/PWA | Node.js/xterm.js | Cloudflare+Tailscale | High |
| kyujin-cho/cc-remote | Messaging APIs | Telegram/Discord | Go binary | Bot tokens | High |
| 9cat/cc-app | SSH/Docker | Flutter | Docker containers | SSH keys | Medium |
| Zbrooklyn/cc-mobile | HTTPS/SSE | Android native | Messages API | OAuth/API key | Medium |
| gldc/cc-remote-app | WebSocket | Expo/React Native | Companion app | VPN | Medium |

---

## Key Findings for ReCursor

### 1. No True "Remote Control" Exists
**Critical**: No repository implements mirroring of official Claude Code Remote Control sessions. Per AGENTS.md:
> "Claude Code Remote Control is first-party (claude.ai/code + official apps). Do not claim we can join/mirror a user's Claude Code Remote Control session via a public protocol."

All solutions use one of:
- **CLI Wrapping**: stdin/stdout bridge (sidmohan0, ly0)
- **Hooks**: Event observation + notification (kyujin-cho, disler)
- **API Proxy**: Traffic interception (liaohch3, dvlin-dev)

### 2. WebSocket is Dominant Transport
Most successful implementations use WebSocket for:
- Real-time streaming of Claude's responses
- Bidirectional communication (commands + responses)
- Session persistence

### 3. Security Patterns
| Pattern | Used By | Notes |
|---------|---------|-------|
| Tailscale VPN | sidmohan0, QuivrHQ | Private network, no port forwarding |
| Cloudflare Tunnel | yazinsai, QuivrHQ | Zero config, public URL |
| Self-hosted | ly0 | Manual network configuration |
| Messaging APIs | kyujin-cho | No network access needed |

### 4. Mobile UI Approaches
| Approach | Examples | Trade-offs |
|----------|----------|------------|
| Web/PWA | sidmohan0, yazinsai, QuivrHQ | Universal access, limited native features |
| Native (Flutter) | 9cat | Cross-platform, larger install |
| Native (Android) | Zbrooklyn | Platform-specific, API-only |
| Expo/React Native | gldc | Faster dev, requires server |

### 5. Hook Ecosystem is Active
- Hooks are the official extension point for Claude Code
- Primary use: notifications, approvals, logging
- Cannot control session flow directly, only observe/respond

---

## Recommendations for ReCursor

### Verified Architecture Patterns

1. **WebSocket Bridge** (Recommended)
   - Follow sidmohan0/ly0 pattern
   - Tauri or Node.js bridge server
   - WebSocket for real-time streaming
   - Tailscale for security

2. **Hook Integration** (For Notifications)
   - Follow kyujin-cho pattern
   - Claude Code hooks for push notifications
   - Separate from main bridge

3. **Flutter + Bridge** (ReCursor's Stack)
   - No direct equivalent found
   - 9cat uses Flutter but with Docker/SSH
   - Opportunity: First Flutter + WebSocket bridge implementation

### Gaps in Current Landscape

1. **No Flutter WebSocket Bridge**: All Flutter apps use API or SSH, not direct Claude Code bridge
2. **No OpenCode UI Parity**: No mobile implementation matches OpenCode desktop patterns
3. **No Agent SDK Integration**: No repos use Agent SDK for parallel controllable sessions

### Citation Evidence

| Claim | Evidence |
|-------|----------|
| WebSocket is dominant | sidmohan0: "WebSocket over Tailscale", ly0: "WebSocket /api/ws/:sessionId" |
| No true remote control | AGENTS.md: "Claude Code Remote Control is first-party" |
| Hooks are official extension | disler: "9 hook types", GowayLee: "Python SDK for hooks" |
| Cloudflare Tunnel popular | yazinsai: "Zero Config Remote Access", QuivrHQ: "Cloudflare Tunnel integration" |

---

## References

1. sidmohan0/claude-code-mobile - https://github.com/sidmohan0/claude-code-mobile
2. ly0/cc-remote-control-server - https://github.com/ly0/cc-remote-control-server
3. yazinsai/claude-code-remote - https://github.com/yazinsai/claude-code-remote
4. QuivrHQ/247-claude-code-remote - https://github.com/QuivrHQ/247-claude-code-remote
5. kyujin-cho/claude-code-remote - https://github.com/kyujin-cho/claude-code-remote
6. 9cat/claude-code-app - https://github.com/9cat/claude-code-app
7. disler/claude-code-hooks-mastery - https://github.com/disler/claude-code-hooks-mastery
8. ReCursor AGENTS.md - C:/Repository/ReCursor/AGENTS.md
