# Research Report: Claude Code Remote Control Third-Party API Availability

> Generated: 2026-03-21 | Researcher Agent
> Task: Determine whether third-party apps can use Claude Code Remote Control

## Executive Summary

**Primary Finding: UNSUPPORTED** — There is **no official public API or protocol** for third-party applications to connect to or mirror Claude Code Remote Control sessions. Official documentation explicitly identifies Remote Control as a **first-party feature** limited to claude.ai/code web UI and official Claude mobile apps (iOS/Android).

**Classification: UNSUPPORTED** — Third-party access to Remote Control is not documented, not authorized, and not feasible without reverse-engineering Anthropic's internal infrastructure.

**Recommended Path for ReCursor**: Continue with documented integration mechanisms (Agent SDK for parallel sessions, Hooks for event observation) rather than pursuing Remote Control integration.

---

## Source Validation

| Source | Tier | Date | Version/Commit | Evidence Type |
|--------|------|------|-----------------|---------------|
| code.claude.com/docs/en/remote-control | 1 (Official) | 2026-03 | — | Feature documentation |
| docs.claude.com/en/api/agent-sdk/overview | 1 (Official) | 2026-03 | — | SDK documentation |
| docs.claude.com/en/docs/agent-sdk/overview | 1 (Official) | 2026-03 | — | SDK restrictions |
| github.com/anthropics/claude-code (issues) | 2 (Official Repo) | 2026-03 | Various | GitHub issues, community |
| docs.anthropic.com/en/docs/claude-code/remote-control | 1 (Official) | 2026-03 | — | Official docs mirror |

---

## Key Findings

### 1. Remote Control Feature Overview (What It Is)

From official documentation:

> "Remote Control connects claude.ai/code or the Claude app for iOS and Android to a Claude Code session running on your machine. Start a task at your desk, then pick it up from your phone on the couch or a browser on another computer." — code.claude.com/docs/en/remote-control

**Technical Architecture:**
- **Transport**: Outbound HTTPS polling to Anthropic API (no inbound ports)
- **Authentication**: claude.ai OAuth required (API keys explicitly not supported)
- **Session Token**: Multiple short-lived credentials, each scoped to single purpose
- **Availability**: Pro, Max, Team, Enterprise plans (Team/Enterprise require admin enable)

**How It Works:**
1. Local Claude Code session registers with Anthropic API
2. Process polls for work via HTTPS (outbound only)
3. Remote client connects via claude.ai/code or mobile app
4. Messages routed through Anthropic API between local session and remote client

### 2. Supported Clients (First-Party Only)

**Officially Documented Clients:**
| Client | Platform | First-Party |
|--------|----------|-------------|
| claude.ai/code | Web Browser | ✅ Yes |
| Claude iOS App | iOS | ✅ Yes |
| Claude Android App | Android | ✅ Yes |
| Third-Party Apps | Any | ❌ Not Supported |

From the docs:
> "Remote Control requires claude.ai authentication. Run `/login` and choose the claude.ai option." — code.claude.com/docs/en/remote-control

> "Subscription: available on Pro, Max, Team, and Enterprise plans. **API keys are not supported.**" — code.claude.com/docs/en/remote-control (emphasis added)

**No documentation exists for:**
- Public Remote Control API endpoints
- Third-party client SDK integration
- Session URL/QR token format specification
- WebSocket or HTTP bridge protocol documentation

### 3. Third-Party Developer Restrictions

From the Agent SDK documentation:

> "**Unless previously approved, Anthropic does not allow third party developers to offer claude.ai login or rate limits for their products, including agents built on the Claude Agent SDK.** Please use the API key authentication methods described above." — docs.claude.com/en/api/agent-sdk/overview

This explicitly restricts third-party developers from using claude.ai authentication infrastructure, which Remote Control requires.

### 4. GitHub Issues Confirm No Public API

Search of github.com/anthropics/claude-code issues reveals:

| Issue | Topic | Resolution |
|-------|-------|------------|
| #30447 | Headless Remote Control request | Open — feature request for daemon mode |
| #30905 | Remote Control for VS Code chat | Closed (not planned) |
| #32982 | Session dies after ~20 min idle | Open — infrastructure bug |
| #34255 | Auto-reconnection fails | Open — reliability issue |

