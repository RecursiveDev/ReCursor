import { EventEmitter } from "events";

export type EventBusEvents = {
  "claude-event": [payload: unknown];
  "session-event": [payload: unknown];
  "tool-event": [payload: unknown];
  "stream-chunk": [payload: unknown];
};

class TypedEventBus extends EventEmitter {
  emitTyped<K extends keyof EventBusEvents>(event: K, ...args: EventBusEvents[K]): boolean {
    return this.emit(event, ...args);
  }

  onTyped<K extends keyof EventBusEvents>(
    event: K,
    listener: (...args: EventBusEvents[K]) => void,
  ): this {
    return this.on(event, listener as (...args: unknown[]) => void);
  }

  offTyped<K extends keyof EventBusEvents>(
    event: K,
    listener: (...args: EventBusEvents[K]) => void,
  ): this {
    return this.off(event, listener as (...args: unknown[]) => void);
  }
}

export const eventBus = new TypedEventBus();
