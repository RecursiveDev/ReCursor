# Data Flow Architecture

> Message flow between ReCursor mobile app, bridge server, and coding agent. **Claude Code is the current integration** — this diagram shows the Claude Code integration pattern. Future agent adapters will follow similar patterns.

---

## Connection Lifecycle

```mermaid
sequenceDiagram
    participant Mobile as ReCursor App
    participant Bridge as Bridge Server
    participant Hooks as Agent Hooks
    participant Agent as Coding Agent (Claude Code)

    Note over Mobile,Agent: Initial Connection
    Mobile->>Bridge: wss:// connect + auth token
    Bridge-->>Mobile: connection_ack { version, sessions }

    Mobile->>Bridge: heartbeat_ping
    Bridge-->>Mobile: heartbeat_pong

    Note over Mobile,Agent: Agent Hook Registration (Claude Code shown)
    Agent->>Hooks: SessionStart event
    Hooks->>Bridge: HTTP POST /hooks/event
    Bridge-->>Hooks: 200 OK

    Bridge->>Mobile: session_started { session_id }
```

---

## Message Flow: User Sends Message

```mermaid
sequenceDiagram
    participant Mobile as ReCursor App
    participant Bridge as Bridge Server
    participant AgentSDK as Agent SDK (Claude)
    participant API as LLM API

    Note over Mobile,API: User sends message via mobile
    Mobile->>Mobile: Queue in SyncQueue (if offline)
    Mobile->>Bridge: message { text, session_id }
    Bridge->>Bridge: Validate session
    Bridge->>AgentSDK: Forward message
    AgentSDK->>API: LLM API request
    API-->>AgentSDK: Stream response

    loop Streaming Response
        AgentSDK->>Bridge: stream_chunk { content }
        Bridge->>Mobile: stream_chunk { content }
        Mobile->>Mobile: Update UI (streaming text)
    end

    AgentSDK-->>Bridge: stream_end
    Bridge-->>Mobile: stream_end
```

---

## Message Flow: Tool Use (via Hooks)

> **Note:** This diagram shows Claude Code's hook integration. Other agents may use different event mechanisms.

```mermaid
sequenceDiagram
    participant Mobile as ReCursor App
    participant Bridge as Bridge Server
    participant Hooks as Agent Hooks
    participant Agent as Coding Agent (Claude Code)
    participant API as LLM API

    Note over Mobile,API: Agent executes tool (Claude Code shown)
    Agent->>Agent: ToolUse (e.g., edit_file)
    Agent->>Hooks: PostToolUse event
    Hooks->>Bridge: HTTP POST /hooks/event
    Note right of Hooks: { tool, params, result, session_id }

    Bridge->>Bridge: Queue event (if mobile offline)
    Bridge->>Mobile: tool_result { tool, result }

    Mobile->>Mobile: Render OpenCode-style Tool Card
    Mobile->>Mobile: Update Session Timeline

    Note over Mobile,API: Tool requires approval
    Agent->>Agent: ToolUse with approval_required
    Agent->>Hooks: PreToolUse event
    Hooks->>Bridge: HTTP POST /hooks/event
    Bridge->>Mobile: approval_required { tool, description }

    Mobile->>Mobile: Show approval UI with rich context
    Mobile->>Bridge: approval_response { decision, modifications }

    Note right of Mobile: Cannot inject into Claude Code directly
    Bridge->>Bridge: Queue for Agent SDK session

    alt Agent SDK Session Active
        Bridge->>AgentSDK: Forward approval
        AgentSDK->>API: Continue with approval context
    else No Agent SDK Session
        Bridge->>Bridge: Log for manual handling
    end
```

---

## Event Types from Hooks

> **Note:** Hook events shown are for Claude Code integration. Other agents may emit different event types.

```mermaid
flowchart TB
    subgraph Events["Hook Event Types (Claude Code)"]
        Session["Session Events"]
        Tool["Tool Events"]
        User["User Events"]
        System["System Events"]
    end

    subgraph SessionEvents[" " ]
        SS[SessionStart]
        SE[SessionEnd]
    end

    subgraph ToolEvents[" " ]
        PTU[PreToolUse]
        PTU2[PostToolUse]
    end

    subgraph UserEvents[" " ]
        UPS[UserPromptSubmit]
    end

    subgraph SystemEvents[" " ]
        ST[Stop]
        SS2[SubagentStop]
        PC[PreCompact]
        N[Notification]
    end

    Session --- SessionEvents
    Tool --- ToolEvents
    User --- UserEvents
    System --- SystemEvents
```

### Event Mapping to UI

| Hook Event | OpenCode UI Component | Mobile Action |
|------------|----------------------|---------------|
| `SessionStart` | Session timeline | Add session to list |
| `SessionEnd` | Session timeline | Mark session ended |
| `PostToolUse` | Tool card | Render tool result card |
| `PreToolUse` | Approval dialog | Show approval UI |
| `UserPromptSubmit` | Chat message | Show user message |
| `Stop` | Session status | Show completion status |
| `SubagentStop` | Subagent status | Update subagent state |

> **Note**: Only confirmed hook events from Claude Code source truth are listed above. See [Claude Code Hooks Integration](../integration/claude-code-hooks.md) for the complete verified event list.

---

## Reconnection Flow

```mermaid
sequenceDiagram
    participant Mobile as ReCursor App
    participant Bridge as Bridge Server

    Note over Mobile,Bridge: Mobile temporarily disconnects
    Bridge->>Bridge: Queue events from Hooks
    Mobile->>Mobile: Detect disconnect
    Mobile->>Mobile: Show "Reconnecting..." UI

    loop Reconnect Attempts
        Mobile->>Bridge: wss:// connect
        alt Bridge Available
            Bridge-->>Mobile: connection_ack
            Bridge->>Mobile: Replay queued events
            Mobile->>Mobile: Process backlog
        else Bridge Unavailable
            Mobile->>Mobile: Wait (exponential backoff)
        end
    end
```

---

## Offline Queue Flow

```mermaid
flowchart TD
    A[User Action] --> B{Online?}
    B -->|Yes| C[Execute Immediately]
    B -->|No| D[Queue in SyncQueue]
    D --> E[Show Pending State]
    
    F[Connectivity Restored] --> G{Bridge Reachable?}
    G -->|Yes| H[Flush Queue]
    H --> I[Mark Synced]
    G -->|No| J[Keep Queued]
    
    C --> K[Update UI]
    I --> K
```

---

## Message Format: Hook Events

```json
{
  "event_type": "PostToolUse",
  "session_id": "sess-abc123",
  "timestamp": "2026-03-17T10:32:00Z",
  "payload": {
    "tool": "edit_file",
    "params": {
      "file_path": "/home/user/project/lib/main.dart",
      "old_string": "void main() {",
      "new_string": "void main() async {"
    },
    "result": {
      "success": true,
      "diff": "... unified diff ..."
    },
    "metadata": {
      "token_count": 150,
      "duration_ms": 250
    }
  }
}
```

---

## Message Format: WebSocket Protocol

See [Bridge Protocol](../bridge-protocol.md) for complete WebSocket message specification.

---

## Related Documentation

- [Architecture Overview](overview.md) — High-level system architecture
- [Claude Code Hooks Integration](../integration/claude-code-hooks.md) — Hook configuration details
- [Agent SDK Integration](../integration/agent-sdk.md) — Parallel session flow
- [Bridge Protocol](../bridge-protocol.md) — WebSocket message specification
- [Offline Architecture](../offline-architecture.md) — Sync queue implementation

---

*Last updated: 2026-03-17*
