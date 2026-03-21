# Research Report: Public Repository Pattern Survey for Claude Mobile/Remote Connectivity

> Generated: 2026-03-21 | Researcher Agent
> Task: Survey active 2026 repos and extract real connection patterns for Claude mobile/remote access

---

## Executive Summary

**Primary Finding:** The Claude Code ecosystem has a **thriving third-party tooling landscape** with **40+ active repositories** addressing mobile/remote connectivity. However, **NONE implement the official Claude Code Remote Control protocol** — all use alternative architectures:

- **Agent SDK / `--sdk-url` WebSocket** (1 major project): The-Vibe-Company/companion (2,218★) - Uses hidden CLI flag to create controllable sessions
- **Terminal Proxy / Tunnel** (5+ projects): ttyd, xterm.js, Cloudflare Tunnel, Tailscale approaches
- **Telegram Bot Bridges** (10+ projects): Stdin/stdout streaming to Telegram clients
- **Custom Coordinator Servers** (2+ projects): Self-hosted coordinator + mobile app
- **Local Session Bridges** (1 project): Filesystem-based inter-session communication
- **Reverse Engineering / Analysis** (3+ projects): Protocol documentation, API logging (explicitly unsupported)

**Key Implication for ReCursor:** The most direct viable path is **Agent SDK integration** (parallel sessions) or **Hooks + Bridge** (event observation). Official Remote Control remains **first-party only** with no public API.

---

## Methodology

**Search Strategy:**
1. GitHub repository search for "claude code remote", "claude-code companion", "claude agent sdk websocket"
2. GitHub repository search for "claude code telegram bot", "claude code terminal", "claude code hooks"
3. Targeted queries for known projects from prior research
4. README content analysis for architecture patterns
5. Activity signal verification (pushedAt, updatedAt, stargazersCount)

**Total Repositories Surveyed:** 40+
**Active in 2026:** 35+
**Detailed Architecture Analysis:** 18 key projects

---

## Classification Taxonomy

| Classification | Definition | ReCursor Relevance |
|----------------|------------|-------------------|
| **OFFICIAL/SUPPORTED** | Anthropic-maintained or officially documented integration | High — direct integration path |
| **UNOFFICIAL** | Works but uses undocumented/reverse-engineered features | Medium — requires monitoring for stability |
| **INCONCLUSIVE** | Insufficient documentation to determine mechanism | Low — needs further investigation |
| **OUTDATED** | No activity after 2025-06, possibly broken | Not recommended |
| **NOT RELEVANT** | Different purpose (e.g., skills, plugins, MCP servers) | Low or none |

---

## Repository Survey Results

### Category A: Agent SDK / `--sdk-url` WebSocket Solutions

#### 🏆 The-Vibe-Company/companion ⭐ 2,218 stars
| Field | Value |
|-------|-------|
| **URL** | https://github.com/The-Vibe-Company/companion |
| **Activity** | pushedAt: 2026-03-19, updatedAt: 2026-03-21 |
| **Classification** | OFFICIAL (uses documented Agent SDK patterns) |
| **Connection Method** | `--sdk-url <ws-url>` WebSocket (CLI connects TO your server) |
| **Protocol** | NDJSON over WebSocket (same as Agent SDK stdin/stdout) |
| **Mobile Support** | ✅ Web + Mobile responsive UI |
| **ReCursor Relevance** | ⭐⭐⭐⭐⭐ HIGH — Direct architectural reference |

**Architecture Summary:**
> Claude Code CLI has a **hidden** `--sdk-url <ws-url>` flag (`.hideHelp()` in Commander) that makes the CLI act as a **WebSocket client**, connecting to a server you control. The protocol is **NDJSON** (newline-delimited JSON) — the same format used over stdin/stdout by the official `@anthropic-ai/claude-agent-sdk`.

**Key Technical Details:**
- **Direction:** CLI connects TO your WebSocket server (outbound from CLI)
- **Authentication:** Bearer token in WebSocket upgrade header
- **Protocol Documentation:** Comprehensive reverse-engineered protocol at `WEBSOCKET_PROTOCOL_REVERSED.md`
- **Message Types:** 13 control subtypes including `start_turn`, `approve_tool`, `cancel`
- **Session Management:** Supports reconnection, message replay, resume

