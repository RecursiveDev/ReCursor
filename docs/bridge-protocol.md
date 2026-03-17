# Bridge Protocol Specification

> WebSocket message protocol between the ReCursor Flutter mobile app and the TypeScript bridge server.

---

## Connection Lifecycle

```mermaid
sequenceDiagram
    participant Mobile as ReCursor App
    participant Bridge as Bridge Server
    participant Hooks as Claude Code Hooks
    participant CC as Claude Code

    Note over Mobile,CC: Initial Connection
    Mobile->>Bridge: wss:// connect + auth token
    Bridge-->>Mobile: connection_ack { version, sessions }
    
    Mobile->>Bridge: heartbeat_ping
    Bridge-->>Mobile: heartbeat_pong

    Note over Mobile,CC: Claude Code Hook Registration
    CC->>Hooks: SessionStart event
    Hooks->>Bridge: HTTP POST /hooks/event
    Bridge-->>Hooks: 200 OK
    
    Bridge->>Mobile: session_started { session_id }
```

---

## Message Format

All messages are JSON objects with a `type` field and an optional `id` for request-response correlation.

```json
{
  "type": "message_type",
  "id": "unique-msg-id",
  "timestamp": "2026-03-16T10:32:00Z",
  "payload": { ... }
}
```

---

## Message Types

### Connection

#### `auth` (client -> server)
Sent immediately after WebSocket connection opens.

```json
{
  "type": "auth",
  "id": "auth-001",
  "payload": {
    "token": "bridge-auth-token-xxxxx",
    "client_version": "1.0.0",
    "platform": "ios"
  }
}
```

#### `connection_ack` (server -> client)
Confirms authentication and connection.

```json
{
  "type": "connection_ack",
  "id": "auth-001",
  "payload": {
    "server_version": "1.0.0",
    "supported_agents": ["claude-code", "opencode", "aider", "goose"],
    "active_sessions": [
      { "session_id": "sess-abc", "agent": "claude-code", "title": "Fix auth bug" }
    ]
  }
}
```

#### `connection_error` (server -> client)
Authentication or connection failure.

```json
{
  "type": "connection_error",
  "id": "auth-001",
  "payload": {
    "code": "AUTH_FAILED",
    "message": "Invalid or expired token"
  }
}
```

#### `heartbeat_ping` / `heartbeat_pong`
Keep-alive messages. Client sends ping, server responds with pong.

```json
{ "type": "heartbeat_ping", "timestamp": "2026-03-16T10:32:00Z" }
{ "type": "heartbeat_pong", "timestamp": "2026-03-16T10:32:00Z" }
```

Interval: 15 seconds (configurable). If no pong received within 10 seconds, client triggers reconnect.

---

### Agent Sessions

#### `session_start` (client -> server)
Start a new agent session or resume an existing one.

```json
{
  "type": "session_start",
  "id": "req-001",
  "payload": {
    "agent": "claude-code",
    "session_id": null,
    "working_directory": "/home/user/project",
    "resume": false
  }
}
```

Set `session_id` and `resume: true` to resume an existing session.

#### `session_ready` (server -> client)
Agent session is initialized and ready.

```json
{
  "type": "session_ready",
  "id": "req-001",
  "payload": {
    "session_id": "sess-abc123",
    "agent": "claude-code",
    "working_directory": "/home/user/project",
    "branch": "main",
    "status": "ready"
  }
}
```

#### `session_end` (bidirectional)
End a session. Can be initiated by client or server.

```json
{
  "type": "session_end",
  "payload": {
    "session_id": "sess-abc123",
    "reason": "user_request" // or "timeout", "error", "completed"
  }
}
```

---

### Chat Messages

#### `message` (client -> server)
Send a chat message to the agent.

```json
{
  "type": "message",
  "id": "msg-001",
  "payload": {
    "session_id": "sess-abc123",
    "content": "Fix the auth bug in login.dart",
    "role": "user"
  }
}
```

#### `stream_start` (server -> client)
Agent begins streaming a response.

```json
{
  "type": "stream_start",
  "payload": {
    "session_id": "sess-abc123",
    "message_id": "msg-resp-001"
  }
}
```

