import Anthropic from "@anthropic-ai/sdk";
import { v4 as uuidv4 } from "uuid";
import { config } from "../config";
import { eventBus } from "../notifications/event_bus";
import type {
  AgentSession,
  SessionConfig,
  StreamStartPayload,
  StreamChunkPayload,
  StreamEndPayload,
  ApprovalRequiredPayload,
  ToolCallPayload,
} from "../types";

function log(msg: string): void {
  console.log(`[${new Date().toISOString()}] [AgentSessionManager] ${msg}`);
}

interface InternalSession {
  meta: AgentSession;
  history: Anthropic.MessageParam[];
  systemPrompt?: string;
  pendingToolCalls: Map<string, { toolName: string; toolInput: Record<string, unknown> }>;
}

export class AgentSessionManager {
  private client: Anthropic;
  private sessions = new Map<string, InternalSession>();

  constructor() {
    this.client = new Anthropic({ apiKey: config.ANTHROPIC_API_KEY });
  }

  async createSession(sessionConfig: SessionConfig): Promise<string> {
    const sessionId = sessionConfig.sessionId ?? uuidv4();

    const meta: AgentSession = {
      id: sessionId,
      model: sessionConfig.model ?? config.AGENT_MODEL,
      working_directory: sessionConfig.workingDirectory ?? config.ALLOWED_PROJECT_ROOT,
      created_at: new Date().toISOString(),
      status: "idle",
    };

    const internal: InternalSession = {
      meta,
      history: [],
      systemPrompt: sessionConfig.systemPrompt,
      pendingToolCalls: new Map(),
    };

    this.sessions.set(sessionId, internal);
    log(`Created session: ${sessionId}`);

    eventBus.emitTyped("session-event", {
      type: "session_created",
      session_id: sessionId,
      model: meta.model,
    });

    return sessionId;
  }

  async resumeSession(sessionId: string): Promise<void> {
    const session = this.sessions.get(sessionId);
    if (!session) throw new Error(`Session not found: ${sessionId}`);
    session.meta.status = "idle";
    log(`Resumed session: ${sessionId}`);
  }

  closeSession(sessionId: string): void {
    const session = this.sessions.get(sessionId);
    if (!session) return;
    session.meta.status = "closed";
    this.sessions.delete(sessionId);
    log(`Closed session: ${sessionId}`);
    eventBus.emitTyped("session-event", {
      type: "session_closed",
      session_id: sessionId,
    });
  }

  async sendMessage(sessionId: string, content: string, clientId: string): Promise<void> {
    const session = this.sessions.get(sessionId);
    if (!session) throw new Error(`Session not found: ${sessionId}`);

    session.meta.status = "active";
    session.history.push({ role: "user", content });

    const messageId = uuidv4();

    const startPayload: StreamStartPayload = {
      session_id: sessionId,
      message_id: messageId,
    };
    eventBus.emitTyped("session-event", {
      type: "stream_start",
      ...startPayload,
      client_id: clientId,
    });

    try {
      const streamParams: Anthropic.MessageStreamParams = {
        model: session.meta.model,
        max_tokens: 8192,
        messages: session.history,
        stream: true,
      };

      if (session.systemPrompt) {
        (streamParams as Record<string, unknown>)["system"] = session.systemPrompt;
      }

      const stream = this.client.messages.stream(streamParams);

      let fullText = "";
      let chunkIndex = 0;
      let stopReason = "end_turn";

      for await (const event of stream) {
        if (event.type === "content_block_delta") {
          const delta = event.delta;
          if (delta.type === "text_delta") {
            const chunk = delta.text;
            fullText += chunk;

            const chunkPayload: StreamChunkPayload = {
              session_id: sessionId,
              message_id: messageId,
              delta: chunk,
              index: chunkIndex++,
            };
            eventBus.emitTyped("stream-chunk", chunkPayload);
          }
        } else if (event.type === "content_block_start") {
          const block = event.content_block;
          if (block.type === "tool_use") {
            session.pendingToolCalls.set(block.id, {
              toolName: block.name,
              toolInput: block.input as Record<string, unknown>,
            });

            const approvalPayload: ApprovalRequiredPayload = {
              session_id: sessionId,
              tool_call_id: block.id,
              tool_name: block.name,
              tool_input: block.input as Record<string, unknown>,
              message: `Tool call requested: ${block.name}`,
            };
            eventBus.emitTyped("tool-event", {
              type: "approval_required",
              ...approvalPayload,
              client_id: clientId,
            });
          }
        } else if (event.type === "message_delta") {
          if (event.delta.stop_reason) {
            stopReason = event.delta.stop_reason;
          }
        }
      }

      const finalMsg = await stream.finalMessage();
      session.history.push({ role: "assistant", content: finalMsg.content });

      session.meta.status = "idle";

      const endPayload: StreamEndPayload = {
        session_id: sessionId,
        message_id: messageId,
        stop_reason: stopReason,
      };
      eventBus.emitTyped("session-event", {
        type: "stream_end",
        ...endPayload,
        client_id: clientId,
      });
    } catch (err) {
      session.meta.status = "idle";
      log(`Stream error in session ${sessionId}: ${String(err)}`);
      throw err;
    }
  }

  async executeToolCall(sessionId: string, toolCallId: string, decision: string): Promise<void> {
    const session = this.sessions.get(sessionId);
    if (!session) throw new Error(`Session not found: ${sessionId}`);

    const pending = session.pendingToolCalls.get(toolCallId);
    if (!pending) {
      log(`Tool call not found: ${toolCallId}`);
      return;
    }

    session.pendingToolCalls.delete(toolCallId);

    if (decision === "reject") {
      log(`Tool call rejected: ${toolCallId}`);
      eventBus.emitTyped("tool-event", {
        type: "tool_rejected",
        session_id: sessionId,
        tool_call_id: toolCallId,
      });
      return;
    }

    log(`Tool call approved: ${toolCallId} (${pending.toolName})`);
    eventBus.emitTyped("tool-event", {
      type: "tool_approved",
      session_id: sessionId,
      tool_call_id: toolCallId,
      tool_name: pending.toolName,
    });
  }

  getActiveSessions(): AgentSession[] {
    return Array.from(this.sessions.values())
      .filter((s) => s.meta.status !== "closed")
      .map((s) => s.meta);
  }
}