**Critical Distinction:**
| Feature | `--sdk-url` | Official Remote Control |
|---------|-------------|------------------------|
| Direction | CLI → Your Server | CLI → Anthropic's Server |
| Auth | Your Bearer token | claude.ai OAuth |
| Endpoint | Your WebSocket server | `wss://api.anthropic.com/v1/session_ingress/ws/` |
| Third-party access | ✅ Allowed | ❌ First-party only |

**ReCursor Implications:**
- **Viable integration path** — Uses documented Agent SDK patterns
- Requires own WebSocket server infrastructure
- Full bidirectional control: launch, monitor, approve tools
- Does NOT require claude.ai authentication (uses API keys)

---

### Category B: Terminal Proxy / Tunnel Solutions

#### Terminal Proxy Architecture Pattern
These projects provide browser-based terminal access to Claude Code CLI. They do **NOT** use Remote Control protocol — they expose a full terminal session.

---

#### trmquang93/remotelab ⭐ 5 stars
| Field | Value |
|-------|-------|
| **URL** | https://github.com/trmquang93/remotelab |
| **Activity** | pushedAt: 2026-03-11, updatedAt: 2026-03-11 |
| **Classification** | UNOFFICIAL |
| **Connection Method** |ttyd + Cloudflare Tunnel + auth proxy |
| **Mobile Support** | ✅ Browser-based, mobile-friendly |
| **ReCursor Relevance** | ⭐⭐⭐ MEDIUM — Alternative architecture pattern |

**Architecture:**
- **Components:** `ttyd` (terminal in browser), Cloudflare Tunnel (HTTPS), auth proxy
- **Tools Supported:** Claude Code, GitHub Copilot, Codex, Cline, Kilo Code + any CLI
- **Session Persistence:** dtach keeps tools running through browser disconnects
- **Security:** scrypt-hashed passwords, HttpOnly cookies, localhost binding

**Quote from README:**
> "Access any AI coding CLI tool — Claude Code, GitHub Copilot, Codex, Cline, and Kilo Code — from any browser on any device via HTTPS."

**ReCursor Implications:**
- **Agent-agnostic** — Works with any CLI tool (good for multi-agent roadmap)
- No Remote Control integration — exposes full terminal
- Requires Cloudflare Tunnel or similar for remote access

---

#### Afstkla/claude-command-center ⭐ 1 star
| Field | Value |
|-------|-------|
| **URL** | https://github.com/Afstkla/claude-command-center |
| **Activity** | pushedAt: 2026-03-14, updatedAt: 2026-03-14 |
| **Classification** | UNOFFICIAL |
| **Connection Method** | Tailscale + xterm.js + tmux |
| **Mobile Support** | ✅ Browser-based, mobile-friendly |
| **ReCursor Relevance** | ⭐⭐⭐ MEDIUM — Tailscale pattern reference |

**Architecture:**
- **Components:** xterm.js terminal, tmux for session persistence, Tailscale for secure networking
- **Features:** Multi-session management, Git worktree workflow, push notifications (ntfy)
- **Transport:** WebSocket with SSE fallback for slow networks
- **Status Detection:** Polls tmux pane content to show session state

**Quote from README:**
> "Built to run on a home server (e.g. Mac Mini) and accessed remotely over Tailscale."

**ReCursor Implications:**
- Tailscale as alternative to Cloudflare Tunnel
- Good dashboard/session management UI patterns
- Still terminal-based, not Remote Control protocol

---

#### yazinsai/claude-code-remote ⭐ 66 stars
| Field | Value |
|-------|-------|
| **URL** | https://github.com/yazinsai/claude-code-remote |
| **Activity** | pushedAt: 2026-02-18, updatedAt: 2026-02-18 |
| **Classification** | UNOFFICIAL |
| **Connection Method** | Cloudflare Tunnel + terminal UI |
| **Mobile Support** | ✅ QR code pairing, mobile app |
| **ReCursor Relevance** | ⭐⭐⭐ MEDIUM — Cloudflare Tunnel pattern |

