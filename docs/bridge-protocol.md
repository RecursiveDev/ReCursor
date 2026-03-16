# Bridge Protocol Specification

> WebSocket message protocol between the Flutter mobile app and the TypeScript bridge server.

---

## Connection Lifecycle

```
Mobile App                          Bridge Server                    CLI Agent
    |                                    |                              |
    |--- wss:// connect (+ auth token) ->|                              |
    |<-- connection_ack { version } -----|                              |
    |                                    |                              |
    |--- heartbeat_ping --------------->|                              |
    |<-- heartbeat_pong ----------------|                              |
    |                                    |                              |
    |--- agent_start { agent, config } ->|--- spawn/attach agent ------>|
    |<-- agent_ready { session_id } -----|<-- agent initialized --------|
    |                                    |                              |
    |--- message { text } ------------->|--- forward to agent --------->|
    |<-- stream_start { msg_id } -------|<-- agent begins response -----|
    |<-- stream_chunk { text } ---------|<-- token --------------------|
    |<-- stream_chunk { text } ---------|<-- token --------------------|
    |<-- stream_end { msg_id } ---------|<-- agent done ----------------|
    |                                    |                              |
    |<-- tool_call { action, params } --|<-- agent requests tool -------|
    |--- tool_response { approved } --->|--- forward decision --------->|
    |                                    |                              |
    |--- disconnect ------------------->|                              |
    |<-- connection_closed --------------|                              |
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
    "branch": "main"
  }
}
```

#### `session_end` (bidirectional)
Terminate a session.

```json
{
  "type": "session_end",
  "id": "req-002",
  "payload": {
    "session_id": "sess-abc123",
    "reason": "user_closed"
  }
}
```

#### `session_list` (client -> server) / `session_list_response` (server -> client)
```json
{ "type": "session_list", "id": "req-003" }

{
  "type": "session_list_response",
  "id": "req-003",
  "payload": {
    "sessions": [
      {
        "session_id": "sess-abc123",
        "agent": "claude-code",
        "title": "Fix auth bug",
        "created_at": "2026-03-16T10:00:00Z",
        "last_message_at": "2026-03-16T10:32:00Z",
        "status": "active"
      }
    ]
  }
}
```

---

### Chat Messages

#### `message` (client -> server)
Send a user message to the agent.

```json
{
  "type": "message",
  "id": "msg-001",
  "payload": {
    "session_id": "sess-abc123",
    "text": "Fix the OAuth redirect bug in lib/auth/login.dart",
    "attachments": []
  }
}
```

#### `stream_start` (server -> client)
Agent begins generating a response.

```json
{
  "type": "stream_start",
  "id": "msg-001",
  "payload": {
    "session_id": "sess-abc123",
    "message_id": "resp-001"
  }
}
```

#### `stream_chunk` (server -> client)
A chunk of the agent's streamed response.

```json
{
  "type": "stream_chunk",
  "payload": {
    "message_id": "resp-001",
    "text": "I'll fix the OAuth redirect",
    "chunk_index": 0
  }
}
```

#### `stream_end` (server -> client)
Agent finished generating the response.

```json
{
  "type": "stream_end",
  "payload": {
    "message_id": "resp-001",
    "final_text": "I'll fix the OAuth redirect in login.dart...",
    "token_count": 245
  }
}
```

---

### Tool Calls & Approvals

#### `tool_call` (server -> client)
Agent requests permission to execute a tool.

```json
{
  "type": "tool_call",
  "id": "tool-001",
  "payload": {
    "session_id": "sess-abc123",
    "tool": "edit_file",
    "description": "Edit lib/auth/login.dart lines 42-45",
    "params": {
      "file": "lib/auth/login.dart",
      "start_line": 42,
      "end_line": 45,
      "old_content": "callbackUrl: 'http://localhost'",
      "new_content": "callbackUrl: 'https://localhost'"
    },
    "reasoning": "The callback URL must use HTTPS for OAuth security.",
    "risk_level": "low"
  }
}
```

