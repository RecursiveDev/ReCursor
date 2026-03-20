---
title: "Error Handling & Recovery Specification"
description: "Error taxonomy, session recovery patterns, and reconnection strategies for the ReCursor bridge protocol. Grounded in benchmark research from remote-claude, BAREclaw, and code-server patterns."
editUrl: "https://github.com/RecursiveDev/ReCursor/edit/main/docs/error-handling.md"
sidebar:
  order: 20
  label: "Error handling"
---
> Error taxonomy, session recovery patterns, and reconnection strategies for the ReCursor bridge protocol. Grounded in benchmark research from remote-claude, BAREclaw, and code-server patterns.

---

## Overview

ReCursor implements a **layered error handling strategy**:

1. **Transport Layer** — WebSocket connection drops, TLS failures
2. **Protocol Layer** — Message validation, sequence errors
3. **Application Layer** — Session failures, tool execution errors
4. **Recovery Layer** — Reconnection, replay, state reconciliation

This document defines error taxonomies, recovery patterns, and implementation guidance for each layer.

---

## Error Taxonomy

### Error Categories

| Category | Prefix | Description | Example |
|----------|--------|-------------|-----------|
| Connection | `CONN_` | Transport-level failures | `CONN_WEBSOCKET_CLOSED` |
| Authentication | `AUTH_` | Token/identity failures | `AUTH_TOKEN_EXPIRED` |
| Protocol | `PROTO_` | Message format violations | `PROTO_INVALID_MESSAGE` |
| Session | `SESS_` | Session lifecycle errors | `SESS_NOT_FOUND` |
| Tool | `TOOL_` | Tool execution failures | `TOOL_EXECUTION_FAILED` |
| Hook | `HOOK_` | Hook event errors | `HOOK_VALIDATION_FAILED` |
| System | `SYS_` | Internal server errors | `SYS_INTERNAL_ERROR` |

### Error Severity Levels

| Level | Behavior | User Impact |
|-------|----------|-------------|
| `info` | Log only | None |
| `warning` | Log + metrics | Minimal (degraded performance) |
| `error` | Log + notify + retry | Moderate (temporary disruption) |
| `critical` | Log + alert + circuit break | High (service unavailable) |
| `fatal` | Log + terminate | Complete session loss |

---

## Connection Errors

### CONN_WEBSOCKET_CLOSED

**Trigger**: WebSocket connection unexpectedly closed.

**Client Behavior:**
```dart
// Dart client implementation
class BridgeConnection {
  static const RECONNECT_DELAYS = [1000, 2000, 5000, 10000, 30000];
  
  Future<void> handleDisconnect(DisconnectReason reason) async {
    if (reason.isRecoverable) {
      await attemptReconnect();
    } else {
      await transitionToErrorState(reason);
    }
  }
  
  Future<void> attemptReconnect() async {
    for (final delay in RECONNECT_DELAYS) {
      await Future.delayed(Duration(milliseconds: delay));
      try {
        await connect();
        await requestReplayBuffer(); // Request missed messages
        return;
      } catch (e) {
        continue;
      }
    }
    throw ReconnectionExhaustedError();
  }
}
```

**Server Behavior:**
```typescript
// Bridge server - keep session alive during reconnect window
const SESSION_GRACE_MS = 5 * 60 * 1000; // 5 minutes

interface SessionState {
  id: string;
  websocket: WebSocket | null;
  replayBuffer: string[];
  graceTimer: NodeJS.Timeout | null;
}

function handleDisconnect(sessionId: string) {
  const session = sessions.get(sessionId);
  if (!session) return;
  
  session.websocket = null;
  session.graceTimer = setTimeout(() => {
    closeSession(sessionId); // Grace period expired
  }, SESSION_GRACE_MS);
}

function handleReconnect(sessionId: string, ws: WebSocket) {
  const session = sessions.get(sessionId);
  if (!session) {
    throw new Error('SESS_NOT_FOUND');
  }
  
  clearTimeout(session.graceTimer);
  session.websocket = ws;
  
  // Send replay buffer
  if (session.replayBuffer.length > 0) {
    ws.send(JSON.stringify({
      type: 'replay_buffer',
      payload: { messages: session.replayBuffer }
    }));
  }
}
```

---

### CONN_TLS_HANDSHAKE_FAILED

**Trigger**: TLS certificate validation failed.

**Resolution Steps:**
1. Check certificate expiry
2. Verify certificate chain
3. Check hostname mismatch
4. For self-signed certs: confirm pinning hash

**Client Response:**
```json
{
  "type": "connection_error",
  "payload": {
    "code": "CONN_TLS_HANDSHAKE_FAILED",
    "message": "TLS certificate validation failed",
    "details": {
      "reason": "CERTIFICATE_EXPIRED",
      "expiry": "2026-03-01T00:00:00Z",
      "suggested_action": "regenerate_certificates"
    },
    "recoverable": false
  }
}
```

