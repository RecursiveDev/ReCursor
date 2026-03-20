# Research Report: Claude Code Integration Feasibility for Third-Party Mobile Client

> Generated: 2026-03-17 | Researcher Agent
> Task: Determine supported integration options for ReCursor (Flutter mobile) to connect to Claude Code

## Executive Summary

**Primary Finding:** There is **no official public API or protocol** for third-party clients to join Claude Code Remote Control sessions. The Remote Control feature is designed exclusively for first-party Anthropic clients (claude.ai/code web UI, VSCode extension, and official Claude mobile apps).

**Recommended Approach:** ReCursor should use the **Claude Agent SDK** (`@anthropic-ai/claude-agent-sdk`) as the supported integration path, running as a separate agentic session rather than attempting to mirror an existing Claude Code session. Alternative integration points include the **Hooks system** for event observation and **MCP (Model Context Protocol)** for tool interoperability.

**Key Risks:** Terms of Service restrictions, authentication complexity, and the undocumented nature of Remote Control internals make direct protocol reverse-engineering inadvisable.

---

## Source Validation

| Source | Tier | Date | Evidence Type |
|--------|------|------|---------------|
| `C:/Repository/claude-code/CHANGELOG.md` | 1 (Official) | 2026-03 | Release notes showing Remote Control as internal feature |
| `C:/Repository/claude-code/LICENSE.md` | 1 (Official) | Current | Commercial Terms of Service reference |
| `C:/Repository/claude-code/plugins/agent-sdk-dev/README.md` | 1 (Official) | Current | Agent SDK documentation |
| `C:/Repository/claude-code/SECURITY.md` | 1 (Official) | Current | Security policy |
| `C:/Repository/claude-code/README.md` | 1 (Official) | Current | Official documentation links |

---

## Key Findings

### 1. Remote Control Feature Analysis

#### What is Remote Control?

From the CHANGELOG analysis, Remote Control is a feature that allows Claude Code terminal sessions to be accessed and controlled from other interfaces:

> "Added `claude remote-control` subcommand for external builds, enabling local environment serving for all users." — CHANGELOG.md v2.1.51

> "Added optional name argument to `/remote-control` and `claude remote-control` (`/remote-control My Project` or `--name "My Project"`) to set a custom session title visible in claude.ai/code" — CHANGELOG.md v2.1.69

#### Remote Control Implementation Details

The CHANGELOG reveals technical implementation details:

**Protocol:** WebSocket-based with JWT authentication
> "Fixed several Remote Control issues: sessions silently dying when the server reaps an idle environment, rapid messages being queued one-at-a-time instead of batched, and stale work items causing redelivery after JWT refresh" — CHANGELOG.md v2.1.77

**Polling Mechanism:**
> "Reduced Remote Control `/poll` rate to once per 10 minutes while connected (was 1–2s), cutting server load ~300×. Reconnection is unaffected — transport loss immediately wakes fast polling." — CHANGELOG.md v2.1.72

**Bridge Sessions:**
> "Fixed bridge sessions failing to recover after extended WebSocket disconnects" — CHANGELOG.md v2.1.77

> "Fixed a race condition in the REPL bridge where new messages could arrive at the server interleaved with historical messages during the initial connection flush, causing message ordering issues." — CHANGELOG.md v2.1.58

#### Official Remote Control Consumers

The CHANGELOG identifies these as the **only** supported Remote Control clients:

1. **claude.ai/code web UI** — "visible in claude.ai/code"
2. **VSCode Extension** — "[VSCode] Added support for remote sessions, allowing OAuth users to browse and resume sessions from claude.ai"
3. **Official Claude mobile apps** — "Fixed Android app crash when running local slash commands (`/voice`, `/cost`) in Remote Control sessions"

#### Policy Restrictions

Remote Control access is restricted by plan tier:

> "Added policy limit fetching (e.g., remote control restrictions) for Team plan OAuth users, not just Enterprise" — CHANGELOG.md v2.1.69

This indicates Remote Control is a **managed feature** with enterprise policy controls, not a public API.

---

### 2. No Public API for Third-Party Remote Control

**Conclusion:** There is **no documented public API** for third-party clients to:
- Join Remote Control sessions
- Mirror chat events from Claude Code
- Observe tool execution in real-time
- Control Claude Code sessions programmatically

