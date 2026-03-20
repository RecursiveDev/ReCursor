# Claude Code Hooks Integration

> Configure Claude Code Hooks to POST events to the ReCursor bridge server for mobile consumption. This is a supported integration path for one-way event observation — not a Remote Control protocol.

---

## Overview

Claude Code provides a **Hooks system** that allows plugins to observe and react to events. ReCursor uses this system to receive real-time events from Claude Code, enabling the mobile app to display agent activity with OpenCode-style UI components.

> **Important**: Hooks are **one-way observation only**. They cannot inject messages or control the Claude Code session. For bidirectional communication, use the [Agent SDK](/integrations/agent-sdk/) for parallel sessions.

---

## Supported Hook Events

Based on the Claude Code hooks system source truth, the following events are confirmed:

| Event | Trigger | Payload |
|-------|---------|---------|
| `SessionStart` | New Claude Code session begins | Session metadata |
| `SessionEnd` | Session terminates | Session summary |
| `PreToolUse` | Agent about to use a tool | Tool, params, risk level |
| `PostToolUse` | Tool execution completed | Tool, result, metadata |
| `UserPromptSubmit` | User submits a prompt | Prompt text, context |
| `Stop` | Agent stops execution | Stop reason, context |
| `SubagentStop` | Subagent stops execution | Subagent result, context |
| `PreCompact` | Before context compaction | Context stats |
| `Notification` | System notification | Message, level |

> **Note**: Other events may exist but are not confirmed in the current Claude Code hooks implementation.

---

## Hook Configuration

Hooks are configured via a `hooks.json` file in your Claude Code plugin directory. Claude Code supports two hook types:

- **`type: "command"`** — Execute bash commands for deterministic checks
- **`type: "prompt"`** — Use LLM-driven decision making for context-aware validation

### Method 1: Command Hooks (Recommended for ReCursor)

Create a `hooks.json` file in your plugin's `hooks/` directory:

```json
{
  "description": "ReCursor bridge integration - forward events to mobile app",
  "hooks": {
    "PreToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "curl -X POST https://100.78.42.15:3000/hooks/event -H 'Content-Type: application/json' -H 'Authorization: Bearer your-bridge-token' -d @-",
            "timeout": 10
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "curl -X POST https://100.78.42.15:3000/hooks/event -H 'Content-Type: application/json' -H 'Authorization: Bearer your-bridge-token' -d @-",
            "timeout": 10
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "curl -X POST https://100.78.42.15:3000/hooks/event -H 'Content-Type: application/json' -H 'Authorization: Bearer your-bridge-token' -d @-",
            "timeout": 10
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "curl -X POST https://100.78.42.15:3000/hooks/event -H 'Content-Type: application/json' -H 'Authorization: Bearer your-bridge-token' -d @-",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "curl -X POST https://100.78.42.15:3000/hooks/event -H 'Content-Type: application/json' -H 'Authorization: Bearer your-bridge-token' -d @-",
            "timeout": 10
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "curl -X POST https://100.78.42.15:3000/hooks/event -H 'Content-Type: application/json' -H 'Authorization: Bearer your-bridge-token' -d @-",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

### Method 2: Prompt-Based Hooks

For context-aware validation, use prompt-based hooks:

```json
{
  "description": "Validation hooks with LLM evaluation",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Validate file write safety. Check: system paths, credentials, path traversal, sensitive content. Return 'approve' or 'deny'.",
            "timeout": 30
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Evaluate if the task is truly complete. Check: all requirements met, tests passing, documentation updated. Return 'complete' or 'continue'.",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### Plugin Directory Structure

```
~/.claude-code/plugins/
└── recursor-bridge/
    ├── hooks.json          # Hook definitions
    └── README.md           # Plugin documentation
```

---

## Bridge Server Endpoint

The ReCursor bridge exposes a `/hooks/event` endpoint to receive Claude Code events:

```typescript

const app = express();
const eventBus = new EventEmitter();

// Middleware
app.use(express.json());

// Hook event endpoint
app.post('/hooks/event', validateHookToken, (req, res) => {
  const hookEvent = req.body;

  if (!validateHookEvent(hookEvent)) {
    return res.status(400).json({ error: 'Invalid hook event' });
  }

  // Emit for internal handling
  eventBus.emit('claude-event', hookEvent);

  // Queue for offline mobile clients
  eventQueue.enqueue(hookEvent);

  res.status(200).json({ received: true });
});

// Token validation middleware
function validateHookToken(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers['authorization'];
  const token = authHeader?.replace('Bearer ', '');

  if (token !== process.env.HOOK_TOKEN) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  next();
}

// Event validation
function validateHookEvent(event: unknown): event is HookEvent {
  return (
    typeof event === 'object' &&
    event !== null &&
    'event_type' in event &&
    typeof (event as HookEvent).event_type === 'string'
  );
}

// Broadcast to connected mobile clients
function broadcastToMobile(event: HookEvent) {
  mobileClients.forEach(client => {
    if (client.sessionId === event.session_id) {
      client.ws.send(JSON.stringify({
        type: 'claude_event',
        payload: event
      }));
    }
  });
}

eventBus.on('claude-event', broadcastToMobile);
```

---

## Formal Event Schema & Validation Contract

This section defines the formal JSON Schema for Claude Code Hook events and the validation contract used by the ReCursor bridge server.

> **Source of Truth**: TypeScript types are authoritative. Dart models are derived.

### Base Event Structure

All hook events share this base structure:

```typescript
// TypeScript source of truth
interface HookEvent {
  event: HookEventType;           // Required: Event discriminator
  timestamp: string;              // Required: ISO 8601 UTC
  session_id: string;             // Required: Session identifier
  payload: HookEventPayload;      // Required: Event-specific data
}

type HookEventType = 
  | 'SessionStart'
  | 'SessionEnd'
  | 'PreToolUse'
  | 'PostToolUse'
  | 'UserPromptSubmit'
  | 'Stop'
  | 'SubagentStop'
  | 'PreCompact'
  | 'Notification';

type HookEventPayload = 
  | SessionStartPayload
  | SessionEndPayload
  | PreToolUsePayload
  | PostToolUsePayload
  | UserPromptSubmitPayload
  | StopPayload
  | SubagentStopPayload
  | PreCompactPayload
  | NotificationPayload;
```

### JSON Schema Definition

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://recursor.dev/schemas/hook-event.json",
  "title": "Claude Code Hook Event",
  "type": "object",
  "required": ["event", "timestamp", "session_id", "payload"],
  "properties": {
    "event": {
      "type": "string",
      "enum": [
        "SessionStart", "SessionEnd", "PreToolUse", "PostToolUse",
        "UserPromptSubmit", "Stop", "SubagentStop", "PreCompact", "Notification"
      ]
    },
    "timestamp": {
      "type": "string",
      "format": "date-time"
    },
    "session_id": {
      "type": "string",
      "minLength": 1
    },
    "payload": {
      "type": "object"
    }
  },
  "allOf": [
    {
      "if": { "properties": { "event": { "const": "SessionStart" } } },
      "then": { "properties": { "payload": { "$ref": "#/definitions/SessionStartPayload" } } }
    },
    {
      "if": { "properties": { "event": { "const": "PreToolUse" } } },
      "then": { "properties": { "payload": { "$ref": "#/definitions/PreToolUsePayload" } } }
    },
    {
      "if": { "properties": { "event": { "const": "PostToolUse" } } },
      "then": { "properties": { "payload": { "$ref": "#/definitions/PostToolUsePayload" } } }
    },
    {
      "if": { "properties": { "event": { "const": "UserPromptSubmit" } } },
      "then": { "properties": { "payload": { "$ref": "#/definitions/UserPromptSubmitPayload" } } }
    },
    {
      "if": { "properties": { "event": { "const": "Stop" } } },
      "then": { "properties": { "payload": { "$ref": "#/definitions/StopPayload" } } }
    }
  ],
  "definitions": {
    "SessionStartPayload": {
      "type": "object",
      "required": ["working_directory"],
      "properties": {
        "working_directory": { "type": "string" },
        "initial_prompt": { "type": "string" },
        "environment": { "type": "object" }
      }
    },
    "PreToolUsePayload": {
      "type": "object",
      "required": ["tool", "params", "risk_level", "requires_approval"],
      "properties": {
        "tool": { "type": "string" },
        "params": { "type": "object" },
        "risk_level": {
          "type": "string",
          "enum": ["low", "medium", "high", "critical"]
        },
        "requires_approval": { "type": "boolean" }
      }
    },
    "PostToolUsePayload": {
      "type": "object",
      "required": ["tool", "params", "result", "success"],
      "properties": {
        "tool": { "type": "string" },
        "params": { "type": "object" },
        "result": {},
        "success": { "type": "boolean" },
        "execution_time_ms": { "type": "number" }
      }
    },
    "UserPromptSubmitPayload": {
      "type": "object",
      "required": ["prompt"],
      "properties": {
        "prompt": { "type": "string" },
        "context_files": {
          "type": "array",
          "items": { "type": "string" }
        },
        "estimated_tokens": { "type": "integer" }
      }
    },
    "StopPayload": {
      "type": "object",
      "required": ["reason"],
      "properties": {
        "reason": {
          "type": "string",
          "enum": ["task_completed", "user_request", "error", "max_tokens", "safety"]
        },
        "message": { "type": "string" },
        "context": { "type": "object" }
      }
    }
  }
}
```

### Validation Contract

The bridge server validates all incoming hook events according to these rules:

| Field | Requirement | Validation Rule | Error Code |
|-------|-------------|-------------------|------------|
| `event` | Required | Must be in confirmed events list | `HOOK_INVALID_EVENT_TYPE` |
| `timestamp` | Required | ISO 8601 format, within 5 min skew | `HOOK_INVALID_TIMESTAMP` |
| `session_id` | Required | Non-empty string, valid format | `HOOK_INVALID_SESSION_ID` |
| `payload` | Required | Object matching event schema | `HOOK_INVALID_PAYLOAD` |

### Timestamp Validation

Timestamps are validated for freshness and format:

```typescript
const MAX_TIMESTAMP_SKEW_MS = 5 * 60 * 1000; // 5 minutes