---

### CONN_TIMEOUT

**Trigger**: Connection attempt exceeded timeout.

**Retry Strategy:**
| Attempt | Delay | Action |
|---------|-------|--------|
| 1 | 1s | Immediate retry |
| 2 | 2s | Retry with cached IP |
| 3 | 5s | Retry with DNS refresh |
| 4+ | 10s | Retry with exponential backoff |

---

## Protocol Errors

### PROTO_INVALID_MESSAGE

**Trigger**: Message failed schema validation.

**Validation Rules:**
```typescript
interface ProtocolMessage {
  type: string;           // Required, non-empty
  id: string;             // Required, UUID format
  timestamp: string;      // Required, ISO 8601
  payload: unknown;       // Required, object
}

const validationRules = {
  type: [required(), matches(/^[a-z_]+$/)],
  id: [required(), uuid()],
  timestamp: [required(), iso8601()],
  payload: [required(), object()]
};
```

**Error Response:**
```json
{
  "type": "error",
  "id": "msg-123",
  "payload": {
    "code": "PROTO_INVALID_MESSAGE",
    "message": "Message validation failed",
    "violations": [
      {
        "field": "timestamp",
        "constraint": "iso8601",
        "received": "2026-03-20 14:32:00"
      }
    ]
  }
}
```

---

### PROTO_SEQUENCE_ERROR

**Trigger**: Message received out of expected sequence.

**Scenarios:**
- `auth` message not first
- `health_check` before `connection_ack`
- `session_message` before `session_join`

**Recovery:**
```typescript
function validateSequence(message: ProtocolMessage, state: ConnectionState): void {
  const expected = SEQUENCE_MAP[state.currentPhase];
  if (!expected.includes(message.type)) {
    throw new ProtocolError('PROTO_SEQUENCE_ERROR', {
      expected,
      received: message.type,
      currentPhase: state.currentPhase
    });
  }
}
```

---

## Session Errors

### SESS_NOT_FOUND

**Trigger**: Referenced session does not exist.

**HTTP Response:**
```json
{
  "error": "NotFound",
  "code": "SESS_NOT_FOUND",
  "message": "Session 'sess-abc123' not found",
  "suggestions": [
    "Check session ID spelling",
    "Session may have expired",
    "Use GET /sessions to list active sessions"
  ]
}
```

---

### SESS_CLOSED

**Trigger**: Operation attempted on closed session.

**Session States:**
```
CREATED → ACTIVE → PAUSED → CLOSED
   ↓         ↓        ↓
 ERROR    ERROR   RESUMABLE
```

**Resumable Sessions:**
Some sessions can be resumed after PAUSED state:
```typescript
interface Session {
  id: string;
  state: 'created' | 'active' | 'paused' | 'closed';
  resumable: boolean;
  checkpoint: SessionCheckpoint | null;
}

async function resumeSession(sessionId: string): Promise<Session> {
  const session = await loadSession(sessionId);
  if (session.state !== 'paused' || !session.resumable) {
    throw new Error('SESS_NOT_RESUMABLE');
  }
  
  // Restore from checkpoint
  await restoreCheckpoint(session.checkpoint);
  session.state = 'active';
  return session;
}
```

---

## Tool Execution Errors

### TOOL_EXECUTION_FAILED

**Trigger**: Tool execution returned non-zero exit code or exception.

**Error Structure:**
```json
{
  "type": "tool_error",
  "payload": {
    "tool_call_id": "tool-abc123",
    "tool": "bash",
    "code": "TOOL_EXECUTION_FAILED",
    "message": "Command exited with code 1",
    "details": {
      "exit_code": 1,
      "stderr": "error: file not found",
      "stdout": "",
      "execution_time_ms": 150
    },
    "retryable": true,
    "max_retries": 3
  }
}
```

**Retryable vs Non-Retryable:**
| Error | Retryable | Strategy |
|-------|-----------|----------|
| Network timeout | Yes | Exponential backoff |
| File not found | No | Fail immediately |
| Permission denied | No | Fail immediately |
| Rate limited | Yes | Backoff with jitter |
| Out of memory | Maybe | Retry once, then fail |

---

### TOOL_TIMEOUT

**Trigger**: Tool execution exceeded maximum duration.

**Configuration:**
```typescript
const TOOL_TIMEOUTS = {
  bash: 300000,      // 5 minutes
  read_file: 10000,  // 10 seconds
  edit_file: 30000,  // 30 seconds
  search: 60000      // 1 minute
};
```

---

## Hook Event Errors

### HOOK_VALIDATION_FAILED

**Trigger**: Hook event failed schema validation.

