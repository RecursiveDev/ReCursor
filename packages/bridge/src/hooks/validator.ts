import type { HookEvent } from "../types";

const MAX_EVENT_AGE_MS = 5 * 60 * 1000;
const MAX_FUTURE_SKEW_MS = 30 * 1000;

export const VALID_EVENT_TYPES: string[] = [
  "SessionStart",
  "SessionEnd",
  "PreToolUse",
  "PostToolUse",
  "UserPromptSubmit",
  "Notification",
  "Stop",
  "SubagentStop",
  "PreCompact",
];

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function isValidTimestamp(value: unknown): value is string {
  if (typeof value !== "string" || value.length === 0) {
    return false;
  }

  const timestamp = Date.parse(value);
  if (Number.isNaN(timestamp)) {
    return false;
  }

  const age = Date.now() - timestamp;
  return age <= MAX_EVENT_AGE_MS && age >= -MAX_FUTURE_SKEW_MS;
}

export function normalizeHookEvent(event: unknown): HookEvent | null {
  if (!isRecord(event)) {
    return null;
  }

  const eventType =
    typeof event.event_type === "string"
      ? event.event_type
      : typeof event.event === "string"
        ? event.event
        : null;

  if (!eventType || !VALID_EVENT_TYPES.includes(eventType)) {
    return null;
  }

  if (typeof event.session_id !== "string" || event.session_id.length === 0) {
    return null;
  }

  if (!isValidTimestamp(event.timestamp)) {
    return null;
  }

  if (!isRecord(event.payload)) {
    return null;
  }

  return {
    event_type: eventType,
    session_id: event.session_id,
    timestamp: event.timestamp,
    payload: event.payload,
  };
}

export function validateHookEvent(event: unknown): event is HookEvent {
  return normalizeHookEvent(event) !== null;
}
