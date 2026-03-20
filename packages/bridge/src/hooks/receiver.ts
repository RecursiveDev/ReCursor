import { Router } from "express";
import { v4 as uuidv4 } from "uuid";
import { validateHookToken } from "../auth/token_validator";
import { EventQueue } from "./event_queue";
import type { ConnectionManager } from "../websocket/connection_manager";
import type { BridgeMessage, HookEvent } from "../types";
import { buildHookProtocolMessages } from "./protocol_mapper";
import { normalizeHookEvent } from "./validator";

function log(msg: string): void {
  console.log(`[${new Date().toISOString()}] [HookReceiver] ${msg}`);
}

interface ProcessedHookEvent {
  eventId: string;
  broadcastCount: number;
}

function extractNotificationId(message: BridgeMessage<unknown>): string | undefined {
  if (
    message.type === "notification" &&
    typeof message.payload === "object" &&
    message.payload !== null &&
    "notification_id" in message.payload &&
    typeof (message.payload as { notification_id?: unknown }).notification_id === "string"
  ) {
    return (message.payload as { notification_id: string }).notification_id;
  }

  return undefined;
}

function processHookEvent(
  event: HookEvent,
  eventQueue: EventQueue,
  connectionManager: ConnectionManager,
): ProcessedHookEvent {
  log(`Received event: ${event.event_type} (session=${event.session_id})`);

  const messages = buildHookProtocolMessages(event);
  for (const message of messages) {
    eventQueue.enqueue(message, {
      sessionId: event.session_id,
      notificationId: extractNotificationId(message),
    });
    connectionManager.broadcast(message);
  }

  return {
    eventId: uuidv4(),
    broadcastCount: messages.length,
  };
}

export function createHooksRouter(
  eventQueue: EventQueue,
  connectionManager: ConnectionManager,
): Router {
  const router = Router();

  router.post("/event", validateHookToken, (req, res) => {
    const event = normalizeHookEvent(req.body);

    if (!event) {
      res.status(400).json({
        error: "ValidationError",
        message: "Invalid event format",
        code: "HOOK_INVALID_PAYLOAD",
      });
      return;
    }

    const result = processHookEvent(event, eventQueue, connectionManager);
    res.status(200).json({
      received: true,
      event_id: result.eventId,
      broadcast_count: result.broadcastCount,
      timestamp: new Date().toISOString(),
    });
  });

  router.post("/batch", validateHookToken, (req, res) => {
    const body = req.body as { events?: unknown };
    const events = Array.isArray(body.events) ? body.events : null;

    if (!events) {
      res.status(400).json({
        error: "ValidationError",
        message: "Invalid batch format: events array is required",
        code: "HOOK_INVALID_PAYLOAD",
      });
      return;
    }

    const normalizedEvents = events.map((event) => normalizeHookEvent(event));
    const invalidCount = normalizedEvents.filter((event) => event === null).length;

    if (invalidCount > 0) {
      res.status(400).json({
        error: "ValidationError",
        message: "One or more hook events were invalid",
        code: "HOOK_INVALID_PAYLOAD",
        details: {
          rejected: invalidCount,
        },
      });
      return;
    }

    const processed = normalizedEvents.map((event) =>
      processHookEvent(event as HookEvent, eventQueue, connectionManager),
    );

    res.status(200).json({
      received: true,
      count: processed.length,
      accepted: processed.length,
      rejected: 0,
      event_ids: processed.map((result) => result.eventId),
    });
  });

  return router;
}
