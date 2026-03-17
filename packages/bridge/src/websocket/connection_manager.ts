import type WebSocket from "ws";
import type { MobileClient, BridgeMessage } from "../types";

function log(msg: string): void {
  console.log(`[${new Date().toISOString()}] [ConnectionManager] ${msg}`);
}

export class ConnectionManager {
  private clients = new Map<string, MobileClient>();

  addClient(id: string, ws: WebSocket): void {
    const client: MobileClient = {
      id,
      ws,
      sessionIds: [],
      authenticated: false,
    };
    this.clients.set(id, client);
    log(`Client added: ${id}`);
  }

  authenticateClient(id: string): void {
    const client = this.clients.get(id);
    if (client) {
      client.authenticated = true;
      log(`Client authenticated: ${id}`);
    }
  }

  removeClient(id: string): void {
    this.clients.delete(id);
    log(`Client removed: ${id}`);
  }

  getClient(id: string): MobileClient | undefined {
    return this.clients.get(id);
  }

  broadcast(
    message: BridgeMessage<unknown>,
    filter?: (client: MobileClient) => boolean
  ): void {
    const json = JSON.stringify(message);
    for (const client of this.clients.values()) {
      if (!client.authenticated) continue;
      if (filter && !filter(client)) continue;
      this.sendRaw(client, json);
    }
  }

  sendToClient(id: string, message: BridgeMessage<unknown>): void {
    const client = this.clients.get(id);
    if (!client) return;
    this.sendRaw(client, JSON.stringify(message));
  }

  addSessionToClient(clientId: string, sessionId: string): void {
    const client = this.clients.get(clientId);
    if (client && !client.sessionIds.includes(sessionId)) {
      client.sessionIds.push(sessionId);
    }
  }

  getClientsForSession(sessionId: string): MobileClient[] {
    const result: MobileClient[] = [];
    for (const client of this.clients.values()) {
      if (client.authenticated && client.sessionIds.includes(sessionId)) {
        result.push(client);
      }
    }
    return result;
  }

  private sendRaw(client: MobileClient, json: string): void {
    try {
      if (client.ws.readyState === 1 /* OPEN */) {
        client.ws.send(json);
      }
    } catch (err) {
      log(`Failed to send to client ${client.id}: ${String(err)}`);
    }
  }
}
