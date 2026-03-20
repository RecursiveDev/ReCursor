import { Router } from "express";
import { validateHookToken } from "../auth/token_validator";
import { validateHookEvent } from "./validator";
import { EventQueue } from "./event_queue";
import type { ConnectionManager } from "../websocket/connection_manager";
import type { HookEvent } from "../types";
import { buildHookProtocolMessages } from "./protocol_mapper";

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

    const messages = buildHookProtocolMessages(event);
    for (const message of messages) {
      const notificationId =
        message.type === "notification" &&
        typeof message.payload === "object" &&
        message.payload !== null &&
        "notification_id" in message.payload &&
        typeof (message.payload as { notification_id?: unknown }).notification_id === "string"
          ? ((message.payload as { notification_id: string }).notification_id as string)
          : undefined;

      eventQueue.enqueue(message, {
        sessionId: event.session_id,
        notificationId,
      });
      connectionManager.broadcast(message);
    }

    res.status(200).json({ received: true });
  });

  return router;
}