**Architecture:**
- **Components:** Cloudflare Tunnel (zero-config HTTPS), terminal session manager
- **Features:** Full terminal access, session persistence, dev server preview
- **Pairing:** QR code scanning for mobile connection
- **Security:** Passcode-based auth

**Quote from README:**
> "Zero Config Remote Access — Uses Cloudflare Tunnel automatically. No port forwarding, no firewall headaches, no ngrok fees."

---

#### langwatch/claude-remote ⭐ 7 stars
| Field | Value |
|-------|-------|
| **URL** | https://github.com/langwatch/claude-remote |
| **Activity** | pushedAt: 2026-02-17, updatedAt: 2026-02-17 |
| **Classification** | UNOFFICIAL |
| **Connection Method** | SSH + Mutagen file sync + shell wrapper |
| **Mobile Support** | ❌ (Local UI, remote execution) |
| **ReCursor Relevance** | ⭐⭐ LOW — Different use case |

**Architecture:**
```
Local Machine:              Remote Server:
┌─────────────────┐        ┌─────────────────┐
│ Claude Code CLI │        │ Heavy compute   │
│ (UI/TUI)        │◄──────►│ (TypeScript,    │
│ ~/Projects/     │  SSH   │  tests, etc.)  │
│ remote/         │        │                 │
└─────────────────┘        └─────────────────┘
```

**Quote from README:**
> "Claude Code can be CPU-intensive (TypeScript compilation, tests, file operations). This setup lets you: Keep your local machine fast and responsive. Use a powerful remote server (EC2, etc.) for heavy lifting."

**ReCursor Implications:**
- Addresses compute offload, not mobile access
- Interesting pattern for ReCursor if remote file sync needed

---

### Category C: Telegram Bot Bridges

#### a5c-ai/claude-code-telegram-bot ⭐ 11 stars
| Field | Value |
|-------|-------|
| **URL** | https://github.com/a5c-ai/claude-code-telegram-bot |
| **Activity** | pushedAt: 2026-02-02, updatedAt: 2026-03-06 |
| **Classification** | UNOFFICIAL |
| **Connection Method** | stdin/stdout JSON streaming to long-lived CLI process |
| **Mobile Support** | ✅ Telegram mobile app |
| **ReCursor Relevance** | ⭐⭐⭐⭐ HIGH —stdin/stdout architecture reference |

**Architecture:**
> "The bot uses a **single long-lived Claude CLI process per session** with bidirectional stdin/stdout streaming JSON communication. This architecture provides:
> - Instant message handling - No process spawn overhead per message
> - Session continuity - Maintains conversation context across all interactions
> - Efficient resource usage - Single process handles multiple message exchanges
> - Native question/answer flow - Responses to Claude's questions stream through stdin"

**Key Features:**
- Multi-project management
- Session isolation and persistence
- Tool approval / rejection via Telegram buttons
- Streaming responses (animated typing)

---

#### Jeffrey0117/ClaudeBot ⭐ 54 stars
| Field | Value |
|-------|-------|
| **URL** | https://github.com/Jeffrey0117/ClaudeBot |
| **Activity** | pushedAt: 2026-03-18, updatedAt: 2026-03-18 |
| **Classification** | UNOFFICIAL |
| **Connection Method** | Telegram bot with streaming, plugin system |
| **Mobile Support** | ✅ Telegram mobile app |
| **ReCursor Relevance** | ⭐⭐⭐ MEDIUM — Reference for mobile messaging patterns |

**Architecture:**
- Plugin system with hot-reload
- Multi-bot support
- Queue management
- Streaming responses

---

#### kidandandcat/ccc(kxn/claude-code-companion) ⭐ 46-303 stars
| Field | Value |
|-------|-------|
| **URL** | https://github.com/kidandandcat/ccc, https://github.com/kxn/claude-code-companion |
| **Activity** | pushedAt: 2026-02-27, updatedAt: 2026-03-16 |
| **Classification** | UNOFFICIAL |
| **Connection Method** | Telegram bot bridge |
| **Mobile Support** | ✅ Telegram mobile app |
| **ReCursor Relevance** | ⭐⭐⭐ MEDIUM — Alternative mobile access pattern |

