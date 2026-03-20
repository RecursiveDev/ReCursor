# Research Report: Benchmark Repositories for Mobile Claude Code Remote Control

> Generated: 2026-03-20 | Researcher Agent

## Executive Summary

This research identifies and analyzes public repositories that implement or approximate "Claude Code remote via mobile" or mobile companion functionality for AI coding agents. After examining 20+ repositories across GitHub, **no repository has fully solved the complete "Claude Code remote from mobile" problem** as ReCursor envisions it. However, several projects provide significant architectural insights and partial solutions that ReCursor should study closely.

**Key Finding**: The ecosystem is fragmented into three categories:
1. **Telegram-based bridges** (most mature) - Remote notifications and approvals via chatbot
2. **Protocol bridges** (most sophisticated) - ACP/HTTP/WebSocket bridges for programmatic access
3. **Notification hooks** (most focused) - Claude Code hooks for mobile push notifications

**Critical Gap**: No existing project combines a native mobile UI (Flutter/React Native) with bidirectional control, session management, and OpenCode-like UX patterns.

---

## Source Validation

| Source | Tier | Date | Relevance |
|--------|------|------|-----------|
| GitHub Repository Analysis | 1 | 2026-03-20 | Primary evidence |
| Repository README/docs | 1 | 2026-03-20 | Architecture details |
| Code structure analysis | 1 | 2026-03-20 | Implementation patterns |

---

## Benchmark Repository Shortlist

### Tier 1: Highest Relevance to ReCursor

#### 1. CCGram (jsayubi/ccgram)
**Repository**: https://github.com/jsayubi/ccgram  
**Stars**: 2 | **Language**: JavaScript/TypeScript | **License**: MIT

**What it does**:  
CCGram is the most feature-complete Telegram-based remote control system for Claude Code. It provides bidirectional communication: Claude Code sends permission requests and questions to Telegram, and users respond via inline buttons that inject keystrokes back into the tmux/PTY session.

**Architecture**:
```
Claude Code → Claude Hooks → CCGram Bot → Telegram → User Phone
     ↑                                              ↓
     └──── tmux/PTY keystroke injection ←───────────┘
```

**Key Features**:
- Permission approvals (Allow/Deny/Always) with blocking flow
- Question answering with selectable options via inline buttons
- Session management (`/sessions`, `/use`, `/stop`)
- Resume past conversations (`/resume` reads from `~/.claude/projects/`)
- Project launcher (`/new myproject`)
- Smart notification suppression (silenced when user is active at terminal)
- Dual injection modes: tmux or headless PTY (node-pty fallback)
- File-based IPC via `/tmp/claude-prompts/`

**Hook Integration**:
| Hook | Event | Function |
|------|-------|----------|
| `permission-hook.js` | `PermissionRequest` | Blocks Claude, sends Telegram message, waits for response |
| `question-notify.js` | `PreToolUse` (AskUserQuestion) | Sends options, injects keystrokes |
| `enhanced-hook-notify.js` | `Stop`, `Notification`, `SessionStart`, `SessionEnd`, `SubagentStop` | Status notifications |
| `user-prompt-hook.js` | `UserPromptSubmit` | Tracks terminal activity for suppression |

**Relevance to ReCursor**:
- ✅ **Similar hook-based approach** - Uses same Claude Code hooks as ReCursor plans
- ✅ **Bidirectional communication** - Proves remote→local injection is viable
- ✅ **Session management** - Pattern for multi-session support
- ✅ **Smart notifications** - Activity-based suppression logic
- ❌ **No native mobile UI** - Telegram bot only, no Flutter app
- ❌ **Limited to chat interface** - No tool cards, diffs, or timeline
- ❌ **No Agent SDK integration** - Only hooks + tmux/PTY injection

