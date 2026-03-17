# Data Models

> Drift schemas, Hive models, and domain entities for ReCursor.

---

## Drift Database Tables (SQLite)

### Sessions

Stores agent chat sessions.

```dart
class Sessions extends Table {
  TextColumn get id => text()();                          // "sess-abc123"
  TextColumn get agentType => text()();                   // "claude-code", "opencode", etc.
  TextColumn get agentId => text().nullable()();          // FK to agents table
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get workingDirectory => text()();
  TextColumn get branch => text().nullable()();
  TextColumn get status => text()();                      // "active", "paused", "closed"
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastMessageAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### Messages

Stores chat messages within sessions.

```dart
class Messages extends Table {
  TextColumn get id => text()();                          // "msg-001"
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get role => text()();                        // "user", "agent", "system"
  TextColumn get content => text()();                     // Full text (markdown)
  TextColumn get messageType => text()
      .withDefault(const Constant('text'))();             // "text", "tool_call", "tool_result"
  TextColumn get metadata => text().nullable()();         // JSON: token count, tool info, etc.
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### Agents

Stores configured agent connections.

```dart
class Agents extends Table {
  TextColumn get id => text()();                          // UUID
  TextColumn get displayName => text()();                 // "Claude Code"
  TextColumn get agentType => text()();                   // "claude-code", "opencode", "aider", "goose", "custom"
  TextColumn get bridgeUrl => text()();                   // "wss://100.78.42.15:3000"
  TextColumn get authToken => text()();                   // Encrypted bridge auth token
  TextColumn get workingDirectory => text().nullable()();
  TextColumn get status => text()
      .withDefault(const Constant('disconnected'))();     // "connected", "disconnected", "inactive"
  DateTimeColumn get lastConnectedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### Approvals

Stores tool call approval history.

```dart
class Approvals extends Table {
  TextColumn get id => text()();                          // "tool-001"
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get tool => text()();                        // "edit_file", "run_command", etc.
  TextColumn get description => text()();                 // Human-readable description
  TextColumn get params => text()();                      // JSON: tool parameters
  TextColumn get reasoning => text().nullable()();        // Agent's explanation
  TextColumn get riskLevel => text()();                   // "low", "medium", "high", "critical"
  TextColumn get decision => text()();                    // "approved", "rejected", "modified", "pending"
  TextColumn get modifications => text().nullable()();    // User's modification instructions
  TextColumn get result => text().nullable()();           // JSON: tool execution result
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get decidedAt => dateTime().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### SyncQueue

Offline mutation queue.

```dart
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operation => text()();                   // "send_message", "approve_tool", "git_command"
  TextColumn get payload => text()();                     // JSON: full operation payload
  TextColumn get sessionId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}
```

### TerminalSessions

Stores terminal session metadata.

```dart
class TerminalSessions extends Table {
  TextColumn get id => text()();                          // "term-sess-001"
  TextColumn get name => text()();                        // "main", "feature-branch"
  TextColumn get workingDirectory => text()();
  TextColumn get status => text()();                      // "active", "closed"
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastActivityAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

---

## Hive Boxes (Key-Value)

### Auth Box

```dart
@HiveType(typeId: 1)
class AuthState {
  @HiveField(0)
  final String accessToken;
  
  @HiveField(1)
  final String refreshToken;
  
  @HiveField(2)
  final DateTime expiresAt;
  
  @HiveField(3)
  final String tokenType; // "oauth" | "pat"
}
```

### Connection Box

```dart
@HiveType(typeId: 2)
class ConnectionState {
  @HiveField(0)
  final String status; // "connected", "disconnected", "reconnecting"
  
  @HiveField(1)
  final String? bridgeUrl;
  
  @HiveField(2)
  final DateTime? lastConnectedAt;
  
  @HiveField(3)
  final int reconnectAttempts;
}
```

### Preferences Box

```dart
@HiveType(typeId: 3)
class UserPreferences {
  @HiveField(0)
  final ThemeMode themeMode;
  
  @HiveField(1)
  final String? defaultAgentId;
  
  @HiveField(2)
  final bool notificationsEnabled;
  
