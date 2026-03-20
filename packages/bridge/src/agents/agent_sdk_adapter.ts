import { v4 as uuidv4 } from "uuid";
import { AgentSessionManager } from "./session_manager";
import type { ConnectionManager } from "../websocket/connection_manager";
import type {
  SessionStartPayload,
  MessagePayload,
  ApprovalResponsePayload,
  SessionEndPayload,
  BridgeMessage,
  SessionReadyPayload,
  ErrorPayload,
} from "../types";

function log(msg: string): void {
  console.log(`[${new Date().toISOString()}] [AgentSdkAdapter] ${msg}`);
}

function ts(): string {
  return new Date().toISOString();
}

export class AgentSdkAdapter {
  private sessionManager: AgentSessionManager;
  private connectionManager: ConnectionManager;

  constructor(sessionManager: AgentSessionManager, connectionManager: ConnectionManager) {
    this.sessionManager = sessionManager;
    this.connectionManager = connectionManager;
  }

  async handleSessionStart(payload: SessionStartPayload, clientId: string): Promise<void> {
    try {
      const sessionId = await this.sessionManager.createSession({
        sessionId: payload.session_id,
        workingDirectory: payload.working_directory,
        systemPrompt: payload.system_prompt,
        model: payload.model,
      });

      this.connectionManager.addSessionToClient(clientId, sessionId);

      const sessions = this.sessionManager.getActiveSessions();
      const session = sessions.find((s) => s.id === sessionId);

      const readyMsg: BridgeMessage<SessionReadyPayload> = {
        type: "session_ready",
        id: uuidv4(),
        timestamp: ts(),
        payload: {
          session_id: sessionId,
          model: session?.model ?? "unknown",
        },
      };
      this.connectionManager.sendToClient(clientId, readyMsg);
      log(`Session started: ${sessionId} for client ${clientId}`);
    } catch (err) {
      log(`Failed to start session: ${String(err)}`);
      const errorMsg: BridgeMessage<ErrorPayload> = {
        type: "error",
        id: uuidv4(),
        timestamp: ts(),
        payload: {
          code: "SESSION_START_FAILED",
          message: String(err),
          request_type: "session_start",
        },
      };
      this.connectionManager.sendToClient(clientId, errorMsg);
    }
  }

  async handleMessage(payload: MessagePayload, clientId: string): Promise<void> {
    try {
      await this.sessionManager.sendMessage(payload.session_id, payload.content, clientId);
    } catch (err) {
      log(`Failed to send message: ${String(err)}`);
      const errorMsg: BridgeMessage<ErrorPayload> = {
        type: "error",
        id: uuidv4(),
        timestamp: ts(),
        payload: {
          code: "MESSAGE_FAILED",
          message: String(err),
          request_type: "message",
        },
      };
      this.connectionManager.sendToClient(clientId, errorMsg);
    }
  }

  async handleApprovalResponse(payload: ApprovalResponsePayload, clientId: string): Promise<void> {
    try {
      await this.sessionManager.executeToolCall(
        payload.session_id,
        payload.tool_call_id,
        payload.decision,
      );
    } catch (err) {
      log(`Failed to handle approval response: ${String(err)}`);
      const errorMsg: BridgeMessage<ErrorPayload> = {
        type: "error",
        id: uuidv4(),
        timestamp: ts(),
        payload: {
          code: "APPROVAL_FAILED",
          message: String(err),
          request_type: "approval_response",
        },
      };
      this.connectionManager.sendToClient(clientId, errorMsg);
    }
  }

  handleSessionEnd(payload: SessionEndPayload): void {
    this.sessionManager.closeSession(payload.session_id);
    log(`Session ended: ${payload.session_id}`);
  }
}
