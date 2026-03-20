# Claude Code Hooks Integration

> Configure Claude Code Hooks to POST events to the ReCursor bridge server for mobile consumption. This is a supported integration path for one-way event observation — not a Remote Control protocol.

---

## Overview

Claude Code provides a **Hooks system** that allows plugins to observe and react to events. ReCursor uses this system to receive real-time events from Claude Code, enabling the mobile app to display agent activity with OpenCode-style UI components.

> **Important**: Hooks are **one-way observation only**. They cannot inject messages or control the Claude Code session. For bidirectional communication, use the [Agent SDK](agent-sdk.md) for parallel sessions.

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
import express from 'express';
import { EventEmitter } from 'events';

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
- [Agent SDK Integration](./agent-sdk.md) — For bidirectional communication
- [Bridge Protocol](../bridge-protocol.md) — WebSocket message specification

---

*Last updated: 2026-03-17 | Verified against Claude Code source truth*
