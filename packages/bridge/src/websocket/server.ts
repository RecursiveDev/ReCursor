import { WebSocketServer as WsServer, type WebSocket } from "ws";
import { v4 as uuidv4 } from "uuid";
import type { IncomingMessage, Server } from "http";
import type { ConnectionManager } from "./connection_manager";
import type { MessageHandler } from "./message_handler";
import { buildBridgeUrl, describeConnectionMode, detectConnectionMode } from "./connection_mode";

const PING_INTERVAL_MS = 30_000;

function log(msg: string): void {
  console.log(`[${new Date().toISOString()}] [WebSocketServer] ${msg}`);
}

function getHeaderValue(req: IncomingMessage, headerName: string): string | undefined {
  const value = req.headers[headerName];
  if (typeof value === "string") {
    return value.split(",")[0]?.trim();
  }

  return value?.[0]?.trim();
}

function isSecureTransport(req: IncomingMessage): boolean {
  const forwardedProto = getHeaderValue(req, "x-forwarded-proto")?.toLowerCase();
  const forwardedSsl = getHeaderValue(req, "x-forwarded-ssl")?.toLowerCase();

  const socketEncrypted =
    "encrypted" in req.socket &&
    Boolean((req.socket as typeof req.socket & { encrypted?: boolean }).encrypted);

  return (
    socketEncrypted ||
    forwardedProto === "https" ||
    forwardedProto === "wss" ||
    forwardedSsl === "on"
  );
}

export class WebSocketServer {
  private wss: WsServer;
  private pingInterval: NodeJS.Timeout | null = null;

  constructor(
    httpServer: Server,
    private connectionManager: ConnectionManager,
    private messageHandler: MessageHandler,
  ) {
    this.wss = new WsServer({
      server: httpServer,
      perMessageDeflate: {
        zlibDeflateOptions: { chunkSize: 1024, memLevel: 7, level: 3 },
        zlibInflateOptions: { chunkSize: 10 * 1024 },
        clientNoContextTakeover: true,
        serverNoContextTakeover: true,
        serverMaxWindowBits: 10,
        concurrencyLimit: 10,
        threshold: 1024,
      },
    });
    this.setup();
  }

  private setup(): void {
    this.wss.on("connection", (ws: WebSocket, req: IncomingMessage) => {
      const clientId = uuidv4();
      const secureTransport = isSecureTransport(req);
      const remoteAddress =
        getHeaderValue(req, "x-forwarded-for") ?? req.socket.remoteAddress ?? undefined;
      const host =
        getHeaderValue(req, "x-forwarded-host") ?? getHeaderValue(req, "host") ?? undefined;
      const connectionMode = detectConnectionMode({
        remoteAddress,
        host,
        secureTransport,
      });
      const connectionModeDescription = describeConnectionMode(connectionMode, {
        remoteAddress,
        host,
      });
      const bridgeUrl = buildBridgeUrl(host, secureTransport);

      log(`New connection: ${clientId} from ${remoteAddress ?? "unknown"} (${connectionMode})`);

      this.connectionManager.addClient(clientId, ws, {
        remoteAddress,
        connectionMode,
        connectionModeDescription,
        bridgeUrl,
      });

      ws.on("message", (data) => {
        const raw = data.toString();
        this.messageHandler.handle(clientId, raw).catch((err) => {
          log(`Unhandled error from client ${clientId}: ${String(err)}`);
        });
      });

      ws.on("close", (code, reason) => {
        log(`Client disconnected: ${clientId} (code=${code}, reason=${reason.toString()})`);
        this.connectionManager.removeClient(clientId);
      });

      ws.on("error", (err) => {
        log(`WebSocket error for client ${clientId}: ${String(err)}`);
        this.connectionManager.removeClient(clientId);
      });
    });

    this.wss.on("error", (err) => {
      log(`WebSocketServer error: ${String(err)}`);
    });

    this.startPingInterval();
  }

  private startPingInterval(): void {
    this.pingInterval = setInterval(() => {
      this.wss.clients.forEach((ws) => {
        if (ws.readyState === ws.OPEN) {
          ws.ping();
        }
      });
    }, PING_INTERVAL_MS);
  }

  close(): void {
    if (this.pingInterval) {
      clearInterval(this.pingInterval);
      this.pingInterval = null;
    }
    this.wss.close();
  }
}
