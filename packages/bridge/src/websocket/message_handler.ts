import path from "path";
import { v4 as uuidv4 } from "uuid";
import { config } from "../config";
import type { ConnectionManager } from "./connection_manager";
import type { AgentSdkAdapter } from "../agents/agent_sdk_adapter";
import type { GitService } from "../git/git_service";
import type {
  BridgeMessage,
  AuthPayload,
  ConnectionAckPayload,
  ConnectionErrorPayload,
  SessionStartPayload,
  MessagePayload,
  ApprovalResponsePayload,
  SessionEndPayload,
  GitDiffPayload,
  GitCommitPayload,
  FileListPayload,
  FileReadPayload,
  ErrorPayload,
  HeartbeatPongPayload,
  FileListResponsePayload,
  FileReadResponsePayload,
} from "../types";
import type { AgentSessionManager } from "../agents/session_manager";
import { FileService } from "../files/file_service";

function log(msg: string): void {
  console.log(`[${new Date().toISOString()}] [MessageHandler] ${msg}`);
}

function ts(): string {
  return new Date().toISOString();
}

function errorMsg(
  code: string,
  message: string,
  requestType?: string
): BridgeMessage<ErrorPayload> {
  return {
    type: "error",
    id: uuidv4(),
    timestamp: ts(),
    payload: { code, message, request_type: requestType },
  };
}

export class MessageHandler {
  private fileService: FileService;