function validateTimestamp(timestamp: string): ValidationResult {
  // Parse ISO 8601
  const parsed = Date.parse(timestamp);
  if (isNaN(parsed)) {
    return { valid: false, code: 'HOOK_INVALID_TIMESTAMP', reason: 'Not ISO 8601' };
  }
  
  const eventTime = new Date(parsed);
  const now = new Date();
  const diff = Math.abs(now.getTime() - eventTime.getTime());
  
  // Reject future/past events outside skew window
  if (diff > MAX_TIMESTAMP_SKEW_MS) {
    return { 
      valid: false, 
      code: 'HOOK_STALE_TIMESTAMP', 
      reason: `Event timestamp ${diff}ms from current time` 
    };
  }
  
  return { valid: true };
}
```

### TypeScript Validation (Zod)

```typescript

// Risk level enum
const RiskLevelSchema = z.enum(['low', 'medium', 'high', 'critical']);

// Base event schema
const HookEventSchema = z.object({
  event: z.enum([
    'SessionStart', 'SessionEnd', 'PreToolUse', 'PostToolUse',
    'UserPromptSubmit', 'Stop', 'SubagentStop', 'PreCompact', 'Notification'
  ]),
  timestamp: z.string().datetime(),
  session_id: z.string().min(1),
  payload: z.record(z.unknown()),
});

// Payload schemas by event type
const SessionStartPayloadSchema = z.object({
  working_directory: z.string(),
  initial_prompt: z.string().optional(),
  environment: z.record(z.unknown()).optional(),
});

const PreToolUsePayloadSchema = z.object({
  tool: z.string(),
  params: z.record(z.unknown()),
  risk_level: RiskLevelSchema,
  requires_approval: z.boolean(),
});

const PostToolUsePayloadSchema = z.object({
  tool: z.string(),
  params: z.record(z.unknown()),
  result: z.unknown(),
  success: z.boolean(),
  execution_time_ms: z.number().optional(),
});

// Event type discriminator
const EventTypeToPayloadSchema = {
  SessionStart: SessionStartPayloadSchema,
  PreToolUse: PreToolUsePayloadSchema,
  PostToolUse: PostToolUsePayloadSchema,
  // ... other event types
} as const;

