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
      acknowledgeWarning: jest.fn(),
      getClient: jest.fn(() => ({
        authenticated: true,
        sessionIds: [],
        connectionMode: "secure_remote",
        connectionModeDescription: "Secure tunnel connection (devbox.tailnet.ts.net)",
        bridgeUrl: "wss://devbox.tailnet.ts.net:3000",
        warningAcknowledged: false,
      })),
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
      getSession: jest.fn((sessionId: string) =>
        sessionId === activeSession.id ? activeSession : undefined,
      ),
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
        connection_mode: "secure_remote",
        connection_mode_description: "Secure tunnel connection (devbox.tailnet.ts.net)",
        bridge_url: "wss://devbox.tailnet.ts.net:3000",
        requires_health_verification: true,
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

  it("returns health_status after auth for the initial verification flow", async () => {
    const { handler, sentMessages, connectionManager } = createDependencies();
    connectionManager.getClient.mockReturnValue({
      authenticated: true,
      sessionIds: [],
      connectionMode: "secure_remote",
      connectionModeDescription: "Secure tunnel connection (devbox.tailnet.ts.net)",
      bridgeUrl: "wss://devbox.tailnet.ts.net:3000",
      warningAcknowledged: false,
    });

    await handler.handle(
      "client-1",
      JSON.stringify({
        type: "health_check",
        id: "health-1",
        timestamp: new Date().toISOString(),
        payload: {
          timestamp: new Date().toISOString(),
          client_nonce: "nonce-123",
          client_capabilities: ["health_v1"],
        },
      }),
    );

    expect(sentMessages[0]?.message).toMatchObject({
      type: "health_status",
      id: "health-1",
      payload: {
        status: "healthy",
        connection_mode: "secure_remote",
        warnings: [],
        checks: {
          tls_valid: true,
          clock_sync: true,
          version_compatible: true,
          token_permissions: true,
        },
        ready: true,
      },
    });
  });

  it("requires acknowledgment before direct public connections become ready", async () => {
    const { handler, sentMessages, connectionManager } = createDependencies();
    connectionManager.getClient.mockReturnValue({
      authenticated: true,
      sessionIds: [],
      connectionMode: "direct_public",
      connectionModeDescription: "Direct public connection (203.0.113.42)",
      bridgeUrl: "wss://203.0.113.42:3000",
      warningAcknowledged: false,
    });

    await handler.handle(
      "client-1",
      JSON.stringify({
        type: "health_check",
        id: "health-2",
        timestamp: new Date().toISOString(),
        payload: {
          timestamp: new Date().toISOString(),
          client_nonce: "nonce-456",
          client_capabilities: ["health_v1", "acknowledgment_v1"],
        },
      }),
    );

    expect(sentMessages[0]?.message).toMatchObject({
      type: "health_status",
      payload: {
        status: "warning",
        connection_mode: "direct_public",
        warnings: ["DIRECT_PUBLIC_CONNECTION"],
        requires_acknowledgment: true,
        ready: false,
      },
    });

    sentMessages.length = 0;

    await handler.handle(
      "client-1",
      JSON.stringify({
        type: "acknowledge_warning",
        id: "ack-1",
        timestamp: new Date().toISOString(),
        payload: {
          warning_code: "DIRECT_PUBLIC_CONNECTION",
          acknowledged: true,
          acknowledged_at: new Date().toISOString(),
        },
      }),
    );

    expect(connectionManager.acknowledgeWarning).toHaveBeenCalledWith("client-1");
    expect(sentMessages[0]?.message).toMatchObject({
      type: "acknowledgment_accepted",
      id: "ack-1",
      payload: {
        warning_code: "DIRECT_PUBLIC_CONNECTION",
        ready: true,
        session_timeout: "8h",
      },
    });
  });

  it("rejects insecure websocket transports during auth", async () => {
    const { handler, sentMessages, connectionManager } = createDependencies();
    connectionManager.getClient.mockReturnValue({
      authenticated: false,
      sessionIds: [],
      connectionMode: "misconfigured",
      connectionModeDescription: "Unencrypted transport detected",
      bridgeUrl: "ws://devbox:3000",
      warningAcknowledged: false,
    });

    await handler.handle(
      "client-1",
      JSON.stringify({
        type: "auth",
        id: "auth-2",
        timestamp: new Date().toISOString(),
        payload: {
          token: "test-bridge-token",
        },
      }),
    );

    expect(sentMessages[0]?.message).toMatchObject({
      type: "connection_error",
      id: "auth-2",
      payload: {
        code: "INSECURE_TRANSPORT",
      },
    });
  });

  it("passes the original request id through session_start handling", async () => {
    const { handler, connectionManager, agentSdkAdapter } = createDependencies();
    connectionManager.getClient.mockReturnValue({
      authenticated: true,
      sessionIds: [],
      connectionMode: "secure_remote",
      connectionModeDescription: "Secure tunnel connection (devbox.tailnet.ts.net)",
      bridgeUrl: "wss://devbox.tailnet.ts.net:3000",
      warningAcknowledged: false,
    });

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
    connectionManager.getClient.mockReturnValue({
      authenticated: true,
      sessionIds: [],
      connectionMode: "secure_remote",
      connectionModeDescription: "Secure tunnel connection (devbox.tailnet.ts.net)",
      bridgeUrl: "wss://devbox.tailnet.ts.net:3000",
      warningAcknowledged: false,
    });

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
      acknowledgeWarning: jest.fn(),
      getClient: jest.fn(() => ({
        authenticated: false,
        sessionIds: [],
        connectionMode: "secure_remote",
        bridgeUrl: "wss://devbox.tailnet.ts.net:3000",
      })),
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
      getSession: jest.fn(),
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