  @HiveField(3)
  final bool offlineModeEnabled;
}
```

---

## Domain Entities (Freezed)

### Message

```dart
@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required String sessionId,
    required MessageRole role,
    required String content,
    required MessageType type,
    required List<MessagePart> parts,
    Map<String, dynamic>? metadata,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(true) bool synced,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}

enum MessageRole { user, agent, system }
enum MessageType { text, toolCall, toolResult, system }
```

### MessagePart (OpenCode-style)

```dart
@freezed
class MessagePart with _$MessagePart {
  const factory MessagePart.text({
    required String content,
  }) = TextPart;

  const factory MessagePart.toolUse({
    required String tool,
    required Map<String, dynamic> params,
    String? id,
  }) = ToolUsePart;

  const factory MessagePart.toolResult({
    required String toolCallId,
    required ToolResult result,
  }) = ToolResultPart;

  const factory MessagePart.thinking({
    required String content,
  }) = ThinkingPart;

  factory MessagePart.fromJson(Map<String, dynamic> json) =>
      _$MessagePartFromJson(json);
}
```

### ChatSession

```dart
@freezed
class ChatSession with _$ChatSession {
  const factory ChatSession({
    required String id,
    required String agentType,
    String? agentId,
    @Default('') String title,
    required String workingDirectory,
    String? branch,
    @Default(SessionStatus.active) SessionStatus status,
    required DateTime createdAt,
    DateTime? lastMessageAt,
    DateTime? updatedAt,
    @Default(true) bool synced,
  }) = _ChatSession;