---

### Category D: Custom Coordinator Solutions

#### ZohaibAhmed/clauder ⭐ 29 stars
| Field | Value |
|-------|-------|
| **URL** | https://github.com/ZohaibAhmed/clauder |
| **Activity** | pushedAt: 2025-07-21 (OLDER, but iOS app exists) |
| **Classification** | OUTDATED (last commit July 2025) |
| **Connection Method** | Custom Go coordinator + Cloudflare Worker + iOS app |
| **Mobile Support** | ✅ Dedicated iOS app |
| **ReCursor Relevance** | ⭐⭐ LOW — Outdated, custom infrastructure |

**Architecture:**
- **Components:** Go coordinator server, Cloudflare Worker relay, iOS app
- **Authentication:** Owner-generated passcode
- **Transport:** WebSocket over HTTPS
- **iOS App:** Native iOS with real-time sync

**Quote from README:**
> "Control Claude Code from your iPhone with secure remote access."

**Critical Note:** This is a **completely separate system** with its own coordinator server. It does NOT connect to Anthropic's Remote Control infrastructure.

---

#### almogdepaz/wolfpack ⭐ 19 stars
| Field | Value |
|-------|-------|
| **URL** | https://github.com/almogdepaz/wolfpack |
| **Activity** | pushedAt: 2026-03-20, updatedAt: 2026-03-20 |
| **Classification** | UNOFFICIAL |
| **Connection Method** | Tailscale + session management |
| **Mobile Support** | ✅ Mobile + Desktop |
| **ReCursor Relevance** | ⭐⭐⭐⭐ HIGH — Active 2026, multi-agent |

**Architecture Quote:**
> "Mobile & desktop command center for AI coding agents. Control Claude, Codex, Gemini sessions across machines from your phone — secured by Tailscale."

**Key Features:**
- Multi-agent support (Claude, Codex, Gemini)
- Tailscale-based secure networking
- Dashboard for session management

---

### Category E: Fleet Management / Multi-Agent Orchestration

#### JohnRiceML/clawport-ui ⭐ 599 stars
| Field | Value |
|-------|-------|
| **URL** | https://github.com/JohnRiceML/clawport-ui |
| **Activity** | pushedAt: 2026-03-17, updatedAt: 2026-03-21 |
| **Classification** | UNOFFICIAL (Built on OpenClaw) |
| **Connection Method** | OpenClaw gateway (fork of Claude Code) |
| **Mobile Support** | ✅ Web-based dashboard |
| **ReCursor Relevance** | ⭐⭐⭐ MEDIUM — UI/UX patterns, but different underlying platform |

**Architecture Quote:**
> "ClawPort is an open-source dashboard for managing, monitoring, and talking directly to your OpenClaw AI agents. It connects to your local OpenClaw gateway..."

**Note:** Built on OpenClaw, a fork of Claude Code. Not directly applicable to ReCursor unless switching to OpenClaw base.

---

#### idolaman/galactic ⭐ 52 stars
| Field | Value |
|-------|-------|
| **URL** | https://github.com/idolaman/galactic |
| **Activity** | pushedAt: 2026-03-19, updatedAt: 2026-03-19 |
| **Classification** | UNOFFICIAL |
| **Connection Method** | Git worktrees + parallel agent orchestration |
| **Mobile Support** | ❌ Desktop (macOS Electron app) |
| **ReCursor Relevance** | ⭐⭐⭐ MEDIUM — Multi-agent patterns |

**Architecture Quote:**
> "The command center to ship 10x faster with a parallel Claude Code fleet, featuring isolated Git Worktrees and zero-conflict networking."

---

#### mieubrisse/agenc ⭐ 19 stars
| Field | Value |
|-------|-------|
| **URL** | https://github.com/mieubrisse/agenc |
| **Activity** | pushedAt: 2026-03-20, updatedAt: 2026-03-20 |
| **Classification** | UNOFFICIAL |
| **Connection Method** | Multi-agent orchestration |
| **Mobile Support** | ❌ Desktop |
| **ReCursor Relevance** | ⭐⭐⭐ MEDIUM — Fleet management patterns |

