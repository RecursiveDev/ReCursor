import { EventQueue } from "../../src/hooks/event_queue";
import { Dispatcher } from "../../src/notifications/dispatcher";
import { eventBus } from "../../src/notifications/event_bus";
import { MessageHandler } from "../../src/websocket/message_handler";
import type {
  AgentSession,
  BridgeMessage,
  NotificationPayload,
  SessionStartPayload,
} from "../../src/types";

describe("MessageHandler", () => {
  afterEach(() => {
    eventBus.removeAllListeners();
  });

  function createDependencies() {
    const sentMessages: Array<{ clientId: string; message: BridgeMessage }> = [];
    const connectionManager = {
      sendToClient: jest.fn((clientId: string, message: BridgeMessage) => {
        sentMessages.push({ clientId, message });
      }),
      authenticateClient: jest.fn(),
      getClient: jest.fn(),
      addSessionToClient: jest.fn(),
      getClientsForSession: jest.fn(),
      broadcast: jest.fn(),
    };

    const agentSdkAdapter = {
      handleSessionStart: jest.fn(),
      handleMessage: jest.fn(),
      handleApprovalResponse: jest.fn(),
      handleSessionEnd: jest.fn(),
    };

    const activeSession: AgentSession = {
      id: "sess-1",
      agent: "claude-code",
      title: "project",
      model: "claude-opus-4-6",
      working_directory: "/repo/project",
      created_at: new Date().toISOString(),
      status: "idle",
    };

    const agentSessionManager = {
      getActiveSessions: jest.fn(() => [activeSession]),
    };

    const gitService = {
      getStatus: jest.fn(),
      commit: jest.fn(),
      getDiff: jest.fn(),
    };

    const queuedNotification: BridgeMessage<NotificationPayload> = {
      type: "notification",
      id: "notif-1",
      timestamp: new Date().toISOString(),
      payload: {
        notification_id: "notif-1",
        session_id: "sess-1",
        notification_type: "approval_required",
        title: "Approval needed",
        body: "Review tool call",
        priority: "high",
      },
    };

    const eventQueue = {
      replay: jest.fn(() => [queuedNotification]),
      acknowledgeNotifications: jest.fn(),
    };

    const handler = new MessageHandler(
      connectionManager as never,
      agentSdkAdapter as never,
      agentSessionManager as never,
      gitService as never,
      eventQueue as never,
    );

    return {
      handler,
      sentMessages,
      connectionManager,
      agentSdkAdapter,
      activeSession,
      eventQueue,
    };
  }

  it("sends a contract-aligned connection_ack and replays queued events on auth", async () => {
    const { handler, sentMessages, connectionManager, activeSession } = createDependencies();

    await handler.handle(
      "client-1",
      JSON.stringify({
        type: "auth",
        id: "auth-1",
        timestamp: new Date().toISOString(),
        payload: {
          token: "test-bridge-token",
          client_version: "1.0.0",
          platform: "ios",
        },
      }),
    );

    expect(connectionManager.authenticateClient).toHaveBeenCalledWith("client-1");
    expect(sentMessages[0]?.message).toMatchObject({
      type: "connection_ack",
      id: "auth-1",
      timestamp: expect.any(String),
      payload: {
        server_version: "0.1.0",
        supported_agents: ["claude-code"],
        active_sessions: [
          {
            session_id: activeSession.id,
            agent: "claude-code",
            title: activeSession.title,
            working_directory: activeSession.working_directory,
            status: activeSession.status,
          },
        ],
      },
    });
    expect(sentMessages[1]?.message.type).toBe("notification");
  });

  it("passes the original request id through session_start handling", async () => {
    const { handler, connectionManager, agentSdkAdapter } = createDependencies();
    connectionManager.getClient.mockReturnValue({ authenticated: true, sessionIds: [] });

    const payload: SessionStartPayload = {
      agent: "claude-code",
      working_directory: "/repo/project",
      resume: false,
    };

    await handler.handle(
      "client-1",
      JSON.stringify({
        type: "session_start",
        id: "req-1",
        timestamp: new Date().toISOString(),
        payload,
      }),
    );

    expect(agentSdkAdapter.handleSessionStart).toHaveBeenCalledWith(payload, "client-1", "req-1");
  });

  it("acknowledges notification ids from the client", async () => {
    const { handler, connectionManager, eventQueue } = createDependencies();
    connectionManager.getClient.mockReturnValue({ authenticated: true, sessionIds: [] });

    await handler.handle(
      "client-1",
      JSON.stringify({
        type: "notification_ack",
        timestamp: new Date().toISOString(),
        payload: {
          notification_ids: ["notif-1", "notif-2"],
        },
      }),
    );

    expect(eventQueue.acknowledgeNotifications).toHaveBeenCalledWith(["notif-1", "notif-2"]);
  });

  it("replays queued agent-sdk tool results after auth reconnect", async () => {
    const sentMessages: Array<{ clientId: string; message: BridgeMessage }> = [];
    const eventQueue = new EventQueue();
    const connectionManager = {
      sendToClient: jest.fn((clientId: string, message: BridgeMessage) => {
        sentMessages.push({ clientId, message });
      }),
      authenticateClient: jest.fn(),
      getClient: jest.fn(),
      addSessionToClient: jest.fn(),
      getClientsForSession: jest.fn(() => []),
      broadcast: jest.fn(),
    };
    const agentSdkAdapter = {
      handleSessionStart: jest.fn(),
      handleMessage: jest.fn(),
      handleApprovalResponse: jest.fn(),
      handleSessionEnd: jest.fn(),
    };
    const agentSessionManager = {
      getActiveSessions: jest.fn(() => []),
    };
    const gitService = {
      getStatus: jest.fn(),
      commit: jest.fn(),
      getDiff: jest.fn(),
    };

    new Dispatcher(connectionManager as never, eventQueue);
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

    const handler = new MessageHandler(
      connectionManager as never,
      agentSdkAdapter as never,
      agentSessionManager as never,
      gitService as never,
      eventQueue,
    );

    await handler.handle(
      "client-1",
      JSON.stringify({
        type: "auth",
        id: "auth-reconnect-1",
        timestamp: new Date().toISOString(),
        payload: {
          token: "test-bridge-token",
          client_version: "1.0.0",
          platform: "ios",
        },
      }),
    );

    expect(sentMessages.map((entry) => entry.message.type)).toEqual([
      "connection_ack",
      "tool_result",
    ]);
    expect(sentMessages[1]?.message).toMatchObject({
      type: "tool_result",
      payload: {
        session_id: "sess-1",
        tool_call_id: "tool-1",
        tool: "run_command",
        result: {
          success: true,
          content: "Tests passed",
          duration_ms: 42,
        },
      },
    });
  });
});