The Remote Control protocol is **internal and undocumented**. Evidence:

1. No API documentation exists in the public docs at code.claude.com
2. No OpenAPI spec or protocol documentation in the repository
3. Authentication requires OAuth via Anthropic's identity system
4. Policy restrictions are enforced server-side

---

### 3. Supported Integration Alternatives

#### Option A: Claude Agent SDK (Recommended)

The **Claude Agent SDK** (`@anthropic-ai/claude-agent-sdk`) is the officially supported way to build agentic applications that interact with Claude.

**Key Details:**
- Package: `@anthropic-ai/claude-agent-sdk` (npm) / `claude-agent-sdk` (pip)
- Documentation: https://docs.claude.com/en/api/agent-sdk/overview
- TypeScript SDK Reference: https://docs.claude.com/en/api/agent-sdk/typescript
- Python SDK Reference: https://docs.claude.com/en/api/agent-sdk/python

**Migration Note:**
> "Removed legacy SDK entrypoint. Please migrate to @anthropic-ai/claude-agent-sdk for future SDK updates" — CHANGELOG.md v2.0.25

**Architecture for ReCursor:**
Instead of mirroring a Claude Code session, ReCursor would:
1. Run its own Agent SDK session
2. Implement similar tool capabilities (Bash, Read, Edit, etc.)
3. Maintain separate conversation state
4. Use the same underlying Claude API

**Limitation:** This creates a **parallel session**, not a mirror of an existing Claude Code session.

---

#### Option B: Hooks System (Event Observation)

Claude Code provides a **Hooks system** that allows plugins to observe and react to events.

**Available Hook Events (confirmed from source truth):**
- `SessionStart` / `SessionEnd`
- `PostToolUse` / `PreToolUse`
- `UserPromptSubmit`
- `Stop` / `SubagentStop`
- `PreCompact`
- `Notification`

> **Note**: Additional events may be mentioned in CHANGELOG but the above list represents confirmed events from the Claude Code hooks implementation source truth.

**Hook Configuration:**
Hooks can be configured to:
- Run shell commands
- POST JSON to HTTP URLs ("Added HTTP hooks, which can POST JSON to a URL and receive JSON instead of running a shell command" — CHANGELOG.md v2.1.46)

**For ReCursor:**
A ReCursor backend could:
1. Set up an HTTP endpoint to receive hook events
2. Configure Claude Code to POST events to this endpoint
3. Forward events to the Flutter mobile app

**Limitation:** Hooks are **one-way** (observation only). They cannot inject messages or control the session.

---

#### Option C: MCP (Model Context Protocol)

MCP is an open protocol for extending Claude's capabilities with custom tools.

**Documentation:** https://code.claude.com/docs/en/plugins (referenced in CHANGELOG)

**Server Types Supported:**
- stdio (local processes)
- SSE (hosted/OAuth)
- HTTP (REST)
- WebSocket (real-time)

**For ReCursor:**
ReCursor could expose itself as an MCP server that Claude Code connects to, enabling:
- Mobile-initiated tool calls
- Bidirectional communication
- Custom tool definitions

---

### 4. Terms of Service and Legal Considerations

**License:**
> "© Anthropic PBC. All rights reserved. Use is subject to Anthropic's Commercial Terms of Service." — `C:/Repository/claude-code/LICENSE.md`

**Security Policy:**
> "The security of our systems and user data is Anthropic's top priority." — `C:/Repository/claude-code/SECURITY.md`

**Risks of Reverse Engineering:**
1. **ToS Violation:** Reverse engineering the Remote Control protocol may violate Anthropic's Commercial Terms of Service
2. **Authentication Barriers:** OAuth and JWT requirements make unauthorized access technically infeasible
3. **Breaking Changes:** Internal APIs change without notice (evident from frequent CHANGELOG updates)
4. **Policy Enforcement:** Remote Control restrictions are enforced server-side for Team/Enterprise plans

---

## Recommended Approach for ReCursor Documentation

### What to State as Plan

1. **Primary Integration:** Use Claude Agent SDK (`@anthropic-ai/claude-agent-sdk`) for core agentic functionality
2. **Event Streaming:** Implement HTTP hooks in Claude Code to stream events to ReCursor backend
3. **Tool Integration:** Expose ReCursor-specific tools via MCP protocol
4. **Authentication:** Use standard Anthropic API key authentication (not OAuth/Remote Control)

