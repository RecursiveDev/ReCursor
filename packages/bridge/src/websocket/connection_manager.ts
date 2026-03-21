import type WebSocket from "ws";
import type { BridgeMessage, ConnectionPurpose, MobileClient } from "../types";
import type { ConnectionMode } from "./connection_mode";

function log(msg: string): void {
  console.log(`[${new Date().toISOString()}] [ConnectionManager] ${msg}`);
}

export interface ClientConnectionMetadata {
  remoteAddress?: string;
  connectionMode?: ConnectionMode;
  connectionModeDescription?: string;
  bridgeUrl?: string;
  purpose?: ConnectionPurpose;
}

export interface ConnectionStateSnapshot {
  totalClients: number;
  authenticatedClients: number;
}

export class ConnectionManager {
  private clients = new Map<string, MobileClient>();
  private listeners = new Set<(snapshot: ConnectionStateSnapshot) => void>();

  addClient(id: string, ws: WebSocket, metadata?: ClientConnectionMetadata): void {
    const client: MobileClient = {
      id,
      ws,
      sessionIds: [],
      authenticated: false,
      purpose: metadata?.purpose,
      remoteAddress: metadata?.remoteAddress,
      connectionMode: metadata?.connectionMode,
      connectionModeDescription: metadata?.connectionModeDescription,
      bridgeUrl: metadata?.bridgeUrl,
      warningAcknowledged: false,
      connectedAt: new Date().toISOString(),
    };
    this.clients.set(id, client);
    this.emitChange();
    log(`Client added: ${id}`);
  }

  authenticateClient(id: string): void {
    const client = this.clients.get(id);
    if (client) {
      client.authenticated = true;
      this.emitChange();
      log(`Client authenticated: ${id}`);
    }
  }

  setClientPurpose(id: string, purpose: ConnectionPurpose): void {
    const client = this.clients.get(id);
    if (client) {
      client.purpose = purpose;
      this.emitChange();
      log(`Client purpose updated: ${id} (${purpose})`);
    }
  }

  acknowledgeWarning(id: string): void {
    const client = this.clients.get(id);
    if (client) {
      client.warningAcknowledged = true;
    }
  }

  removeClient(id: string): void {
    this.clients.delete(id);
    this.emitChange();
    log(`Client removed: ${id}`);
  }

  getClient(id: string): MobileClient | undefined {
    return this.clients.get(id);
  }

  getAuthenticatedClientCount(): number {
    let count = 0;
    for (const client of this.clients.values()) {
      if (client.authenticated) {
        count += 1;
      }
    }
    return count;
  }

  getTotalClientCount(): number {
    return this.clients.size;
  }

  subscribe(listener: (snapshot: ConnectionStateSnapshot) => void): () => void {
    this.listeners.add(listener);
    listener(this.snapshot());

    return () => {
      this.listeners.delete(listener);
    };
  }

  broadcast(message: BridgeMessage<unknown>, filter?: (client: MobileClient) => boolean): void {
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

  getPrimaryClients(): MobileClient[] {
    return this.getClientsByPurpose("primary");
  }

  getProbeClients(): MobileClient[] {
    return this.getClientsByPurpose("probe");
  }

  private emitChange(): void {
    const snapshot = this.snapshot();
    for (const listener of this.listeners) {
      listener(snapshot);
    }
  }

  private snapshot(): ConnectionStateSnapshot {
    return {
      totalClients: this.getTotalClientCount(),
      authenticatedClients: this.getAuthenticatedClientCount(),
    };
  }

  private getClientsByPurpose(purpose: ConnectionPurpose): MobileClient[] {
    const result: MobileClient[] = [];
    for (const client of this.clients.values()) {
      if (client.purpose === purpose) {
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