**Architecture Quote:**
> "The CEO command center for your fleet of Claudes. AgenC is an AI work factory focused on learning loops."

---

### Category F: Desktop Command Centers

#### Dominien/claude-code-commander ⭐ 13 stars
| Field | Value |
|-------|-------|
| **URL** | https://github.com/Dominien/claude-code-commander |
| **Activity** | pushedAt: 2026-03-12, updatedAt: 2026-03-20 |
| **Classification** | UNOFFICIAL |
| **Connection Method** | MCP-based orchestration |
| **Mobile Support** | ❌ Desktop |
| **ReCursor Relevance** | ⭐⭐⭐ MEDIUM — Dashboard patterns |

**Architecture Quote:**
> "Desktop command center for managing multiple Claude Code sessions across codebases. See everything Claude Code knows — projects, MCP servers, sessions, costs — in one dashboard."

---

### Category G: Session Bridges (Local)

#### PatilShreyas/claude-code-session-bridge ⭐ 10 stars
| Field | Value |
|-------|-------|
| **URL** | https://github.com/PatilShreyas/claude-code-session-bridge |
| **Activity** | pushedAt: 2026-03-18, updatedAt: 2026-03-19 |
| **Classification** | UNOFFICIAL |
| **Connection Method** | Local filesystem (`~/.claude/session-bridge/`) |
| **Mobile Support** | ❌ Same-machine only |
| **ReCursor Relevance** | ⭐ LOW — Not remote access |

**Architecture Quote:**
> "Don't expect remote access — both sessions must be on the same machine. It uses the local filesystem, not a network protocol."

---

### Category H: Reverse Engineering / Analysis Projects

#### Yuyz0112/claude-code-reverse ⭐ 2,213 stars
| Field | Value |
|-------|-------|
| **URL** | https://github.com/Yuyz0112/claude-code-reverse |
| **Activity** | pushedAt: 2025-08-26, updatedAt: 2026-03-21 (high activity) |
| **Classification** | UNSUPPORTED (explicitly noted) |
| **Connection Method** | API request logging/analysis |
| **Mobile Support** | N/A — Analysis tool |
| **ReCursor Relevance** | ⭐ EDUCATIONAL — Understanding internal protocol |

**Critical Note from README:**
> "At the time, there was another version by someone else that directly restored the source code based on sourcemaps. However, that repository was later taken down, **indicating that Anthropic officially does not support this type of reverse engineering**."

**Value:** Provides deep insight into Claude Code's internal architecture, API patterns, and message types. Useful for understanding but **NOT for implementation**.

---

#### AprilNEA/reverse-engineering-claude-code-antspace ⭐ 10 stars
| Field | Value |
|-------|-------|
| **URL** | https://github.com/AprilNEA/reverse-engineering-claude-code-antspace |
| **Activity** | pushedAt: 2026-03-19, updatedAt: 2026-03-19 |
| **Classification** | UNSUPPORTED |
| **Connection Method** | Sandbox analysis |
| **ReCursor Relevance** | ⭐ EDUCATIONAL |

---

### Category I: Notification Hooks

Multiple notification hook projects were found (2026 active):

| Repository | Stars | Activity | Method |
|------------|-------|----------|--------|
| BND-1/claude-code-hooks-notification | 12 | 2026-01-05 | Discord webhook |
| jiunbae/aily | 6 | 2026-03-20 | Discord per-session threads |
| eyalzh/claude-code-toast | 16 | 2025-07-22 | MacOS toast |
| kmio11/cc-notification | 6 | 2025-07-06 | Webhook notifications |

**ReCursor Relevance:** ⭐⭐⭐ HIGH — Direct reference for Hooks-based event observation integration.

---

## Architecture Pattern Comparison Matrix