**Lessons for ReCursor**:
1. File-based IPC (`/tmp/claude-prompts/`) is a simple, reliable pattern for hook→bridge communication
2. Blocking permission flows require careful timeout handling and cleanup
3. Session persistence via `~/.claude/projects/` enables resume functionality
4. Activity detection (`UserPromptSubmit` hook) enables smart notification suppression
5. PTY injection is a viable alternative to tmux for headless operation

---

#### 2. BAREclaw (elliotbonneville/bareclaw)
**Repository**: https://github.com/elliotbonneville/bareclaw  
**Stars**: 19 | **Language**: TypeScript | **License**: MIT

**What it does**:  
BAREclaw is a thin multiplexer daemon that bridges any messaging channel (HTTP, Telegram, SMS, etc.) to persistent Claude Code CLI processes. It shells out to `claude -p` rather than using the Agent SDK, routing through the Claude Max subscription for $0 marginal cost.

**Architecture**:
```
[curl / Telegram / SMS / ...]
    → Adapter → ProcessManager
        → Session Host (detached process per channel)
            → Persistent Claude process
        ← Response via same channel
```

**Key Components**:
- **ProcessManager**: Core orchestrator managing channels, spawning session hosts, FIFO dispatch
- **Session Hosts**: Detached processes holding single Claude sessions, communicating via Unix sockets
- **Adapters**: Thin translation layers (HTTP, Telegram) deriving channel keys from protocol session boundaries
- **PushRegistry**: Routes outbound messages to correct adapter by channel prefix

