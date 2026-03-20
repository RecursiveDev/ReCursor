import path from "path";
import { v4 as uuidv4 } from "uuid";
import { config } from "../config";
import type { ConnectionManager } from "./connection_manager";
import type { AgentSdkAdapter } from "../agents/agent_sdk_adapter";
import type { GitService } from "../git/git_service";
import { SUPPORTED_AGENTS } from "../types";
import type {
  ActiveSessionPayload,
  ApprovalResponsePayload,
  AuthPayload,
  BridgeMessage,
  ConnectionAckPayload,
  ConnectionErrorPayload,
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
  HeartbeatPongPayload,
  MessagePayload,
  NotificationAckPayload,
  SessionEndPayload,
  SessionStartPayload,
} from "../types";
import type { AgentSessionManager } from "../agents/session_manager";
import { FileService } from "../files/file_service";
import type { EventQueue } from "../hooks/event_queue";

const SERVER_VERSION = "0.1.0";

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
        errorMsg("BRIDGE_ERROR", "Invalid JSON message"),
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
        case "session_start":
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
            errorMsg("BRIDGE_ERROR", `Unknown message type: ${type}`, type),
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

    this.connectionManager.authenticateClient(clientId);

    const activeSessions = this.agentSessionManager.getActiveSessions().map(mapActiveSession);

    const ackMsg: BridgeMessage<ConnectionAckPayload> = {
      type: "connection_ack",
      id: requestId ?? uuidv4(),
      timestamp: ts(),
      payload: {
        server_version: SERVER_VERSION,
        supported_agents: [...SUPPORTED_AGENTS],
        active_sessions: activeSessions,
      },
    };
    this.connectionManager.sendToClient(clientId, ackMsg);

    for (const queuedMessage of this.eventQueue.replay()) {
      this.connectionManager.sendToClient(clientId, queuedMessage);
    }

    log(`Auth succeeded for client ${clientId}`);
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