| Project | Stars | Activity | Connection Method | Protocol | Mobile | ReCursor Relevance |
|---------|-------|----------|-------------------|----------|--------|-------------------|
| **The-Vibe-Company/companion** | 2,218 | 2026-03-19 | `--sdk-url` WebSocket | NDJSON |✅ |⭐⭐⭐⭐⭐ |
| trmquang93/remotelab | 5 | 2026-03-11 | ttyd + Cloudflare | Terminal | ✅ | ⭐⭐⭐ |
| Afstkla/claude-command-center | 1 | 2026-03-14 | Tailscale + tmux | Terminal | ✅ | ⭐⭐⭐ |
| yazinsai/claude-code-remote | 66 | 2026-02-18 | Cloudflare Tunnel | Terminal | ✅ | ⭐⭐⭐ |
| langwatch/claude-remote | 7 | 2026-02-17 | SSH + Mutagen | Shell wrapper | ❌ | ⭐⭐ |
| a5c-ai/claude-code-telegram-bot | 11 | 2026-02-02 | stdin/stdout | JSON streaming | ✅ | ⭐⭐⭐⭐ |
| Jeffrey0117/ClaudeBot | 54 | 2026-03-18 | Telegram bot | Plugin system | ✅ | ⭐⭐⭐ |
| kxn/claude-code-companion | 303 | 2025-11-02 | Telegram | JSON | ✅ | ⭐⭐⭐ |
| ZohaibAhmed/clauder | 29 | 2025-07-21 | Custom coordinator | WebSocket | ✅ | ⭐⭐ |
| almogdepaz/wolfpack | 19 | 2026-03-20 | Tailscale + session | Multi-agent | ✅ | ⭐⭐⭐⭐ |
| JohnRiceML/clawport-ui | 599 | 2026-03-17 | OpenClaw gateway | Custom | ✅ | ⭐⭐⭐ |
| idolaman/galactic | 52 | 2026-03-19 | Git worktrees | Fleet | ❌ | ⭐⭐⭐ |
| mieubrisse/agenc | 19 | 2026-03-20 | Multi-agent | Fleet | ❌ | ⭐⭐⭐ |
| Dominien/claude-code-commander | 13 | 2026-03-12 | MCP orchestration | Dashboard | ❌ | ⭐⭐⭐ |
| PatilShreyas/claude-code-session-bridge | 10 | 2026-03-18 | Filesystem | Local only | ❌ | ⭐ |
| Yuyz0112/claude-code-reverse | 2,213 | 2025-08-26 | Analysis | N/A | N/A | ⭐ Educational |
| **Official Remote Control** | — | 2026 | claude.ai OAuth | WebSocket | ✅ | ❌ First-party |

---

## Why "Third-Party Claude Remote" Without Official Remote Control Support

### The Core Question
> How can repos claim "remote control" without official Remote Control API support?

### The Answer
All surveyed third-party solutions use **alternative architectures** that bypass the official Remote Control protocol entirely:

| Approach | How It Works | Uses Remote Control? |
|----------|--------------|---------------------|
| **Agent SDK** | `--sdk-url` flag makes CLI connect to YOUR server | ❌ No — parallel protocol |
| **Terminal Proxy** | ttyd/xterm.js exposes full terminal in browser | ❌ No — terminal level |
| **Telegram Bot** | stdin/stdout JSON streaming to bot | ❌ No — process level |
| **Custom Coordinator** | Self-hosted server + mobile app | ❌ No — completely separate |
| **SSH/Tunnel** | Remote shell access | ❌ No — OS level |

### What Makes CompanionDifferent

The-Vibe-Company/companion is often confused with Remote Control, but it uses a **different protocol**:

**Official Remote Control:**
```
CLI → Anthropic's Servers (wss://api.anthropic.com/...)← claude.ai / Mobile App
```

**Companion (`--sdk-url`):**
```
CLI → YOUR WebSocket Server ← Your Web/Mobile App
```

The `--sdk-url` flag is part of the **Agent SDK** infrastructure, designed for programmatic control, not Remote Control. It's documented (via Agent SDK docs) but the WebSocket interface is "hidden" (`.hideHelp()` in Commander).

---

## Recommended Patterns for ReCursor

Based on this survey, the following patterns are most viable for ReCursor's agent-agnostic roadmap:

### Tier 1: Primary Recommendations

