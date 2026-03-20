import http from "http";
import express from "express";
import cors from "cors";
import { config } from "./config";
import { ConnectionManager } from "./websocket/connection_manager";
import { MessageHandler } from "./websocket/message_handler";
import { WebSocketServer } from "./websocket/server";
import { AgentSessionManager } from "./agents/session_manager";
import { AgentSdkAdapter } from "./agents/agent_sdk_adapter";
import { GitService } from "./git/git_service";
import { EventQueue } from "./hooks/event_queue";
import { createHooksRouter } from "./hooks/receiver";
import { Dispatcher } from "./notifications/dispatcher";
import { rateLimiter } from "./auth/rate_limiter";
import { createApiRouter } from "./http/api_router";

function log(msg: string): void {
  console.log(`[${new Date().toISOString()}] [Server] ${msg}`);
}

export async function startServer(): Promise<void> {
  const connectionManager = new ConnectionManager();
  const agentSessionManager = new AgentSessionManager();
  const agentSdkAdapter = new AgentSdkAdapter(agentSessionManager, connectionManager);
  const gitService = new GitService(config.ALLOWED_PROJECT_ROOT);
  const eventQueue = new EventQueue();

  const _dispatcher = new Dispatcher(connectionManager, eventQueue);

  const messageHandler = new MessageHandler(
    connectionManager,
    agentSdkAdapter,
    agentSessionManager,
    gitService,
    eventQueue,
  );

  const app = express();
  app.use(cors());
  app.use(express.json());
  app.use(rateLimiter);

  const apiRouter = createApiRouter(connectionManager, agentSessionManager);
  const hooksRouter = createHooksRouter(eventQueue, connectionManager);

  app.use("/api/v1", apiRouter);
  app.use("/api/v1/hooks", hooksRouter);

  app.get("/health", (_req, res) => {
    res.json({ status: "ok", timestamp: new Date().toISOString() });
  });
  app.use("/hooks", hooksRouter);

  const httpServer = http.createServer(app);

  const _wsServer = new WebSocketServer(httpServer, connectionManager, messageHandler);

  await new Promise<void>((resolve) => {
    httpServer.listen(config.PORT, () => {
      log(`Bridge server listening on port ${config.PORT}`);
      log(`Allowed project root: ${config.ALLOWED_PROJECT_ROOT}`);
      resolve();
    });
  });

  const shutdown = (signal: string) => {
    log(`Received ${signal}, shutting down...`);
    httpServer.close(() => {
      log("HTTP server closed");
      process.exit(0);
    });

    setTimeout(() => {
      log("Forced shutdown after timeout");
      process.exit(1);
    }, 10_000).unref();
  };

  process.on("SIGTERM", () => shutdown("SIGTERM"));
  process.on("SIGINT", () => shutdown("SIGINT"));
}
