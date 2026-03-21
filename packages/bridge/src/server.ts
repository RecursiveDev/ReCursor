import fs from "fs";
import http, { type Server as HttpServer } from "http";
import https from "https";
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

function createHttpServer(app: express.Express): HttpServer {
  if (!config.TLS_ENABLED || !config.BRIDGE_TLS_CERT_PATH || !config.BRIDGE_TLS_KEY_PATH) {
    log("Starting bridge without TLS (HTTP mode)");
    return http.createServer(app);
  }

  log(`Starting bridge with TLS cert ${config.BRIDGE_TLS_CERT_PATH}`);
  return https.createServer(
    {
      cert: fs.readFileSync(config.BRIDGE_TLS_CERT_PATH),
      key: fs.readFileSync(config.BRIDGE_TLS_KEY_PATH),
    },
    app,
  );
}

export interface BridgeRuntime {
  connectionManager: ConnectionManager;
  stop(): Promise<void>;
}

export async function createBridgeRuntime(): Promise<BridgeRuntime> {
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

  const httpServer = createHttpServer(app);
  const wsServer = new WebSocketServer(httpServer, connectionManager, messageHandler);

  await new Promise<void>((resolve) => {
    httpServer.listen(config.PORT, () => {
      log(`Bridge server listening on port ${config.PORT}`);
      log(`Allowed project root: ${config.ALLOWED_PROJECT_ROOT}`);
      if (config.ANTHROPIC_API_KEY) {
        log("Agent SDK features enabled");
      } else {
        log("Agent SDK features disabled (ANTHROPIC_API_KEY not configured)");
      }
      resolve();
    });
  });

  return {
    connectionManager,
    async stop(): Promise<void> {
      await new Promise<void>((resolve, reject) => {
        wsServer.close();
        httpServer.close((error) => {
          if (error) {
            reject(error);
            return;
          }
          resolve();
        });
      });
    },
  };
}

export async function startServer(): Promise<void> {
  const runtime = await createBridgeRuntime();

  const shutdown = (signal: string) => {
    log(`Received ${signal}, shutting down...`);
    runtime
      .stop()
      .then(() => {
        log("Bridge runtime closed");
        process.exit(0);
      })
      .catch((error) => {
        log(`Failed to close bridge runtime cleanly: ${String(error)}`);
        process.exit(1);
      });

    setTimeout(() => {
      log("Forced shutdown after timeout");
      process.exit(1);
    }, 10_000).unref();
  };

  process.on("SIGTERM", () => shutdown("SIGTERM"));
  process.on("SIGINT", () => shutdown("SIGINT"));

  await new Promise<void>(() => {
    // Keep the process alive while the bridge runtime is running.
  });
}
