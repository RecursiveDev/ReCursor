/**
 * Tests for ConnectionManager Cloudflare tunnel metadata handling.
 *
 * These tests define the EXPECTED behavior for Cloudflare tunnel connection metadata.
 * Metadata (connectionMode, bridgeUrl, remoteAddress) should be properly stored
 * and propagated from WebSocket handshake through to client state.
 *
 * Currently FAILING because metadata initialization and propagation is not fully
 * implemented for Cloudflare tunnel connections.
 */
import { ConnectionManager } from "../../src/websocket/connection_manager";
import type { BridgeMessage } from "../../src/types";
import type { ClientConnectionMetadata } from "../../src/websocket/connection_manager";

function createMockWebSocket(readyState: number = 1): { readyState: number; send: jest.Mock } {
  return {
    readyState,
    send: jest.fn(),
  };
}

describe("ConnectionManager - Cloudflare Tunnel Metadata", () => {
  let connectionManager: ConnectionManager;

  beforeEach(() => {
    connectionManager = new ConnectionManager();
  });

  describe("addClient with Cloudflare tunnel metadata", () => {
    it("should store connectionMode from metadata when provided", () => {
      const ws = createMockWebSocket();
      const metadata: ClientConnectionMetadata = {
        remoteAddress: "216.247.15.107",
        connectionMode: "secure_remote",
        connectionModeDescription: "Secure tunnel connection (my-app.trycloudflare.com)",
        bridgeUrl: "wss://my-app.trycloudflare.com",
      };

      connectionManager.addClient("client-tunnel", ws as never, metadata);

      const client = connectionManager.getClient("client-tunnel");
      expect(client?.connectionMode).toBe("secure_remote");
      expect(client?.connectionModeDescription).toBe(
        "Secure tunnel connection (my-app.trycloudflare.com)",
      );
      expect(client?.bridgeUrl).toBe("wss://my-app.trycloudflare.com");
    });

    it("should store remoteAddress from Cloudflare tunnel connection", () => {
      const ws = createMockWebSocket();
      const metadata: ClientConnectionMetadata = {
        remoteAddress: "216.247.15.107",
        connectionMode: "secure_remote",
      };

      connectionManager.addClient("client-tunnel", ws as never, metadata);

      const client = connectionManager.getClient("client-tunnel");
      expect(client?.remoteAddress).toBe("216.247.15.107");
    });

    it("should handle IPv6-mapped Cloudflare addresses", () => {
      const ws = createMockWebSocket();
      const metadata: ClientConnectionMetadata = {
        remoteAddress: "::ffff:d0f7:0f6b",
        connectionMode: "secure_remote",
        bridgeUrl: "wss://test.trycloudflare.com",
      };

      connectionManager.addClient("client-ipv6", ws as never, metadata);

      const client = connectionManager.getClient("client-ipv6");
      expect(client?.remoteAddress).toBe("::ffff:d0f7:0f6b");
      expect(client?.connectionMode).toBe("secure_remote");
    });

    it("should preserve all metadata fields for Tailscale comparison", () => {
      // Tailscale metadata - should also work correctly
      const wsTailcale = createMockWebSocket();
      const tailscaleMetadata: ClientConnectionMetadata = {
        remoteAddress: "100.64.0.1",
        connectionMode: "secure_remote",
        connectionModeDescription: "Secure tunnel connection (devbox.tailnet.ts.net)",
        bridgeUrl: "wss://devbox.tailnet.ts.net",
      };

      connectionManager.addClient("client-tailscale", wsTailcale as never, tailscaleMetadata);

      const tsClient = connectionManager.getClient("client-tailscale");
      expect(tsClient?.connectionMode).toBe("secure_remote");
      expect(tsClient?.bridgeUrl).toBe("wss://devbox.tailnet.ts.net");
    });
  });

  describe("metadata propagation in connection_ack", () => {
    it("should allow retrieving stored tunnel metadata for connection_ack", () => {
      const ws = createMockWebSocket();
      const metadata: ClientConnectionMetadata = {
        remoteAddress: "216.247.15.107",
        connectionMode: "secure_remote",
        connectionModeDescription: "Secure tunnel connection (tunnel.trycloudflare.com)",
        bridgeUrl: "wss://tunnel.trycloudflare.com",
      };

      connectionManager.addClient("client-cf", ws as never, metadata);
      connectionManager.authenticateClient("client-cf");

      const client = connectionManager.getClient("client-cf");
      // Metadata should be available for inclusion in connection_ack payload
      expect(client?.connectionMode).toBe("secure_remote");
      expect(client?.bridgeUrl).toBe("wss://tunnel.trycloudflare.com");
    });

    it("should handle direct_public classification with metadata", () => {
      const ws = createMockWebSocket();
      const metadata: ClientConnectionMetadata = {
        remoteAddress: "203.0.113.50", // Public IP, not tunnel
        connectionMode: "direct_public",
        connectionModeDescription: "Direct public connection (203.0.113.50)",
        bridgeUrl: "wss://203.0.113.50",
      };

      connectionManager.addClient("client-direct", ws as never, metadata);

      const client = connectionManager.getClient("client-direct");
      expect(client?.connectionMode).toBe("direct_public");
      // Even direct connections should have warning tracking capability
      expect(client?.warningAcknowledged).toBe(false);
    });
  });

  describe("connection metadata with multiple sessions", () => {
    it("should maintain connectionMode across sessions for same client", () => {
      const ws = createMockWebSocket();
      const metadata: ClientConnectionMetadata = {
        connectionMode: "secure_remote",
        bridgeUrl: "wss://session-tunnel.trycloudflare.com",
      };

      connectionManager.addClient("client-multi", ws as never, metadata);
      connectionManager.addSessionToClient("client-multi", "sess-1");
      connectionManager.addSessionToClient("client-multi", "sess-2");

      const client = connectionManager.getClient("client-multi");
      expect(client?.sessionIds).toHaveLength(2);
      expect(client?.connectionMode).toBe("secure_remote");
      expect(client?.bridgeUrl).toBe("wss://session-tunnel.trycloudflare.com");
    });

    it("should filter clients by session and preserve tunnel metadata", () => {
      const ws1 = createMockWebSocket();
      const ws2 = createMockWebSocket();

      connectionManager.addClient("client-1", ws1 as never, {
        connectionMode: "secure_remote",
        bridgeUrl: "wss://tunnel1.trycloudflare.com",
      });
      connectionManager.addClient("client-2", ws2 as never, {
        connectionMode: "local_only",
        bridgeUrl: "wss://localhost",
      });

      connectionManager.authenticateClient("client-1");
      connectionManager.authenticateClient("client-2");

      connectionManager.addSessionToClient("client-1", "shared-session");
      connectionManager.addSessionToClient("client-2", "shared-session");

      const clients = connectionManager.getClientsForSession("shared-session");
      expect(clients).toHaveLength(2);

      // Verify tunnel metadata is preserved for filtering
      const tunnelClient = clients.find((c) => c.id === "client-1");
      expect(tunnelClient?.connectionMode).toBe("secure_remote");
    });
  });

  describe("broadcast to tunnel-connected clients", () => {
    it("should broadcast to all authenticated clients including tunnel clients", () => {
      const wsLocal = createMockWebSocket();
      const wsTunnel = createMockWebSocket();

      connectionManager.addClient("local-client", wsLocal as never, {
        connectionMode: "local_only",
      });
      connectionManager.addClient("tunnel-client", wsTunnel as never, {
        connectionMode: "secure_remote",
        bridgeUrl: "wss://tunnel.trycloudflare.com",
      });

      connectionManager.authenticateClient("local-client");
      connectionManager.authenticateClient("tunnel-client");

      const message: BridgeMessage = {
        type: "session_start",
        timestamp: new Date().toISOString(),
        payload: { session_id: "sess-1" },
      };

      connectionManager.broadcast(message);

      expect(wsLocal.send).toHaveBeenCalledTimes(1);
      expect(wsTunnel.send).toHaveBeenCalledTimes(1);
    });

    it("should support filtering by connection mode for security messages", () => {
      const wsLocal = createMockWebSocket();
      const wsDirect = createMockWebSocket();
      const wsTunnel = createMockWebSocket();

      connectionManager.addClient("local", wsLocal as never, { connectionMode: "local_only" });
      connectionManager.addClient("direct", wsDirect as never, {
        connectionMode: "direct_public",
      });
      connectionManager.addClient("tunnel", wsTunnel as never, {
        connectionMode: "secure_remote",
      });

      connectionManager.authenticateClient("local");
      connectionManager.authenticateClient("direct");
      connectionManager.authenticateClient("tunnel");

      const warningMessage: BridgeMessage = {
        type: "connection_warning",
        timestamp: new Date().toISOString(),
        payload: {
          code: "INSECURE_CONNECTION",
          message: "Warning for direct public connection",
        },
      };

      // Broadcast only to direct_public clients
      connectionManager.broadcast(
        warningMessage,
        (client) => client.connectionMode === "direct_public",
      );

      expect(wsLocal.send).not.toHaveBeenCalled();
      expect(wsTunnel.send).not.toHaveBeenCalled();
      expect(wsDirect.send).toHaveBeenCalledTimes(1);
    });
  });
});
