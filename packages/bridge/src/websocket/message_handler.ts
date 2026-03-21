import path from "path";
import { v4 as uuidv4 } from "uuid";
import { config } from "../config";
import type { ConnectionManager } from "./connection_manager";
import type { AgentSdkAdapter } from "../agents/agent_sdk_adapter";
import type { GitService } from "../git/git_service";
import { SUPPORTED_AGENTS } from "../types";
import type {
  AcknowledgeWarningPayload,
  AcknowledgmentAcceptedPayload,
  ActiveSessionPayload,
  ApprovalResponsePayload,
  AuthPayload,
  BridgeMessage,
  ConnectionAckPayload,
  ConnectionErrorPayload,
  ConnectionPurpose,
  ErrorPayload,
  FileListPayload,
  FileListResponsePayload,
  FileReadPayload,
  FileReadResponsePayload,
  GitCommitPayload,
  GitDiffPayload,
  GitDiffResponsePayload,
  GitStatusPayload,
  GitStatusRequestPayload,
  HealthCheckPayload,
  HealthStatusPayload,
  HeartbeatPongPayload,
  MessagePayload,
  NotificationAckPayload,
  SessionEndPayload,
  SessionStartPayload,
} from "../types";
import type { AgentSessionManager } from "../agents/session_manager";
import { FileService } from "../files/file_service";
import type { EventQueue } from "../hooks/event_queue";
import type { ConnectionMode } from "./connection_mode";

const SERVER_VERSION = "0.1.0";
const DEFAULT_CONNECTION_MODE: ConnectionMode = "secure_remote";
const DEFAULT_BRIDGE_URL = "wss://bridge.local";
const WARNING_CODE_DIRECT_PUBLIC = "DIRECT_PUBLIC_CONNECTION";

function log(msg: string): void {
  console.log(`[${new Date().toISOString()}] [MessageHandler] ${msg}`);
}

function ts(): string {
  return new Date().toISOString();
}

function errorMsg(
  code: string,
  message: string,
  requestType?: string,
  sessionId?: string,
): BridgeMessage<ErrorPayload> {
  return {
    type: "error",
    id: uuidv4(),
    timestamp: ts(),
    payload: {
      code,
      message,
      request_type: requestType,
      session_id: sessionId,
      recoverable: code !== "AUTH_FAILED",
    },
  };
}

function mapActiveSession(session: {
  id: string;
  agent: "claude-code";
  title: string;
  working_directory: string;
  status: "active" | "idle" | "closed";
}): ActiveSessionPayload {
  return {
    session_id: session.id,
    agent: session.agent,
    title: session.title,
    working_directory: session.working_directory,
    status: session.status,
  };
}

function parseClientTimestamp(value?: string): number | null {
  if (!value) {
    return null;
  }

  const parsed = Date.parse(value);
  return Number.isNaN(parsed) ? null : parsed;
}

function clampLatency(value: number): number {
  return value < 0 ? 0 : value;
}

function normalizeConnectionPurpose(value?: string): ConnectionPurpose {
  return value === "probe" ? "probe" : "primary";
}

export class MessageHandler {
  private fileService: FileService;

  constructor(
    private connectionManager: ConnectionManager,
    private agentSdkAdapter: AgentSdkAdapter,
    private agentSessionManager: AgentSessionManager,
    private gitService: GitService,
    private eventQueue: EventQueue,
  ) {
    this.fileService = new FileService(config.ALLOWED_PROJECT_ROOT);
  }

