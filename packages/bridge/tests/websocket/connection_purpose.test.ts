/**
 * Tests for connection purpose metadata handling (probe vs primary).
 *
 * These tests define the expected behavior for distinguishing short-lived
 * probe connections from primary mobile sessions. Currently FAILING -
 * implementation code changes required.
 *
 * Connection Purpose Semantics (per bridge-protocol.md):
 * - Probe: ~500ms-2s duration, health verification, capability check, close code 1000
 * - Primary: Session lifetime, active session for all communication
 */
import { eventBus } from "../../src/notifications/event_bus";
import { ConnectionManager } from "../../src/websocket/connection_manager";
import { MessageHandler } from "../../src/websocket/message_handler";
import type { AgentSession, BridgeMessage, ConnectionAckPayload } from "../../src/types";

describe("Connection Purpose Metadata Handling", () => {
  afterEach(() => {
    eventBus.removeAllListeners();
  });

  /**
   * Helper to create test dependencies with configurable client state.
   */
  function createDependencies(
    options: {
      connectionMode?: "secure_remote" | "direct_public";
      existingPurpose?: "primary" | "probe";
    } = {},
  ) {
    const { connectionMode = "secure_remote", existingPurpose } = options;
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
        connectionMode,
        connectionModeDescription: "Secure tunnel connection (test.trycloudflare.com)",
        bridgeUrl: "wss://test.trycloudflare.com",
        warningAcknowledged: false,
        purpose: existingPurpose,
      })),
      addSessionToClient: jest.fn(),
      getClientsForSession: jest.fn(),
      broadcast: jest.fn(),
      setClientPurpose: jest.fn(),
      getPrimaryClients: jest.fn(() => []),
      getProbeClients: jest.fn(() => []),
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

    const eventQueue = {
      replay: jest.fn(() => []),
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

  describe("Auth payload purpose field", () => {
    it("should accept purpose='probe' in auth payload during connection handshake", async () => {
      const { handler, sentMessages, connectionManager } = createDependencies();

      // Client sends auth with purpose: "probe" to check bridge health
      await handler.handle(
        "client-probe-1",
        JSON.stringify({
          type: "auth",
          id: "auth-probe-1",
          timestamp: new Date().toISOString(),
          payload: {
            token: "test-bridge-token",
            client_version: "1.0.0",
            platform: "ios",
            purpose: "probe", // NEW: Client declares this is a probe connection
          },
        }),
      );

      expect(connectionManager.authenticateClient).toHaveBeenCalledWith("client-probe-1");

      const ackMessage = sentMessages[0]?.message as BridgeMessage<ConnectionAckPayload>;
      expect(ackMessage.type).toBe("connection_ack");
      // NEW: Bridge should echo back accepted purpose
      expect(ackMessage.payload.purpose).toBe("probe");
    });

    it("should accept purpose='primary' in auth payload for main session connection", async () => {
      const { handler, sentMessages } = createDependencies();

      await handler.handle(
        "client-primary-1",
        JSON.stringify({
          type: "auth",
          id: "auth-primary-1",
          timestamp: new Date().toISOString(),
          payload: {
            token: "test-bridge-token",
            client_version: "1.0.0",
            platform: "android",
            purpose: "primary", // Primary connection for session
          },
        }),
      );

      const ackMessage = sentMessages[0]?.message as BridgeMessage<ConnectionAckPayload>;
      expect(ackMessage.type).toBe("connection_ack");
      expect(ackMessage.payload.purpose).toBe("primary");
    });

    it("should default to 'primary' purpose when purpose field is omitted", async () => {
      const { handler, sentMessages } = createDependencies();

      // Legacy clients without purpose field should default to primary
      await handler.handle(
        "client-legacy-1",
        JSON.stringify({
          type: "auth",
          id: "auth-legacy-1",
          timestamp: new Date().toISOString(),
          payload: {
            token: "test-bridge-token",
            client_version: "1.0.0",
            platform: "ios",
            // purpose field omitted - should default to 'primary'
          },
        }),
      );

      const ackMessage = sentMessages[0]?.message as BridgeMessage<ConnectionAckPayload>;
      expect(ackMessage.payload.purpose).toBe("primary");
    });
  });

  describe("ConnectionManager purpose tracking", () => {
    function addClient(connectionManager: ConnectionManager, clientId: string): void {
      connectionManager.addClient(clientId, {
        readyState: 1,
        send: jest.fn(),
      } as never);
    }

    it("should expose getPrimaryClients() returning only primary purpose clients", async () => {
      const connectionManager = new ConnectionManager();

      addClient(connectionManager, "client-1");
      addClient(connectionManager, "client-2");
      addClient(connectionManager, "client-3");

      connectionManager.setClientPurpose("client-1", "primary");
      connectionManager.setClientPurpose("client-2", "probe");
      connectionManager.setClientPurpose("client-3", "primary");

      const primaryClients = connectionManager.getPrimaryClients();
      expect(primaryClients).toHaveLength(2);
      expect(primaryClients.map((c) => c.id)).toEqual(
        expect.arrayContaining(["client-1", "client-3"]),
      );
    });

    it("should expose getProbeClients() returning only probe purpose clients", async () => {
      const connectionManager = new ConnectionManager();

      addClient(connectionManager, "client-1");
      addClient(connectionManager, "client-2");
      addClient(connectionManager, "client-3");

      connectionManager.setClientPurpose("client-1", "primary");
      connectionManager.setClientPurpose("client-2", "probe");
      connectionManager.setClientPurpose("client-3", "probe");

      const probeClients = connectionManager.getProbeClients();
      expect(probeClients).toHaveLength(2);
      expect(probeClients.map((c) => c.id)).toEqual(
        expect.arrayContaining(["client-2", "client-3"]),
      );
    });

    it("should include purpose in client metadata for diagnostics", async () => {
      const connectionManager = new ConnectionManager();

      addClient(connectionManager, "client-probe-1");
      connectionManager.setClientPurpose("client-probe-1", "probe");

      const client = connectionManager.getClient("client-probe-1");

      // MobileClient should have purpose field populated
      expect(client?.purpose).toBe("probe");
    });
  });

  describe("Connection purpose diagnostics logging", () => {
    it("should log purpose during auth for observability", async () => {
      const { handler, connectionManager } = createDependencies();
      const consoleSpy = jest.spyOn(console, "log").mockImplementation(() => {});

      await handler.handle(
        "client-diag-1",
        JSON.stringify({
          type: "auth",
          id: "auth-diag-1",
          timestamp: new Date().toISOString(),
          payload: {
            token: "test-bridge-token",
            client_version: "1.0.0",
            platform: "ios",
            purpose: "probe",
          },
        }),
      );

      // Bridge should log the purpose for diagnostics
      const loggedCalls = consoleSpy.mock.calls.map((call) => call.join(" "));
      const hasPurposeLog = loggedCalls.some(
        (log) => log.includes("client-diag-1") && log.includes("probe"),
      );

      expect(hasPurposeLog).toBe(true);

      consoleSpy.mockRestore();
    });
  });

  describe("Probe connection close code semantics", () => {
    it("should accept probe connections with documented close code expectation", async () => {
      // This test documents that probe connections are expected to close
      // with code 1000 (Normal) after health verification.
      // The actual close code validation happens at WebSocket layer,
      // this test verifies purpose metadata is correctly tagged.

      const { handler, sentMessages } = createDependencies();

      await handler.handle(
        "client-probe-close",
        JSON.stringify({
          type: "auth",
          id: "auth-probe-close",
          timestamp: new Date().toISOString(),
          payload: {
            token: "test-bridge-token",
            client_version: "1.0.0",
            platform: "ios",
            purpose: "probe",
          },
        }),
      );

      // Probe connection receives successful auth
      const ackMessage = sentMessages[0]?.message as BridgeMessage<ConnectionAckPayload>;
      expect(ackMessage.type).toBe("connection_ack");
      expect(ackMessage.payload.purpose).toBe("probe");

      // Note: Actual close code 1000 verification requires WebSocket mock
      // and is outside scope of this test slice.
    });
  });

  describe("Primary connection session association", () => {
    it("should allow session_start only from primary connections", async () => {
      const { handler, connectionManager, agentSdkAdapter } = createDependencies({
        existingPurpose: "probe",
      });

      // Authenticate first
      await handler.handle(
        "client-probe-session",
        JSON.stringify({
          type: "auth",
          id: "auth-probe-session",
          timestamp: new Date().toISOString(),
          payload: {
            token: "test-bridge-token",
            purpose: "probe",
          },
        }),
      );

      // Reset mocks to check session_start specifically
      jest.clearAllMocks();

      // Probe connection should not be allowed to start sessions
      await handler.handle(
        "client-probe-session",
        JSON.stringify({
          type: "session_start",
          id: "session-1",
          timestamp: new Date().toISOString(),
          payload: {
            agent: "claude-code",
            working_directory: "/repo",
          },
        }),
      );

      // session_start handler should NOT be called for probe connections
      // (or should return error indicating probe cannot start sessions)
      // This test expects the purpose field to be checked during session_start
      expect(agentSdkAdapter.handleSessionStart).not.toHaveBeenCalled();
    });
  });
});
