import { v4 as uuidv4 } from "uuid";
import { AgentSessionManager } from "./session_manager";
import type { ConnectionManager } from "../websocket/connection_manager";
import type {
  ApprovalResponsePayload,
  BridgeMessage,
  ErrorPayload,
  MessagePayload,
  SessionEndPayload,
  SessionReadyPayload,
  SessionStartPayload,
  SupportedAgent,
} from "../types";

function log(msg: string): void {
  console.log(`[${new Date().toISOString()}] [AgentSdkAdapter] ${msg}`);
}

function ts(): string {
  return new Date().toISOString();
}

function resolveSupportedAgent(agent?: string): SupportedAgent {
  if (!agent || agent === "claude-code") {
    return "claude-code";
  }

  throw new Error(`Unsupported agent: ${agent}. Only claude-code is currently supported.`);
}

export class AgentSdkAdapter {
  private sessionManager: AgentSessionManager;
  private connectionManager: ConnectionManager;

  constructor(sessionManager: AgentSessionManager, connectionManager: ConnectionManager) {
    this.sessionManager = sessionManager;
    this.connectionManager = connectionManager;
  }

  async handleSessionStart(
    payload: SessionStartPayload,
    clientId: string,
    requestId?: string,
  ): Promise<void> {
    try {
      const agent = resolveSupportedAgent(payload.agent);
      const shouldResume = payload.resume === true && typeof payload.session_id === "string";
      let sessionId: string;

      if (shouldResume && payload.session_id) {
        await this.sessionManager.resumeSession(payload.session_id);
        sessionId = payload.session_id;
      } else {
        sessionId = await this.sessionManager.createSession({
          agent,
          sessionId: payload.session_id ?? undefined,
          workingDirectory: payload.working_directory,
          systemPrompt: payload.system_prompt,
          model: payload.model,
        });
      }

      this.connectionManager.addSessionToClient(clientId, sessionId);

      const session = this.sessionManager.getSession(sessionId);
      if (!session) {
        throw new Error(`Session not found after start: ${sessionId}`);
      }

      const readyMsg: BridgeMessage<SessionReadyPayload> = {
        type: "session_ready",
        id: requestId ?? uuidv4(),
        timestamp: ts(),
        payload: {
          session_id: sessionId,
          agent: session.agent,
          working_directory: session.working_directory,
          status: "ready",
          model: session.model,
        },
      };
      this.connectionManager.sendToClient(clientId, readyMsg);
      log(`Session started: ${sessionId} for client ${clientId}`);
    } catch (err) {
      log(`Failed to start session: ${String(err)}`);
      const errorMsg: BridgeMessage<ErrorPayload> = {
        type: "error",
        id: requestId ?? uuidv4(),
        timestamp: ts(),
        payload: {
          code: "BRIDGE_ERROR",
          message: String(err),
          request_type: "session_start",
          recoverable: false,
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
          code: "AGENT_ERROR",
          message: String(err),
          request_type: "message",
          session_id: payload.session_id,
          recoverable: true,
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
        payload.modifications,
      );
    } catch (err) {
      log(`Failed to handle approval response: ${String(err)}`);
      const errorMsg: BridgeMessage<ErrorPayload> = {
        type: "error",
        id: uuidv4(),
        timestamp: ts(),
        payload: {
          code: "TOOL_ERROR",
          message: String(err),
          request_type: "approval_response",
          session_id: payload.session_id,
          recoverable: true,
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
