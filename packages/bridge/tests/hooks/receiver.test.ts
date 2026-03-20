import { createHooksRouter } from "../../src/hooks/receiver";
import { EventQueue } from "../../src/hooks/event_queue";
import type { ConnectionManager } from "../../src/websocket/connection_manager";
import type { BridgeMessage } from "../../src/types";
import express from "express";
import request from "supertest";

function createMockConnectionManager(): {
  manager: jest.Mocked<ConnectionManager>;
  broadcastMessages: BridgeMessage[];
} {
  const broadcastMessages: BridgeMessage[] = [];
  const manager = {
    sendToClient: jest.fn(),
    authenticateClient: jest.fn(),
    getClient: jest.fn(),
    addSessionToClient: jest.fn(),
    getClientsForSession: jest.fn(() => []),
    broadcast: jest.fn((message: BridgeMessage) => {
      broadcastMessages.push(message);
    }),
  };
  return { manager: manager as never, broadcastMessages };
}

describe("createHooksRouter", () => {
  let eventQueue: EventQueue;
  let mockConnectionManager: jest.Mocked<ConnectionManager>;
  let broadcastMessages: BridgeMessage[];
  let app: express.Application;

  beforeEach(() => {
    eventQueue = new EventQueue();
    const result = createMockConnectionManager();
    mockConnectionManager = result.manager;
    broadcastMessages = result.broadcastMessages;

    app = express();
    app.use(express.json());
    app.use("/hooks", createHooksRouter(eventQueue, mockConnectionManager));
  });

  describe("POST /hooks/event", () => {
    it("should accept valid hook events with valid token", async () => {
      const response = await request(app)
        .post("/hooks/event")
        .set("Authorization", "Bearer test-hook-token")
        .send({
          event_type: "SessionStart",
          session_id: "sess-123",
          timestamp: new Date().toISOString(),
          payload: { working_directory: "/repo/project" },
        });

      expect(response.status).toBe(200);
      expect(response.body).toEqual({ received: true });
    });

    it("should reject requests without token", async () => {
      const response = await request(app).post("/hooks/event").send({
        event_type: "SessionStart",
        session_id: "sess-123",
        timestamp: new Date().toISOString(),
        payload: {},
      });

      expect(response.status).toBe(401);
    });

    it("should reject requests with invalid token", async () => {
      const response = await request(app)
        .post("/hooks/event")
        .set("Authorization", "Bearer invalid-token")
        .send({
          event_type: "SessionStart",
          session_id: "sess-123",
          timestamp: new Date().toISOString(),
          payload: {},
        });

      expect(response.status).toBe(401);
    });

    it("should reject invalid hook event shape", async () => {
      const response = await request(app)
        .post("/hooks/event")
        .set("Authorization", "Bearer test-hook-token")
        .send({
          event_type: "InvalidEventType",
          session_id: "sess-123",
          timestamp: new Date().toISOString(),
          payload: {},
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe("Bad Request");
    });

    it("should reject stale timestamps", async () => {
      const staleTimestamp = new Date(Date.now() - 10 * 60 * 1000).toISOString();
      const response = await request(app)
        .post("/hooks/event")
        .set("Authorization", "Bearer test-hook-token")
        .send({
          event_type: "SessionStart",
          session_id: "sess-123",
          timestamp: staleTimestamp,
          payload: {},
        });

      expect(response.status).toBe(400);
    });

    it("should enqueue events after validation", async () => {
      const initialSize = eventQueue.size();

      await request(app)
        .post("/hooks/event")
        .set("Authorization", "Bearer test-hook-token")
        .send({
          event_type: "SessionStart",
          session_id: "sess-123",
          timestamp: new Date().toISOString(),
          payload: { working_directory: "/repo/project" },
        });

      expect(eventQueue.size()).toBe(initialSize + 1);
    });

    it("should broadcast events to connected clients", async () => {
      await request(app)
        .post("/hooks/event")
        .set("Authorization", "Bearer test-hook-token")
        .send({
          event_type: "SessionStart",
          session_id: "sess-123",
          timestamp: new Date().toISOString(),
          payload: { working_directory: "/repo/project" },
        });

      expect(mockConnectionManager.broadcast).toHaveBeenCalled();
    });

    it("should handle UserPromptSubmit events", async () => {
      const response = await request(app)
        .post("/hooks/event")
        .set("Authorization", "Bearer test-hook-token")
        .send({
          event_type: "UserPromptSubmit",
          session_id: "sess-456",
          timestamp: new Date().toISOString(),
          payload: {
            prompt: "Write a function that sorts an array",
          },
        });

      expect(response.status).toBe(200);
    });

    it("should handle PostToolUse events", async () => {
      const response = await request(app)
        .post("/hooks/event")
        .set("Authorization", "Bearer test-hook-token")
        .send({
          event_type: "PostToolUse",
          session_id: "sess-789",
          timestamp: new Date().toISOString(),
          payload: {
            tool: "read",
            params: { path: "/src/index.ts" },
            result: "file contents",
          },
        });

      expect(response.status).toBe(200);
    });

    it("should handle PreToolUse events", async () => {
      const response = await request(app)
        .post("/hooks/event")
        .set("Authorization", "Bearer test-hook-token")
        .send({
          event_type: "PreToolUse",
          session_id: "sess-123",
          timestamp: new Date().toISOString(),
          payload: {
            tool: "write",
            params: { path: "/src/new.ts" },
          },
        });

      expect(response.status).toBe(200);
    });

    it("should handle SessionEnd events", async () => {
      const response = await request(app)
        .post("/hooks/event")
        .set("Authorization", "Bearer test-hook-token")
        .send({
          event_type: "SessionEnd",
          session_id: "sess-123",
          timestamp: new Date().toISOString(),
          payload: {
            reason: "completed",
          },
        });

      expect(response.status).toBe(200);
    });

    it("should handle Notification events", async () => {
      const response = await request(app)
        .post("/hooks/event")
        .set("Authorization", "Bearer test-hook-token")
        .send({
          event_type: "Notification",
          session_id: "sess-123",
          timestamp: new Date().toISOString(),
          payload: {
            notification_type: "info",
            title: "Test notification",
            body: "Test message",
          },
        });

      expect(response.status).toBe(200);
    });
  });

  describe("session routing", () => {
    it("should route events by session_id", async () => {
      await request(app).post("/hooks/event").set("Authorization", "Bearer test-hook-token").send({
        event_type: "SessionStart",
        session_id: "specific-session-123",
        timestamp: new Date().toISOString(),
        payload: {},
      });

      const messages = eventQueue.replay();
      expect(messages).toHaveLength(1);

      // Replay with session ID filter
      const sessionMessages = eventQueue.replay("specific-session-123");
      expect(sessionMessages).toHaveLength(1);

      const otherMessages = eventQueue.replay("other-session");
      expect(otherMessages).toHaveLength(0);
    });
  });
});
