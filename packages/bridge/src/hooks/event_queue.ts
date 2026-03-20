import type { BridgeMessage } from "../types";

const MAX_QUEUE_SIZE = 1000;

interface QueuedMessage {
  message: BridgeMessage<unknown>;
  sessionId?: string;
  notificationId?: string;
}

export class EventQueue {
  private queue: QueuedMessage[] = [];

  enqueue(
    message: BridgeMessage<unknown>,
    options: { sessionId?: string; notificationId?: string } = {},
  ): void {
    if (this.queue.length >= MAX_QUEUE_SIZE) {
      this.queue.shift();
    }

    this.queue.push({
      message,
      sessionId: options.sessionId,
      notificationId: options.notificationId,
    });
  }

  replay(sessionId?: string): BridgeMessage<unknown>[] {
    if (!sessionId) {
      return this.queue.map((entry) => entry.message);
    }

    return this.queue
      .filter((entry) => entry.sessionId === sessionId)
      .map((entry) => entry.message);
  }

  acknowledgeNotifications(notificationIds: string[]): void {
    if (notificationIds.length === 0) {
      return;
    }

    const acknowledged = new Set(notificationIds);
    this.queue = this.queue.filter((entry) => {
      if (!entry.notificationId) {
        return true;
      }
      return !acknowledged.has(entry.notificationId);
    });
  }

  clear(sessionId?: string): void {
    if (!sessionId) {
      this.queue = [];
      return;
    }

    this.queue = this.queue.filter((entry) => entry.sessionId !== sessionId);
  }

  size(): number {
    return this.queue.length;
  }
}
