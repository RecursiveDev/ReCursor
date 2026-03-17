import type { HookEvent } from "../types";

const MAX_QUEUE_SIZE = 1000;

export class EventQueue {
  private queue: HookEvent[] = [];

  enqueue(event: HookEvent): void {
    if (this.queue.length >= MAX_QUEUE_SIZE) {
      this.queue.shift(); // drop oldest
    }
    this.queue.push(event);
  }

  dequeue(sessionId?: string): HookEvent[] {
    if (!sessionId) {
      const all = [...this.queue];
      this.queue = [];
      return all;
    }
    const matching = this.queue.filter((e) => e.session_id === sessionId);
    this.queue = this.queue.filter((e) => e.session_id !== sessionId);
    return matching;
  }

  clear(sessionId?: string): void {
    if (!sessionId) {
      this.queue = [];
    } else {
      this.queue = this.queue.filter((e) => e.session_id !== sessionId);
    }
  }

  size(): number {
    return this.queue.length;
  }
}
