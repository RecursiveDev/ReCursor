import type WebSocket from "ws";

export const SUPPORTED_AGENTS = ["claude-code"] as const;

export type SupportedAgent = (typeof SUPPORTED_AGENTS)[number];
export type AgentSessionStatus = "active" | "idle" | "closed";
export type RiskLevel = "low" | "medium" | "high" | "critical";
export type ApprovalDecision = "approved" | "rejected" | "modified";

export interface BridgeMessage<T = unknown> {
  type: string;
  id?: string;
  timestamp: string;
  payload: T;
}

export interface AuthPayload {
  token: string;
  client_version?: string;
  platform?: string;
}

export interface ActiveSessionPayload {
  session_id: string;
  agent: SupportedAgent;
  title: string;
  working_directory: string;
  status: AgentSessionStatus;
}

export interface ConnectionAckPayload {
  server_version: string;
  supported_agents: SupportedAgent[];
  active_sessions: ActiveSessionPayload[];
}

export interface ConnectionErrorPayload {
  code: string;
  message: string;
}

export type HeartbeatPingPayload = Record<string, never>;
export type HeartbeatPongPayload = Record<string, never>;

export interface SessionStartPayload {
  agent?: string;
  session_id?: string | null;
  working_directory?: string;
  resume?: boolean;
  system_prompt?: string;
  model?: string;
}

export interface SessionReadyPayload {
  session_id: string;
  agent: SupportedAgent;
  working_directory: string;
  status: "ready";
  model: string;
  branch?: string;
}

export interface SessionEndPayload {
  session_id: string;
  reason?: "user_request" | "timeout" | "error" | "completed";
}

export interface MessagePayload {
  session_id: string;
  content: string;
  role?: "user" | "assistant";
}

export interface StreamStartPayload {
  session_id: string;
  message_id: string;
}

export interface StreamChunkPayload {
  session_id: string;
  message_id: string;
  content: string;
  is_tool_use: boolean;
}

export interface StreamEndPayload {
  session_id: string;
  message_id: string;
  finish_reason: string;
}

export interface ToolCallPayload {
  session_id: string;
  tool_call_id: string;
  tool: string;
  params: Record<string, unknown>;
  description: string;
}

export interface ApprovalRequiredPayload {
  session_id: string;
  tool_call_id: string;
  tool: string;
  params: Record<string, unknown>;
  description: string;
  risk_level: RiskLevel;
  source: "hooks" | "agent_sdk";
}

export interface ApprovalResponsePayload {
  session_id: string;
  tool_call_id: string;
  decision: ApprovalDecision;
  modifications: Record<string, unknown> | null;
}

export interface ToolExecutionResult {
  success: boolean;
  content: string;
  diff?: string;
  error?: string;
  duration_ms?: number;
}

export interface ToolResultPayload {
  session_id: string;
  tool_call_id: string;
  tool: string;
  result: ToolExecutionResult;
}

export interface ClaudeEventPayload {
  event_type: string;
  session_id: string;
  timestamp: string;
  payload: Record<string, unknown>;
}

export interface GitFileChange {
  path: string;
  status: "added" | "modified" | "deleted" | "renamed" | "copied" | "untracked" | "unknown";
  staged: boolean;
}

export interface DiffLine {
  type: "context" | "added" | "removed";
  content: string;
  old_line_number?: number;
  new_line_number?: number;
}

export interface DiffHunk {
  old_start: number;
  old_lines: number;
  new_start: number;
  new_lines: number;
  header: string;
  lines: DiffLine[];
}

export interface DiffFile {
  path: string;
  old_path: string;
  new_path: string;
  status: "added" | "modified" | "deleted" | "renamed";
  additions: number;
  deletions: number;
  hunks: DiffHunk[];
}

export interface GitStatusRequestPayload {
  session_id?: string;
}

export interface GitStatusPayload {
  session_id?: string;
  branch: string;
  ahead: number;
  behind: number;
  is_clean: boolean;
  changes: GitFileChange[];
}

export interface GitStatusResponsePayload extends GitStatusPayload {}

export interface GitDiffPayload {
  session_id?: string;
  files?: string[];
  cached?: boolean;
}

export interface GitDiffResponsePayload {
  session_id?: string;
  files: DiffFile[];
}

export interface GitCommitPayload {
  session_id?: string;
  message: string;
  files?: string[];
}

export interface GitBranch {
  name: string;
  is_current: boolean;
  is_remote: boolean;
}

export interface FileListPayload {
  session_id?: string;
  path: string;
  offset?: number;
  limit?: number;
  includeHidden?: boolean;
}

export interface FileEntry {
  name: string;
  path?: string;
  type: "file" | "directory";
  size?: number;
  modified?: string;
}

export interface FileListResponsePayload {
  session_id?: string;
  path: string;
  entries: FileEntry[];
  total?: number;
  offset?: number;
  limit?: number;
  hasMore?: boolean;
}

export interface FileReadPayload {
  session_id?: string;
  path: string;
  offset?: number;
  limit?: number;
}

export interface FileReadResponsePayload {
  session_id?: string;
  path: string;
  content: string;
  size: number;
  lines: number;
  offset?: number;
  limit?: number;
  hasMore?: boolean;
  encoding?: "utf8";
}

export interface NotificationPayload {
  notification_id?: string;
  session_id?: string;
  notification_type: string;
  title: string;
  body: string;
  priority: "low" | "normal" | "high";
  data?: Record<string, unknown>;
}

export interface NotificationAckPayload {
  notification_ids: string[];
}

export interface ErrorPayload {
  code: string;
  message: string;
  session_id?: string;
  recoverable?: boolean;
  request_type?: string;
}

export interface MobileClient {
  id: string;
  ws: WebSocket;
  sessionIds: string[];
  authenticated: boolean;
}

export interface AgentSession {
  id: string;
  agent: SupportedAgent;
  title: string;
  model: string;
  working_directory: string;
  created_at: string;
  status: AgentSessionStatus;
}

export interface SessionConfig {
  agent?: SupportedAgent;
  sessionId?: string;
  workingDirectory?: string;
  systemPrompt?: string;
  model?: string;
}

export interface HookEvent {
  event_type: string;
  session_id: string;
  timestamp: string;
  payload: Record<string, unknown>;
}

export interface ToolResult {
  success: boolean;
  content: string;
  diff?: string;
  error?: string;
  durationMs: number;
}
