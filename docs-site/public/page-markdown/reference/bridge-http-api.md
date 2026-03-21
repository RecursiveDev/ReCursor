# Bridge HTTP API Specification

> REST endpoint specification for the ReCursor bridge server. Complements the WebSocket protocol with HTTP endpoints for hook ingestion, health checks, and control operations.

---

## Overview

The ReCursor bridge server implements a **dual transport pattern**:

| Transport | Purpose | Protocol |
|-----------|---------|----------|
| WebSocket | Real-time bidirectional streaming | `wss://` |
| HTTP | Hook ingestion, health checks, control | `https://` |

This design aligns with patterns from benchmark repositories (cc-remote-control-server, BAREclaw) where WebSocket handles interactive sessions while HTTP provides stateless endpoints for external integrations.

---

## Base URL

```
https://<bridge-host>:<port>/api/v1
```

**Connection Modes:**
- **Local development**: `https://127.0.0.1:3000/api/v1`
- **Tailscale/WireGuard**: `https://100.x.x.x:3000/api/v1`
- **Custom domain**: `https://bridge.example.com:3000/api/v1`

---

## Authentication

All HTTP endpoints require authentication via Bearer token in the `Authorization` header.

```http
Authorization: Bearer <token>
```

| Token Type | Endpoint Category | Source |
|------------|-------------------|--------|
| Device Token | `/health`, `/ws` pairing | Generated at QR pairing |
| Hook Token | `/hooks/*` | Bridge server env var |
| Admin Token | `/admin/*` | Bridge server env var |

### Token Validation Response

```json
{
  "error": "Unauthorized",
  "message": "Invalid or expired token",
  "code": "AUTH_INVALID_TOKEN"
}
```

---

## Endpoints

### Health & Discovery

#### GET /health

Returns bridge health status and connection metadata.

**Request:**
```bash
curl -H "Authorization: Bearer $DEVICE_TOKEN" \
  https://100.78.42.15:3000/api/v1/health
```

