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
    acknowledgeWarning: jest.fn(),
    getClient: jest.fn(),
    addSessionToClient: jest.fn(),
    getClientsForSession: jest.fn(() => []),
    getAuthenticatedClientCount: jest.fn(() => 0),
    getTotalClientCount: jest.fn(() => 0),
    broadcast: jest.fn((message: BridgeMessage) => {
      broadcastMessages.push(message);
    }),
  };
  return { manager: manager as never, broadcastMessages };
}

describe("createHooksRouter", () => {
  let eventQueue: EventQueue;
  let mockConnectionManager: jest.Mocked<ConnectionManager>;
  let app: express.Application;

  beforeEach(() => {
    eventQueue = new EventQueue();
    const result = createMockConnectionManager();
    mockConnectionManager = result.manager;

    app = express();
    app.use(express.json());
    app.use("/hooks", createHooksRouter(eventQueue, mockConnectionManager));
  });

  describe("POST /hooks/event", () => {
    it("accepts valid hook events with valid token", async () => {
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
      expect(response.body).toMatchObject({
        received: true,
        event_id: expect.any(String),
        broadcast_count: 1,
        timestamp: expect.any(String),
      });
    });

    it("accepts the docs alias field name event as well as event_type", async () => {
      const response = await request(app)
        .post("/hooks/event")
        .set("Authorization", "Bearer test-hook-token")
        .send({
          event: "SessionStart",
          session_id: "sess-123",
          timestamp: new Date().toISOString(),
          payload: { working_directory: "/repo/project" },
        });

      expect(response.status).toBe(200);
      expect(response.body.received).toBe(true);
    });

    it("rejects requests without token", async () => {
      const response = await request(app).post("/hooks/event").send({
        event_type: "SessionStart",
        session_id: "sess-123",
        timestamp: new Date().toISOString(),
        payload: {},
      });

      expect(response.status).toBe(401);
      expect(response.body.code).toBe("HOOK_AUTH_FAILED");
    });

    it("rejects requests with invalid token", async () => {
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
      expect(response.body.code).toBe("HOOK_AUTH_FAILED");
    });

    it("rejects invalid hook event shape", async () => {
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
      expect(response.body.code).toBe("HOOK_INVALID_PAYLOAD");
    });

    it("rejects stale timestamps", async () => {
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
      expect(response.body.code).toBe("HOOK_INVALID_PAYLOAD");
    });

    it("enqueues events after validation", async () => {
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

    it("broadcasts events to connected clients", async () => {
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

    it("creates notification side-effects for hook events that need user attention", async () => {
      const response = await request(app)
        .post("/hooks/event")
        .set("Authorization", "Bearer test-hook-token")
        .send({
          event_type: "PreToolUse",
          session_id: "sess-123",
          timestamp: new Date().toISOString(),
          payload: {
            tool: "edit_file",
            tool_call_id: "tool-123",
            risk_level: "high",
            description: "Update startup validation",
            params: {
              file_path: "apps/mobile/lib/main.dart",
            },
          },
        });

      expect(response.status).toBe(200);
      expect(response.body.broadcast_count).toBe(3);
      expect(eventQueue.replay("sess-123")).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ type: "claude_event" }),
          expect.objectContaining({ type: "approval_required" }),
          expect.objectContaining({
            type: "notification",
            payload: expect.objectContaining({
              notification_type: "approval_required",
              data: expect.objectContaining({
                tool_call_id: "tool-123",
                screen: "approval_detail",
              }),
            }),
          }),
        ]),
      );
    });
  });

  describe("POST /hooks/batch", () => {
    it("accepts batches of valid events", async () => {
      const response = await request(app)
        .post("/hooks/batch")
        .set("Authorization", "Bearer test-hook-token")
        .send({
          events: [
            {
              event_type: "SessionStart",
              session_id: "sess-123",
              timestamp: new Date().toISOString(),
              payload: {},
            },
            {
              event: "PostToolUse",
              session_id: "sess-123",
              timestamp: new Date().toISOString(),
              payload: { tool: "read" },
            },
          ],
        });

      expect(response.status).toBe(200);
      expect(response.body).toMatchObject({
        received: true,
        count: 2,
        accepted: 2,
        rejected: 0,
      });
      expect(response.body.event_ids).toHaveLength(2);
    });
  });

  describe("session routing", () => {
    it("routes events by session_id", async () => {
      await request(app).post("/hooks/event").set("Authorization", "Bearer test-hook-token").send({
        event_type: "SessionStart",
        session_id: "specific-session-123",
        timestamp: new Date().toISOString(),
        payload: {},
      });

      const messages = eventQueue.replay();
      expect(messages).toHaveLength(1);

      const sessionMessages = eventQueue.replay("specific-session-123");
      expect(sessionMessages).toHaveLength(1);

      const otherMessages = eventQueue.replay("other-session");
      expect(otherMessages).toHaveLength(0);
    });
  });
});