No issues request or document third-party API access. The headless mode request (#30447) specifically asks for official support for running Remote Control without terminal, not for third-party access.

### 5. What ReCursor Could Legitimately Use

**SUPPORTED Integration Mechanisms:**

| Mechanism | Type | Capability | ReCursor Relevance |
|-----------|------|-------------|---------------------|
| **Agent SDK** | API | Create parallel agentic sessions | High — primary recommended path |
| **Hooks System** | Event Observation | Observe tool use, messages | Medium — one-way event forwarding |
| **MCP Servers** | Tool Extension | Add custom tools to Claude Code | Low — requires user configuration |
| **CLAUDE.md** | Context | Project-level instructions | Medium — can guide behavior |

**NOT SUPPORTED:**

| Mechanism | Status | Reason |
|-----------|--------|--------|
| Remote Control Protocol | UNSUPPORTED | No public API documentation |
| Session Mirroring | UNSUPPORTED | Requires internal Anthropic infrastructure |
| claude.ai OAuth for Third-Party | PROHIBITED | Explicitly restricted in ToS |
| Session URL/Token Generation | UNSUPPORTED | Internal Anthropic API |

---

## Security and Architecture Analysis

### Why Third-Party Access Is Not Supported

1. **Authentication Model**: Remote Control requires claude.ai OAuth, which is managed by Anthropic. Third-party apps cannot authenticate users through this flow.

2. **Session Token Scope**: Session tokens are short-lived and scoped to specific purposes. They're generated server-side by Anthropic infrastructure.

3. **Business Model Protection**: Remote Control is a subscription feature differentiator for Anthropic's first-party clients.

4. **Security Architecture**: From docs: "The connection uses multiple short-lived, narrowly scoped credentials, each limited to a specific purpose and expiring independently."

5. **Infrastructure Routing**: All traffic routes through Anthropic's API — there is no peer-to-peer alternative.

### Transport Protocol Evidence

From CHANGELOG analysis (prior research):
- WebSocket-based streaming with fallback to HTTPS polling
- `/poll` endpoint for session work items
- `control_response` messages for bidirectional communication
- JWT refresh for session credential renewal

This is **internal protocol** not documented for public use.

---

## Risk Assessment

### Risks of Pursuing Remote Control Integration

| Risk | Severity | Description |
|------|----------|-------------|
| **ToS Violation** | HIGH | Explicit prohibition on third-party claude.ai authentication |
| **Protocol Instability** | HIGH | Internal protocol can change without notice |
| **Security Vulnerability** | HIGH | Would require reverse-engineering auth tokens |
| **Reliability Issues** | MEDIUM | Even official clients experience disconnections (#32982, #34255) |
| **No Official Support** | HIGH | Anthropic would not assist with integration issues |

### Recommended Approach

**Continue with documented integration paths:**

1. **Primary: Agent SDK** — Create parallel agentic sessions with full tool access
2. **Secondary: Hooks** — Forward session events to mobile app via bridge server
3. **Tertiary: MCP** — Extend Claude Code capabilities with custom tools

**Do NOT pursue:**
- Reverse-engineering Remote Control protocol
- Attempting to authenticate via claude.ai OAuth
- Creating session mirroring through undocumented APIs

---

## Comparison: Remote Control vs Agent SDK

| Capability | Remote Control | Agent SDK |
|------------|---------------|-----------|
| **Session Type** | Mirror existing session | Create new session |
| **Authentication** | claude.ai OAuth | API Key (official) |
| **Third-Party Access** | Not supported | Fully supported |
| **Mobile UI** | Official apps only | Custom apps can build |
| **File Access** | Local machine | Local/container runtime |
| **MCP Servers** | Available (local) | Available (configurable) |
| **Hooks** | Available | Available |
| **Tool Execution** | Mirrors local session | Independent agent loop |

---

## Evidence from Official Sources

### From code.claude.com/docs/en/remote-control

Key passages establishing first-party-only status:

> "Remote Control connects **claude.ai/code or the Claude app for iOS and Android** to a Claude Code session running on your machine." (emphasis added)

> "Your local Claude Code session makes outbound HTTPS requests only and never opens inbound ports on your machine. When you start Remote Control, it **registers with the Anthropic API and polls for work**."

> "All traffic travels through the Anthropic API over TLS."

> "Subscription: available on Pro, Max, Team, and Enterprise plans. **API keys are not supported.**"

### From docs.claude.com/en/api/agent-sdk/overview

> "Unless previously approved, Anthropic does not allow third party developers to offer **claude.ai login or rate limits** for their products."

### From GitHub Issues

Issue #30447 (headless request) demonstrates that even power users must request official support for non-standard Remote Control usage rather than implementing it themselves.

---

## Answer to Research Questions

### Success Criterion 1: Official Evidence of Public Third-Party Remote Control API

**FINDING: NONE**

No official documentation indicates a public third-party Remote Control API or protocol. All official sources describe Remote Control as connecting first-party clients (claude.ai/code web UI, iOS app, Android app) to local sessions.

**Classification: UNSUPPORTED**

### Success Criterion 2: First-Party vs Third-Party Integration Surfaces

**FINDING: Clearly Distinguished**

| Integration Type | First-Party (Claude Apps) | Third-Party (ReCursor) |
|------------------|--------------------------|------------------------|
| Remote Control | ✅ Supported | ❌ Not Supported |
| Agent SDK | ✅ Supported | ✅ Supported |
| API Key Auth | ❌ N/A | ✅ Supported |
| claude.ai Auth | ✅ Required for RC | ❌ Prohibited |
| Hooks | ✅ Supported | ✅ Supported |

### Success Criterion 3: What ReCursor Can Legitimately Reuse

**SUPPORTED:**
- Agent SDK for creating parallel agentic sessions
- Hooks system for one-way event observation
- MCP servers for tool extension
- CLAUDE.md for project context

**UNSUPPORTED/UNKNOWN:**
- Remote Control protocol (no public documentation)
- Session mirroring (no API endpoints documented)
- claude.ai authentication for third-party apps (explicitly prohibited)

### Success Criterion 4: Risk-Aware Recommendation

**RECOMMENDATION: Do NOT pursue Remote Control integration.**

Continue with documented architecture from AGENTS.md:
1. Claude Agent SDK for parallel, controllable sessions
2. Hooks (Claude Code plugin hooks) for one-way event observation

The existing repo constraint in AGENTS.md remains accurate:
> "Claude Code Remote Control is first‑party (claude.ai/code + official apps). Do **not** claim we can join/mirror a user's Claude Code Remote Control session via a public protocol unless official docs explicitly provide it."

---

## References

1. https://code.claude.com/docs/en/remote-control — Official Remote Control documentation
2. https://docs.claude.com/en/api/agent-sdk/overview — Agent SDK with third-party restrictions
3. https://docs.claude.com/en/docs/agent-sdk/overview — Agent SDK overview (canonical)
4. https://github.com/anthropics/claude-code/issues/30447 — Headless Remote Control feature request
5. https://github.com/anthropics/claude-code/issues/30905 — VS Code Remote Control (closed: not planned)
6. C:/Repository/ReCursor/docs/research/claude-remote-control-2026-03-17.md — Prior internal research
7. C:/Repository/ReCursor/docs/research/claude-code-integration-feasibility-2026-03-17.md — Prior feasibility analysis
8. C:/Repository/ReCursor/AGENTS.md — Project constraints

---

## Appendix: Official Client List

From official documentation, the **only** supported Remote Control clients:

1. **claude.ai/code** — Web browser interface
2. **Claude iOS App** — Official Apple App Store app
3. **Claude Android App** — Official Google Play Store app

No other clients are mentioned or supported in any official documentation.

---

## Appendix: Authentication Requirements

From code.claude.com/docs/en/remote-control:

> **"Remote Control requires claude.ai authentication and does not work with third-party providers."**

Configuration:
- Run `/login` and choose claude.ai option
- Cannot use API keys
- Cannot use `CLAUDE_CODE_USE_BEDROCK`, `CLAUDE_CODE_USE_VERTEX`, or `CLAUDE_CODE_USE_FOUNDRY`

---

*End of Research Report*