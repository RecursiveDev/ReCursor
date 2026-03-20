import { buildHookProtocolMessages } from "../../src/hooks/protocol_mapper";
import type { HookEvent } from "../../src/types";

describe("buildHookProtocolMessages", () => {
  it("maps PreToolUse hooks to approval and notification messages", () => {
    const event: HookEvent = {
      event_type: "PreToolUse",
      session_id: "sess-1",
      timestamp: new Date().toISOString(),
      payload: {
        tool: "run_command",
        params: {
          command: "flutter build apk",
          file_path: "apps/mobile/lib/main.dart",
        },
        description: "Build Android APK",
        risk_level: "medium",
        tool_call_id: "call-1",
      },
    };

    const messages = buildHookProtocolMessages(event);
    const approvalRequired = messages.find((message) => message.type === "approval_required");
    const notification = messages.find((message) => message.type === "notification");

    expect(messages[0]?.type).toBe("claude_event");
    expect(approvalRequired).toMatchObject({
      payload: {
        session_id: "sess-1",
        tool_call_id: "call-1",
        tool: "run_command",
        params: {
          command: "flutter build apk",
          file_path: "apps/mobile/lib/main.dart",
        },
        description: "Build Android APK",
        risk_level: "medium",
        source: "hooks",
      },
    });
    expect(notification).toMatchObject({
      payload: {
        session_id: "sess-1",
        notification_type: "approval_required",
        title: "Observed tool request: run_command",
        body: "Build Android APK",
        priority: "normal",
        data: {
          tool_call_id: "call-1",
          tool: "run_command",
          source: "hooks",
          screen: "approval_detail",
          file_paths: ["apps/mobile/lib/main.dart"],
        },
      },
    });
  });

  it("maps PostToolUse hooks to tool_result and diff notifications", () => {
    const event: HookEvent = {
      event_type: "PostToolUse",
      session_id: "sess-1",
      timestamp: new Date().toISOString(),
      payload: {
        tool: "edit_file",
        tool_call_id: "call-2",
        path: "apps/mobile/lib/main.dart",
        result: {
          success: true,
          content: "File edited successfully",
          diff: "@@ -1 +1 @@",
        },
      },
    };

    const messages = buildHookProtocolMessages(event);
    const toolResult = messages.find((message) => message.type === "tool_result");
    const notification = messages.find((message) => message.type === "notification");

    expect(toolResult).toMatchObject({
      payload: {
        session_id: "sess-1",
        tool_call_id: "call-2",
        tool: "edit_file",
        result: {
          success: true,
          content: "File edited successfully",
          diff: "@@ -1 +1 @@",
        },
      },
    });
    expect(notification).toMatchObject({
      payload: {
        session_id: "sess-1",
        notification_type: "task_complete",
        title: "Diff ready: edit_file",
        body: "Observed code changes from edit_file.",
        priority: "normal",
        data: {
          tool_call_id: "call-2",
          tool: "edit_file",
          source: "hooks",
          screen: "diff",
          diff_available: true,
          file_paths: ["apps/mobile/lib/main.dart"],
        },
      },
    });
  });

  it("maps Notification hooks to notification messages with ack ids", () => {
    const event: HookEvent = {
      event_type: "Notification",
      session_id: "sess-1",
      timestamp: new Date().toISOString(),
      payload: {
        title: "Agent idle",
        message: "Claude Code is waiting for input.",
      },
    };

    const messages = buildHookProtocolMessages(event);
    const notification = messages.find((message) => message.type === "notification");

    expect(notification).toMatchObject({
      payload: {
        session_id: "sess-1",
        notification_type: "agent_idle",
        title: "Agent idle",
        body: "Claude Code is waiting for input.",
        priority: "normal",
      },
    });
    expect(typeof notification?.id).toBe("string");
  });
});
