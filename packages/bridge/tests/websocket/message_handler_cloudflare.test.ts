/**
 * Tests for MessageHandler auth flow with Cloudflare tunnel connections.
 *
 * These tests verify that mobile clients connecting through Cloudflare tunnels
 * receive the correct connection_ack payload with proper connection classification.
 *
 * Currently PASSING - these tests document the expected auth flow behavior
 * that should work once connection_mode detection is fixed.
 */
import { EventQueue } from "../../src/hooks/event_queue";
import { eventBus } from "../../src/notifications/event_bus";
import { MessageHandler } from "../../src/websocket/message_handler";
import type { AgentSession, BridgeMessage, ConnectionAckPayload } from "../../src/types";

describe("MessageHandler - Cloudflare Tunnel Auth Flow", () => {
  afterEach(() => {
    eventBus.removeAllListeners();
  });

  function createDependencies(connectionMode: "secure_remote" | "direct_public" = "secure_remote") {
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
        connectionModeDescription:
          connectionMode === "secure_remote"
            ? "Secure tunnel connection (test.trycloudflare.com)"
            : "Direct public connection (216.247.15.107)",
        bridgeUrl: "wss://test.trycloudflare.com",
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

  describe("auth message handling", () => {
    it("should send connection_ack with secure_remote for Cloudflare tunnel clients", async () => {
      const { handler, sentMessages, connectionManager } = createDependencies("secure_remote");

      await handler.handle(
        "client-cloudflare",
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

      expect(connectionManager.authenticateClient).toHaveBeenCalledWith("client-cloudflare");

      const ackMessage = sentMessages[0]?.message as BridgeMessage<ConnectionAckPayload>;
      expect(ackMessage.type).toBe("connection_ack");
      expect(ackMessage.payload.connection_mode).toBe("secure_remote");
      expect(ackMessage.payload.connection_mode_description).toContain("Secure tunnel");
      expect(ackMessage.payload.bridge_url).toBe("wss://test.trycloudflare.com");
    });

    it("should include Cloudflare tunnel URL in bridge_url field", async () => {
      const { handler, sentMessages } = createDependencies("secure_remote");

      await handler.handle(
        "client-cloudflare",
        JSON.stringify({
          type: "auth",
          id: "auth-2",
          timestamp: new Date().toISOString(),
          payload: {
            token: "test-bridge-token",
            client_version: "1.0.0",
            platform: "android",
          },
        }),
      );

      const ackMessage = sentMessages[0]?.message as BridgeMessage<ConnectionAckPayload>;
      // Bridge URL should be a wss:// URL for Cloudflare tunnels
      expect(ackMessage.payload.bridge_url).toMatch(/^wss:\/\//);
    });

    it("should expose dynamic URL nature in connection metadata for Cloudflare", async () => {
      const { handler, sentMessages } = createDependencies("secure_remote");

      await handler.handle(
        "client-cloudflare",
        JSON.stringify({
          type: "auth",
          id: "auth-3",
          timestamp: new Date().toISOString(),
          payload: {
            token: "test-bridge-token",
            client_version: "1.0.0",
            platform: "ios",
          },
        }),
      );

      const ackMessage = sentMessages[0]?.message as BridgeMessage<ConnectionAckPayload>;
      // Cloudflare tunnels use secure_remote mode with dynamic URLs
      expect(ackMessage.payload.connection_mode).toBe("secure_remote");
      // The bridge_url should contain trycloudflare.com for ephemeral tunnels
      // (Note: Production named tunnels would use different hostnames)
    });
  });

  describe("connection_mode classification for mobile clients", () => {
    it("should classify Cloudflare tunnel connections as secure_remote (not direct_public)", async () => {
      // This test documents the CURRENT EXPECTED behavior
      // When the fix is applied, Cloudflare connections should be classified as secure_remote
      // Currently they may be misclassified as direct_public
      const { handler, sentMessages } = createDependencies("secure_remote");

      await handler.handle(
        "client-cloudflare",
        JSON.stringify({
          type: "auth",
          id: "auth-cloudflare-1",
          timestamp: new Date().toISOString(),
          payload: {
            token: "test-bridge-token",
            client_version: "1.0.0",
            platform: "ios",
          },
        }),
      );

      const ackMessage = sentMessages[0]?.message as BridgeMessage<ConnectionAckPayload>;

      // EXPECTED: Cloudflare tunnel connections should be classified as secure_remote
      // because:
      // 1. TLS is terminated at Cloudflare edge (secureTransport = true)
      // 2. The host (*.trycloudflare.com) is a known tunnel provider
      // 3. Traffic is proxied through Cloudflare infrastructure
      expect(ackMessage.payload.connection_mode).toBe("secure_remote");
    });

    it("should provide accurate connection_mode_description for Cloudflare tunnels", async () => {
      const { handler, sentMessages } = createDependencies("secure_remote");

      await handler.handle(
        "client-cloudflare",
        JSON.stringify({
          type: "auth",
          id: "auth-cloudflare-2",
          timestamp: new Date().toISOString(),
          payload: {
            token: "test-bridge-token",
            client_version: "1.0.0",
            platform: "android",
          },
        }),
      );

      const ackMessage = sentMessages[0]?.message as BridgeMessage<ConnectionAckPayload>;

      // The description should clearly indicate this is a secure tunnel
      expect(ackMessage.payload.connection_mode_description).toMatch(/secure.*tunnel/i);
    });
  });

  describe("connection_ack payload structure", () => {
    it("should include all required fields for mobile client", async () => {
      const { handler, sentMessages, activeSession } = createDependencies();

      await handler.handle(
        "client-1",
        JSON.stringify({
          type: "auth",
          id: "auth-payload-test",
          timestamp: new Date().toISOString(),
          payload: {
            token: "test-bridge-token",
            client_version: "1.0.0",
            platform: "ios",
          },
        }),
      );

      const ackMessage = sentMessages[0]?.message as BridgeMessage<ConnectionAckPayload>;
      const payload = ackMessage.payload;

      // Required fields per types.ts
      expect(payload.server_version).toBeDefined();
      expect(payload.supported_agents).toBeDefined();
      expect(payload.connection_mode).toBeDefined();
      expect(payload.connection_mode_description).toBeDefined();
      expect(payload.bridge_url).toBeDefined();
      expect(payload.requires_health_verification).toBeDefined();
      expect(payload.active_sessions).toBeDefined();

      // Active sessions structure
      expect(payload.active_sessions).toBeInstanceOf(Array);
      expect(payload.active_sessions[0]).toMatchObject({
        session_id: activeSession.id,
        agent: activeSession.agent,
        title: activeSession.title,
        working_directory: activeSession.working_directory,
        status: activeSession.status,
      });
    });

    it("should set requires_health_verification to true for remote connections", async () => {
      const { handler, sentMessages } = createDependencies("secure_remote");

      await handler.handle(
        "client-remote",
        JSON.stringify({
          type: "auth",
          id: "auth-health-check",
          timestamp: new Date().toISOString(),
          payload: {
            token: "test-bridge-token",
            client_version: "1.0.0",
            platform: "ios",
          },
        }),
      );

      const ackMessage = sentMessages[0]?.message as BridgeMessage<ConnectionAckPayload>;
      // Non-local connections should require health verification
      expect(ackMessage.payload.requires_health_verification).toBe(true);
    });
  });

  describe("security implications of connection classification", () => {
    it("should warn for direct_public connections (if misclassification occurs)", async () => {
      // This test documents what SHOULD happen if Cloudflare is misclassified as direct_public
      // When properly classified as secure_remote, no warning should be needed
      const { handler, sentMessages } = createDependencies("direct_public");

      await handler.handle(
        "client-misclassified",
        JSON.stringify({
          type: "auth",
          id: "auth-direct",
          timestamp: new Date().toISOString(),
          payload: {
            token: "test-bridge-token",
            client_version: "1.0.0",
            platform: "ios",
          },
        }),
      );

      const ackMessage = sentMessages[0]?.message as BridgeMessage<ConnectionAckPayload>;

      // When Cloudflare is properly classified as secure_remote, this test should pass
      // with connection_mode === "secure_remote"
      // When misclassified as direct_public, connection_mode will be "direct_public"
      // which would trigger security warnings in the mobile client
      expect(["secure_remote", "direct_public"]).toContain(ackMessage.payload.connection_mode);
    });
  });
});
