import { ConnectionManager } from "../../src/websocket/connection_manager";
import type { MobileClient, BridgeMessage } from "../../src/types";

function createMockWebSocket(readyState: number = 1): {
  ws: { readyState: number; send: jest.Mock };
} {
  return {
    ws: {
      readyState,
      send: jest.fn(),
    },
  };
}

describe("ConnectionManager", () => {
  let connectionManager: ConnectionManager;

  beforeEach(() => {
    connectionManager = new ConnectionManager();
  });

  describe("addClient", () => {
    it("should add a client with unauthenticated state", () => {
      const { ws } = createMockWebSocket();
      connectionManager.addClient("client-1", ws as never);

      const client = connectionManager.getClient("client-1");
      expect(client).toBeDefined();
      expect(client?.id).toBe("client-1");
      expect(client?.authenticated).toBe(false);
      expect(client?.sessionIds).toEqual([]);
    });

    it("should allow adding multiple clients", () => {
      const { ws: ws1 } = createMockWebSocket();
      const { ws: ws2 } = createMockWebSocket();

      connectionManager.addClient("client-1", ws1 as never);
      connectionManager.addClient("client-2", ws2 as never);

      expect(connectionManager.getClient("client-1")).toBeDefined();
      expect(connectionManager.getClient("client-2")).toBeDefined();
    });
  });

  describe("authenticateClient", () => {
    it("should mark an existing client as authenticated", () => {
      const { ws } = createMockWebSocket();
      connectionManager.addClient("client-1", ws as never);
      connectionManager.authenticateClient("client-1");

      const client = connectionManager.getClient("client-1");
      expect(client?.authenticated).toBe(true);
    });

    it("should do nothing for non-existent client", () => {
      // Should not throw
      expect(() => connectionManager.authenticateClient("unknown-client")).not.toThrow();
    });
  });

  describe("removeClient", () => {
    it("should remove an existing client", () => {
      const { ws } = createMockWebSocket();
      connectionManager.addClient("client-1", ws as never);
      connectionManager.removeClient("client-1");

      expect(connectionManager.getClient("client-1")).toBeUndefined();
    });

    it("should do nothing for non-existent client", () => {
      // Should not throw
      expect(() => connectionManager.removeClient("unknown-client")).not.toThrow();
    });
  });

  describe("getClient", () => {
    it("should return undefined for non-existent client", () => {
      expect(connectionManager.getClient("unknown")).toBeUndefined();
    });

    it("should return the client when it exists", () => {
      const { ws } = createMockWebSocket();
      connectionManager.addClient("client-1", ws as never);

      const client = connectionManager.getClient("client-1");
      expect(client?.id).toBe("client-1");
    });
  });

  describe("addSessionToClient", () => {
    it("should add a session to client's session list", () => {
      const { ws } = createMockWebSocket();
      connectionManager.addClient("client-1", ws as never);
      connectionManager.addSessionToClient("client-1", "sess-1");

      const client = connectionManager.getClient("client-1");
      expect(client?.sessionIds).toContain("sess-1");
    });

    it("should not duplicate sessions", () => {
      const { ws } = createMockWebSocket();
      connectionManager.addClient("client-1", ws as never);
      connectionManager.addSessionToClient("client-1", "sess-1");
      connectionManager.addSessionToClient("client-1", "sess-1");

      const client = connectionManager.getClient("client-1");
      expect(client?.sessionIds.filter((id) => id === "sess-1")).toHaveLength(1);
    });

    it("should do nothing for non-existent client", () => {
      // Should not throw
      expect(() => connectionManager.addSessionToClient("unknown", "sess-1")).not.toThrow();
    });
  });

  describe("getClientsForSession", () => {
    it("should return clients subscribed to the session", () => {
      const { ws: ws1 } = createMockWebSocket();
      const { ws: ws2 } = createMockWebSocket();

      connectionManager.addClient("client-1", ws1 as never);
      connectionManager.addClient("client-2", ws2 as never);

      connectionManager.authenticateClient("client-1");
      connectionManager.authenticateClient("client-2");

      connectionManager.addSessionToClient("client-1", "sess-1");
      connectionManager.addSessionToClient("client-2", "sess-1");

      const clients = connectionManager.getClientsForSession("sess-1");
      expect(clients).toHaveLength(2);
      expect(clients.map((c) => c.id)).toContain("client-1");
      expect(clients.map((c) => c.id)).toContain("client-2");
    });

    it("should not return unauthenticated clients", () => {
      const { ws } = createMockWebSocket();
      connectionManager.addClient("client-1", ws as never);
      // Not authenticated
      connectionManager.addSessionToClient("client-1", "sess-1");

      const clients = connectionManager.getClientsForSession("sess-1");
      expect(clients).toHaveLength(0);
    });

    it("should return empty array for session with no subscribers", () => {
      const clients = connectionManager.getClientsForSession("unknown-session");
      expect(clients).toEqual([]);
    });
  });

  describe("broadcast", () => {
    it("should send message to all authenticated clients", () => {
      const { ws: ws1 } = createMockWebSocket();
      const { ws: ws2 } = createMockWebSocket();

      connectionManager.addClient("client-1", ws1 as never);
      connectionManager.addClient("client-2", ws2 as never);

      connectionManager.authenticateClient("client-1");
      connectionManager.authenticateClient("client-2");

      const message: BridgeMessage = {
        type: "test_event",
        timestamp: new Date().toISOString(),
        payload: { data: "test" },
      };

      connectionManager.broadcast(message);

      expect(ws1.send).toHaveBeenCalledTimes(1);
      expect(ws2.send).toHaveBeenCalledTimes(1);
    });

    it("should not send to unauthenticated clients", () => {
      const { ws } = createMockWebSocket();
      connectionManager.addClient("client-1", ws as never);
      // Not authenticated

      const message: BridgeMessage = {
        type: "test_event",
        timestamp: new Date().toISOString(),
        payload: { data: "test" },
      };

      connectionManager.broadcast(message);
      expect(ws.send).not.toHaveBeenCalled();
    });

    it("should respect filter function", () => {
      const { ws: ws1 } = createMockWebSocket();
      const { ws: ws2 } = createMockWebSocket();

      connectionManager.addClient("client-1", ws1 as never);
      connectionManager.addClient("client-2", ws2 as never);

      connectionManager.authenticateClient("client-1");
      connectionManager.authenticateClient("client-2");

      connectionManager.addSessionToClient("client-1", "sess-1");
      connectionManager.addSessionToClient("client-2", "sess-2");

      const message: BridgeMessage = {
        type: "test_event",
        timestamp: new Date().toISOString(),
        payload: { data: "test" },
      };

      // Only send to clients subscribed to sess-1
      connectionManager.broadcast(message, (client) => client.sessionIds.includes("sess-1"));

      expect(ws1.send).toHaveBeenCalledTimes(1);
      expect(ws2.send).not.toHaveBeenCalled();
    });

    it("should not send to clients with closed WebSocket", () => {
      const { ws: ws1 } = createMockWebSocket(1); // OPEN
      const { ws: ws2 } = createMockWebSocket(3); // CLOSED

      connectionManager.addClient("client-1", ws1 as never);
      connectionManager.addClient("client-2", ws2 as never);

      connectionManager.authenticateClient("client-1");
      connectionManager.authenticateClient("client-2");

      const message: BridgeMessage = {
        type: "test_event",
        timestamp: new Date().toISOString(),
        payload: { data: "test" },
      };

      connectionManager.broadcast(message);

      expect(ws1.send).toHaveBeenCalledTimes(1);
      expect(ws2.send).not.toHaveBeenCalled();
    });
  });

  describe("sendToClient", () => {
    it("should send message to specific client", () => {
      const { ws } = createMockWebSocket();
      connectionManager.addClient("client-1", ws as never);
      connectionManager.authenticateClient("client-1");

      const message: BridgeMessage = {
        type: "test_event",
        id: "msg-1",
        timestamp: new Date().toISOString(),
        payload: { data: "test" },
      };

      connectionManager.sendToClient("client-1", message);

      expect(ws.send).toHaveBeenCalledTimes(1);
      const sentData = JSON.parse(ws.send.mock.calls[0][0]);
      expect(sentData.type).toBe("test_event");
      expect(sentData.id).toBe("msg-1");
    });

    it("should do nothing for non-existent client", () => {
      const message: BridgeMessage = {
        type: "test_event",
        timestamp: new Date().toISOString(),
        payload: { data: "test" },
      };

      // Should not throw
      expect(() => connectionManager.sendToClient("unknown", message)).not.toThrow();
    });

    it("should not send if WebSocket is not open", () => {
      const { ws } = createMockWebSocket(0); // CONNECTING
      connectionManager.addClient("client-1", ws as never);
      connectionManager.authenticateClient("client-1");

      const message: BridgeMessage = {
        type: "test_event",
        timestamp: new Date().toISOString(),
        payload: { data: "test" },
      };

      connectionManager.sendToClient("client-1", message);
      expect(ws.send).not.toHaveBeenCalled();
    });
  });
});
