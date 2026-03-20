# Research Report: Claude Code Remote Control Protocol

> Generated: 2026-03-17 | Researcher Agent

## Executive Summary

Claude Code Remote Control is a feature that allows users to connect [claude.ai/code](https://claude.ai/code) or the Claude mobile app (iOS/Android) to a Claude Code session running locally on their machine. This enables users to start a task at their desk and continue from their phone or another browser. The remote control functionality is available on Pro, Max, Team, and Enterprise plans (requires Claude Code v2.1.51+).

For the ReCursor project, understanding this protocol is critical for building a Flutter mobile UI that can mirror Claude Code's desktop UI/UX and connect to a running Claude Code instance to sync chat and tool events.

## Source Validation

| Source | Tier | Date | Version |
|--------|------|------|---------|
| code.claude.com/docs/en/remote-control | 1 | 2026-03 | v2.1.77 |
| C:/Repository/claude-code/CHANGELOG.md | 1 | 2026-03 | v2.1.77 |
| code.claude.com/docs/en/security | 1 | 2026-03 | - |
| code.claude.com/docs/en/cli-reference | 1 | 2026-03 | - |
| code.claude.com/docs/en/sdk | 1 | 2026-03 | - |

## 1. Remote Control: How It's Enabled/Exposed

### 1.1 Transport Architecture

**Key Finding:** Claude Code Remote Control uses a **polling-based outbound HTTPS architecture** with WebSocket-like streaming, NOT direct client-server connections.

From the official docs:
> "Your local Claude Code session makes outbound HTTPS requests only and never opens inbound ports on your machine. When you start Remote Control, it registers with the Anthropic API and polls for work. When you connect from another device, the server routes messages between the web or mobile client and your local session over a streaming connection."

> "All traffic travels through the Anthropic API over TLS, the same transport security as any Claude Code session."

### 1.2 How Remote Control is Started

There are three ways to enable remote control:

**Method 1: Dedicated Server Mode** (CLI)
```bash
claude remote-control [options]
```
- Stays running in terminal as a server
- Waits for remote connections
- Displays session URL and QR code (spacebar toggles QR)
- No local interactive session

**Method 2: Interactive Session with Remote Control** (CLI Flag)
```bash
claude --remote-control ["Session Name"]
# or
claude --rc "My Project"
```
- Runs interactive terminal session locally
- ALSO available remotely via claude.ai/code or mobile app
- Can type messages locally while remote session is active

**Method 3: From Within Running Session** (Slash Command)
```
/remote-control [Session Name]
# or
/rc My Project
```
- Carries over current conversation history
- Displays session URL and QR code
- Cannot use --verbose, --sandbox, --no-sandbox flags with this method

### 1.3 Server Mode Configuration Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--name "My Project"` | Custom session title visible at claude.ai/code | Auto-generated |
| `--spawn <mode>` | How concurrent sessions are created | `same-dir` |
| `--capacity <N>` | Maximum concurrent sessions | 32 |
| `--verbose` | Detailed connection/session logs | false |
| `--sandbox` / `--no-sandbox` | Enable/disable sandboxing | off |

### 1.4 Spawn Modes

The `--spawn` flag controls concurrent session behavior:

- **`same-dir`** (default): All sessions share the current working directory. Can conflict if editing same files.
- **`worktree`**: Each on-demand session gets its own git worktree. Requires a git repository. Can be toggled at runtime with `w` key.

### 1.5 Auto-Enable Remote Control

Via `/config` command: **"Enable Remote Control for all sessions"** → set to `true`
- Every interactive session registers one remote session
- Multiple instances = multiple separate environments/sessions
- For multiple concurrent sessions from single process, use server mode with `--spawn`

### 1.6 Connection Flow

1. User runs `claude remote-control` (or `--remote-control`)
2. Local Claude Code process registers with Anthropic API
3. Process polls for work via HTTPS (outbound only)
4. When remote client connects (claude.ai/code or mobile app), Anthropic API routes messages
5. Traffic flows: Local Claude ↔ Anthropic API ↔ Remote Client

## 2. Message/Event Schema

### 2.1 Transport Protocol Details

Based on CHANGELOG analysis:

**Protocol Stack:**
- Transport: HTTPS (outbound polling from local)
- Routing: Anthropic API acts as message broker
- Real-time updates: Stream-based connection (similar to SSE/WebSocket semantics but over HTTPS polling)
- Authentication: JWT tokens with expiration
- Protocol references: "bridge" sessions, "/poll" endpoint, "control_response" messages

### 2.2 Key CHANGELOG Evidence for Protocol

From CHANGELOG.md v2.1.76:
> "Fixed several Remote Control issues: sessions silently dying when the server reaps an idle environment, rapid messages being queued one-at-a-time instead of batched, and stale work items causing redelivery after JWT refresh"

> "Fixed bridge sessions failing to recover after extended WebSocket disconnects"

From CHANGELOG.md v2.1.70:
> "Reduced Remote Control `/poll` rate to once per 10 minutes while connected (was 1–2s), cutting server load ~300x. Reconnection is unaffected — transport loss immediately wakes fast polling."

From CHANGELOG.md v2.1.69:
> "Added policy limit fetching (e.g., remote control restrictions) for Team plan OAuth users"

From CHANGELOG.md v2.1.51:
> "Added `claude remote-control` subcommand for external builds, enabling local environment serving for all users."

> "Fixed a bug where duplicate `control_response` messages (e.g. from WebSocket reconnects) could cause API 400 errors by pushing duplicate assistant messages into the conversation."

### 2.3 Inferred Message/Event Types

Based on CHANGELOg and documentation analysis:

#### Core Event Types:

1. **Session Events**
   - `SessionStart`: When remote client connects
   - `SessionEnd`: When session terminates
   - `BridgeSessionConnect`: WebSocket/transport layer connection
   - `BridgeSessionDisconnect`: Transport disconnection

2. **Message Events**
   - `UserMessage`: Input from remote user
   - `AssistantMessage`: Claude's response
   - `ControlResponse`: Status/control messages between local and remote
   - `QueuedMessages`: Batched messages during rapid input

3. **Tool Events**
   - `ToolUse`: When Claude uses a tool
   - `ToolResult`: Result of tool execution
   - `ToolError`: Tool execution failure

4. **State Events**
   - `SessionState`: Current conversation state sync
   - `Poll`: Periodic health/keep-alive check
   - `JWTRefresh`: Token refresh event

### 2.4 SDK Event Types (Reference)

From CHANGELOG.md v2.1.66:
> "Added `SDKRateLimitInfo` and `SDKRateLimitEvent` types to the SDK, enabling consumers to receive rate limit status updates including utilization, reset times, and overage information"

This suggests the SDK uses strongly-typed events. Event categories include:
- Rate limiting events
- Message streaming events
- Session lifecycle events
- Tool execution events

### 2.5 Stream Updates

From CHANGELOG.md v2.1.71:
> "Fixed a race condition in the REPL bridge where new messages could arrive at the server interleaved with historical messages during the initial connection flush, causing message ordering issues."

This indicates:
- Initial connection sends historical messages
- Real-time messages stream after
- Ordering must be maintained
- Bridge handles synchronization

## 3. Security Model

### 3.1 Architecture Summary

From official docs:
> "Your local Claude Code session makes outbound HTTPS requests only and never opens inbound ports on your machine."

> "All traffic travels through the Anthropic API over TLS, the same transport security as any Claude Code session."

> "The connection uses multiple short-lived credentials, each scoped to a single purpose and expiring independently."

### 3.2 Authentication Requirements

**Subscription:**
- Available on: Pro, Max, Team, Enterprise plans
- Team/Enterprise admins must enable Claude Code in admin settings first
- **API keys are NOT supported** — OAuth/Anthropic account required

**Authentication Steps:**
1. Run `claude` and use `/login` to sign in through claude.ai
2. Must authenticate with Anthropic (OAuth-based)
3. Workspace trust: Run `claude` in project directory at least once to accept trust dialog

### 3.3 Multi-layered Credentials

From docs:
> "The connection uses multiple short-lived credentials, each scoped to a single purpose and expiring independently."

Evidence from CHANGELOG:
- JWT tokens with refresh cycles
- Session-scoped credentials
- Independent expiration per purpose

### 3.4 Network Security

**Outbound-Only:**
- Local machine ONLY makes outbound HTTPS requests
- No inbound ports opened on local machine
- No direct peer-to-peer connection between devices

**Routing:**
- All traffic goes through Anthropic API as broker
- TLS encryption same as regular Claude Code sessions
- Session URL generated for access: `claude.ai/code`

### 3.5 Session Limits/Reconnect

**Network Outage Behavior:**
From docs:
> "Survive interruptions: if your laptop sleeps or your network drops, the session reconnects automatically when your machine comes back online"

**Timeout Threshold:**
> "Extended network outage: if your machine is awake but unable to reach the network for more than roughly 10 minutes, the session times out and the process exits."

### 3.6 Policy Restrictions

From CHANGELOG:
> "Added policy limit fetching (e.g., remote control restrictions) for Team plan OAuth users"

Enterprise/Team admins can restrict remote control usage via managed settings.

### 3.7 Workspace Security

From Security docs:
> "Claude Code uses strict read-only permissions by default. When additional actions are needed (editing files, running tests, executing commands), Claude Code requests explicit permission."

> "Write access restriction: Claude Code can only write to the folder where it was started and its subfolders"

Remote Control inherits all local security settings including sandbox mode.

## 4. Integration Constraints & Limitations

### 4.1 Version Requirements

- **Minimum version:** Claude Code v2.1.51 or later
- Check version: `claude --version`
- Feature added: v2.1.51 ("Added `claude remote-control` subcommand for external builds")

### 4.2 Platform Support

**Local Machine:**
- Any platform running Claude Code (macOS, Linux, Windows)

**Remote Clients:**
- claude.ai/code (any browser)
- Claude iOS app
- Claude Android app

### 4.3 Session Limitations

From docs:

1. **One remote session per interactive process:**
   > "outside of server mode, each Claude Code instance supports one remote session at a time. Use server mode with `--spawn` to run multiple concurrent sessions from a single process."

2. **Terminal must stay open:**
   > "Remote Control runs as a local process. If you close the terminal or stop the `claude` process, the session ends."

3. **Network timeout:**
   > "if your machine is awake but unable to reach the network for more than roughly 10 minutes, the session times out and the process exits."

### 4.4 Scalability Limits

| Resource | Default Limit |
|----------|---------------|
| Concurrent sessions (server mode) | 32 (configurable via `--capacity`) |
| Reconnection window | ~10 minutes max network outage |
| Polling rate | Once per 10 minutes while connected (was 1-2s pre-v2.1.70) |

### 4.5 Authentication Constraints

- OAuth/Anthropic account required (API keys NOT supported)
- Must be on Pro/Max/Team/Enterprise plan
- Team/Enterprise: Admin must enable Claude Code in admin settings

### 4.6 Known Issues from CHANGELOG

**Fixed in v2.1.76:**
- Sessions silently dying when server reaps idle environment
- Rapid messages queued one-at-a-time instead of batched
- Stale work items causing redelivery after JWT refresh
- Bridge sessions failing to recover after extended WebSocket disconnects

**Fixed in v2.1.70:**
- Reduced Remote Control `/poll` rate to once per 10 minutes (previously 1-2s)

**Fixed in v2.1.69:**
- `claude remote-control` crashing immediately on npm installs with "bad option: --sdk-url"
- Duplicate `control_response` messages causing API 400 errors

**Fixed in v2.1.63:**
- Listener leak in bridge polling loop
- Race condition in REPL bridge with message ordering

### 4.7 Feature Limitations vs Claude Code on Web

From docs:
> "Remote Control executes on your machine, so your local MCP servers, tools, and project configuration stay available. Claude Code on the web executes in Anthropic-managed cloud infrastructure."

**Remote Control has:**
- Local filesystem access
- Local MCP servers
- Local tools and project configuration
- Local environment

**Claude Code on Web has:**
- Cloud execution (no local setup required)
- Access to repos not locally cloned
- Multiple parallel tasks

## 5. Open Questions for ReCursor Implementation

### 5.1 Protocol-Level Questions

1. **Direct Integration Feasibility:** The official protocol requires routing through Anthropic's API. For ReCursor's use case (connecting Flutter mobile UI to local Claude Code), the same transport may not be directly usable without an Anthropic API intermediary.

2. **Message Format:** The exact JSON schema for `control_response`, `bridge` messages, and SDK events is not publicly documented. Reverse engineering would be required or a different protocol would need to be implemented.

3. **Authentication Token Flow:** How session URLs are generated and validated, and how JWT tokens are exchanged between local client and remote viewers.

### 5.2 Implementation Approach Questions

1. **Proxy/Broker:** Would ReCursor need to implement its own message broker/proxy between Flutter mobile and local Claude Code, or could it tap into the existing bridge mechanism?

2. **Tool Event Mirroring:** How are tool use/result events rendered on the remote client? Are these full JSON-RPC messages or simplified representations?

3. **Bidirectional Sync:** The protocol supports "work from both surfaces at once." How is message ordering and conflict resolution handled when both terminals are active?

### 5.3 Security Considerations for ReCursor

1. **Custom Authentication:** If implementing a custom remote control protocol, how would authentication and authorization be handled securely?

2. **Local Network Exposure:** Unlike Claude's official implementation (outbound-only), ReCursor's approach may need to expose a local server or use WebRTC/similar. Security implications need analysis.

3. **Origin Validation:** Does Claude Code validate remote client origins? How would session hijacking be prevented?

### 5.4 Technical Gaps

1. **No Public SDK for Remote Control:** The Agent SDK is for building agents, not controlling Claude Code remotely. No documented API for third-party remote control clients.

2. **Undocumented Protocol:** The WebSocket/bridge protocol details are internal and subject to change.

3. **No Standalone Server:** `claude remote-control` is part of the Claude Code CLI, not a standalone daemon that could be easily embedded.

## 6. Recommendations for ReCursor

### 6.1 Two Possible Architecture Approaches

**Approach A: Integration with Official Protocol (If Supported)**
- Contact Anthropic to inquire about third-party remote control API/SDK
- If available, use official SDK types (SDKRateLimitInfo, SDKRateLimitEvent, etc.)
- Route through Anthropic API (as official clients do)

**Approach B: Custom Protocol Implementation** (More Likely)
- Implement a custom bridge between Flutter app and local Claude Code
- Use Claude Code's plugin/hook system to capture events
- Implement separate WebSocket server for mobile communication
- Build custom message schema mirroring Claude's UX

### 6.2 Plugin-Based Event Capture

Claude Code supports:
- Hooks (PreToolUse, PostToolUse, SessionStart, SessionEnd, etc.)
- Custom skills
- Settings for auto-enabling

A plugin could capture:
- Chat messages
- Tool calls/results
- Session state changes
- Streaming updates

### 6.3 Custom Message Schema Recommendation

Based on the observed patterns:

```typescript
// Suggested event types for ReCursor
interface ReCursorEvent {
  type: 'message' | 'tool_use' | 'tool_result' | 'state_change' | 'error';
  sessionId: string;
  timestamp: number;
  payload: unknown;
}

// Mirroring Claude's chat structure
interface ChatMessage {
  role: 'user' | 'assistant';
  content: string | ContentBlock[];
  id: string;
}

// Tool execution events
interface ToolUseEvent {
  toolName: string;
  toolInput: Record<string, unknown>;
  toolUseId: string;
}

interface ToolResultEvent {
  toolUseId: string;
  result: unknown;
  status: 'success' | 'error';
}
```

### 6.4 Security Recommendations

1. Generate cryptographically secure session tokens
2. Use TLS for all communication
3. Implement origin validation
4. Support token expiration and refresh
5. Allow explicit user approval for remote connections
6. Restrict to local network or implement secure tunnel

## References

1. **Claude Code Remote Control Documentation:** https://code.claude.com/docs/en/remote-control
2. **Claude Code Security Documentation:** https://code.claude.com/docs/en/security
3. **Claude Code CLI Reference:** https://code.claude.com/docs/en/cli-reference
4. **Claude Code Settings Documentation:** https://code.claude.com/docs/en/settings
5. **Agent SDK Documentation:** https://code.claude.com/docs/en/sdk
6. **Local Repository:** C:/Repository/claude-code/CHANGELOG.md (v2.1.77)

---

*Note: The Claude Code Remote Control protocol is proprietary and not publicly documented as a third-party API. The information above was gathered from official documentation and changelog analysis. For production use, direct integration with Anthropic's official APIs or explicit permission would be required.*
