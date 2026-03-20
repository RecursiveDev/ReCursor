import path from "path";
import Anthropic from "@anthropic-ai/sdk";
import { v4 as uuidv4 } from "uuid";
import { config } from "../config";
import { eventBus } from "../notifications/event_bus";
import type {
  AgentSession,
  ApprovalDecision,
  ApprovalRequiredPayload,
  SessionConfig,
  StreamChunkPayload,
  StreamEndPayload,
  StreamStartPayload,
  SupportedAgent,
  ToolExecutionResult,
} from "../types";
import {
  AnthropicMessageRuntime,
  type AgentRuntime,
  type AgentRuntimeMessage,
  type AgentRuntimeToolResultBlock,
  type AgentRuntimeToolUseBlock,
} from "./agent_runtime";
import { isWithinAllowedRoot, ToolExecutor } from "./tool_executor";

function log(msg: string): void {
  console.log(`[${new Date().toISOString()}] [AgentSessionManager] ${msg}`);
}

interface PendingToolResolution {
  decision: ApprovalDecision;
  params: Record<string, unknown>;
}

interface PendingToolCall {
  tool: string;
  params: Record<string, unknown>;
  resolve: (resolution: PendingToolResolution) => void;
}

interface InternalSession {
  meta: AgentSession;
  history: AgentRuntimeMessage[];
  systemPrompt?: string;
  pendingToolCalls: Map<string, PendingToolCall>;
}

function toSupportedAgent(agent?: SupportedAgent): SupportedAgent {
  return agent ?? "claude-code";
}

function buildSessionTitle(workingDirectory: string): string {
  return path.basename(workingDirectory) || "Claude Code session";
}

function mapFinishReason(stopReason: string | null): string {
  switch (stopReason) {
    case "end_turn":
      return "stop";
    case "max_tokens":
      return "length";
    case "tool_use":
      return "tool_call";
    default:
      return stopReason ?? "stop";
  }
}

function mapRiskLevel(tool: string): ApprovalRequiredPayload["risk_level"] {
  switch (tool) {
    case "run_command":
    case "Bash":
      return "high";
    case "edit_file":
    case "Edit":
      return "medium";
    case "read_file":
    case "glob":
    case "grep":
    case "ls":
    case "Read":
    case "Glob":
    case "Grep":
    case "LS":
      return "low";
    default:
      return "medium";
  }
}

function formatToolResultForModel(tool: string, result: ToolExecutionResult): string {
  const parts = [`Tool: ${tool}`, `Success: ${result.success ? "true" : "false"}`];

  if (result.content) {
    parts.push(`Content:\n${result.content}`);
  }

  if (result.diff) {
    parts.push(`Diff:\n${result.diff}`);
  }

  if (result.error) {
    parts.push(`Error:\n${result.error}`);
  }

  if (typeof result.duration_ms === "number") {
    parts.push(`DurationMs: ${result.duration_ms}`);
  }

  return parts.join("\n\n");
}

export class AgentSessionManager {
  private runtime: AgentRuntime;
  private toolExecutor: ToolExecutor;
  private sessions = new Map<string, InternalSession>();

  constructor(runtime?: AgentRuntime, toolExecutor?: ToolExecutor) {
    this.runtime =
      runtime ?? new AnthropicMessageRuntime(new Anthropic({ apiKey: config.ANTHROPIC_API_KEY }));
    this.toolExecutor = toolExecutor ?? new ToolExecutor();
  }

  async createSession(sessionConfig: SessionConfig): Promise<string> {
    const sessionId = sessionConfig.sessionId ?? uuidv4();
    const agent = toSupportedAgent(sessionConfig.agent);
    const workingDirectory = path.resolve(
      sessionConfig.workingDirectory ?? config.ALLOWED_PROJECT_ROOT,
    );

    if (!isWithinAllowedRoot(workingDirectory)) {
      throw new Error(`Working directory is outside of allowed project root: ${workingDirectory}`);
    }

    const meta: AgentSession = {
      id: sessionId,
      agent,
      title: buildSessionTitle(workingDirectory),
      model: sessionConfig.model ?? config.AGENT_MODEL,
      working_directory: workingDirectory,
      created_at: new Date().toISOString(),
      status: "idle",
    };

    const internal: InternalSession = {
      meta,
      history: [],
      systemPrompt: sessionConfig.systemPrompt,
      pendingToolCalls: new Map(),
    };

    this.sessions.set(sessionId, internal);
    log(`Created session: ${sessionId}`);

    eventBus.emitTyped("session-event", {
      type: "session_created",
      session_id: sessionId,
      agent: meta.agent,
      model: meta.model,
    });

    return sessionId;
  }

  async resumeSession(sessionId: string): Promise<void> {
    const session = this.sessions.get(sessionId);
    if (!session) {
      throw new Error(`Session not found: ${sessionId}`);
    }

    session.meta.status = "idle";
    log(`Resumed session: ${sessionId}`);
  }

  closeSession(sessionId: string): void {
    const session = this.sessions.get(sessionId);
    if (!session) {
      return;
    }

    session.meta.status = "closed";
    this.sessions.delete(sessionId);
    log(`Closed session: ${sessionId}`);

    eventBus.emitTyped("session-event", {
      type: "session_closed",
      session_id: sessionId,
    });
  }

