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

function log(msg: string): void {
  console.log(`[${new Date().toISOString()}] [Server] ${msg}`);
}

export async function startServer(): Promise<void> {
  // Compose dependencies
  const connectionManager = new ConnectionManager();
  const agentSessionManager = new AgentSessionManager();
  const agentSdkAdapter = new AgentSdkAdapter(agentSessionManager, connectionManager);
  const gitService = new GitService(config.ALLOWED_PROJECT_ROOT);
  const eventQueue = new EventQueue();

  // Dispatcher subscribes to event bus and forwards to clients
  const _dispatcher = new Dispatcher(connectionManager);

  const messageHandler = new MessageHandler(
    connectionManager,
    agentSdkAdapter,
    agentSessionManager,
    gitService
  );

  // Express app
  const app = express();
  app.use(cors());
  app.use(express.json());
  app.use(rateLimiter);

  // Health check
  app.get("/health", (_req, res) => {
    res.json({ status: "ok", timestamp: new Date().toISOString() });
  });

  // Hook receiver
  const hooksRouter = createHooksRouter(eventQueue, connectionManager);
  app.use("/hooks", hooksRouter);

  // HTTP server
  const httpServer = http.createServer(app);

  // WebSocket server
  const _wsServer = new WebSocketServer(httpServer, connectionManager, messageHandler);

  // Start listening
  await new Promise<void>((resolve) => {
    httpServer.listen(config.PORT, () => {
      log(`Bridge server listening on port ${config.PORT}`);
      log(`Allowed project root: ${config.ALLOWED_PROJECT_ROOT}`);
      resolve();
    });
  });

  // Graceful shutdown
  const shutdown = (signal: string) => {
    log(`Received ${signal}, shutting down...`);
    httpServer.close(() => {
      log("HTTP server closed");
      process.exit(0);
    });

    // Force exit after 10s
    setTimeout(() => {
      log("Forced shutdown after timeout");
      process.exit(1);
    }, 10_000).unref();
  };

  process.on("SIGTERM", () => shutdown("SIGTERM"));
  process.on("SIGINT", () => shutdown("SIGINT"));
}
