import { v4 as uuidv4 } from "uuid";
import type {
  BridgeMessage,
  ClaudeEventPayload,
  ApprovalRequiredPayload,
  HookEvent,
  NotificationPayload,
  RiskLevel,
  ToolExecutionResult,
  ToolResultPayload,
} from "../types";

function timestamp(): string {
  return new Date().toISOString();
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === "object" && value !== null ? (value as Record<string, unknown>) : null;
}

function asString(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

function asBoolean(value: unknown): boolean | undefined {
  return typeof value === "boolean" ? value : undefined;
}

function asRiskLevel(value: unknown): RiskLevel {
  if (value === "low" || value === "medium" || value === "high" || value === "critical") {
    return value;
  }
  return "medium";
}

function extractTool(payload: Record<string, unknown>): string {
  return asString(payload.tool) ?? asString(payload.tool_name) ?? "unknown_tool";
}

function extractToolParams(payload: Record<string, unknown>): Record<string, unknown> {
  return asRecord(payload.params) ?? asRecord(payload.tool_input) ?? {};
}

function extractToolCallId(payload: Record<string, unknown>): string {
  return asString(payload.tool_call_id) ?? uuidv4();
}

function createClaudeEventMessage(event: HookEvent): BridgeMessage<ClaudeEventPayload> {
  return {
    type: "claude_event",
    id: uuidv4(),
    timestamp: timestamp(),
    payload: {
      event_type: event.event_type,
      session_id: event.session_id,
      timestamp: event.timestamp,
      payload: event.payload,
    },
  };
}

function createApprovalRequiredMessage(
  event: HookEvent,
): BridgeMessage<ApprovalRequiredPayload> | null {
  if (event.event_type !== "PreToolUse") {
    return null;
  }

  const payload = event.payload;
  const tool = extractTool(payload);
  const params = extractToolParams(payload);
  const description =
    asString(payload.description) ?? asString(payload.message) ?? `Approval required for ${tool}`;

  return {
    type: "approval_required",
    id: uuidv4(),
    timestamp: timestamp(),
    payload: {
      session_id: event.session_id,
      tool_call_id: extractToolCallId(payload),
      tool,
      params,
      description,
      risk_level: asRiskLevel(payload.risk_level),
      source: "hooks",
    },
  };
}

function createToolResultMessage(event: HookEvent): BridgeMessage<ToolResultPayload> | null {
  if (event.event_type !== "PostToolUse") {
    return null;
  }

  const payload = event.payload;
  const resultPayload = asRecord(payload.result);
  const result: ToolExecutionResult = {
    success: asBoolean(resultPayload?.success) ?? true,
    content:
      asString(resultPayload?.content) ??
      asString(payload.content) ??
      JSON.stringify(resultPayload ?? payload),
    diff: asString(resultPayload?.diff),
    error: asString(resultPayload?.error),
    duration_ms:
      typeof payload.duration_ms === "number"
        ? payload.duration_ms
        : typeof resultPayload?.duration_ms === "number"
          ? resultPayload.duration_ms
          : undefined,
  };

  return {
    type: "tool_result",
    id: uuidv4(),
    timestamp: timestamp(),
    payload: {
      session_id: event.session_id,
      tool_call_id: extractToolCallId(payload),
      tool: extractTool(payload),
      result,
    },
  };
}

function createNotificationMessage(event: HookEvent): BridgeMessage<NotificationPayload> | null {
  if (event.event_type !== "Notification") {
    return null;
  }

  const payload = event.payload;
  const notificationId = uuidv4();
  const level = asString(payload.level);
  const priority = level === "error" || level === "warning" ? "high" : "normal";

  return {
    type: "notification",
    id: notificationId,
    timestamp: timestamp(),
    payload: {
      notification_id: notificationId,
      session_id: event.session_id,
      notification_type: asString(payload.notification_type) ?? "agent_idle",
      title: asString(payload.title) ?? "Claude Code notification",
      body: asString(payload.body) ?? asString(payload.message) ?? JSON.stringify(payload),
      priority,
      data: asRecord(payload.data) ?? asRecord(payload.metadata) ?? undefined,
    },
  };
}

export function buildHookProtocolMessages(event: HookEvent): BridgeMessage<unknown>[] {
  const messages: BridgeMessage<unknown>[] = [createClaudeEventMessage(event)];

  const approvalRequiredMessage = createApprovalRequiredMessage(event);
  if (approvalRequiredMessage) {
    messages.push(approvalRequiredMessage);
  }

  const toolResultMessage = createToolResultMessage(event);
  if (toolResultMessage) {
    messages.push(toolResultMessage);
  }

  const notificationMessage = createNotificationMessage(event);
  if (notificationMessage) {
    messages.push(notificationMessage);
  }

  return messages;
}