  constructor(
    private connectionManager: ConnectionManager,
    private agentSdkAdapter: AgentSdkAdapter,
    private agentSessionManager: AgentSessionManager,
    private gitService: GitService
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
        errorMsg("PARSE_ERROR", "Invalid JSON message")
      );
      return;
    }

    const { type, payload } = msg;

    // Auth is allowed without authentication
    if (type === "auth") {
      await this.handleAuth(clientId, payload as AuthPayload);
      return;
    }

    // Heartbeat is allowed without authentication (but only if already authenticated in practice)
    if (type === "heartbeat_ping") {
      this.handleHeartbeat(clientId);
      return;
    }

    // All other messages require authentication
    const client = this.connectionManager.getClient(clientId);
    if (!client || !client.authenticated) {
      this.connectionManager.sendToClient(
        clientId,
        {
          type: "connection_error",
          id: uuidv4(),
          timestamp: ts(),
          payload: {
            code: "NOT_AUTHENTICATED",
            message: "Client must authenticate before sending messages",
          } as ConnectionErrorPayload,
        }
      );
      return;
    }

    try {
      switch (type) {
        case "session_start":
          await this.agentSdkAdapter.handleSessionStart(payload as SessionStartPayload, clientId);
          break;

        case "message":
          await this.agentSdkAdapter.handleMessage(payload as MessagePayload, clientId);
          break;

        case "approval_response":
          await this.agentSdkAdapter.handleApprovalResponse(payload as ApprovalResponsePayload, clientId);
          break;

        case "session_end":
          this.agentSdkAdapter.handleSessionEnd(payload as SessionEndPayload);
          break;

        case "git_status_request":
          await this.handleGitStatusRequest(clientId, msg.id);
          break;

        case "git_commit":
          await this.handleGitCommit(clientId, payload as GitCommitPayload);
          break;

        case "git_diff":
          await this.handleGitDiff(clientId, payload as GitDiffPayload, msg.id);
          break;

        case "file_list":
          await this.handleFileList(clientId, payload as FileListPayload);
          break;

        case "file_read":
          await this.handleFileRead(clientId, payload as FileReadPayload);
          break;

        case "notification_ack":
          // no-op in this implementation
          break;

        default:
          log(`Unknown message type: ${type} from client ${clientId}`);
          this.connectionManager.sendToClient(
            clientId,
            errorMsg("UNKNOWN_TYPE", `Unknown message type: ${type}`, type)
          );
      }
    } catch (err) {
      log(`Error handling ${type} for client ${clientId}: ${String(err)}`);
      this.connectionManager.sendToClient(
        clientId,
        errorMsg("HANDLER_ERROR", String(err), type)
      );
    }
  }

  private async handleAuth(clientId: string, payload: AuthPayload): Promise<void> {
    if (!payload?.token || payload.token !== config.BRIDGE_TOKEN) {
      this.connectionManager.sendToClient(clientId, {
        type: "connection_error",
        id: uuidv4(),
        timestamp: ts(),
        payload: {
          code: "INVALID_TOKEN",
          message: "Authentication failed: invalid token",
        } as ConnectionErrorPayload,
      });
      log(`Auth failed for client ${clientId}`);
      return;
    }

    this.connectionManager.authenticateClient(clientId);

    const activeSessions = this.agentSessionManager.getActiveSessions();

    const ackMsg: BridgeMessage<ConnectionAckPayload> = {
      type: "connection_ack",
      id: uuidv4(),
      timestamp: ts(),
      payload: {
        client_id: clientId,
        active_sessions: activeSessions,
      },
    };
    this.connectionManager.sendToClient(clientId, ackMsg);
    log(`Auth succeeded for client ${clientId}`);
  }

  private handleHeartbeat(clientId: string): void {
    const pong: BridgeMessage<HeartbeatPongPayload> = {
      type: "heartbeat_pong",
      id: uuidv4(),
      timestamp: ts(),
      payload: {},
    };
    this.connectionManager.sendToClient(clientId, pong);
  }

  private async handleGitStatusRequest(clientId: string, requestId?: string): Promise<void> {
    const status = await this.gitService.getStatus();
    this.connectionManager.sendToClient(clientId, {
      type: "git_status_response",
      id: uuidv4(),
      timestamp: ts(),
      payload: { ...status, request_id: requestId },
    });
  }

  private async handleGitCommit(clientId: string, payload: GitCommitPayload): Promise<void> {
    await this.gitService.commit(payload.message, payload.files);
    this.connectionManager.sendToClient(clientId, {
      type: "git_status_response",
      id: uuidv4(),
      timestamp: ts(),
      payload: { ...(await this.gitService.getStatus()) },
    });
  }

  private async handleGitDiff(
    clientId: string,
    payload: GitDiffPayload,
    requestId?: string
  ): Promise<void> {
    const files = await this.gitService.getDiff(payload.files, payload.cached);
    this.connectionManager.sendToClient(clientId, {
      type: "git_diff_response",
      id: uuidv4(),
      timestamp: ts(),
      payload: { files, request_id: requestId },
    });
  }

  private async handleFileList(clientId: string, payload: FileListPayload): Promise<void> {
    const dirPath = path.resolve(payload.path);
    const result = await this.fileService.listDirectory(dirPath, {
      offset: payload.offset,
      limit: payload.limit,
      includeHidden: payload.includeHidden,
    });

    // Map FileService entries to the wire FileEntry shape (includes path)
    const entries = result.entries.map((e) => ({
      name: e.name,
      path: path.join(dirPath, e.name),
      type: e.type,
      size: e.size,
      modified: e.modifiedAt,
    }));

    const resp: BridgeMessage<FileListResponsePayload> = {
      type: "file_list_response",
      id: uuidv4(),
      timestamp: ts(),
      payload: {
        path: dirPath,
        entries,
        total: result.total,
        offset: result.offset,
        limit: result.limit,
        hasMore: result.hasMore,
        request_id: payload.request_id,
      },
    };
    this.connectionManager.sendToClient(clientId, resp);
  }

  private async handleFileRead(clientId: string, payload: FileReadPayload): Promise<void> {
    const filePath = path.resolve(payload.path);
    const result = await this.fileService.readFile(filePath, {
      offset: payload.offset,
      limit: payload.limit,
    });

    const resp: BridgeMessage<FileReadResponsePayload> = {
      type: "file_read_response",
      id: uuidv4(),
      timestamp: ts(),
      payload: {
        path: filePath,
        content: result.content,
        encoding: "utf8",
        totalLines: result.totalLines,
        offset: result.offset,
        limit: result.limit,
        hasMore: result.hasMore,
        request_id: payload.request_id,
      },
    };
    this.connectionManager.sendToClient(clientId, resp);
  }
}
