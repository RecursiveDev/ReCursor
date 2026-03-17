import { v4 as uuidv4 } from "uuid";
import { eventBus } from "./event_bus";
import type { ConnectionManager } from "../websocket/connection_manager";
import type { BridgeMessage, ClaudeEventPayload, StreamChunkPayload } from "../types";

function timestamp(): string {
  return new Date().toISOString();
}

export class Dispatcher {
  private connectionManager: ConnectionManager;

  constructor(connectionManager: ConnectionManager) {
    this.connectionManager = connectionManager;
    this.subscribe();
  }

  private subscribe(): void {
    eventBus.onTyped("claude-event", (payload) => {
      const msg: BridgeMessage<ClaudeEventPayload> = {
        type: "claude_event",
        id: uuidv4(),
        timestamp: timestamp(),
        payload: payload as ClaudeEventPayload,
      };
      const sessionId = (payload as ClaudeEventPayload).session_id;
      this.broadcast(msg, sessionId);
    });

    eventBus.onTyped("stream-chunk", (payload) => {
      const chunk = payload as StreamChunkPayload;
      const msg: BridgeMessage<StreamChunkPayload> = {
        type: "stream_chunk",
        id: uuidv4(),
        timestamp: timestamp(),
        payload: chunk,
      };
      const clients = this.connectionManager.getClientsForSession(chunk.session_id);
      for (const client of clients) {
        this.connectionManager.sendToClient(client.id, msg);
      }
    });
  }

  dispatch(clientId: string, message: BridgeMessage<unknown>): void {
    this.connectionManager.sendToClient(clientId, message);
  }

  broadcast(message: BridgeMessage<unknown>, sessionId?: string): void {
    if (sessionId) {
      const clients = this.connectionManager.getClientsForSession(sessionId);
      for (const client of clients) {
        this.connectionManager.sendToClient(client.id, message);
      }
    } else {
      this.connectionManager.broadcast(message);
    }
  }
}
