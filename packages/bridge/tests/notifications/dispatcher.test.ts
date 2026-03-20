import { EventQueue } from "../../src/hooks/event_queue";
import { Dispatcher } from "../../src/notifications/dispatcher";
import { eventBus } from "../../src/notifications/event_bus";
import type { BridgeMessage, MobileClient } from "../../src/types";

describe("Dispatcher", () => {
  afterEach(() => {
    eventBus.removeAllListeners();
  });

  it("forwards stream lifecycle, approval, and tool result events to session clients", () => {
    const sentMessages: BridgeMessage[] = [];
    const eventQueue = new EventQueue();
    const connectionManager = {
      getClientsForSession: jest.fn((_sessionId: string): MobileClient[] => [
        {
          id: "client-1",
          authenticated: true,
          sessionIds: ["sess-1"],
          ws: {} as never,
        },
      ]),
      sendToClient: jest.fn((_clientId: string, message: BridgeMessage) => {
        sentMessages.push(message);
      }),
      broadcast: jest.fn(),
    };

    new Dispatcher(connectionManager as never, eventQueue);

    eventBus.emitTyped("session-event", {
      type: "stream_start",
      session_id: "sess-1",
      message_id: "msg-1",
    });
    eventBus.emitTyped("stream-chunk", {
      session_id: "sess-1",
      message_id: "msg-1",
      content: "Hello",
    });
    eventBus.emitTyped("tool-event", {
      type: "approval_required",
      session_id: "sess-1",
      tool_call_id: "tool-1",
      tool: "run_command",
      params: { command: "npm test" },
      description: "Run tests",
      risk_level: "medium",
      source: "agent_sdk",
    });
    eventBus.emitTyped("tool-event", {
      type: "tool_result",
      session_id: "sess-1",
      tool_call_id: "tool-1",
      tool: "run_command",
      result: {
        success: true,
        content: "Tests passed",
        duration_ms: 42,
      },
    });
    eventBus.emitTyped("session-event", {
      type: "stream_end",
      session_id: "sess-1",
      message_id: "msg-1",
      finish_reason: "stop",
    });

    expect(sentMessages.map((message) => message.type)).toEqual([
      "stream_start",
      "stream_chunk",
      "approval_required",
      "tool_result",
      "stream_end",
    ]);
    expect(sentMessages[1]).toMatchObject({
      payload: {
        session_id: "sess-1",
        message_id: "msg-1",
        content: "Hello",
        is_tool_use: false,
      },
    });
    expect(sentMessages[2]).toMatchObject({
      payload: {
        tool: "run_command",
        params: { command: "npm test" },
        source: "agent_sdk",
      },
    });
    expect(sentMessages[3]).toMatchObject({
      payload: {
        tool: "run_command",
        result: {
          success: true,
          content: "Tests passed",
          duration_ms: 42,
        },
      },
    });
    expect(eventQueue.size()).toBe(1);
    expect(eventQueue.replay("sess-1")).toEqual([
      expect.objectContaining({
        type: "tool_result",
        payload: expect.objectContaining({
          session_id: "sess-1",
          tool_call_id: "tool-1",
          tool: "run_command",
        }),
      }),
    ]);
  });
});
