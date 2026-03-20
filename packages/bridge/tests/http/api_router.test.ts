import express from "express";
import request from "supertest";
import { createApiRouter } from "../../src/http/api_router";
import type { AgentSession } from "../../src/types";

describe("createApiRouter", () => {
  function createApp() {
    const activeSession: AgentSession = {
      id: "sess-1",
      agent: "claude-code",
      title: "Bridge startup validation",
      model: "claude-opus-4-6",
      working_directory: "/repo/project",
      created_at: new Date().toISOString(),
      status: "active",
    };

    const connectionManager = {
      getAuthenticatedClientCount: jest.fn(() => 2),
      getClientsForSession: jest.fn(() => [{ id: "client-1" }]),
    };

    const agentSessionManager = {
      getActiveSessions: jest.fn(() => [activeSession]),
      getSession: jest.fn((id: string) => (id === activeSession.id ? activeSession : undefined)),
    };

    const app = express();
    app.use("/api/v1", createApiRouter(connectionManager as never, agentSessionManager as never));

    return { app, activeSession, connectionManager, agentSessionManager };
  }

  it("returns health details for authenticated requests", async () => {
    const { app } = createApp();

    const response = await request(app)
      .get("/api/v1/health")
      .set("Authorization", "Bearer test-bridge-token")
      .set("X-Forwarded-Proto", "https")
      .set("X-Forwarded-For", "100.88.0.4")
      .set("Host", "devbox.tailnet.ts.net:3000");

    expect(response.status).toBe(200);
    expect(response.body).toMatchObject({
      status: "healthy",
      version: "0.1.0",
      connection_mode: "secure_remote",
      active_sessions: 1,
      active_websockets: 2,
    });
  });

  it("returns bridge capabilities", async () => {
    const { app } = createApp();

    const response = await request(app)
      .get("/api/v1/info")
      .set("Authorization", "Bearer test-bridge-token");

    expect(response.status).toBe(200);
    expect(response.body).toMatchObject({
      name: "recursor-bridge",
      version: "0.1.0",
      protocol_version: "1.0",
      supported_agents: ["claude-code"],
    });
    expect(response.body.features).toContain("health_verification");
  });

  it("lists active sessions", async () => {
    const { app, activeSession } = createApp();

    const response = await request(app)
      .get("/api/v1/sessions")
      .set("Authorization", "Bearer test-bridge-token");

    expect(response.status).toBe(200);
    expect(response.body).toMatchObject({
      total: 1,
      sessions: [
        expect.objectContaining({
          id: activeSession.id,
          agent_type: activeSession.agent,
          title: activeSession.title,
        }),
      ],
    });
  });

  it("returns a single session detail document", async () => {
    const { app, activeSession } = createApp();

    const response = await request(app)
      .get(`/api/v1/sessions/${activeSession.id}`)
      .set("Authorization", "Bearer test-bridge-token");

    expect(response.status).toBe(200);
    expect(response.body).toMatchObject({
      id: activeSession.id,
      agent_type: activeSession.agent,
      title: activeSession.title,
      recent_events: [],
    });
  });

  it("returns 404 for unknown sessions", async () => {
    const { app } = createApp();

    const response = await request(app)
      .get("/api/v1/sessions/unknown")
      .set("Authorization", "Bearer test-bridge-token");

    expect(response.status).toBe(404);
    expect(response.body).toMatchObject({
      code: "SESSION_NOT_FOUND",
    });
  });
});