**Validation Schema:**
```typescript
const HookEventSchema = z.object({
  event: z.enum(['SessionStart', 'SessionEnd', 'PreToolUse', 'PostToolUse', 
                 'UserPromptSubmit', 'Stop', 'SubagentStop']),
  timestamp: z.string().datetime(),
  session_id: z.string().min(1),
  payload: z.record(z.unknown())
});
```

**Response:**
```json
{
  "received": false,
  "code": "HOOK_VALIDATION_FAILED",
  "errors": [
    {
      "field": "event",
      "message": "Invalid enum value. Expected one of: SessionStart, SessionEnd..."
    }
  ]
}
```

---

## Recovery Patterns

### Replay Buffer Pattern

Based on remote-claude's implementation:

```typescript
interface ReplayBuffer {
  maxSize: number;        // 100KB default
  maxAge: number;         // 30 minutes
  buffer: string[];
  
  append(message: string): void {
    this.buffer.push(message);
    const size = JSON.stringify(this.buffer).length;
    
    // Trim by size
    while (size > this.maxSize && this.buffer.length > 0) {
      this.buffer.shift();
    }
  }
  
  getReplay(since?: Date): string[] {
    if (!since) return [...this.buffer];
    return this.buffer.filter(msg => msg.timestamp > since);
  }
}
```

---

### Circuit Breaker Pattern

For external service calls (Agent SDK, file system):

```typescript
class CircuitBreaker {
  private failures = 0;
  private lastFailureTime: number | null = null;
  private state: 'closed' | 'open' | 'half-open' = 'closed';
  
  constructor(
    private threshold = 5,
    private timeoutMs = 60000
  ) {}
  
  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === 'open') {
      if (Date.now() - (this.lastFailureTime || 0) > this.timeoutMs) {
        this.state = 'half-open';
      } else {
        throw new Error('CIRCUIT_OPEN');
      }
    }
    
    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (e) {
      this.onFailure();
      throw e;
    }
  }
  
  private onSuccess() {
    this.failures = 0;
    this.state = 'closed';
  }
  
  private onFailure() {
    this.failures++;
    this.lastFailureTime = Date.now();
    if (this.failures >= this.threshold) {
      this.state = 'open';
    }
  }
}
```

---

### Session Persistence Pattern

Based on BAREclaw's session recovery:

```typescript
interface PersistedSession {
  id: string;
  agentType: string;
  workingDirectory: string;
  createdAt: string;
  lastActivityAt: string;
  checkpoint: {
    messageCount: number;
    lastMessageId: string;
    contextSnapshot: unknown;
  };
}

async function saveSessions(sessions: PersistedSession[]): Promise<void> {
  const data = JSON.stringify(sessions, null, 2);
  await fs.writeFile(SESSIONS_FILE, data);
}

async function loadSessions(): Promise<PersistedSession[]> {
  try {
    const data = await fs.readFile(SESSIONS_FILE, 'utf-8');
    return JSON.parse(data);
  } catch {
    return [];
  }
}
```

---

## Client-Side Recovery

### Dart Implementation

```dart
class BridgeConnectionRecovery {
  static const MAX_RETRIES = 5;
  static const BASE_DELAY = Duration(seconds: 1);
  
  final List<BridgeMessage> _pendingMessages = [];
  DateTime? _lastReceivedMessageTime;
  
  Future<void> reconnect() async {
    for (var attempt = 0; attempt < MAX_RETRIES; attempt++) {
      try {
        await _connect();
        await _synchronizeState();
        _flushPendingMessages();
        return;
      } catch (e) {
        final delay = BASE_DELAY * (attempt + 1);
        await Future.delayed(delay);
      }
    }
    throw BridgeConnectionException('Max retries exceeded');
  }
  
  Future<void> _synchronizeState() async {
    // Request replay since last known message
    if (_lastReceivedMessageTime != null) {
      await sendMessage(BridgeMessage.requestReplay(
        since: _lastReceivedMessageTime!
      ));
    }
  }
  
  void _flushPendingMessages() {
    while (_pendingMessages.isNotEmpty) {
      final msg = _pendingMessages.removeAt(0);
      sendMessage(msg);
    }
  }
  
  void onDisconnect() {
    // Queue outgoing messages during disconnect
    _messageController.stream.listen((msg) {
      if (!isConnected) {
        _pendingMessages.add(msg);
      }
    });
  }
}
```

---

## Error Metrics & Monitoring

### Metric Labels

```typescript
interface ErrorMetric {
  category: string;       // Error category prefix
  code: string;           // Full error code
  severity: string;       // info/warning/error/critical/fatal
  source: string;         // client/server/hook
  session_id?: string;    // Associated session
  user_agent?: string;    // Client version
}
```

### Alert Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| Error rate | > 5% | > 15% |
| Reconnection failures | > 10/min | > 50/min |
| Session drops | > 5/min | > 20/min |
| Hook validation failures | > 20/min | > 100/min |

---

*Last updated: 2026-03-20*
