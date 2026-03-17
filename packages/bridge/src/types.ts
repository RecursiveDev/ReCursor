import type WebSocket from "ws";

// ---------------------------------------------------------------------------
// Base envelope
// ---------------------------------------------------------------------------

export interface BridgeMessage<T = unknown> {
  type: string;
  id?: string;
  timestamp: string;
  payload: T;
}

// ---------------------------------------------------------------------------
// Auth / connection
// ---------------------------------------------------------------------------

export interface AuthPayload {
  token: string;
}

export interface ConnectionAckPayload {
  client_id: string;
  active_sessions: AgentSession[];
}

export interface ConnectionErrorPayload {
  code: string;
  message: string;
}

// ---------------------------------------------------------------------------
// Heartbeat
// ---------------------------------------------------------------------------

export type HeartbeatPingPayload = Record<string, never>;
export type HeartbeatPongPayload = Record<string, never>;

// ---------------------------------------------------------------------------
// Sessions
// ---------------------------------------------------------------------------

export interface SessionStartPayload {
  session_id?: string;
  working_directory?: string;
  system_prompt?: string;
  model?: string;
}

export interface SessionReadyPayload {
  session_id: string;
  model: string;
}

export interface SessionEndPayload {
  session_id: string;
}

// ---------------------------------------------------------------------------
// Chat / streaming
// ---------------------------------------------------------------------------

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
  delta: string;
  index: number;
}

export interface StreamEndPayload {
  session_id: string;
  message_id: string;
  stop_reason: string;
}

// ---------------------------------------------------------------------------
// Tools
// ---------------------------------------------------------------------------

export interface ToolCallPayload {
  session_id: string;
  tool_call_id: string;
  tool_name: string;
  tool_input: Record<string, unknown>;
}

export interface ApprovalRequiredPayload {
  session_id: string;
  tool_call_id: string;
  tool_name: string;
  tool_input: Record<string, unknown>;
  message: string;
}

export interface ApprovalResponsePayload {
  session_id: string;
  tool_call_id: string;
  decision: "approve" | "reject";
  reason?: string;
}

export interface ToolResultPayload {
  session_id: string;
  tool_call_id: string;
  tool_name: string;
  success: boolean;
  content: string;
  error?: string;
  duration_ms: number;
}

// ---------------------------------------------------------------------------
// Claude hook events
// ---------------------------------------------------------------------------

export interface ClaudeEventPayload {
  event_type: string;
  session_id: string;
  timestamp: string;
  payload: Record<string, unknown>;
}

// ---------------------------------------------------------------------------
// Git
// ---------------------------------------------------------------------------

export interface GitFileChange {
  path: string;
  status:
    | "added"
    | "modified"
    | "deleted"
    | "renamed"
    | "copied"
    | "untracked"
    | "unknown";
  staged: boolean;
}

export interface DiffLine {
  type: "context" | "addition" | "deletion";
  content: string;
  old_line_number?: number;
  new_line_number?: number;
}

export interface DiffHunk {
  old_start: number;
  old_count: number;
  new_start: number;
  new_count: number;
  header: string;
  lines: DiffLine[];
}

export interface DiffFile {
  old_path: string;
  new_path: string;
  is_new: boolean;
  is_deleted: boolean;
  is_renamed: boolean;
  hunks: DiffHunk[];
}

export interface GitStatusPayload {
  branch: string;
  ahead: number;
  behind: number;
  is_clean: boolean;
  changes: GitFileChange[];
}

export interface GitStatusResponsePayload extends GitStatusPayload {
  request_id?: string;
}

export interface GitDiffPayload {
  files?: string[];
  cached?: boolean;
}

export interface GitDiffResponsePayload {
  files: DiffFile[];
  request_id?: string;
}

export interface GitCommitPayload {
  message: string;
  files?: string[];
}

export interface GitBranch {
  name: string;
  is_current: boolean;
  is_remote: boolean;
}

// ---------------------------------------------------------------------------
// Files
// ---------------------------------------------------------------------------

export interface FileListPayload {
  path: string;
  offset?: number;
  limit?: number;
  includeHidden?: boolean;
  request_id?: string;
}

export interface FileEntry {
  name: string;
  path: string;
  type: "file" | "directory";
  size?: number;
  modified?: string;
}

export interface FileListResponsePayload {
  path: string;
  entries: FileEntry[];
  total: number;
  offset: number;
  limit: number;
  hasMore: boolean;
  request_id?: string;
}

export interface FileReadPayload {
  path: string;
  offset?: number;
  limit?: number;
  request_id?: string;
}

export interface FileReadResponsePayload {
  path: string;
  content: string;
  encoding: "utf8";
  totalLines: number;
  offset: number;
  limit: number;
  hasMore: boolean;
  request_id?: string;
}

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------

export interface NotificationPayload {
  notification_id: string;
  title: string;
  body: string;
  level: "info" | "warning" | "error";
  session_id?: string;
  metadata?: Record<string, unknown>;
}

export interface NotificationAckPayload {
  notification_id: string;
}

// ---------------------------------------------------------------------------
// Error
// ---------------------------------------------------------------------------

export interface ErrorPayload {
  code: string;
  message: string;
  request_type?: string;
}

// ---------------------------------------------------------------------------
// Internal domain models
// ---------------------------------------------------------------------------

export interface MobileClient {
  id: string;
  ws: WebSocket;
  sessionIds: string[];
  authenticated: boolean;
}

export interface AgentSession {
  id: string;
  model: string;
  working_directory: string;
  created_at: string;
  status: "active" | "idle" | "closed";
}

export interface SessionConfig {
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
  error?: string;
  durationMs: number;
}