  async handle(clientId: string, rawMessage: string): Promise<void> {
    let msg: BridgeMessage<unknown>;

    try {
      msg = JSON.parse(rawMessage) as BridgeMessage<unknown>;
    } catch {
      this.connectionManager.sendToClient(
        clientId,
        errorMsg("PROTO_INVALID_MESSAGE", "Invalid JSON message"),
      );
      return;
    }

    const { type, payload, id } = msg;

    if (type === "auth") {
      await this.handleAuth(clientId, payload as AuthPayload, id);
      return;
    }

    if (type === "heartbeat_ping") {
      this.handleHeartbeat(clientId, id);
      return;
    }

    const client = this.connectionManager.getClient(clientId);
    if (!client || !client.authenticated) {
      this.connectionManager.sendToClient(clientId, {
        type: "connection_error",
        id: id ?? uuidv4(),
        timestamp: ts(),
        payload: {
          code: "AUTH_FAILED",
          message: "Client must authenticate before sending messages",
        } as ConnectionErrorPayload,
      });
      return;
    }

    try {
      switch (type) {
        case "health_check":
          this.handleHealthCheck(clientId, payload as HealthCheckPayload, id);
          break;

        case "acknowledge_warning":
          this.handleWarningAcknowledgment(clientId, payload as AcknowledgeWarningPayload, id);
          break;

        case "session_start":
          if (client.purpose === "probe") {
            this.connectionManager.sendToClient(
              clientId,
              errorMsg(
                "PROTO_SEQUENCE_ERROR",
                "Probe connections cannot start sessions",
                "session_start",
              ),
            );
            break;
          }

          await this.agentSdkAdapter.handleSessionStart(
            payload as SessionStartPayload,
            clientId,
            id,
          );
          break;

        case "message":
          await this.agentSdkAdapter.handleMessage(payload as MessagePayload, clientId);
          break;

        case "approval_response":
          await this.agentSdkAdapter.handleApprovalResponse(
            payload as ApprovalResponsePayload,
            clientId,
          );
          break;

        case "session_end":
          this.agentSdkAdapter.handleSessionEnd(payload as SessionEndPayload);
          break;

        case "git_status_request":
          await this.handleGitStatusRequest(
            clientId,
            (payload as GitStatusRequestPayload | undefined)?.session_id,
            id,
          );
          break;

        case "git_commit":
          await this.handleGitCommit(clientId, payload as GitCommitPayload, id);
          break;

        case "git_diff":
          await this.handleGitDiff(clientId, payload as GitDiffPayload, id);
          break;

        case "file_list":
          await this.handleFileList(clientId, payload as FileListPayload, id);
          break;

        case "file_read":
          await this.handleFileRead(clientId, payload as FileReadPayload, id);
          break;

        case "notification_ack":
          this.handleNotificationAck(payload as NotificationAckPayload);
          break;

        default:
          log(`Unknown message type: ${type} from client ${clientId}`);
          this.connectionManager.sendToClient(
            clientId,
            errorMsg("PROTO_INVALID_MESSAGE", `Unknown message type: ${type}`, type),
          );
      }
    } catch (err) {
      const sessionId =
        typeof payload === "object" && payload !== null && "session_id" in payload
          ? String((payload as { session_id?: unknown }).session_id ?? "")
          : undefined;
      log(`Error handling ${type} for client ${clientId}: ${String(err)}`);
      this.connectionManager.sendToClient(
        clientId,
        errorMsg("BRIDGE_ERROR", String(err), type, sessionId),
      );
    }
  }

  private async handleAuth(
    clientId: string,
    payload: AuthPayload,
    requestId?: string,
  ): Promise<void> {
    if (!payload?.token || payload.token !== config.BRIDGE_TOKEN) {
      this.connectionManager.sendToClient(clientId, {
        type: "connection_error",
        id: requestId ?? uuidv4(),
        timestamp: ts(),
        payload: {
          code: "AUTH_FAILED",
          message: "Invalid or expired token",
        } as ConnectionErrorPayload,
      });
      log(`Auth failed for client ${clientId}`);
      return;
    }

    const client = this.connectionManager.getClient(clientId);
    if (client?.connectionMode === "misconfigured") {
      this.connectionManager.sendToClient(clientId, {
        type: "connection_error",
        id: requestId ?? uuidv4(),
        timestamp: ts(),
        payload: {
          code: "INSECURE_TRANSPORT",
          message:
            "Bridge requires wss:// (WebSocket Secure). Unencrypted ws:// connections are blocked.",
          documentation_url: "https://docs.recursor.dev/security/tls-required",
          remediation: "Enable TLS on your bridge server and use wss:// URLs",
        } as ConnectionErrorPayload,
      });
      log(`Rejected insecure transport for client ${clientId}`);
      return;
    }

    const purpose = normalizeConnectionPurpose(payload?.purpose);
    (this.connectionManager as Partial<ConnectionManager>).setClientPurpose?.(clientId, purpose);
    this.connectionManager.authenticateClient(clientId);

    const activeSessions = this.agentSessionManager.getActiveSessions().map(mapActiveSession);
    const connectionMode = client?.connectionMode ?? DEFAULT_CONNECTION_MODE;
    const connectionModeDescription =
      client?.connectionModeDescription ?? "Secure tunnel connection";
    const bridgeUrl = client?.bridgeUrl ?? DEFAULT_BRIDGE_URL;

    const ackMsg: BridgeMessage<ConnectionAckPayload> = {
      type: "connection_ack",
      id: requestId ?? uuidv4(),
      timestamp: ts(),
      payload: {
        server_version: SERVER_VERSION,
        supported_agents: [...SUPPORTED_AGENTS],
        connection_mode: connectionMode,
        connection_mode_description: connectionModeDescription,
        bridge_url: bridgeUrl,
        requires_health_verification: true,
        active_sessions: activeSessions,
        purpose,
      },
    };
    this.connectionManager.sendToClient(clientId, ackMsg);

    for (const queuedMessage of this.eventQueue.replay()) {
      this.connectionManager.sendToClient(clientId, queuedMessage);
    }

    log(`Auth succeeded for client ${clientId} (purpose=${purpose})`);
  }

