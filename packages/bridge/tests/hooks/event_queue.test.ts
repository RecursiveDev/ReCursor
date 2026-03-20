import { EventQueue } from "../../src/hooks/event_queue";
import type { BridgeMessage, NotificationPayload } from "../../src/types";

describe("EventQueue", () => {
  it("replays queued messages without removing them", () => {
    const queue = new EventQueue();
    const message: BridgeMessage = {
      type: "claude_event",
      id: "evt-1",
      timestamp: new Date().toISOString(),
      payload: { event_type: "SessionStart" },
    };

    queue.enqueue(message, { sessionId: "sess-1" });

    expect(queue.replay()).toEqual([message]);
    expect(queue.size()).toBe(1);
  });

  it("acknowledges queued notifications by id", () => {
    const queue = new EventQueue();
    const notification: BridgeMessage<NotificationPayload> = {
      type: "notification",
      id: "notif-1",
      timestamp: new Date().toISOString(),
      payload: {
        notification_id: "notif-1",
        session_id: "sess-1",
        notification_type: "approval_required",
        title: "Approval needed",
        body: "Review tool call",
        priority: "high",
      },
    };
    const toolResult: BridgeMessage = {
      type: "tool_result",
      id: "tool-1",
      timestamp: new Date().toISOString(),
      payload: { session_id: "sess-1" },
    };

    queue.enqueue(notification, { sessionId: "sess-1", notificationId: "notif-1" });
    queue.enqueue(toolResult, { sessionId: "sess-1" });

    queue.acknowledgeNotifications(["notif-1"]);

    expect(queue.replay()).toEqual([toolResult]);
  });
});
