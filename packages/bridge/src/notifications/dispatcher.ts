import { v4 as uuidv4 } from "uuid";
import { eventBus } from "./event_bus";
import type { EventQueue } from "../hooks/event_queue";
import type { ConnectionManager } from "../websocket/connection_manager";
import type {
  ApprovalRequiredPayload,
  BridgeMessage,
  StreamChunkPayload,
  StreamEndPayload,
  StreamStartPayload,
  ToolResultPayload,
} from "../types";

function timestamp(): string {
  return new Date().toISOString();
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function asString(value: unknown): string | undefined {
  return typeof value === "string" ? value : undefined;
}

export class Dispatcher {
  private connectionManager: ConnectionManager;
  private eventQueue?: EventQueue;

  constructor(connectionManager: ConnectionManager, eventQueue?: EventQueue) {
    this.connectionManager = connectionManager;
    this.eventQueue = eventQueue;
    this.subscribe();
  }

  private subscribe(): void {
    eventBus.onTyped("session-event", (payload) => {
      if (!isRecord(payload) || typeof payload.type !== "string") {
        return;
      }

      switch (payload.type) {
        case "stream_start":
          this.broadcastToSession(payload.session_id, {
            type: "stream_start",
            id: uuidv4(),
            timestamp: timestamp(),
            payload: {
              session_id: asString(payload.session_id) ?? "",
              message_id: asString(payload.message_id) ?? "",
            } satisfies StreamStartPayload,
          });
          break;

        case "stream_end":
          this.broadcastToSession(payload.session_id, {
            type: "stream_end",
            id: uuidv4(),
            timestamp: timestamp(),
            payload: {
              session_id: asString(payload.session_id) ?? "",
              message_id: asString(payload.message_id) ?? "",
              finish_reason: asString(payload.finish_reason) ?? "stop",
            } satisfies StreamEndPayload,
          });
          break;

        case "session_closed":
          this.broadcastToSession(payload.session_id, {
            type: "session_end",
            id: uuidv4(),
            timestamp: timestamp(),
            payload: {
              session_id: asString(payload.session_id) ?? "",
              reason: "completed",
            },
          });
          break;

        default:
          break;
      }
    });

    eventBus.onTyped("tool-event", (payload) => {
      if (!isRecord(payload) || typeof payload.type !== "string") {
        return;
      }

      if (payload.type === "approval_required") {
        this.broadcastToSession(payload.session_id, {
          type: "approval_required",
          id: uuidv4(),
          timestamp: timestamp(),
          payload: {
            session_id: asString(payload.session_id) ?? "",
            tool_call_id: asString(payload.tool_call_id) ?? "",
            tool: asString(payload.tool) ?? "unknown_tool",
            params: isRecord(payload.params) ? payload.params : {},
            description: asString(payload.description) ?? "Approval required",
            risk_level:
              payload.risk_level === "low" ||
              payload.risk_level === "medium" ||
              payload.risk_level === "high" ||
              payload.risk_level === "critical"
                ? payload.risk_level
                : "medium",
            source: payload.source === "hooks" ? "hooks" : "agent_sdk",
          } satisfies ApprovalRequiredPayload,
        });
        return;
      }

      if (payload.type === "tool_result") {
        const message: BridgeMessage<ToolResultPayload> = {
          type: "tool_result",
          id: uuidv4(),
          timestamp: timestamp(),
          payload: {
            session_id: asString(payload.session_id) ?? "",
            tool_call_id: asString(payload.tool_call_id) ?? "",
            tool: asString(payload.tool) ?? "unknown_tool",
            result: isRecord(payload.result)
              ? {
                  success: payload.result.success === true,
                  content: asString(payload.result.content) ?? "",
                  diff: asString(payload.result.diff),
                  error: asString(payload.result.error),
                  duration_ms:
                    typeof payload.result.duration_ms === "number"
                      ? payload.result.duration_ms
                      : undefined,
                }
              : {
                  success: false,
                  content: "",
                  error: "Missing tool result payload",
                },
          } satisfies ToolResultPayload,
        };

        this.broadcastToSession(payload.session_id, message, { queueForReplay: true });
      }
    });

    eventBus.onTyped("stream-chunk", (payload) => {
      if (!isRecord(payload)) {
        return;
      }

      const chunkPayload: StreamChunkPayload = {
        session_id: asString(payload.session_id) ?? "",
        message_id: asString(payload.message_id) ?? "",
        content: asString(payload.content) ?? "",
        is_tool_use: false,
      };

      const msg: BridgeMessage<StreamChunkPayload> = {
        type: "stream_chunk",
        id: uuidv4(),
        timestamp: timestamp(),
        payload: chunkPayload,
      };

      this.broadcastToSession(chunkPayload.session_id, msg);
    });
  }

  dispatch(clientId: string, message: BridgeMessage<unknown>): void {
    this.connectionManager.sendToClient(clientId, message);
  }

  broadcast(message: BridgeMessage<unknown>, sessionId?: string): void {
    if (sessionId) {
      this.broadcastToSession(sessionId, message);
      return;
    }

    this.connectionManager.broadcast(message);
  }

  private broadcastToSession(
    sessionId: unknown,
    message: BridgeMessage<unknown>,
    options: {
      queueForReplay?: boolean;
    } = {},
  ): void {
    if (typeof sessionId !== "string" || sessionId.length === 0) {
      return;
    }

    if (options.queueForReplay) {
      this.eventQueue?.enqueue(message, { sessionId });
    }

    const clients = this.connectionManager.getClientsForSession(sessionId);
    for (const client of clients) {
      this.connectionManager.sendToClient(client.id, message);
    }
  }
}
