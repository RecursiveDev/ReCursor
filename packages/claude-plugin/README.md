# ReCursor Claude Code Plugin

Forwards Claude Code events to the ReCursor bridge server for mobile consumption.

## Installation

Copy this plugin to your Claude Code plugins directory:

```bash
mkdir -p ~/.claude-code/plugins/recursor-bridge
cp hooks.json ~/.claude-code/plugins/recursor-bridge/hooks.json
```

## Configuration

Set environment variables before running Claude Code:

```bash
export RECURSOR_BRIDGE_URL=http://100.78.42.15:3000   # Your bridge server URL (Tailscale IP)
export RECURSOR_HOOK_TOKEN=your-hook-token-here        # Matches HOOK_TOKEN in bridge .env
```

Or add them to your shell profile (`~/.zshrc`, `~/.bashrc`).

## Events Forwarded

- `SessionStart` — New Claude Code session begins
- `SessionEnd` — Session terminates
- `PreToolUse` — Agent about to use a tool
- `PostToolUse` — Tool execution completed
- `UserPromptSubmit` — User submits a prompt
- `Stop` — Agent stops execution
- `SubagentStop` — Subagent stops
- `Notification` — System notification

## Security

- Hook commands use `|| true` so failures do not block Claude Code operation
- The bridge validates the `RECURSOR_HOOK_TOKEN` before processing events
- Use HTTPS (`https://`) for the bridge URL in production (Tailscale provides encryption)