// Validation function
export function validateHookEvent(data: unknown): { 
  success: true; event: HookEvent 
} | { 
  success: false; errors: ValidationError[] 
} {
  // Validate base structure
  const baseResult = HookEventSchema.safeParse(data);
  if (!baseResult.success) {
    return { 
      success: false, 
      errors: baseResult.error.errors.map(e => ({
        field: e.path.join('.'),
        message: e.message,
        code: 'VALIDATION_ERROR'
      }))
    };
  }
  
  const event = baseResult.data;
  
  // Validate timestamp freshness
  const timestampValidation = validateTimestamp(event.timestamp);
  if (!timestampValidation.valid) {
    return {
      success: false,
      errors: [{ field: 'timestamp', message: timestampValidation.reason, code: timestampValidation.code }]
    };
  }
  
  // Validate payload against event-specific schema
  const payloadSchema = EventTypeToPayloadSchema[event.event as keyof typeof EventTypeToPayloadSchema];
  if (payloadSchema) {
    const payloadResult = payloadSchema.safeParse(event.payload);
    if (!payloadResult.success) {
      return {
        success: false,
        errors: payloadResult.error.errors.map(e => ({
          field: `payload.${e.path.join('.')}`,
          message: e.message,
          code: 'PAYLOAD_VALIDATION_ERROR'
        }))
      };
    }
  }
  
  return { success: true, event: event as HookEvent };
}
```

### Dart Validation

```dart

// Generated code
part 'hook_event.g.dart';

@JsonSerializable()
class HookEvent {
  final String event;
  final DateTime timestamp;
  final String sessionId;
  final Map<String, dynamic> payload;

  HookEvent({
    required this.event,
    required this.timestamp,
    required this.sessionId,
    required this.payload,
  });

  factory HookEvent.fromJson(Map<String, dynamic> json) =>
      _$HookEventFromJson(json);

  Map<String, dynamic> toJson() => _$HookEventToJson(this);
}

// Validation
class HookEventValidator {
  static const List<String> validEventTypes = [
    'SessionStart', 'SessionEnd', 'PreToolUse', 'PostToolUse',
    'UserPromptSubmit', 'Stop', 'SubagentStop', 'PreCompact', 'Notification'
  ];

  static const Duration maxTimestampSkew = Duration(minutes: 5);

  static ValidationResult validate(Map<String, dynamic> json) {
    final errors = <ValidationError>[];

    // Validate required fields
    if (!json.containsKey('event')) {
      errors.add(ValidationError(field: 'event', message: 'Required field missing'));
    } else if (!validEventTypes.contains(json['event'])) {
      errors.add(ValidationError(
        field: 'event',
        message: 'Invalid event type: ${json['event']}',
        code: 'HOOK_INVALID_EVENT_TYPE',
      ));
    }

    if (!json.containsKey('timestamp')) {
      errors.add(ValidationError(field: 'timestamp', message: 'Required field missing'));
    } else {
      try {
        final timestamp = DateTime.parse(json['timestamp'] as String);
        final now = DateTime.now();
        final diff = now.difference(timestamp).abs();

        if (diff > maxTimestampSkew) {
          errors.add(ValidationError(
            field: 'timestamp',
            message: 'Timestamp ${diff.inSeconds}s from current time',
            code: 'HOOK_STALE_TIMESTAMP',
          ));
        }
      } catch (e) {
        errors.add(ValidationError(
          field: 'timestamp',
          message: 'Invalid ISO 8601 format',
          code: 'HOOK_INVALID_TIMESTAMP',
        ));
      }
    }

    if (!json.containsKey('session_id')) {
      errors.add(ValidationError(field: 'session_id', message: 'Required field missing'));
    } else if ((json['session_id'] as String).isEmpty) {
      errors.add(ValidationError(
        field: 'session_id',
        message: 'Session ID cannot be empty',
        code: 'HOOK_INVALID_SESSION_ID',
      ));
    }

    if (!json.containsKey('payload')) {
      errors.add(ValidationError(field: 'payload', message: 'Required field missing'));
    } else if (json['payload'] is! Map) {
      errors.add(ValidationError(
        field: 'payload',
        message: 'Payload must be an object',
        code: 'HOOK_INVALID_PAYLOAD',
      ));
    }

    return errors.isEmpty
        ? ValidationResult.valid()
        : ValidationResult.invalid(errors);
  }
}

class ValidationResult {
  final bool isValid;
  final List<ValidationError> errors;

