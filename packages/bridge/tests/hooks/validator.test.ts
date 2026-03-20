import { validateHookEvent } from "../../src/hooks/validator";
import type { HookEvent } from "../../src/types";

function createEvent(eventType: string, timestamp = new Date().toISOString()): HookEvent {
  return {
    event_type: eventType,
    session_id: "sess-123",
    timestamp,
    payload: { example: true },
  };
}

describe("validateHookEvent", () => {
  it("accepts documented hook events", () => {
    expect(validateHookEvent(createEvent("SessionStart"))).toBe(true);
    expect(validateHookEvent(createEvent("UserPromptSubmit"))).toBe(true);
    expect(validateHookEvent(createEvent("PostToolUse"))).toBe(true);
  });

  it("rejects unsupported event types", () => {
    expect(validateHookEvent(createEvent("UnknownEvent"))).toBe(false);
  });

  it("rejects stale timestamps", () => {
    const staleTimestamp = new Date(Date.now() - 10 * 60 * 1000).toISOString();
    expect(validateHookEvent(createEvent("SessionEnd", staleTimestamp))).toBe(false);
  });
});