`risk_level`: `"low"` | `"medium"` | `"high"` | `"critical"`

#### `tool_response` (client -> server)
User's decision on the tool call.

```json
{
  "type": "tool_response",
  "id": "tool-001",
  "payload": {
    "session_id": "sess-abc123",
    "decision": "approved",
    "modifications": null
  }
}
```

`decision`: `"approved"` | `"rejected"` | `"modified"`

When `decision` is `"modified"`:
```json
{
  "decision": "modified",
  "modifications": "Also update the staging environment URL in config/staging.yaml"
}
```

#### `tool_result` (server -> client)
Outcome of an executed tool.

```json
{
  "type": "tool_result",
  "id": "tool-001",
  "payload": {
    "session_id": "sess-abc123",
    "tool": "edit_file",
    "success": true,
    "output": "File edited successfully: lib/auth/login.dart",
    "diff": "@@ -42,1 +42,1 @@\n-callbackUrl: 'http://...'\n+callbackUrl: 'https://...'"
  }
}
```

---

### Git Operations

#### `git_command` (client -> server)
Execute a git operation through the bridge.

```json
{
  "type": "git_command",
  "id": "git-001",
  "payload": {
    "session_id": "sess-abc123",
    "command": "commit",
    "params": {
      "message": "Fix OAuth redirect bug",
      "files": ["lib/auth/login.dart", "lib/auth/oauth.dart"]
    }
  }
}
```

Supported commands: `status`, `commit`, `push`, `pull`, `fetch`, `branch_list`, `branch_create`, `branch_switch`, `log`, `diff`.

#### `git_result` (server -> client)
```json
{
  "type": "git_result",
  "id": "git-001",
  "payload": {
    "command": "commit",
    "success": true,
    "output": "Created commit abc1234: Fix OAuth redirect bug",
    "data": {
      "commit_hash": "abc1234",
      "branch": "main",
      "files_changed": 2
    }
  }
}
```

#### `git_progress` (server -> client)
Progress updates for long-running git operations (push, pull, clone).

```json
{
  "type": "git_progress",
  "id": "git-002",
  "payload": {
    "command": "push",
    "phase": "compressing",
    "progress": 63,
    "message": "Compressing objects: 63% (3/5)"
  }
}
```

---

### Terminal

#### `terminal_input` (client -> server)
```json
{
  "type": "terminal_input",
  "id": "term-001",
  "payload": {
    "session_id": "term-sess-001",
    "input": "flutter test\n"
  }
}
```

#### `terminal_output` (server -> client)
```json
{
  "type": "terminal_output",
  "payload": {
    "session_id": "term-sess-001",
    "output": "00:05 +12: All tests passed!\n",
    "is_stderr": false
  }
}
```

#### `terminal_signal` (client -> server)
Send signals (e.g., Ctrl+C).

```json
{
  "type": "terminal_signal",
  "payload": {
    "session_id": "term-sess-001",
    "signal": "SIGINT"
  }
}
```

---

## Error Codes

| Code | Description |
|------|-------------|
| `AUTH_FAILED` | Invalid or expired auth token |
| `SESSION_NOT_FOUND` | Referenced session does not exist |
| `AGENT_UNAVAILABLE` | Requested agent type not installed or not responding |
| `AGENT_ERROR` | Agent returned an error |
| `GIT_ERROR` | Git operation failed |
| `PERMISSION_DENIED` | Operation blocked by bridge authorization policy |
| `RATE_LIMITED` | Too many requests |
| `INTERNAL_ERROR` | Unexpected bridge server error |

Error response format:
```json
{
  "type": "error",
  "id": "original-request-id",
  "payload": {
    "code": "SESSION_NOT_FOUND",
    "message": "Session sess-xyz does not exist or has expired"
  }
}
```

---

## Protocol Versioning

- Protocol version is exchanged during `connection_ack`.
- Clients and servers should be forward-compatible: ignore unknown fields.
- Breaking changes increment the major version. The bridge rejects connections from incompatible clients with `connection_error` code `VERSION_MISMATCH`.