  async sendMessage(sessionId: string, content: string, clientId: string): Promise<void> {
    const session = this.sessions.get(sessionId);
    if (!session) {
      throw new Error(`Session not found: ${sessionId}`);
    }

    session.meta.status = "active";
    session.history.push({ role: "user", content });

    const messageId = uuidv4();
    const startPayload: StreamStartPayload = {
      session_id: sessionId,
      message_id: messageId,
    };

    eventBus.emitTyped("session-event", {
      type: "stream_start",
      ...startPayload,
      client_id: clientId,
    });

    let finishReason = "stop";

    try {
      for (let iteration = 0; iteration < config.AGENT_MAX_ITERATIONS; iteration += 1) {
        const turn = await this.runtime.runTurn({
          model: session.meta.model,
          maxTokens: 8192,
          messages: session.history,
          systemPrompt: session.systemPrompt,
          tools: this.toolExecutor.getToolDefinitions(),
          onTextDelta: (textDelta) => {
            const chunkPayload: StreamChunkPayload = {
              session_id: sessionId,
              message_id: messageId,
              content: textDelta,
              is_tool_use: false,
            };
            eventBus.emitTyped("stream-chunk", chunkPayload);
          },
        });

        session.history.push({
          role: turn.message.role,
          content: turn.message.content,
        });
        finishReason = mapFinishReason(turn.stopReason);

        const toolCalls = turn.message.content.filter(
          (block): block is AgentRuntimeToolUseBlock => block.type === "tool_use",
        );

        if (turn.stopReason !== "tool_use" || toolCalls.length === 0) {
          session.meta.status = "idle";
          const endPayload: StreamEndPayload = {
            session_id: sessionId,
            message_id: messageId,
            finish_reason: finishReason,
          };

          eventBus.emitTyped("session-event", {
            type: "stream_end",
            ...endPayload,
            client_id: clientId,
          });
          return;
        }

        const toolResults: AgentRuntimeToolResultBlock[] = [];
        for (const toolCall of toolCalls) {
          toolResults.push(await this.executeApprovedTool(sessionId, clientId, session, toolCall));
        }

        session.history.push({
          role: "user",
          content: toolResults,
        });
      }

      throw new Error(
        `Agent tool loop exceeded configured max iterations: ${config.AGENT_MAX_ITERATIONS}`,
      );
    } catch (err) {
      session.meta.status = "idle";
      log(`Stream error in session ${sessionId}: ${String(err)}`);
      throw err;
    }
  }

  async executeToolCall(
    sessionId: string,
    toolCallId: string,
    decision: ApprovalDecision,
    modifications: Record<string, unknown> | null,
  ): Promise<void> {
    const session = this.sessions.get(sessionId);
    if (!session) {
      throw new Error(`Session not found: ${sessionId}`);
    }

    const pending = session.pendingToolCalls.get(toolCallId);
    if (!pending) {
      throw new Error(`Tool call not found: ${toolCallId}`);
    }

    session.pendingToolCalls.delete(toolCallId);

    if (decision === "rejected") {
      log(`Tool call rejected: ${toolCallId}`);
      eventBus.emitTyped("tool-event", {
        type: "tool_rejected",
        session_id: sessionId,
        tool_call_id: toolCallId,
      });
      pending.resolve({ decision, params: pending.params });
      return;
    }

    const resolvedParams =
      decision === "modified" ? (modifications ?? pending.params) : pending.params;

    log(`Tool call ${decision}: ${toolCallId} (${pending.tool})`);
    eventBus.emitTyped("tool-event", {
      type: decision === "modified" ? "tool_modified" : "tool_approved",
      session_id: sessionId,
      tool_call_id: toolCallId,
      tool: pending.tool,
      params: resolvedParams,
    });
    pending.resolve({ decision, params: resolvedParams });
  }

  getSession(sessionId: string): AgentSession | undefined {
    return this.sessions.get(sessionId)?.meta;
  }

  getActiveSessions(): AgentSession[] {
    return Array.from(this.sessions.values())
      .filter((session) => session.meta.status !== "closed")
      .map((session) => session.meta);
  }

  private async executeApprovedTool(
    sessionId: string,
    clientId: string,
    session: InternalSession,
    toolCall: AgentRuntimeToolUseBlock,
  ): Promise<AgentRuntimeToolResultBlock> {
    const approval = await new Promise<PendingToolResolution>((resolve) => {
      session.pendingToolCalls.set(toolCall.id, {
        tool: toolCall.name,
        params: toolCall.input,
        resolve,
      });

      const approvalPayload: ApprovalRequiredPayload = {
        session_id: sessionId,
        tool_call_id: toolCall.id,
        tool: toolCall.name,
        params: toolCall.input,
        description: `Approval required for ${toolCall.name}`,
        risk_level: mapRiskLevel(toolCall.name),
        source: "agent_sdk",
      };

      eventBus.emitTyped("tool-event", {
        type: "approval_required",
        ...approvalPayload,
        client_id: clientId,
      });
    });

    if (approval.decision === "rejected") {
      return {
        type: "tool_result",
        tool_use_id: toolCall.id,
        content: `Tool execution rejected by user for ${toolCall.name}.`,
        is_error: true,
      };
    }

    const execution = await this.toolExecutor.execute(
      toolCall.name,
      approval.params,
      session.meta.working_directory,
    );

    const result: ToolExecutionResult = {
      success: execution.success,
      content: execution.content,
      diff: execution.diff,
      error: execution.error,
      duration_ms: execution.durationMs,
    };

    eventBus.emitTyped("tool-event", {
      type: "tool_result",
      session_id: sessionId,
      tool_call_id: toolCall.id,
      tool: toolCall.name,
      result,
    });

    return {
      type: "tool_result",
      tool_use_id: toolCall.id,
      content: formatToolResultForModel(toolCall.name, result),
      is_error: !result.success,
    };
  }
}