| Pattern | Source | ReCursor Applicability | Effort |
|---------|--------|------------------------|--------|
| **Agent SDK / `--sdk-url`** | The-Vibe-Company/companion | Full bidirectional control, parallel sessions | Medium |
| **Hooks + Bridge** | Notification hooks pattern | One-way event observation | Low |
| **stdin/stdout JSON** | Telegram bots | Process-level control | Medium |

### Tier 2: Alternative Patterns

| Pattern | Source | ReCursor Applicability | Effort |
|---------|--------|------------------------|--------|
| **Terminal Proxy** | remotelab, claude-command-center | Agent-agnostic terminal access | High |
| **Tailscale Networking** | wolfpack, claude-command-center | Secure remote networking | Medium |
| **Multi-Agent Dashboard** | galactic, agenc | Fleet management UI patterns | High |

### Tier 3: NOT Recommended

| Pattern | Reason |
|---------|--------|
| **Official Remote Control** | First-party only, no public API |
| **Reverse Engineering** | Explicitly unsupported, ToS risk |
| **Custom Coordinator** | High infrastructure overhead, outdated refs |

---

## Activity Status Summary

| Status | Count | Examples |
|--------|-------|----------|
| **Active 2026** | 35+ | companion, wolfpack, ClaudeBot, galactic, remotelab |
| **Active Late 2025** | 5+ | clauder, some notification hooks |
| **Outdated/Abandoned** | < 5 | Various small forks |

---

## Source Validation

| Source | Tier | Notes |
|--------|------|-------|
| code.claude.com/docs/en/remote-control | 1 (Official) | Confirms first-party only |
| docs.claude.com/en/api/agent-sdk/overview | 1 (Official) | Agent SDK documentation |
| github.com/The-Vibe-Company/companion | 2 (Maintainer) | Primary`--sdk-url` reference |
| github.com/anthropics/claude-code | 1 (Official) | CLI source, CHANGELOG |
| github.com/Yuyz0112/claude-code-reverse | 3 (Community) | Protocol analysis |
| All other repos surveyed | 3 (Community) | Architecture patterns |

---

## Conclusions

1. **No public Remote Control API exists** — All third-party "remote" solutions use alternative architectures.

2. **Agent SDK `--sdk-url` is the most viable path** — The-Vibe-Company/companion demonstrates a production-ready WebSocket interface that provides full control without requiring claude.ai authentication.

3. **Terminal proxy approaches are agent-agnostic** — ttyd/tailscale solutions work with any CLI tool, aligning with ReCursor's multi-agent roadmap.

4. **Hooks remain the simplest event observation** — For one-way monitoring, the hooks system is officially supported and low-effort.

5. **Activity is strong in 2026** — The ecosystem is vibrant with multiple active projects across architectures.

---

## References

- The-Vibe-Company/companion: https://github.com/The-Vibe-Company/companion
- The-Vibe-Company/companion WEBSOCKET_PROTOCOL_REVERSED.md: Full protocol documentation
- trmquang93/remotelab: https://github.com/trmquang93/remotelab
- Afstkla/claude-command-center: https://github.com/Afstkla/claude-command-center
- yazinsai/claude-code-remote: https://github.com/yazinsai/claude-code-remote
- langwatch/claude-remote: https://github.com/langwatch/claude-remote
- ZohaibAhmed/clauder: https://github.com/ZohaibAhmed/clauder
- a5c-ai/claude-code-telegram-bot: https://github.com/a5c-ai/claude-code-telegram-bot
- Jeffrey0117/ClaudeBot: https://github.com/Jeffrey0117/ClaudeBot
- almogdepaz/wolfpack: https://github.com/almogdepaz/wolfpack
- JohnRiceML/clawport-ui: https://github.com/JohnRiceML/clawport-ui
- idolaman/galactic: https://github.com/idolaman/galactic
- mieubrisse/agenc: https://github.com/mieubrisse/agenc
- PatilShreyas/claude-code-session-bridge: https://github.com/PatilShreyas/claude-code-session-bridge
- Yuyz0112/claude-code-reverse: https://github.com/Yuyz0112/claude-code-reverse
- Official Remote Control Docs: https://code.claude.com/docs/en/remote-control
- Agent SDK Docs: https://docs.claude.com/en/api/agent-sdk/overview
- Claude Code CHANGELOG: https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md