  private handleHeartbeat(clientId: string, requestId?: string): void {
    const pong: BridgeMessage<HeartbeatPongPayload> = {
      type: "heartbeat_pong",
      id: requestId ?? uuidv4(),
      timestamp: ts(),
      payload: {},
    };
    this.connectionManager.sendToClient(clientId, pong);
  }

  private handleHealthCheck(
    clientId: string,
    payload: HealthCheckPayload,
    requestId?: string,
  ): void {
    const client = this.connectionManager.getClient(clientId);
    const connectionMode = client?.connectionMode ?? DEFAULT_CONNECTION_MODE;
    const clientTimestamp = parseClientTimestamp(payload.timestamp);
    const now = Date.now();
    const clockSkewMs =
      clientTimestamp === null ? Number.POSITIVE_INFINITY : Math.abs(now - clientTimestamp);
    const latencyMs = clientTimestamp === null ? 0 : clampLatency(now - clientTimestamp);
    const clockSync = clockSkewMs <= 5 * 60 * 1000;

    const checks: HealthStatusPayload["checks"] = {
      tls_valid: connectionMode !== "misconfigured",
      clock_sync: clockSync,
      version_compatible: true,
      token_permissions: true,
    };

    const directPublicWarningRequired =
      connectionMode === "direct_public" && client?.warningAcknowledged !== true;

    const healthPayload: HealthStatusPayload = {
      status: directPublicWarningRequired ? "warning" : "healthy",
      connection_mode: connectionMode,
      warnings: directPublicWarningRequired ? [WARNING_CODE_DIRECT_PUBLIC] : [],
      checks,
      server_timestamp: ts(),
      latency_ms: latencyMs,
      ready: !directPublicWarningRequired && Object.values(checks).every(Boolean),
      ...(directPublicWarningRequired
        ? {
            warning_details: {
              [WARNING_CODE_DIRECT_PUBLIC]:
                "Connection is over public internet without tunnel. Certificate validation is required.",
            },
            requires_acknowledgment: true,
          }
        : {}),
    };

    this.connectionManager.sendToClient(clientId, {
      type: "health_status",
      id: requestId ?? uuidv4(),
      timestamp: ts(),
      payload: healthPayload,
    });
  }

  private handleWarningAcknowledgment(
    clientId: string,
    payload: AcknowledgeWarningPayload,
    requestId?: string,
  ): void {
    const client = this.connectionManager.getClient(clientId);

    if (!client || client.connectionMode !== "direct_public") {
      this.connectionManager.sendToClient(
        clientId,
        errorMsg(
          "PROTO_SEQUENCE_ERROR",
          "Warning acknowledgment is only valid for direct public connections",
          "acknowledge_warning",
        ),
      );
      return;
    }

    if (!payload.acknowledged || payload.warning_code !== WARNING_CODE_DIRECT_PUBLIC) {
      this.connectionManager.sendToClient(
        clientId,
        errorMsg(
          "PROTO_INVALID_MESSAGE",
          "Invalid warning acknowledgment payload",
          "acknowledge_warning",
        ),
      );
      return;
    }

    this.connectionManager.acknowledgeWarning(clientId);

    const response: BridgeMessage<AcknowledgmentAcceptedPayload> = {
      type: "acknowledgment_accepted",
      id: requestId ?? uuidv4(),
      timestamp: ts(),
      payload: {
        warning_code: payload.warning_code,
        ready: true,
        session_timeout: "8h",
      },
    };

    this.connectionManager.sendToClient(clientId, response);
  }

