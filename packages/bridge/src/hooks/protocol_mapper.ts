import { v4 as uuidv4 } from "uuid";
import type {
  ApprovalRequiredPayload,
  BridgeMessage,
  ClaudeEventPayload,
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

function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value.filter((entry): entry is string => typeof entry === "string" && entry.length > 0);
}

function asRiskLevel(value: unknown): RiskLevel {
  if (value === "low" || value === "medium" || value === "high" || value === "critical") {
    return value;
  }
  return "medium";
}

function priorityFromRiskLevel(riskLevel: RiskLevel): NotificationPayload["priority"] {
  return riskLevel === "high" || riskLevel === "critical" ? "high" : "normal";
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

function extractFilePaths(payload: Record<string, unknown>): string[] {
  const params = extractToolParams(payload);
  const resultPayload = asRecord(payload.result);
  const candidates: unknown[] = [
    payload.file_path,
    payload.path,
    payload.current_file,
    payload.old_path,
    payload.new_path,
    params.file_path,
    params.path,
    params.current_file,
    params.old_path,
    params.new_path,
    params.files,
    params.paths,
    resultPayload?.file_path,
    resultPayload?.path,
    resultPayload?.old_path,
    resultPayload?.new_path,
    resultPayload?.files,
    resultPayload?.paths,
  ];

  const paths = new Set<string>();
  for (const candidate of candidates) {
    if (typeof candidate === "string" && candidate.length > 0) {
      paths.add(candidate);
      continue;
    }

    for (const value of asStringArray(candidate)) {
      paths.add(value);
    }
  }

  return [...paths];
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
  const payload = event.payload;
  const notificationId = uuidv4();

  if (event.event_type === "Notification") {
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

  if (event.event_type === "PreToolUse") {
    const tool = extractTool(payload);
    const toolCallId = extractToolCallId(payload);
    const description =
      asString(payload.description) ??
      asString(payload.message) ??
      `Tool request observed for ${tool}`;
    const riskLevel = asRiskLevel(payload.risk_level);
    const filePaths = extractFilePaths(payload);

    return {
      type: "notification",
      id: notificationId,
      timestamp: timestamp(),
      payload: {
        notification_id: notificationId,
        session_id: event.session_id,
        notification_type: "approval_required",
        title: `Observed tool request: ${tool}`,
        body: description,
        priority: priorityFromRiskLevel(riskLevel),
        data: {
          tool_call_id: toolCallId,
          tool,
          source: "hooks",
          screen: "approval_detail",
          ...(filePaths.length > 0 ? { file_paths: filePaths } : {}),
        },
      },
    };
  }

  if (event.event_type === "PostToolUse") {
    const tool = extractTool(payload);
    const toolCallId = extractToolCallId(payload);
    const resultPayload = asRecord(payload.result);
    const diff = asString(resultPayload?.diff);
    const error = asString(resultPayload?.error);
    const success = asBoolean(resultPayload?.success) ?? true;
    const filePaths = extractFilePaths(payload);

    if (!success || error) {
      return {
        type: "notification",
        id: notificationId,
        timestamp: timestamp(),
        payload: {
          notification_id: notificationId,
          session_id: event.session_id,
          notification_type: "error",
          title: `Tool failed: ${tool}`,
          body: error ?? `Observed tool failure for ${tool}`,
          priority: "high",
          data: {
            tool_call_id: toolCallId,
            tool,
            source: "hooks",
            screen: "chat",
            ...(filePaths.length > 0 ? { file_paths: filePaths } : {}),
          },
        },
      };
    }

    if (diff) {
      return {
        type: "notification",
        id: notificationId,
        timestamp: timestamp(),
        payload: {
          notification_id: notificationId,
          session_id: event.session_id,
          notification_type: "task_complete",
          title: `Diff ready: ${tool}`,
          body: `Observed code changes from ${tool}.`,
          priority: "normal",
          data: {
            tool_call_id: toolCallId,
            tool,
            source: "hooks",
            screen: "diff",
            diff_available: true,
            ...(filePaths.length > 0 ? { file_paths: filePaths } : {}),
          },
        },
      };
    }
  }

  return null;
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