  ValidationResult.valid() : isValid = true, errors = [];
  ValidationResult.invalid(this.errors) : isValid = false;
}

class ValidationError {
  final String field;
  final String message;
  final String? code;

  ValidationError({
    required this.field,
    required this.message,
    this.code,
  });
}
```

### Validation Response Format

When validation fails, the bridge server responds with:

```json
{
  "received": false,
  "validation_errors": [
    {
      "field": "timestamp",
      "message": "Event timestamp 312000ms from current time",
      "code": "HOOK_STALE_TIMESTAMP"
    }
  ],
  "timestamp": "2026-03-20T14:32:00.000Z"
}
```

---

## Event Payload Schemas

### PostToolUse Event

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

### PreToolUse Event

```json
{
  "event_type": "PreToolUse",
  "session_id": "sess-abc123",
  "timestamp": "2026-03-17T10:32:00Z",
  "payload": {
    "tool": "Bash",
    "params": {
      "command": "rm -rf /important",
      "description": "Clean up files"
    },
    "risk_level": "high",
    "requires_approval": true
  }
}
```

### SessionStart Event

```json
{
  "event_type": "SessionStart",
  "session_id": "sess-abc123",
  "timestamp": "2026-03-17T10:30:00Z",
  "payload": {
    "working_directory": "/home/user/project",
    "initial_prompt": "Refactor the authentication module",
    "environment": {
      "shell": "zsh",
      "claude_version": "2.1.0"
    }
  }
}
```

### SessionEnd Event

```json
{
  "event_type": "SessionEnd",
  "session_id": "sess-abc123",
  "timestamp": "2026-03-17T11:45:00Z",
  "payload": {
    "duration_seconds": 4500,
    "tools_used": ["Read", "Edit", "Bash"],
    "summary": "Completed authentication refactoring",
    "exit_code": 0
  }
}
```

### Stop Event

```json
{
  "event_type": "Stop",
  "session_id": "sess-abc123",
  "timestamp": "2026-03-17T11:45:00Z",
  "payload": {
    "reason": "task_completed",
    "message": "Task completed successfully",
    "context": {
      "files_modified": 3,
      "tests_passed": true
    }
  }
}
```

### UserPromptSubmit Event

```json
{
  "event_type": "UserPromptSubmit",
  "session_id": "sess-abc123",
  "timestamp": "2026-03-17T10:35:00Z",
  "payload": {
    "prompt": "Add error handling to the bridge setup reconnect flow",
    "context": {
      "current_file": "lib/features/startup/bridge_setup_screen.dart",
      "cursor_position": 145
    }
  }
}
```

---

## Security Considerations

1. **Token Authentication**: Always use the `Authorization: Bearer <token>` header
2. **HTTPS Only**: Use TLS for all hook communications in production
3. **IP Allowlisting**: Restrict bridge endpoint to known Claude Code IPs if possible
4. **Payload Validation**: Validate all incoming hook events before processing
5. **Rate Limiting**: Implement rate limiting on the `/hooks/event` endpoint

---

## Troubleshooting

### Hooks Not Firing

1. Verify `hooks.json` syntax is valid JSON
2. Check plugin is in correct directory: `~/.claude-code/plugins/`
3. Ensure hook commands have execute permissions
4. Review Claude Code logs for hook execution errors

### Bridge Not Receiving Events

1. Verify bridge URL is accessible from Claude Code host
2. Check firewall rules allow outbound HTTP to bridge
3. Confirm authentication token matches
4. Test with simple `curl` command manually

### Event Validation Failures

1. Ensure events match expected schema
2. Check `event_type` is in the confirmed events list
3. Verify `timestamp` is ISO 8601 format
4. Confirm `session_id` is present and valid

---

## References

- [Claude Code Hook Development Guide](file:///C:/Repository/claude-code/plugins/plugin-dev/skills/hook-development/SKILL.md)
- [Hookify Plugin Example](file:///C:/Repository/claude-code/plugins/hookify/hooks/hooks.json)
- [Agent SDK Integration](/integrations/agent-sdk/) — For bidirectional communication
- [Bridge Protocol](/architecture/bridge-protocol/) — WebSocket message specification

---

*Last updated: 2026-03-20 | Verified against Claude Code source truth*