  factory ChatSession.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionFromJson(json);
}

enum SessionStatus { active, paused, closed }
```

### AgentConfig

```dart
@freezed
class AgentConfig with _$AgentConfig {
  const factory AgentConfig({
    required String id,
    required String displayName,
    required AgentType type,
    required String bridgeUrl,
    required String authToken,
    String? workingDirectory,
    @Default(AgentConnectionStatus.disconnected) AgentConnectionStatus status,
    DateTime? lastConnectedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AgentConfig;

  factory AgentConfig.fromJson(Map<String, dynamic> json) =>
      _$AgentConfigFromJson(json);
}

enum AgentType { claudeCode, openCode, aider, goose, custom }
enum AgentConnectionStatus { connected, disconnected, inactive }
```

### ToolCall

```dart
@freezed
class ToolCall with _$ToolCall {
  const factory ToolCall({
    required String id,
    required String sessionId,
    required String tool,
    required Map<String, dynamic> params,
    String? description,
    String? reasoning,
    @Default(RiskLevel.low) RiskLevel riskLevel,
    @Default(ApprovalDecision.pending) ApprovalDecision decision,
    String? modifications,
    Map<String, dynamic>? result,
    required DateTime createdAt,
    DateTime? decidedAt,
  }) = _ToolCall;

  factory ToolCall.fromJson(Map<String, dynamic> json) =>
      _$ToolCallFromJson(json);
}

enum RiskLevel { low, medium, high, critical }
enum ApprovalDecision { pending, approved, rejected, modified }
```

### ToolResult

```dart
@freezed
class ToolResult with _$ToolResult {
  const factory ToolResult({
    required bool success,
    required String content,
    Map<String, dynamic>? metadata,
    String? error,
    int? durationMs,
  }) = _ToolResult;

  factory ToolResult.fromJson(Map<String, dynamic> json) =>
      _$ToolResultFromJson(json);
}
```

---

## Git Models

### GitStatus

```dart
@freezed
class GitStatus with _$GitStatus {
  const factory GitStatus({
    required String branch,
    required List<GitFileChange> changes,
    required int ahead,
    required int behind,
    required bool isClean,
  }) = _GitStatus;

  factory GitStatus.fromJson(Map<String, dynamic> json) =>
      _$GitStatusFromJson(json);
}
```

### GitFileChange

```dart
@freezed
class GitFileChange with _$GitFileChange {
  const factory GitFileChange({
    required String path,
    required FileChangeStatus status,
    int? additions,
    int? deletions,
    String? diff,
  }) = _GitFileChange;

  factory GitFileChange.fromJson(Map<String, dynamic> json) =>
      _$GitFileChangeFromJson(json);
}

enum FileChangeStatus { modified, added, deleted, untracked, renamed }
```

### GitBranch

```dart
@freezed
class GitBranch with _$GitBranch {
  const factory GitBranch({
    required String name,
    required bool isCurrent,
    String? upstream,
    int? ahead,
    int? behind,
  }) = _GitBranch;

  factory GitBranch.fromJson(Map<String, dynamic> json) =>
      _$GitBranchFromJson(json);
}
```

---

## Diff Models

### DiffFile

```dart
@freezed
class DiffFile with _$DiffFile {
  const factory DiffFile({
    required String path,
    required String oldPath,
    required String newPath,
    required FileChangeStatus status,
    required int additions,
    required int deletions,
    required List<DiffHunk> hunks,
    String? oldMode,
    String? newMode,
  }) = _DiffFile;

  factory DiffFile.fromJson(Map<String, dynamic> json) =>
      _$DiffFileFromJson(json);
}
```

### DiffHunk

```dart
@freezed
class DiffHunk with _$DiffHunk {
  const factory DiffHunk({
    required String header,
    required int oldStart,
    required int oldLines,
    required int newStart,
    required int newLines,
    required List<DiffLine> lines,
  }) = _DiffHunk;

  factory DiffHunk.fromJson(Map<String, dynamic> json) =>
      _$DiffHunkFromJson(json);
}
```

### DiffLine

```dart
@freezed
class DiffLine with _$DiffLine {
  const factory DiffLine({
    required DiffLineType type,
    required String content,
    int? oldLineNumber,
    int? newLineNumber,
  }) = _DiffLine;

  factory DiffLine.fromJson(Map<String, dynamic> json) =>
      _$DiffLineFromJson(json);
}

enum DiffLineType { context, added, removed }
```

---

## File Tree Models

### FileTreeNode

```dart
@freezed
class FileTreeNode with _$FileTreeNode {
  const factory FileTreeNode({
    required String name,
    required String path,
    required FileNodeType type,
    List<FileTreeNode>? children,
    int? size,
    DateTime? modifiedAt,
    String? content,
  }) = _FileTreeNode;

  factory FileTreeNode.fromJson(Map<String, dynamic> json) =>
      _$FileTreeNodeFromJson(json);
}

enum FileNodeType { file, directory }
```

---

## Hook Event Models

### HookEvent

```dart
@freezed
class HookEvent with _$HookEvent {
  const factory HookEvent({
    required String eventType,
    required String sessionId,
    required DateTime timestamp,
    required Map<String, dynamic> payload,
  }) = _HookEvent;

  factory HookEvent.fromJson(Map<String, dynamic> json) =>
      _$HookEventFromJson(json);
}
```

### PostToolUseEvent

```dart
@freezed
class PostToolUseEvent with _$PostToolUseEvent {
  const factory PostToolUseEvent({
    required String tool,
    required Map<String, dynamic> toolInput,
    required ToolResult result,
    Map<String, dynamic>? metadata,
  }) = _PostToolUseEvent;

  factory PostToolUseEvent.fromJson(Map<String, dynamic> json) =>
      _$PostToolUseEventFromJson(json);
}
```

### PreToolUseEvent

```dart
@freezed
class PreToolUseEvent with _$PreToolUseEvent {
  const factory PreToolUseEvent({
    required String tool,
    required Map<String, dynamic> toolInput,
    required String riskLevel,
    required String description,
    required bool requiresApproval,
  }) = _PreToolUseEvent;

  factory PreToolUseEvent.fromJson(Map<String, dynamic> json) =>
      _$PreToolUseEventFromJson(json);
}
```

---

## Related Documentation

- [Project Structure](project-structure.md) — Flutter directory layout
- [Bridge Protocol](bridge-protocol.md) — WebSocket message specification
- [Offline Architecture](offline-architecture.md) — Sync and storage patterns
- [Claude Code Hooks Integration](integration/claude-code-hooks.md) — Event models
- [OpenCode UI Patterns](integration/opencode-ui-patterns.md) — UI component data

---

*Last updated: 2026-03-17*
