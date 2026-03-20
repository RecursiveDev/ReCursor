import { Router, type Request } from "express";
import os from "os";
import { validateBridgeToken } from "../auth/token_validator";
import type { AgentSessionManager } from "../agents/session_manager";
import type { ConnectionManager } from "../websocket/connection_manager";
import { buildBridgeUrl, detectConnectionMode } from "../websocket/connection_mode";
import { SUPPORTED_AGENTS } from "../types";
import { VALID_EVENT_TYPES } from "../hooks/validator";

function getHeaderValue(req: Request, headerName: string): string | undefined {
  const value = req.headers[headerName];
  if (typeof value === "string") {
    return value.split(",")[0]?.trim();
  }

  return value?.[0]?.trim();
}

function detectRequestMode(req: Request) {
  const forwardedProto = getHeaderValue(req, "x-forwarded-proto")?.toLowerCase();
  const secureTransport = req.secure || forwardedProto === "https";
  const remoteAddress =
    getHeaderValue(req, "x-forwarded-for") ?? req.socket.remoteAddress ?? undefined;
  const host = getHeaderValue(req, "x-forwarded-host") ?? getHeaderValue(req, "host") ?? undefined;
  const connectionMode = detectConnectionMode({
    remoteAddress,
    host,
    secureTransport,
  });

  return {
    connectionMode,
    bridgeUrl: buildBridgeUrl(host, secureTransport),
  };
}

export function createApiRouter(
  connectionManager: ConnectionManager,
  agentSessionManager: AgentSessionManager,
): Router {
  const router = Router();

  router.get("/health", validateBridgeToken, (req, res) => {
    const { connectionMode } = detectRequestMode(req);
    res.json({
      status: "healthy",
      version: "0.1.0",
      uptime_seconds: Math.floor(process.uptime()),
      connection_mode: connectionMode,
      active_sessions: agentSessionManager.getActiveSessions().length,
      active_websockets: connectionManager.getAuthenticatedClientCount(),
      system: {
        platform: process.platform,
        node_version: process.version,
        memory_mb: Math.round(process.memoryUsage().rss / (1024 * 1024)),
        hostname: os.hostname(),
      },
      timestamp: new Date().toISOString(),
    });
  });

  router.get("/info", validateBridgeToken, (req, res) => {
    res.json({
      name: "recursor-bridge",
      version: "0.1.0",
      protocol_version: "1.0",
      features: ["websocket_sessions", "hook_events", "agent_sdk", "health_verification"],
      supported_agents: [...SUPPORTED_AGENTS],
      supported_hooks: [...VALID_EVENT_TYPES],
      limits: {
        max_sessions: 10,
        max_websocket_connections: 5,
        max_message_size_mb: 10,
        hook_timeout_seconds: 30,
      },
    });
  });

  router.get("/sessions", validateBridgeToken, (_req, res) => {
    const sessions = agentSessionManager.getActiveSessions().map((session) => ({
      id: session.id,
      agent_type: session.agent,
      title: session.title,
      working_directory: session.working_directory,
      status: session.status,
      created_at: session.created_at,
      last_activity_at: session.created_at,
      websocket_connected: connectionManager.getClientsForSession(session.id).length > 0,
      hook_count: 0,
    }));

    res.json({
      sessions,
      total: sessions.length,
    });
  });

  router.get("/sessions/:id", validateBridgeToken, (req, res) => {
    const sessionId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const session = agentSessionManager.getSession(sessionId);

    if (!session) {
      res.status(404).json({
        error: "NotFound",
        message: `Session not found: ${sessionId}`,
        code: "SESSION_NOT_FOUND",
      });
      return;
    }

    res.json({
      id: session.id,
      agent_type: session.agent,
      title: session.title,
      working_directory: session.working_directory,
      status: session.status,
      created_at: session.created_at,
      last_activity_at: session.created_at,
      websocket_connected: connectionManager.getClientsForSession(session.id).length > 0,
      hook_count: 0,
      recent_events: [],
    });
  });

  router.get("/ws", validateBridgeToken, (req, res) => {
    const { bridgeUrl } = detectRequestMode(req);
    res.status(400).json({
      error: "BadRequest",
      message: "WebSocket upgrade required",
      code: "WS_UPGRADE_REQUIRED",
      websocket_url: `${bridgeUrl}/api/v1/ws`,
    });
  });

  return router;
}
