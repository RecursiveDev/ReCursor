import type { HookEvent } from "../types";

export const VALID_EVENT_TYPES: string[] = [
  "PreToolUse",
  "PostToolUse",
  "Notification",
  "Stop",
  "SubagentStop",
  "PreCompact",
];

export function validateHookEvent(event: unknown): event is HookEvent {
  if (typeof event !== "object" || event === null) {
    return false;
  }
  const e = event as Record<string, unknown>;

  if (typeof e["event_type"] !== "string" || e["event_type"].length === 0) {
    return false;
  }
  if (typeof e["session_id"] !== "string" || e["session_id"].length === 0) {
    return false;
  }
  if (typeof e["timestamp"] !== "string" || e["timestamp"].length === 0) {
    return false;
  }
  if (typeof e["payload"] !== "object" || e["payload"] === null) {
    return false;
  }
  return true;
}
