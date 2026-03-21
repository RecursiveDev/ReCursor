# Research Report: Third-Party Claude Code Remote Control Usage Survey

> Generated: 2026-03-21 | Researcher Agent
> Task: Extensive research on claimed third-party Claude Code Remote Control usage in public repositories

---

## Executive Summary

**Primary Finding: NO PUBLIC THIRD-PARTY REMOTE CONTROL API EXISTS**

Extensive survey of GitHub repositories, official documentation, and community discussions confirms that **no public repository implements Claude Code Remote Control using the official Remote Control protocol**. All "remote access" solutions discovered use alternative architectures:

- **Terminal proxy approaches** (ttyd + Cloudflare Tunnel, Tailscale)
- **SSH-based remote execution**
- **Agent SDK / `--sdk-url` websocket** (different from Remote Control)
- **PTY + custom coordinator servers**

The official Remote Control feature remains **first-party only** (claude.ai/code web, iOS app, Android app). Feature requests to expose Remote Control API publicly have been **closed as "not_planned"** by Anthropic.

---

## Source Validation

| Source | Tier | Date | Evidence Type |
|--------|------|------|---------------|
| code.claude.com/docs/en/remote-control | 1 (Official) | 2026-03 | Feature documentation |
| github.com/anthropics/claude-code/issues/16391 | 2 (Official Repo) | 2026-02 | Feature request closed as not_planned |
| github.com/The-Vibe-Company/companion | 3 (Community) | 2026-03 | Active project (uses Agent SDK) |
| github.com/ZohaibAhmed/clauder | 3 (Community) | 2025-07 | Alternative architecture |
| github.com/trmquang93/remotelab | 3 (Community) | 2026-03 | Terminal proxy approach |
| github.com/Afstkla/claude-command-center | 3 (Community) | 2026-03 | Tailscale + tmux approach |
| github.com/yazinsai/claude-code-remote | 3 (Community) | 2026-01 | Cloudflare Tunnel approach |
| github.com/langwatch/claude-remote | 3 (Community) | 2026-02 | SSH + Mutagen approach |
| github.com/Yuyz0112/claude-code-reverse | 3 (Community) | 2025-08 | Reverse engineering (explicitly unsupported) |
| github.com/AprilNEA/reverse-engineering-claude-code-antspace | 3 (Community) | 2026-03 | Sandbox reverse engineering |
| Medium article (Orseni) | 3 (Community) | 2026-03 | Comparison with third-party solution |
| reddit.com/r/ClaudeCode | 3 (Community) | 2026-03 | User discussion |
| Official Remote Control WebSocket issues | 2 (Official Repo) | 2026-03 | Bug reports (#31853, #32982, etc.) |

---

## Classification of Third-Party Solutions

### Category A: Terminal Proxy / Tunnel Solutions (UNOFFICIAL)

These projects provide remote terminal access, not Remote Control protocol integration.

| Repository | Architecture | Remote Control Protocol? |
|------------|-------------|-------------------------|
| **trmquang93/remotelab** | ttyd + Cloudflare Tunnel + auth proxy | ❌ No - Full terminal access |
| **yazinsai/claude-code-remote** | Cloudflare Tunnel + terminal UI | ❌ No - Terminal tunneling |
| **Afstkla/claude-command-center** | Tailscale + xterm.js + tmux | ❌ No - Terminal multiplexer |
| **langwatch/claude-remote** | SSH + Mutagen file sync + shell wrapper | ❌ No - SSH remote execution |

**Key Insight**: These are essentially sophisticated SSH alternatives. They provide a terminal emulator running Claude Code CLI, accessed remotely. They do NOT use or interact with the Remote Control protocol.

**Evidence** (from remotelab README):
> "Access any AI coding CLI tool — Claude Code, GitHub Copilot, OpenAI Codex, Cline, and Kilo Code — from any browser on any device via HTTPS."

This is a general-purpose terminal solution, not a Claude Code Remote Control client.

---

### Category B: Agent SDK / --sdk-url Solutions (OFFICIAL - DIFFERENT PROTOCOL)

**The-Vibe-Company/companion** (aka "claude-code-controller", "the-companion")

The most sophisticated third-party solution found. Uses a different protocol than Remote Control.

| Aspect | Details |
|--------|---------|
| **Architecture** | `--sdk-url` WebSocket + NDJSON protocol |
| **Protocol** | Uses hidden `--sdk-url` flag (CLI connects TO your server) |
| **Authentication** | Bearer token in WebSocket upgrade header |
| **Source** | Uses Agent SDK transport (stdin/stdout JSON over WebSocket) |
| **Classification** | OFFICIAL (uses documented Agent SDK patterns) |

**Key Evidence from their documentation**:
> "Claude Code CLI has a **hidden** `--sdk-url <ws-url>` flag (`.hideHelp()` in Commander) that makes the CLI act as a **WebSocket client**, connecting to a server you control. The protocol is **NDJSON** (newline-delimited JSON) — the same format used over stdin/stdout by the official `@anthropic-ai/claude-agent-sdk`."

**Critical Distinction**: `--sdk-url` ≠ Remote Control

| Feature | `--sdk-url` | Remote Control |
|---------|-------------|----------------|
| Direction | CLI connects TO your server | CLI connects TO Anthropic's server |
| Auth | Your Bearer token | claude.ai OAuth |
| Endpoint | Your WebSocket server | `wss://api.anthropic.com/v1/session_ingress/ws/` |
| Purpose | Programmatic control | Mobile/web remote access |
| Third-party access | ✅ Allowed | ❌ First-party only |

**Companion's Protocol Documentation** explicitly notes this is "undocumented" but based on the Agent SDK:
> "This document describes the undocumented WebSocket protocol that Claude Code CLI uses for programmatic control via the `--sdk-url` flag. This is the same NDJSON protocol used over stdin/stdout by the official `@anthropic-ai/claude-agent-sdk`."

---

### Category C: Custom Coordinator Solutions (UNOFFICIAL)

**ZohaibAhmed/clauder**

| Aspect | Details |
|--------|---------|
| **Architecture** | Custom Go coordinator + iOS app |
| **Transport** | Your own Cloudflare Worker coordinator |
| **Authentication** | Passcode-based, your own auth |
| **Classification** | UNOFFICIAL - Does not use Remote Control |

**Evidence from README**:
> "Control Claude Code from your iPhone with secure remote access."
> "COORDINATOR_URL: Required for remote iOS access. This should point to your deployed coordinator."
> "All endpoints require Bearer token authentication."

This is a completely separate system with its own coordinator server. It does NOT connect to Anthropic's Remote Control infrastructure.

---

### Category D: Reverse Engineering Projects (UNSUPPORTED - NOT REMOTE CONTROL)

| Repository | Type | Remote Control? | Status |
|------------|------|-----------------|--------|
| **Yuyz0112/claude-code-reverse** | API request logging | ❌ No | Explicitly notes "Anthropic officially does not support this type of reverse engineering" |
| **AprilNEA/reverse-engineering-claude-code-antspace** | Sandbox analysis | ❌ No | Internal Firecracker VM analysis |
| **musistudio/claude-code-reverse** (router) | API routing | ❌ No | Routes to alternative providers |
| **ingo-eichhorst/claude-wire** | Network interceptor | ❌ No | Logging/debugging tool |

**Critical Note** from Yuyz0112/claude-code-reverse:
> "At the time, there was another version by someone else that directly restored the source code based on sourcemaps. However, that repository was later taken down, **indicating that Anthropic officially does not support this type of reverse engineering**."

---

### Category E: Plugin-Based Solutions (NOT REMOTE CONTROL)

**PatilShreyas/claude-code-session-bridge**

Local filesystem-based inter-session communication. Not remote access.

**Evidence from README**:
> "Don't expect remote access — both sessions must be on the same machine. It uses the local filesystem (`~/.claude/session-bridge/`), not a network protocol."

---

## Official Remote Control Protocol Analysis

From GitHub issues, the Remote Control protocol details have been reverse-engineered by users debugging disconnection bugs:

### Endpoints Discovered

| Endpoint | Purpose |
|----------|---------|
| `wss://api.anthropic.com/v1/session_ingress/ws/...` | WebSocket streaming |
| Session ingress HTTP polling | Fallback transport |

### Protocol Details (from user debugging)

- **Keep-alive frames**: `{"type":"keep_alive"}` every 5 minutes
- **WebSocket ping/pong**: Every 10 seconds
- **Server-side TTL**: ~25 minutes (causes periodic disconnections)
- **Transport**: Outbound HTTPS/WebSocket only (no inbound ports)
- **Authentication**: claude.ai OAuth session tokens

### Key Bug Reports Indicate Internal Protocol Complexity

Issues #31853, #32982, #34868, #34255 document:
- 25-minute server-side connection lifetime limits
- Keep-alive frames not resetting session TTL
- Server returning HTTP 404 for active sessions
- WebSocket close codes 1006/1002 patterns

**No third-party implementations** attempt to interact with this protocol.

---

## Why Third-Party Repos Exist Despite No Official Support

### The Nuanced Answer

**Question**: If there's no official Remote Control API, why do third-party repos exist?

**Answer**: They don't implement Remote Control — they provide **alternatives** that bypass Remote Control entirely:

1. **Terminal Access Solutions** (remotelab, claude-command-center, etc.)
   - Provide a **terminal emulator** accessible via browser
   - Work with **any CLI tool**, not just Claude Code
   - Use standard remote access (Cloudflare Tunnel, Tailscale, SSH)
   - **Do not touch** Remote Control protocol

2. **Agent SDK Solutions** (The Companion)
   - Use the **documented Agent SDK** patterns
   - CLI connects to **your WebSocket server** (opposite direction from Remote Control)
   - Different use case: programmatic control, not mobile continuation

3. **Reverse Engineering** (Yuyz0112, AprilNEA)
   - Analyze Claude Code for **educational/research purposes**
   - Document internal API patterns
   - Explicitly noted as **unsupported**
   - Not intended for Remote Control integration

4. **Workarounds Created Before Remote Control Existed**
   - Remote Control launched February 24, 2026
   - Many projects created **before that date** to solve the mobile access problem
   - Now have alternative paths (official Remote Control vs. unofficial terminal access)

---

## Official Documentation Confirmation

### Remote Control Clients (First-Party Only)

From official docs (code.claude.com/docs/en/remote-control):

> "Remote Control connects claude.ai/code or the Claude app for iOS and Android to a Claude Code session running on your machine."

> "Subscription: available on Pro, Max, Team, and Enterprise plans. **API keys are not supported.**"

> "Remote Control requires claude.ai authentication. Run `/login` and choose the claude.ai option."

**No documentation for:**
- Public WebSocket endpoint specification
- Session URL/QR token format specification  
- Third-party client authentication flow
- Remote Control API SDK

### Feature Request Closure

Issue #16391: "[FEATURE] Expose /ingress remote session features"
- Requested: Public API for session management
- Status: **CLOSED as "not_planned"**
- Date: February 2026

This confirms Anthropic has **declined** to expose Remote Control as a public API.

---

## Security and Architecture Analysis

### Why Third-Party Remote Control Is Not Supported

| Reason | Evidence |
|--------|----------|
| **Authentication** | Requires claude.ai OAuth (not available to third parties) |
| **Session Tokens** | Short-lived, generated server-side by Anthropic |
| **Transport** | Routes through Anthropic's API servers |
| **Business Model** | Premium feature for first-party clients |
| **ToS Restriction** | Agent SDK docs: "Anthropic does not allow third party developers to offer claude.ai login" |

### What Third Parties Actually Do

| Approach | How It Works | Remote Control? |
|----------|-------------|-----------------|
| Terminal Proxy | Run tttyd/emulator, tunnel via Cloudflare/Tailscale | ❌ No |
| SSH Remote | Execute commands on remote server via SSH | ❌ No |
| Agent SDK | Spawn CLI subprocess, communicate via stdin/stdout or `--sdk-url` | ❌ No (different protocol) |
| Custom Coordinator | Build your own relay server (like Clauder) | ❌ No |
| **Remote Control** | Connect to Anthropic's session_ingress via claude.ai OAuth | ✅ Yes — **First-party only** |

---

## Recommendations for ReCursor

### Integration Path

Based on this research, ReCursor should:

1. **Continue with Agent SDK** for parallel, controllable sessions
2. **Continue with Hooks** for event observation
3. **NOT claim Remote Control integration** unless official docs change
4. **Monitor** for any official Remote Control API announcements

### Alternative Approaches (If Mobile Access Required)

If remote access is essential for ReCursor users, consider:

| Option | Integration Complexity | User Experience | Official Support |
|--------|----------------------|-----------------|------------------|
| Agent SDK session | Medium | Good (parallel session, not mirror) | ✅ Official |
| Terminal proxy (like Companion) | High | Medium (your own server) | ⚠️ Agent SDK |
| Terminal tunnel (like remotelab) | Medium | Medium (full terminal) | ❌ Unofficial |
| Wait for official API | N/A | Excellent | ⏳ Unknown |

---

## References

### Official Documentation
- https://code.claude.com/docs/en/remote-control
- https://docs.claude.com/en/api/agent-sdk/overview

### GitHub Repositories Analyzed
- https://github.com/The-Vibe-Company/companion (Agent SDK-based)
- https://github.com/ZohaibAhmed/clauder (Custom coordinator)
- https://github.com/trmquang93/remotelab (Terminal proxy)
- https://github.com/Afstkla/claude-command-center (Tailscale + tmux)
- https://github.com/yazinsai/claude-code-remote (Cloudflare Tunnel)
- https://github.com/langwatch/claude-remote (SSH approach)
- https://github.com/Yuyz0112/claude-code-reverse (Reverse engineering)
- https://github.com/AprilNEA/reverse-engineering-claude-code-antspace (Sandbox analysis)
- https://github.com/PatilShreyas/claude-code-session-bridge (Local plugin)
- https://github.com/anthropics/claude-code/issues/16391 (Feature request)

### Community Discussions
- Reddit: r/ClaudeCode discussion of Remote Control vs. third-party solutions
- Medium: "Claude Code on Your Phone" comparison article (Orseni, March 2026)
- Medium: "Claude Remote Control vs OpenClaw" analysis (Castellano, March 2026)

### Bug Reports (Protocol Details)
- https://github.com/anthropics/claude-code/issues/31853
- https://github.com/anthropics/claude-code/issues/32982
- https://github.com/anthropics/claude-code/issues/34868
- https://github.com/anthropics/claude-code/issues/34255

---

## Conclusion

**No third-party repository implements Claude Code Remote Control using the official Remote Control protocol.** All solutions discovered use alternative architectures that either:
1. Provide terminal access (not Remote Control)
2. Use Agent SDK / `--sdk-url` (different protocol)
3. Build custom communication layers
4. Analyze internals for research purposes

The official Remote Control feature remains **first-party only**. Any claim that ReCursor can "mirror" or "join" a user's Remote Control session is **unsupported** without official documentation or public API.