#### `stream_chunk` (server -> client)
Chunk of streamed response content.

```json
{
  "type": "stream_chunk",
  "payload": {
    "session_id": "sess-abc123",
    "message_id": "msg-resp-001",
    "content": "I'll help you fix the auth bug",
    "is_tool_use": false
  }
}
```

#### `stream_end` (server -> client)
Streaming response is complete.

```json
{
  "type": "stream_end",
  "payload": {
    "session_id": "sess-abc123",
    "message_id": "msg-resp-001",
    "finish_reason": "stop" // or "tool_call", "length", "error"
  }
}
```

---

### Tool Calls

#### `tool_call` (server -> client)
Agent wants to use a tool. Sent when Agent SDK initiates tool use.

```json
{
  "type": "tool_call",
  "id": "tool-001",
  "payload": {
    "session_id": "sess-abc123",
    "tool_call_id": "call-abc123",
    "tool": "edit_file",
    "params": {
      "file_path": "/home/user/project/lib/auth.dart",
      "old_string": "void login() {",
      "new_string": "void login() async {"
    },
    "description": "Add async keyword to login function"
  }
}
```

#### `claude_event` (server -> client)
Event from Claude Code Hooks. See [Claude Code Hooks Integration](integration/claude-code-hooks.md).

```json
{
  "type": "claude_event",
  "payload": {
    "event_type": "PostToolUse",
    "session_id": "sess-abc123",
    "timestamp": "2026-03-16T10:32:00Z",
    "payload": {
      "tool": "edit_file",
      "result": { "success": true }
    }
  }
}
```

#### `approval_required` (server -> client)
Tool call requires user approval (from Hooks or Agent SDK).

```json
{
  "type": "approval_required",
  "id": "tool-001",
  "payload": {
    "session_id": "sess-abc123",
    "tool_call_id": "call-abc123",
    "tool": "run_command",
    "params": {
      "command": "flutter build apk"
    },
    "description": "Build Android APK",
    "risk_level": "medium",
    "source": "hooks" // or "agent_sdk"
  }
}
```

#### `approval_response` (client -> server)
User's decision on a tool call approval.

```json
{
  "type": "approval_response",
  "id": "tool-001",
  "payload": {
    "session_id": "sess-abc123",
    "tool_call_id": "call-abc123",
    "decision": "approved", // or "rejected", "modified"
    "modifications": null // or modified params
  }
}
```

#### `tool_result` (server -> client)
Result of tool execution.

```json
{
  "type": "tool_result",
  "payload": {
    "session_id": "sess-abc123",
    "tool_call_id": "call-abc123",
    "tool": "edit_file",
    "result": {
      "success": true,
      "content": "File edited successfully",
      "diff": "... unified diff ..."
    }
  }
}
```

---

### Git Operations

#### `git_status_request` (client -> server)
Request current git status.

```json
{
  "type": "git_status_request",
  "id": "git-001",
  "payload": {
    "session_id": "sess-abc123"
  }
}
```

#### `git_status_response` (server -> client)
Current git status.

```json
{
  "type": "git_status_response",
  "id": "git-001",
  "payload": {
    "session_id": "sess-abc123",
    "branch": "feature/auth-fix",
    "ahead": 2,
    "behind": 0,
    "is_clean": false,
    "changes": [
      { "path": "lib/auth.dart", "status": "modified", "additions": 5, "deletions": 2 }
    ]
  }
}
```

#### `git_commit` (client -> server)
Create a commit.

```json
{
  "type": "git_commit",
  "id": "git-002",
  "payload": {
    "session_id": "sess-abc123",
    "message": "Fix auth bug in login flow",
    "files": ["lib/auth.dart"] // null = all staged
  }
}
```

#### `git_diff` (client -> server)
Request diff for files.

```json
{
  "type": "git_diff",
  "id": "git-003",
  "payload": {
    "session_id": "sess-abc123",
    "files": ["lib/auth.dart"], // null = all changes
    "cached": false
  }
}
```

#### `git_diff_response` (server -> client)
Diff content.

