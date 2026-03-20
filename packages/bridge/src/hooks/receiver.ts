import { Router } from "express";
import { v4 as uuidv4 } from "uuid";
import { validateHookToken } from "../auth/token_validator";
import { validateHookEvent } from "./validator";
import { EventQueue } from "./event_queue";
import { eventBus } from "../notifications/event_bus";
import type { ConnectionManager } from "../websocket/connection_manager";
import type { BridgeMessage, ClaudeEventPayload, HookEvent } from "../types";

function log(msg: string): void {
  console.log(`[${new Date().toISOString()}] [HookReceiver] ${msg}`);
}

export function createHooksRouter(
  eventQueue: EventQueue,
  connectionManager: ConnectionManager,
): Router {
  const router = Router();

  router.post("/event", validateHookToken, (req, res) => {
    const body: unknown = req.body;

    if (!validateHookEvent(body)) {
      res.status(400).json({ error: "Bad Request", message: "Invalid hook event shape" });
      return;
    }

    const event: HookEvent = body;
    log(`Received event: ${event.event_type} (session=${event.session_id})`);

    eventQueue.enqueue(event);

    const claudeEventPayload: ClaudeEventPayload = {
      event_type: event.event_type,
      session_id: event.session_id,
      timestamp: event.timestamp,
      payload: event.payload,
    };

    eventBus.emitTyped("claude-event", claudeEventPayload);

    const msg: BridgeMessage<ClaudeEventPayload> = {
      type: "claude_event",
      id: uuidv4(),
      timestamp: new Date().toISOString(),
      payload: claudeEventPayload,
    };

    connectionManager.broadcast(msg);

    res.status(200).json({ received: true });
  });

  return router;
}