**Key Features**:
- One persistent Claude process per channel (conversation context)
- Strict FIFO queuing per channel with message coalescing
- Session persistence across restarts (saved to `.bareclaw-sessions.json`)
- Self-restart capability (Claude can modify BAREclaw's source and trigger restart)
- Heartbeat system (hourly scheduled job)
- Multi-tenant channel isolation

**Relevance to ReCursor**:
- ✅ **Channel abstraction** - Clean separation of transport from session management
- ✅ **Process-per-channel model** - Isolates sessions, enables concurrent conversations
- ✅ **Adapter pattern** - Easy to add new transport mechanisms (could include WebSocket for mobile)
- ✅ **Session persistence** - JSON-based session recovery with `--resume`
- ❌ **No native mobile app** - HTTP/Telegram only
- ❌ **No structured UI components** - Plain text responses only
- ❌ **Uses CLI spawning** - Not Agent SDK based

**Lessons for ReCursor**:
1. Channel abstraction (one Claude process per conversation) scales better than shared sessions
2. Unix domain sockets provide reliable IPC between session hosts and manager
3. FIFO queuing with coalescing handles rapid-fire messages gracefully
4. Session persistence via JSON files enables recovery without data loss
5. Adapter pattern allows transport-agnostic core (HTTP, WebSocket, etc.)

---

#### 3. ACP Bridge (xiwan/acp-bridge)
**Repository**: https://github.com/xiwan/acp-bridge  
**Stars**: 18 | **Language**: Python | **License**: MIT-0

**What it does**:  
ACP Bridge exposes local CLI agents (Kiro CLI, Claude Code, OpenAI Codex) via the Agent Client Protocol (ACP) over HTTP, with async job support and Discord push notifications. It provides a standardized HTTP API for multiple agent backends.

**Architecture**:
```
Discord/User → OpenClaw Gateway → ACP Bridge (uvicorn) → CLI Agent (ACP stdio)
                                              ↓
                                       Async job queue
                                              ↓
                                       Webhook callback
```

**Key Features**:
- Native ACP protocol support (structured event stream: thinking/tool_call/text/status)
- Process pool with subprocess reuse per session
- Sync + SSE streaming + Markdown card output
- Async jobs with webhook callbacks
- Multi-IM formatter (Discord/Feishu)
- Auto-reply to `session/request_permission` (prevents Claude hanging)
- Bearer Token + IP allowlist authentication
- OpenClaw tools proxy (unified entry for message/tts/web_search/nodes/cron)
- Client is pure bash + jq (zero Python dependency)

**API Endpoints**:
| Method | Path | Description |
|--------|------|-------------|
| GET | `/agents` | List registered agents |
| POST | `/runs` | Sync/streaming agent call |
| POST | `/jobs` | Submit async job |
| GET | `/jobs/{job_id}` | Query job status |
| GET | `/health` | Health check |

**Relevance to ReCursor**:
- ✅ **Multi-agent support** - Handles Kiro, Claude Code, Codex uniformly
- ✅ **ACP protocol** - Standardized agent communication protocol
- ✅ **Async job pattern** - Long-running tasks with webhook completion
- ✅ **SSE streaming** - Real-time response streaming to clients
- ✅ **Process pool** - Efficient subprocess reuse with context retention
- ❌ **No mobile UI** - HTTP API only, no Flutter/React Native
- ❌ **Discord-centric** - Designed for chat bot integration
- ❌ **Complex setup** - Requires OpenClaw Gateway for notifications

**Lessons for ReCursor**:
1. ACP protocol provides structured event types (thinking/tool_call/text/status)
2. Process pools with session-scoped reuse enable efficient multi-turn conversations
3. Async job pattern with webhooks handles long-running tasks gracefully
4. SSE streaming is essential for real-time UX in mobile contexts
5. Multi-agent abstraction allows supporting Claude + other agents

---

#### 4. Agent-WS (Lisovate/agent-ws)
**Repository**: https://github.com/Lisovate/agent-ws  
**Stars**: 29 | **Language**: TypeScript | **License**: MIT

**What it does**:  
Agent-WS is a WebSocket bridge for CLI AI agents. It streams responses from Claude Code and Codex CLI over WebSocket, acting as a "dumb pipe" with no prompt engineering or credential handling.

**Architecture**:
```
┌───────────────┐     WebSocket      ┌─────────────┐      stdio       ┌─────────────┐
│  Your App     │ <=================> │  agent-ws   │ <===============> │ Claude Code │
│  (any client) │   localhost:9999   │  (Node.js)  │      stdio       │  / Codex    │
└───────────────┘                    └─────────────┘                   └─────────────┘
```

**Key Features**:
- One CLI process per WebSocket connection
- Real-time streaming via WebSocket
- Supports Claude Code and Codex
- Process lifecycle management (timeout, cancellation, cleanup)
- Library usage for embedding in Node.js backends
- Security: localhost-only, origin validation, no credential storage

**Protocol**:
```json
// Client → Agent
{ "type": "prompt", "prompt": "Build a login form", "requestId": "uuid", "provider": "claude" }
{ "type": "cancel", "requestId": "uuid" }

// Agent → Client
{ "type": "connected", "version": "1.0", "agent": "agent-ws" }
{ "type": "chunk", "content": "Here's a login form...", "requestId": "uuid" }
{ "type": "complete", "requestId": "uuid" }
```

**Relevance to ReCursor**:
- ✅ **WebSocket transport** - Ideal for mobile real-time communication
- ✅ **Clean protocol design** - Simple JSON message types
- ✅ **Process isolation** - One process per connection
- ✅ **Library embedding** - Can be integrated into larger systems
- ❌ **No mobile client** - Just the bridge, no UI
- ❌ **No hooks integration** - Direct CLI spawning only
- ❌ **No session persistence** - Each connection is independent

**Lessons for ReCursor**:
1. WebSocket is the right transport for mobile real-time communication
2. Simple JSON protocols are easier to implement across platforms
3. Process-per-connection provides isolation but may not scale
4. Library embedding pattern allows integration into existing backends

---

### Tier 2: Moderate Relevance

#### 5. CC-Bridge (ranaroussi/cc-bridge)
**Repository**: https://github.com/ranaroussi/cc-bridge  
**Stars**: 42 | **Language**: Go | **License**: MIT

**What it does**:  
Provides Anthropic API compatibility using the official Claude Code CLI under the hood. Wraps `claude -p` to expose an OpenAI-compatible HTTP API.

**Key Features**:
- 100% Anthropic API compatible (SDKs work without changes)
- SSE streaming support
- Tool use emulation via prompt engineering
- Vision and PDF support
- macOS menu bar app available

**Relevance to ReCursor**:
- ✅ **API compatibility layer** - Pattern for bridging CLI to HTTP API
- ✅ **Tool use emulation** - How to expose CLI tools via API
- ❌ **No mobile focus** - Desktop/server oriented
- ❌ **No hooks** - Pure CLI wrapping

---

#### 6. Claude Telegram Bridge (viniciustodesco/claude-telegram-bridge)
**Repository**: https://github.com/viniciustodesco/claude-telegram-bridge  
**Stars**: 7 | **Language**: JavaScript | **License**: MIT

**What it does**:  
Control Claude Code CLI via Telegram with real-time streaming, vision (images), and audio transcription (Whisper API).

**Key Features**:
- Real-time streaming responses
- Context persistence across messages
- Image analysis (vision)
- Voice message transcription
- Multi-language support (EN/PT/NL)
- Group chat support

**Relevance to ReCursor**:
- ✅ **Multimodal support** - Images and audio handling
- ✅ **Streaming UX** - Real-time response updates
- ❌ **Telegram-only** - No native mobile app
- ❌ **No structured UI** - Chat interface only

---

#### 7. OpenClaw Bridge (totorospirit/cc-openclaw-bridge)
**Repository**: https://github.com/totorospirit/cc-openclaw-bridge  
**Stars**: 4 | **Language**: TypeScript | **License**: MIT

**What it does**:  
MCP server that gives Claude Code a voice when running headless. Questions and notifications delivered through OpenClaw to messaging apps (Telegram, Signal, Discord).

**Key Features**:
- MCP server architecture
- File-based IPC (`/tmp/cc-openclaw-bridge/`)
- Async question/answer flow
- Auto-summary on session exit
- Multi-agent support

**Relevance to ReCursor**:
- ✅ **MCP pattern** - Model Context Protocol integration
- ✅ **File-based IPC** - Simple, reliable communication
- ❌ **No mobile app** - Messaging bridge only
- ❌ **Requires OpenClaw** - Tight coupling to specific platform

---

### Tier 3: Niche/Minimal Solutions

#### 8. VSCode MobilePush (j0nb05/VSCode_Mobilepush)
**Repository**: https://github.com/j0nb05/VSCode_Mobilepush  
**Stars**: 0 | **Language**: JavaScript

**What it does**:  
Claude Code hook that sends tool approval requests to phone via push notifications. Express + Socket.IO server with QR-based device pairing and PWA client.

**Relevance to ReCursor**:
- ✅ **Push notification approach** - Alternative to polling
- ✅ **PWA client** - Web-based mobile UI
- ❌ **Limited scope** - Only approvals, not full control
- ❌ **Early stage** - Minimal implementation

---

## Comparative Analysis Matrix

| Repository | Mobile UI | Hooks | Agent SDK | WebSocket | Session Mgmt | Bidirectional | OpenCode-like UX |
|------------|-----------|-------|-----------|-----------|--------------|---------------|------------------|
| CCGram | ❌ Telegram | ✅ | ❌ | ❌ | ✅ | ✅ | ❌ |
| BAREclaw | ❌ HTTP/Telegram | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |
| ACP Bridge | ❌ HTTP | ❌ | ❌ | ❌ (SSE) | ✅ | ✅ | ❌ |
| Agent-WS | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ |
| CC-Bridge | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Claude-Telegram | ❌ Telegram | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |
| OpenClaw Bridge | ❌ | ✅ (MCP) | ❌ | ❌ | ✅ | ✅ | ❌ |
| **ReCursor (planned)** | ✅ Flutter | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## Critical Findings

### Has any repo truly solved "Claude Code remote from mobile"?

**No.** No existing repository provides a complete solution matching ReCursor's vision:

1. **No native mobile UI**: All solutions use Telegram bots, HTTP APIs, or messaging platforms. None provide a purpose-built mobile app with OpenCode-like UX patterns (tool cards, diffs, timeline).

2. **No Agent SDK integration**: Most solutions shell out to `claude -p` CLI rather than using the Agent SDK. This limits programmatic control and requires Claude Max subscription.

3. **Limited bidirectional control**: While CCGram and BAREclaw achieve bidirectional communication, they rely on tmux/PTY injection or CLI spawning rather than proper SDK APIs.

4. **No structured UI components**: All solutions are text/chat-based. None render tool cards, file diffs, git operations, or timeline views.

5. **No offline/queue support**: All solutions require persistent connectivity. None provide offline queuing with sync.

### What ReCursor can learn from each:

| Repository | Key Lesson |
|------------|------------|
| CCGram | File-based IPC is reliable; session persistence enables resume; activity detection enables smart notifications |
| BAREclaw | Channel abstraction scales well; FIFO queuing with coalescing handles rapid messages; session hosts provide isolation |
| ACP Bridge | ACP protocol provides structured events; process pools enable efficient multi-turn; async jobs handle long tasks |
| Agent-WS | WebSocket is ideal transport; simple JSON protocols work well; process-per-connection provides isolation |
| OpenClaw Bridge | MCP pattern enables tool exposure; file-based IPC is simple and reliable |

---

## Recommendations for ReCursor

### Architecture Decisions Based on Benchmarks

1. **Use WebSocket (not HTTP polling)**: Agent-WS and BAREclaw demonstrate WebSocket is the right transport for real-time mobile communication.

2. **Implement channel/session abstraction**: BAREclaw's channel model provides clean isolation and scalability.

3. **Support both hooks and Agent SDK**: CCGram's hook-based approach is proven for notifications/approvals; Agent SDK provides deeper integration.

4. **File-based IPC for hooks**: CCGram and OpenClaw Bridge use `/tmp/` file-based IPC successfully—simple and reliable.

5. **Process pool for Agent SDK**: ACP Bridge's process pool pattern enables efficient session reuse.

6. **Session persistence**: All mature solutions persist session state—essential for resume functionality.

### Gaps ReCursor Should Fill

1. **Native Flutter UI**: No competitor has this—major differentiation
2. **OpenCode-like UX**: Tool cards, diffs, timeline—unprecedented in mobile
3. **Offline support**: Queue actions when disconnected
4. **Agent SDK integration**: Most use CLI spawning
5. **Structured data**: JSON-based tool results, not just text

---

## References

| Repository | URL | Stars | Last Updated |
|------------|-----|-------|--------------|
| CCGram | https://github.com/jsayubi/ccgram | 2 | 2026-02-25 |
| BAREclaw | https://github.com/elliotbonneville/bareclaw | 19 | 2026-02-25 |
| ACP Bridge | https://github.com/xiwan/acp-bridge | 18 | 2026-03-19 |
| Agent-WS | https://github.com/Lisovate/agent-ws | 29 | 2026-03-16 |
| CC-Bridge | https://github.com/ranaroussi/cc-bridge | 42 | 2026-01-10 |
| Claude-Telegram | https://github.com/viniciustodesco/claude-telegram-bridge | 7 | 2025-11-15 |
| OpenClaw Bridge | https://github.com/totorospirit/cc-openclaw-bridge | 4 | 2026-03-03 |
| VSCode MobilePush | https://github.com/j0nb05/VSCode_Mobilepush | 0 | 2026-03-11 |

---

## Research Methodology

- **Search Queries**: "Claude Code remote mobile", "Claude Code API bridge", "AI coding agent mobile companion", "Claude Telegram bot", "OpenCode mobile", "Claude Code hooks websocket"
- **Analysis Depth**: README review, architecture documentation, code structure analysis
- **Validation**: Cross-referenced claims with code structure where possible
- **Limitations**: Did not perform live testing of repositories; analysis based on documentation and static code review