  private handleNotificationAck(payload: NotificationAckPayload): void {
    if (!Array.isArray(payload.notification_ids)) {
      return;
    }

    this.eventQueue.acknowledgeNotifications(
      payload.notification_ids.filter((value): value is string => typeof value === "string"),
    );
  }

  private async handleGitStatusRequest(
    clientId: string,
    sessionId: string | undefined,
    requestId?: string,
  ): Promise<void> {
    const status = await this.gitService.getStatus();
    const responsePayload: GitStatusPayload = {
      ...status,
      session_id: sessionId,
    };

    this.connectionManager.sendToClient(clientId, {
      type: "git_status_response",
      id: requestId ?? uuidv4(),
      timestamp: ts(),
      payload: responsePayload,
    });
  }

  private async handleGitCommit(
    clientId: string,
    payload: GitCommitPayload,
    requestId?: string,
  ): Promise<void> {
    await this.gitService.commit(payload.message, payload.files);

    this.connectionManager.sendToClient(clientId, {
      type: "git_status_response",
      id: requestId ?? uuidv4(),
      timestamp: ts(),
      payload: {
        ...(await this.gitService.getStatus()),
        session_id: payload.session_id,
      } satisfies GitStatusPayload,
    });
  }

  private async handleGitDiff(
    clientId: string,
    payload: GitDiffPayload,
    requestId?: string,
  ): Promise<void> {
    const files = await this.gitService.getDiff(payload.files, payload.cached);
    const responsePayload: GitDiffResponsePayload = {
      session_id: payload.session_id,
      files,
    };

    this.connectionManager.sendToClient(clientId, {
      type: "git_diff_response",
      id: requestId ?? uuidv4(),
      timestamp: ts(),
      payload: responsePayload,
    });
  }

  private async handleFileList(
    clientId: string,
    payload: FileListPayload,
    requestId?: string,
  ): Promise<void> {
    const dirPath = path.resolve(payload.path);
    const result = await this.fileService.listDirectory(dirPath, {
      offset: payload.offset,
      limit: payload.limit,
      includeHidden: payload.includeHidden,
    });

    const entries = result.entries.map((entry) => ({
      name: entry.name,
      path: path.join(dirPath, entry.name),
      type: entry.type,
      size: entry.size,
      modified: entry.modifiedAt,
    }));

    const responsePayload: FileListResponsePayload = {
      session_id: payload.session_id,
      path: dirPath,
      entries,
      total: result.total,
      offset: result.offset,
      limit: result.limit,
      hasMore: result.hasMore,
    };

    this.connectionManager.sendToClient(clientId, {
      type: "file_list_response",
      id: requestId ?? uuidv4(),
      timestamp: ts(),
      payload: responsePayload,
    });
  }

  private async handleFileRead(
    clientId: string,
    payload: FileReadPayload,
    requestId?: string,
  ): Promise<void> {
    const filePath = path.resolve(payload.path);
    const result = await this.fileService.readFile(filePath, {
      offset: payload.offset,
      limit: payload.limit,
    });

    const responsePayload: FileReadResponsePayload = {
      session_id: payload.session_id,
      path: filePath,
      content: result.content,
      size: Buffer.byteLength(result.content, "utf8"),
      lines: result.totalLines,
      offset: result.offset,
      limit: result.limit,
      hasMore: result.hasMore,
      encoding: "utf8",
    };

    this.connectionManager.sendToClient(clientId, {
      type: "file_read_response",
      id: requestId ?? uuidv4(),
      timestamp: ts(),
      payload: responsePayload,
    });
  }
}
