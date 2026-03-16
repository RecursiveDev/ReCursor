# Data Models

> Drift schemas, Hive models, and domain entities for RemoteCLI.

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

### Preferences Box

```dart
// Box name: 'preferences'
// Keys:
//   'theme_mode'        -> String: "system", "light", "dark"
//   'code_font_size'    -> int: 12-24
//   'notification_sound' -> bool
//   'notification_vibrate' -> bool
//   'quiet_hours_enabled' -> bool
//   'quiet_hours_start' -> String: "22:00"
//   'quiet_hours_end'   -> String: "07:00"
//   'auto_reconnect'    -> bool
//   'reconnect_timeout' -> int: seconds
//   'max_retry_attempts' -> int
//   'heartbeat_interval' -> int: seconds
//   'cert_pinning_enabled' -> bool
//   'require_tailscale' -> bool
//   'max_offline_storage_mb' -> int
//   'auto_clear_days'   -> int
```

### Session Cache Box

```dart
// Box name: 'session_cache'
// Keys:
//   'active_session_id'  -> String: current chat session ID
//   'active_agent_id'    -> String: current agent ID
//   'last_repo_owner'    -> String: last browsed repo owner
//   'last_repo_name'     -> String: last browsed repo name
//   'last_branch'        -> String: last selected branch
//   'last_sync_at'       -> String: ISO 8601 timestamp
```

---

## Domain Entities

Immutable domain objects used in the UI and business logic layers. These are separate from Drift models — repositories map between them.

### Message

```dart
class Message {
  final String id;
  final String sessionId;
  final MessageRole role;           // user, agent, system
  final String content;
  final MessageType type;           // text, toolCall, toolResult
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
}

enum MessageRole { user, agent, system }
enum MessageType { text, toolCall, toolResult }
```

### ChatSession

```dart
class ChatSession {
  final String id;
  final String agentType;
  final String title;
  final String workingDirectory;
  final String? branch;
  final SessionStatus status;       // active, paused, closed
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final Message? lastMessage;       // For session list preview
}

enum SessionStatus { active, paused, closed }
```

### AgentConfig

```dart
class AgentConfig {
  final String id;
  final String displayName;
  final AgentType agentType;
  final String bridgeUrl;
  final String authToken;
  final String? workingDirectory;
  final AgentConnectionStatus status;
  final DateTime? lastConnectedAt;
  final int activeSessions;
}

enum AgentType { claudeCode, openCode, aider, goose, custom }
enum AgentConnectionStatus { connected, disconnected, inactive }
```

### ToolCall

```dart
class ToolCall {
  final String id;
  final String sessionId;
  final String tool;                // "edit_file", "run_command", etc.
  final String description;
  final Map<String, dynamic> params;
  final String? reasoning;
  final RiskLevel riskLevel;
  final ApprovalDecision decision;
  final String? modifications;
  final ToolResult? result;
  final DateTime createdAt;
  final DateTime? decidedAt;
}

enum RiskLevel { low, medium, high, critical }
enum ApprovalDecision { pending, approved, rejected, modified }

class ToolResult {
  final bool success;
  final String output;
  final String? diff;
}
```

### GitStatus

```dart
class GitStatus {
  final String branch;
  final int modified;
  final int added;
  final int deleted;
  final int untracked;
  final int ahead;                  // Commits ahead of remote
  final int behind;                 // Commits behind remote
  final List<GitFileChange> files;
}

class GitFileChange {
  final String path;
  final FileChangeStatus status;    // modified, added, deleted, untracked
  final int additions;
  final int deletions;
}

enum FileChangeStatus { modified, added, deleted, untracked, renamed }
```

### GitBranch

```dart
class GitBranch {
  final String name;
  final bool isLocal;
  final bool isCurrent;
  final String? remoteName;         // "origin/main"
  final String? lastCommitMessage;
  final DateTime? lastCommitAt;
  final int? aheadBy;
  final int? behindBy;
}
```

### DiffFile

```dart
class DiffFile {
  final String path;
  final int additions;
  final int deletions;
  final bool isNew;
  final bool isDeleted;
  final List<DiffHunk> hunks;
}

class DiffHunk {
  final int oldStart;
  final int oldCount;
  final int newStart;
  final int newCount;
  final String header;              // "@@ -40,7 +40,8 @@"
  final List<DiffLine> lines;
}

class DiffLine {
  final DiffLineType type;         // context, added, removed
  final int? oldLineNumber;
  final int? newLineNumber;
  final String content;
}

enum DiffLineType { context, added, removed }
```

### FileTree (via Bridge)

```dart
class FileTreeNode {
  final String name;
  final String path;
  final FileNodeType type;         // file, directory
  final int? size;
  final List<FileTreeNode> children;
}

enum FileNodeType { file, directory }
```

---

## Serialization

- **Drift models:** Auto-generated by Drift's code generator. No manual JSON needed.
- **Domain entities:** Use `freezed` + `json_serializable` for immutable classes with `fromJson`/`toJson`.
- **WebSocket messages:** Parsed in `websocket_messages.dart` using a `type` field discriminator to route to the correct model's `fromJson`.

```dart
// Example message parsing
WebSocketMessage parseMessage(String raw) {
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return switch (json['type']) {
    'stream_chunk'  => StreamChunk.fromJson(json),
    'tool_call'     => ToolCallMessage.fromJson(json),
    'session_ready' => SessionReady.fromJson(json),
    'error'         => ErrorMessage.fromJson(json),
    _               => UnknownMessage(json),
  };
}
```