**Response 200:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "uptime_seconds": 86400,
  "connection_mode": "secure_remote",
  "active_sessions": 3,
  "active_websockets": 2,
  "system": {
    "platform": "darwin",
    "node_version": "20.11.0",
    "memory_mb": 512
  },
  "timestamp": "2026-03-20T14:32:00.000Z"
}
```

**Response 503 (Degraded):**
```json
{
  "status": "degraded",
  "version": "1.0.0",
  "checks": {
    "websocket_server": "healthy",
    "hook_endpoint": "healthy",
    "agent_sdk": "unhealthy",
    "disk_space": "healthy"
  },
  "timestamp": "2026-03-20T14:32:00.000Z"
}
```

---

#### GET /info

Returns bridge capabilities and supported features.

**Response 200:**
```json
{
  "name": "recursor-bridge",
  "version": "1.0.0",
  "protocol_version": "1.0",
  "features": [
    "websocket_sessions",
    "hook_events",
    "agent_sdk",
    "pty_sessions",
    "file_sync"
  ],
  "supported_agents": ["claude-code", "opencode", "aider", "goose"],
  "supported_hooks": [
    "SessionStart",
    "SessionEnd",
    "PreToolUse",
    "PostToolUse",
    "UserPromptSubmit",
    "Stop",
    "SubagentStop"
  ],
  "limits": {
    "max_sessions": 10,
    "max_websocket_connections": 5,
    "max_message_size_mb": 10,
    "hook_timeout_seconds": 30
  }
}
```

---

### Hook Event Ingestion

#### POST /hooks/event

Receives events from Claude Code Hooks. This is the primary ingress point for hook events.

**Request Headers:**
```http
Content-Type: application/json
Authorization: Bearer <hook_token>
X-Hook-Source: claude-code
X-Hook-Version: 1.0
```

**Request Body:**
```json
{
  "event": "PreToolUse",
  "timestamp": "2026-03-20T14:32:00.000Z",
  "session_id": "sess-abc123",
  "payload": {
    "tool": "edit_file",
    "params": {
      "path": "src/main.ts",
      "content": "..."
    },
    "risk_level": "medium"
  }
}
```

**Response 200:**
```json
{
  "received": true,
  "event_id": "evt-uuid-123",
  "broadcast_count": 2,
  "timestamp": "2026-03-20T14:32:00.050Z"
}
```

**Response 400 (Validation Error):**
```json
{
  "error": "ValidationError",
  "message": "Invalid event format: missing required field 'event'",
  "code": "HOOK_INVALID_PAYLOAD",
  "details": {
    "field": "event",
    "constraint": "required"
  }
}
```

**Response 401:**
```json
{
  "error": "Unauthorized",
  "message": "Invalid hook token",
  "code": "HOOK_AUTH_FAILED"
}
```

---

#### POST /hooks/batch

Batch event ingestion for high-frequency scenarios.

**Request Body:**
```json
{
  "events": [
    {
      "event": "PreToolUse",
      "timestamp": "2026-03-20T14:32:00.000Z",
      "session_id": "sess-abc123",
      "payload": { ... }
    },
    {
      "event": "PostToolUse",
      "timestamp": "2026-03-20T14:32:01.000Z",
      "session_id": "sess-abc123",
      "payload": { ... }
    }
  ]
}
```

**Response 200:**
```json
{
  "received": true,
  "count": 2,
  "accepted": 2,
  "rejected": 0,
  "event_ids": ["evt-1", "evt-2"]
}
```

---

### Session Management

#### GET /sessions

List active sessions.

**Response 200:**
```json
{
  "sessions": [
    {
      "id": "sess-abc123",
      "agent_type": "claude-code",
      "title": "Bridge startup validation",
      "working_directory": "/home/user/recursor",
      "status": "active",
      "created_at": "2026-03-20T14:00:00.000Z",
      "last_activity_at": "2026-03-20T14:32:00.000Z",
      "websocket_connected": true,
      "hook_count": 15
    }
  ],
  "total": 1
}
```

---

#### GET /sessions/:id

Get detailed session information.

**Response 200:**
```json
{
  "id": "sess-abc123",
  "agent_type": "claude-code",
  "title": "Bridge startup validation",
  "working_directory": "/home/user/recursor",
  "status": "active",
  "created_at": "2026-03-20T14:00:00.000Z",
  "last_activity_at": "2026-03-20T14:32:00.000Z",
  "websocket_connected": true,
  "hook_count": 15,
  "recent_events": [
    {
      "type": "PreToolUse",
      "timestamp": "2026-03-20T14:32:00.000Z",
      "tool": "read_file"
    }
  ]
}
```

**Response 404:**
```json
{
  "error": "NotFound",
  "message": "Session not found: sess-abc123",
  "code": "SESSION_NOT_FOUND"
}
```

---

#### POST /sessions/:id/events

Send an event to a specific session (for Agent SDK integration).

**Request Body:**
```json
{
  "type": "user_message",
  "content": "Please review the changes",
  "metadata": {
    "source": "mobile_app",
    "client_version": "1.0.0"
  }
}
```

**Response 202:**
```json
{
  "accepted": true,
  "event_id": "evt-user-123",
  "session_id": "sess-abc123"
}
```

---

### WebSocket Upgrade

#### GET /ws

WebSocket upgrade endpoint. Returns 400 for non-WebSocket requests.

**Request Headers:**
```http
Upgrade: websocket
Connection: Upgrade
Authorization: Bearer <device_token>
Sec-WebSocket-Key: <key>
Sec-WebSocket-Version: 13
```

**Response 101:** WebSocket upgrade successful.

**Response 400:**
```json
{
  "error": "BadRequest",
  "message": "WebSocket upgrade required",
  "code": "WS_UPGRADE_REQUIRED",
  "websocket_url": "wss://100.78.42.15:3000/api/v1/ws"
}
```

---

### File Operations

#### GET /files/tree

Get file tree for a working directory.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Absolute or relative path |
| `depth` | number | Max depth (default: 3) |

**Response 200:**
```json
{
  "path": "/home/user/recursor",
  "entries": [
    {
      "name": "src",
      "type": "directory",
      "children": [
        {
          "name": "main.ts",
          "type": "file",
          "size": 1024,
          "modified_at": "2026-03-20T14:00:00.000Z"
        }
      ]
    },
    {
      "name": "package.json",
      "type": "file",
      "size": 512,
      "modified_at": "2026-03-20T13:00:00.000Z"
    }
  ]
}
```

---

#### GET /files/content

Get file content.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Absolute file path |

**Response 200:**
```json
{
  "path": "/home/user/recursor/src/main.ts",
  "content": "import { app } from './app';\n...",
  "size": 1024,
  "encoding": "utf-8",
  "modified_at": "2026-03-20T14:00:00.000Z"
}
```

---

### Admin Operations

#### POST /admin/reload-hooks

Reload hook configuration without restart.

**Response 200:**
```json
{
  "reloaded": true,
  "timestamp": "2026-03-20T14:32:00.000Z",
  "active_hooks": ["PreToolUse", "PostToolUse", "SessionStart"]
}
```

---

## Error Response Format

All errors follow a consistent format:

```json
{
  "error": "ErrorName",
  "message": "Human-readable description",
  "code": "UPPER_SNAKE_CASE_CODE",
  "request_id": "req-uuid-123",
  "timestamp": "2026-03-20T14:32:00.000Z",
  "documentation_url": "https://docs.recursor.dev/errors/UPPER_SNAKE_CASE_CODE"
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `AUTH_INVALID_TOKEN` | 401 | Token missing, malformed, or expired |
| `AUTH_INSUFFICIENT_SCOPE` | 403 | Valid token lacks required scope |
| `HOOK_INVALID_PAYLOAD` | 400 | Event validation failed |
| `HOOK_AUTH_FAILED` | 401 | Hook token invalid |
| `SESSION_NOT_FOUND` | 404 | Session ID does not exist |
| `SESSION_CLOSED` | 409 | Session is no longer active |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Unexpected server error |

---

## Rate Limiting

| Endpoint Category | Limit | Window |
|-------------------|-------|--------|
| `/health`, `/info` | 60 | 1 minute |
| `/hooks/event` | 120 | 1 minute |
| `/hooks/batch` | 10 | 1 minute |
| `/sessions/*` | 30 | 1 minute |
| `/files/*` | 60 | 1 minute |

**Rate Limit Response:**
```json
{
  "error": "RateLimitExceeded",
  "message": "Rate limit exceeded: 120 requests per minute",
  "code": "RATE_LIMIT_EXCEEDED",
  "retry_after": 45
}
```

---

## CORS Configuration

The bridge server enables CORS for development scenarios:

```http
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Authorization, Content-Type, X-Request-ID
Access-Control-Max-Age: 86400
```

> **Note**: In production, configure specific origins rather than `*`.

---

## TLS Requirements

All HTTP endpoints require TLS. See [security-architecture.md](../operations/security-architecture/) for:
- Self-signed certificate generation
- Certificate pinning
- Mobile platform TLS caveats

---

*Last updated: 2026-03-20*