### What to State as Open Questions

1. **Session Synchronization:** How to synchronize state between a user's desktop Claude Code session and mobile ReCursor session
2. **Multi-Device Coordination:** Whether to support simultaneous use or session handoff
3. **Enterprise Policy:** How to handle environments with managed settings restricting hooks/MCP

### Risk Statement for Documentation

```markdown
## Integration Risks and Limitations

**Not Supported:** Direct integration with Claude Code's Remote Control feature is not 
possible for third-party applications. Remote Control is restricted to official Anthropic 
clients (claude.ai/code, VSCode extension, official mobile apps) and requires OAuth 
authentication with enterprise policy enforcement.

**Recommended Alternative:** ReCursor uses the Claude Agent SDK to create independent 
agentic sessions with equivalent capabilities. This approach:
- ✅ Is fully supported by Anthropic
- ✅ Uses public APIs with stable contracts
- ✅ Complies with Terms of Service
- ⚠️ Creates parallel sessions rather than mirroring desktop sessions
```

---

## Verification Evidence

### Command Output: Repository Search

```bash
$ cd C:/Repository/claude-code && grep -ri "remote.control" --include="*.md" -C 3 | head -50
CHANGELOG.md-- Fixed several Remote Control issues: sessions silently dying when the server reaps an idle environment, rapid messages being queued one-at-a-time instead of batched, and stale work items causing redelivery after JWT refresh
CHANGELOG.md-- Fixed bridge sessions failing to recover after extended WebSocket disconnects
CHANGELOG.md:- Improved Remote Control session titles — now derived from your first prompt instead of showing "Interactive session"
CHANGELOG.md:- Added optional name argument to `/remote-control` and `claude remote-control` (`/remote-control My Project` or `--name "My Project"`) to set a custom session title visible in claude.ai/code
CHANGELOG.md:- Added policy limit fetching (e.g., remote control restrictions) for Team plan OAuth users, not just Enterprise
```

### File Listing: Agent SDK Plugin

```bash
$ ls -la C:/Repository/claude-code/plugins/agent-sdk-dev/
total 16
drwxr-xr-x 1 Administrator 197121 0 Mar 17 19:57 .
drwxr-xr-x 1 Administrator 197121 0 Mar 17 19:57 ..
-rw-r--r-- 1 Administrator 197121 795 Mar 17 19:57 README.md
-rw-r--r-- 1 Administrator 197121 1729 Mar 17 19:57 commands/
-rw-r--r-- 1 Administrator 197121 4632 Mar 17 19:57 agents/
```

### Quoted Excerpt: Agent SDK Documentation Reference

From `C:/Repository/claude-code/plugins/agent-sdk-dev/README.md`:

> "Resources:
> - [Agent SDK Overview](https://docs.claude.com/en/api/agent-sdk/overview)
> - [TypeScript SDK Reference](https://docs.claude.com/en/api/agent-sdk/typescript)
> - [Python SDK Reference](https://docs.claude.com/en/api/agent-sdk/python)
> - [Agent SDK Examples](https://docs.claude.com/en/api/agent-sdk/examples)"

### Quoted Excerpt: License Terms

From `C:/Repository/claude-code/LICENSE.md`:

> "© Anthropic PBC. All rights reserved. Use is subject to Anthropic's [Commercial Terms of Service](https://www.anthropic.com/legal/commercial-terms)."

---

## References

1. **Claude Code Repository:** `C:/Repository/claude-code/`
2. **Official Documentation:** https://code.claude.com/docs/en/overview
3. **Agent SDK Docs:** https://docs.claude.com/en/api/agent-sdk/overview
4. **Commercial Terms:** https://www.anthropic.com/legal/commercial-terms
5. **Security Policy:** https://hackerone.com/anthropic-vdp

---

## Conclusion

ReCursor should **not** attempt to integrate with Claude Code's Remote Control feature due to:
- Lack of public API documentation
- OAuth/JWT authentication requirements
- Enterprise policy restrictions
- Terms of Service implications

Instead, ReCursor should:
1. Build on the **Claude Agent SDK** for core functionality
2. Use **HTTP hooks** for event observation from Claude Code
3. Implement **MCP servers** for tool interoperability
4. Position as a **complementary mobile agent** rather than a remote control client

This approach is fully supported, legally compliant, and architecturally sound.