```json
{
  "type": "git_diff_response",
  "id": "git-003",
  "payload": {
    "session_id": "sess-abc123",
    "files": [
      {
        "path": "lib/auth.dart",
        "old_path": "lib/auth.dart",
        "new_path": "lib/auth.dart",
        "status": "modified",
        "additions": 5,
        "deletions": 2,
        "hunks": [
          {
            "header": "@@ -10,5 +10,5 @@",
            "old_start": 10,
            "old_lines": 5,
            "new_start": 10,
            "new_lines": 5,
            "lines": [
              { "type": "context", "content": " class AuthService {" },
              { "type": "removed", "content": "-  void login() {" },
              { "type": "added", "content": "+  void login() async {" },
              { "type": "context", "content": "     // ..." }
            ]
          }
        ]
      }
    ]
  }
}
```

---

### File Operations

#### `file_list` (client -> server)
List files in a directory.

```json
{
  "type": "file_list",
  "id": "file-001",
  "payload": {
    "session_id": "sess-abc123",
    "path": "/home/user/project/lib"
  }
}
```

#### `file_list_response` (server -> client)
Directory listing.

```json
{
  "type": "file_list_response",
  "id": "file-001",
  "payload": {
    "session_id": "sess-abc123",
    "path": "/home/user/project/lib",
    "entries": [
      { "name": "auth.dart", "type": "file", "size": 2048 },
      { "name": "models", "type": "directory" }
    ]
  }
}
```

#### `file_read` (client -> server)
Read file content.

```json
{
  "type": "file_read",
  "id": "file-002",
  "payload": {
    "session_id": "sess-abc123",
    "path": "/home/user/project/lib/auth.dart",
    "offset": 0,
    "limit": 100
  }
}
```

#### `file_read_response` (server -> client)
File content.

```json
{
  "type": "file_read_response",
  "id": "file-002",
  "payload": {
    "session_id": "sess-abc123",
    "path": "/home/user/project/lib/auth.dart",
    "content": "class AuthService { ... }",
    "size": 2048,
    "lines": 45
  }
}
```

---

### Notifications

#### `notification` (server -> client)
Server-initiated notification.

```json
{
  "type": "notification",
  "id": "notif-001",
  "payload": {
    "session_id": "sess-abc123",
    "notification_type": "approval_required",
    "title": "Approval needed: Edit login.dart",
    "body": "Claude Code wants to change the OAuth callback URL.",
    "priority": "high",
    "data": {
      "tool_call_id": "tool-001",
      "screen": "approval_detail"
    }
  }
}
```

#### `notification_ack` (client -> server)
Acknowledge receipt of notifications.

```json
{
  "type": "notification_ack",
  "payload": {
    "notification_ids": ["notif-001", "notif-002"]
  }
}
```

---

### Errors

#### `error` (server -> client)
Server-side error.

```json
{
  "type": "error",
  "payload": {
    "code": "AGENT_ERROR",
    "message": "Failed to execute tool: permission denied",
    "session_id": "sess-abc123",
    "recoverable": true
  }
}
```

---

## Error Codes

| Code | Description | Recoverable |
|------|-------------|-------------|
| `AUTH_FAILED` | Invalid or expired token | No (re-auth required) |
| `SESSION_NOT_FOUND` | Session ID doesn't exist | No |
| `AGENT_ERROR` | Agent execution failed | Yes (retry) |
| `TOOL_ERROR` | Tool execution failed | Yes (modify params) |
| `GIT_ERROR` | Git operation failed | Yes |
| `RATE_LIMITED` | Too many requests | Yes (backoff) |
| `BRIDGE_ERROR` | Internal bridge error | Yes |

---

## Reconnection Behavior

When the mobile app reconnects after disconnection:

1. Client sends `auth` message
2. Server responds with `connection_ack` including `active_sessions`
3. Server replays any queued events (notifications, tool results)
4. Client acknowledges with `notification_ack`

---

## Related Documentation

- [Architecture Overview](architecture/overview.md) — System architecture
- [Data Flow](architecture/data-flow.md) — Message sequence diagrams
- [Claude Code Hooks Integration](integration/claude-code-hooks.md) — Hook event format
- [Agent SDK Integration](integration/agent-sdk.md) — Agent SDK message flow

---

*Last updated: 2026-03-17*
