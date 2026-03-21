---
title: "Dart ↔ TypeScript Type Mapping Specification"
description: "Cross-language contract defining type-safe serialization between Flutter (Dart) and Bridge (TypeScript). TypeScript protocol is source-of-truth."
editUrl: "https://github.com/RecursiveDev/ReCursor/edit/main/docs-site/src/content/docs/type-mapping.md"
sidebar:
  order: 30
  label: "Type mapping"
---
> Cross-language contract defining type-safe serialization between Flutter (Dart) and Bridge (TypeScript). TypeScript protocol is source-of-truth.

---

## Overview

ReCursor uses a **TypeScript-first protocol** where:
- TypeScript types are the **source of truth**
- Dart types are **derived** and must match exactly
- JSON is the **wire format** for both directions

This document defines the mapping rules, edge cases, and validation requirements for maintaining type safety across the language boundary.

---

## Primitive Type Mapping

| TypeScript | Dart | JSON | Notes |
|------------|------|------|-------|
| `string` | `String` | string | UTF-8 encoded |
| `number` | `double` | number | All numbers are doubles in JSON |
| `number` (int) | `int` | number | Use `int` in Dart for integer values |
| `boolean` | `bool` | boolean | |
| `null` | `null` | null | |
| `undefined` | N/A | absent | Use nullable types in Dart |
| `Date` | `DateTime` | ISO 8601 string | Always UTC in transit |
| `bigint` | `int` | string | Serialize as string to avoid precision loss |
| `Uint8Array` | `Uint8List` | base64 string | Binary data encoding |

---

## String Enums

TypeScript string enums map to Dart enums with explicit string values.

### TypeScript (Source of Truth)

```typescript
export enum ConnectionMode {
  LocalOnly = 'local_only',
  PrivateNetwork = 'private_network',
  SecureRemote = 'secure_remote',
  DirectPublic = 'direct_public',
  Misconfigured = 'misconfigured'
}

export enum MessageType {
  Auth = 'auth',
  ConnectionAck = 'connection_ack',
  HealthCheck = 'health_check',
  HealthStatus = 'health_status',
  SessionStarted = 'session_started',
  SessionEnded = 'session_ended',
  ToolUse = 'tool_use',
  ToolResult = 'tool_result',
  Error = 'error'
}

export enum RiskLevel {
  Low = 'low',
  Medium = 'medium',
  High = 'high',
  Critical = 'critical'
}
```

### Dart (Derived)

```dart
enum ConnectionMode {
  localOnly('local_only'),
  privateNetwork('private_network'),
  secureRemote('secure_remote'),
  directPublic('direct_public'),
  misconfigured('misconfigured');

  final String value;
  const ConnectionMode(this.value);

  factory ConnectionMode.fromString(String value) {
    return ConnectionMode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown ConnectionMode: $value'),
    );
  }
}

enum MessageType {
  auth('auth'),
  connectionAck('connection_ack'),
  healthCheck('health_check'),
  healthStatus('health_status'),
  sessionStarted('session_started'),
  sessionEnded('session_ended'),
  toolUse('tool_use'),
  toolResult('tool_result'),
  error('error');

  final String value;
  const MessageType(this.value);

  factory MessageType.fromString(String value) {
    return MessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown MessageType: $value'),
    );
  }
}

enum RiskLevel {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  final String value;
  const RiskLevel(this.value);

  factory RiskLevel.fromString(String value) {
    return RiskLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown RiskLevel: $value'),
    );
  }
}
```

---

## Complex Types

### ProtocolMessage

Base message type for all WebSocket communication.

#### TypeScript (Source of Truth)

```typescript
export interface ProtocolMessage {
  type: MessageType;
  id: string;                    // UUID v4
  timestamp: string;             // ISO 8601 UTC
  payload: unknown;
}

export interface AuthPayload {
  token: string;
  client_version: string;
  platform: 'ios' | 'android' | 'web';
  device_id?: string;
}

export interface ConnectionAckPayload {
  server_version: string;
  supported_agents: string[];
  connection_mode: ConnectionMode;
  connection_mode_description: string;
  bridge_url: string;
  requires_health_verification: boolean;
  active_sessions: SessionInfo[];
}

export interface SessionInfo {
  session_id: string;
  agent: string;
  title: string;
  working_directory?: string;
}
```

#### Dart (Derived)

```dart
@JsonSerializable()
class ProtocolMessage {
  final MessageType type;
  final String id;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  ProtocolMessage({
    required this.type,
    required this.id,
    required this.timestamp,
    required this.payload,
  });

  factory ProtocolMessage.fromJson(Map<String, dynamic> json) =>
      _$ProtocolMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ProtocolMessageToJson(this);
}

@JsonSerializable()
class AuthPayload {
  final String token;
  final String clientVersion;
  final String platform;
  final String? deviceId;

  AuthPayload({
    required this.token,
    required this.clientVersion,
    required this.platform,
    this.deviceId,
  });

  factory AuthPayload.fromJson(Map<String, dynamic> json) =>
      _$AuthPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$AuthPayloadToJson(this);
}

@JsonSerializable()
class ConnectionAckPayload {
  final String serverVersion;
  final List<String> supportedAgents;
  final ConnectionMode connectionMode;
  final String connectionModeDescription;
  final String bridgeUrl;
  final bool requiresHealthVerification;
  final List<SessionInfo> activeSessions;

  ConnectionAckPayload({
    required this.serverVersion,
    required this.supportedAgents,
    required this.connectionMode,
    required this.connectionModeDescription,
    required this.bridgeUrl,
    required this.requiresHealthVerification,
    required this.activeSessions,
  });

  factory ConnectionAckPayload.fromJson(Map<String, dynamic> json) =>
      _$ConnectionAckPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectionAckPayloadToJson(this);
}

@JsonSerializable()
class SessionInfo {
  final String sessionId;
  final String agent;
  final String title;
  final String? workingDirectory;

  SessionInfo({
    required this.sessionId,
    required this.agent,
    required this.title,
    this.workingDirectory,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) =>
      _$SessionInfoFromJson(json);

  Map<String, dynamic> toJson() => _$SessionInfoToJson(this);
}
```

---

## Hook Event Types

### TypeScript (Source of Truth)

```typescript
export type HookEventType = 
  | 'SessionStart'
  | 'SessionEnd'
  | 'PreToolUse'
  | 'PostToolUse'
  | 'UserPromptSubmit'
  | 'Stop'
  | 'SubagentStop'
  | 'PreCompact'
  | 'Notification';

export interface HookEvent {
  event: HookEventType;
  timestamp: string;           // ISO 8601 UTC
  session_id: string;
  payload: HookEventPayload;
}

export type HookEventPayload = 
  | SessionStartPayload
  | SessionEndPayload
  | PreToolUsePayload
  | PostToolUsePayload
  | UserPromptSubmitPayload
  | StopPayload;

export interface SessionStartPayload {
  working_directory: string;
  initial_prompt?: string;
}

export interface SessionEndPayload {
  duration_seconds: number;
  message_count: number;
  exit_reason: 'user_exit' | 'error' | 'completion';
}

export interface PreToolUsePayload {
  tool: string;
  params: Record<string, unknown>;
  risk_level: RiskLevel;
  requires_approval: boolean;
}

export interface PostToolUsePayload {
  tool: string;
  params: Record<string, unknown>;
  result: unknown;
  execution_time_ms: number;
  success: boolean;
}

export interface UserPromptSubmitPayload {
  prompt: string;
  context_files?: string[];
  estimated_tokens?: number;
}

export interface StopPayload {
  reason: 'user_request' | 'tool_error' | 'max_tokens' | 'safety';
  context?: string;
}
```

### Dart (Derived)

```dart
@JsonSerializable()
class HookEvent {
  final String event;
  final DateTime timestamp;
  final String sessionId;
  final Map<String, dynamic> payload;

  HookEvent({
    required this.event,
    required this.timestamp,
    required this.sessionId,
    required this.payload,
  });

  factory HookEvent.fromJson(Map<String, dynamic> json) =>
      _$HookEventFromJson(json);

  Map<String, dynamic> toJson() => _$HookEventToJson(this);

  // Typed accessors
  SessionStartPayload? get asSessionStart => 
      event == 'SessionStart' ? SessionStartPayload.fromJson(payload) : null;
  
  PreToolUsePayload? get asPreToolUse =>
      event == 'PreToolUse' ? PreToolUsePayload.fromJson(payload) : null;
  
  PostToolUsePayload? get asPostToolUse =>
      event == 'PostToolUse' ? PostToolUsePayload.fromJson(payload) : null;
}

@JsonSerializable()
class SessionStartPayload {
  final String workingDirectory;
  final String? initialPrompt;

  SessionStartPayload({
    required this.workingDirectory,
    this.initialPrompt,
  });

  factory SessionStartPayload.fromJson(Map<String, dynamic> json) =>
      _$SessionStartPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$SessionStartPayloadToJson(this);
}

@JsonSerializable()
class SessionEndPayload {
  final int durationSeconds;
  final int messageCount;
  final String exitReason;

  SessionEndPayload({
    required this.durationSeconds,
    required this.messageCount,
    required this.exitReason,
  });

  factory SessionEndPayload.fromJson(Map<String, dynamic> json) =>
      _$SessionEndPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$SessionEndPayloadToJson(this);
}

@JsonSerializable()
class PreToolUsePayload {
  final String tool;
  final Map<String, dynamic> params;
  final RiskLevel riskLevel;
  final bool requiresApproval;

  PreToolUsePayload({
    required this.tool,
    required this.params,
    required this.riskLevel,
    required this.requiresApproval,
  });

  factory PreToolUsePayload.fromJson(Map<String, dynamic> json) =>
      _$PreToolUsePayloadFromJson(json);

  Map<String, dynamic> toJson() => _$PreToolUsePayloadToJson(this);
}

@JsonSerializable()
class PostToolUsePayload {
  final String tool;
  final Map<String, dynamic> params;
  final dynamic result;
  final int executionTimeMs;
  final bool success;

  PostToolUsePayload({
    required this.tool,
    required this.params,
    required this.result,
    required this.executionTimeMs,
    required this.success,
  });

  factory PostToolUsePayload.fromJson(Map<String, dynamic> json) =>
      _$PostToolUsePayloadFromJson(json);

  Map<String, dynamic> toJson() => _$PostToolUsePayloadToJson(this);
}

@JsonSerializable()
class UserPromptSubmitPayload {
  final String prompt;
  final List<String>? contextFiles;
  final int? estimatedTokens;

  UserPromptSubmitPayload({
    required this.prompt,
    this.contextFiles,
    this.estimatedTokens,
  });

  factory UserPromptSubmitPayload.fromJson(Map<String, dynamic> json) =>
      _$UserPromptSubmitPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$UserPromptSubmitPayloadToJson(this);
}

@JsonSerializable()
class StopPayload {
  final String reason;
  final String? context;

  StopPayload({
    required this.reason,
    this.context,
  });

  factory StopPayload.fromJson(Map<String, dynamic> json) =>
      _$StopPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$StopPayloadToJson(this);
}
```

---

## Error Types

### TypeScript (Source of Truth)

```typescript
export interface BridgeError {
  code: string;                // UPPER_SNAKE_CASE
  message: string;
  details?: Record<string, unknown>;
  recoverable: boolean;
  retry_after_ms?: number;
}

export interface ErrorMessage {
  type: 'error';
  id: string;
  payload: {
    code: string;
    message: string;
    original_message_id?: string;
    details?: Record<string, unknown>;
  };
}
```

### Dart (Derived)

```dart
@JsonSerializable()
class BridgeError {
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final bool recoverable;
  final int? retryAfterMs;

  BridgeError({
    required this.code,
    required this.message,
    this.details,
    required this.recoverable,
    this.retryAfterMs,
  });

  factory BridgeError.fromJson(Map<String, dynamic> json) =>
      _$BridgeErrorFromJson(json);

  Map<String, dynamic> toJson() => _$BridgeErrorToJson(this);
}

@JsonSerializable()
class ErrorMessage {
  final String type;
  final String id;
  final ErrorPayload payload;

  ErrorMessage({
    required this.type,
    required this.id,
    required this.payload,
  });

  factory ErrorMessage.fromJson(Map<String, dynamic> json) =>
      _$ErrorMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorMessageToJson(this);
}

@JsonSerializable()
class ErrorPayload {
  final String code;
  final String message;
  final String? originalMessageId;
  final Map<String, dynamic>? details;

  ErrorPayload({
    required this.code,
    required this.message,
    this.originalMessageId,
    this.details,
  });

  factory ErrorPayload.fromJson(Map<String, dynamic> json) =>
      _$ErrorPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorPayloadToJson(this);
}
```

---

## Date/Time Handling

### Rules

1. **All timestamps in transit are ISO 8601 UTC strings**
2. **TypeScript generates UTC**: `new Date().toISOString()`
3. **Dart parses to DateTime**: `DateTime.parse()` (assumes UTC if no timezone)
4. **Dart serializes to UTC**: `dateTime.toUtc().toIso8601String()`

### TypeScript

```typescript
// Always use toISOString() for wire format
const timestamp = new Date().toISOString(); // "2026-03-20T14:32:00.000Z"

// Parse incoming
const date = new Date(timestamp); // Converts to Date object
```

### Dart

```dart
// Serialization
String serializeDateTime(DateTime dt) => dt.toUtc().toIso8601String();

// Deserialization
DateTime deserializeDateTime(String iso) => DateTime.parse(iso).toUtc();

// JSON converter for json_serializable
class UTCDateTimeConverter implements JsonConverter<DateTime, String> {
  const UTCDateTimeConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json).toUtc();

  @override
  String toJson(DateTime dt) => dt.toUtc().toIso8601String();
}
```

---

## Nullability Rules

### TypeScript → Dart Mapping

| TypeScript | Dart | Notes |
|------------|------|-------|
| `string` | `String` | Non-nullable |
| `string \| null` | `String?` | Nullable |
| `string \| undefined` | `String?` | Nullable (undefined becomes null in JSON) |
| `string?` (optional) | `String?` | Nullable |
| `T[]` | `List<T>` | Non-nullable list, non-nullable items |
| `T[] \| null` | `List<T>?` | Nullable list |
| `(T \| null)[]` | `List<T?>` | Non-nullable list, nullable items |

### Example

```typescript
interface Example {
  required: string;           // → String
  optional?: string;          // → String?
  nullable: string | null;    // → String?
  array: string[];            // → List<String>
  nullableArray: string[] | null;  // → List<String>?
  mixedArray: (string | null)[];   // → List<String?>
}
```

```dart
@JsonSerializable()
class Example {
  final String required;
  final String? optional;
  final String? nullable;
  final List<String> array;
  final List<String>? nullableArray;
  final List<String?> mixedArray;

  Example({
    required this.required,
    this.optional,
    this.nullable,
    required this.array,
    this.nullableArray,
    required this.mixedArray,
  });
}
```

---

## Validation Requirements

### TypeScript Validation (Zod)

```typescript
import { z } from 'zod';

export const ProtocolMessageSchema = z.object({
  type: z.enum(['auth', 'connection_ack', 'health_check', /* ... */]),
  id: z.string().uuid(),
  timestamp: z.string().datetime(),
  payload: z.record(z.unknown()),
});

export const HookEventSchema = z.object({
  event: z.enum(['SessionStart', 'SessionEnd', 'PreToolUse', /* ... */]),
  timestamp: z.string().datetime(),
  session_id: z.string().min(1),
  payload: z.record(z.unknown()),
});

export function validateMessage(data: unknown): ProtocolMessage {
  return ProtocolMessageSchema.parse(data);
}
```

### Dart Validation

```dart
class MessageValidator {
  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static void validateProtocolMessage(Map<String, dynamic> json) {
    if (!json.containsKey('type')) {
      throw ValidationError('Missing required field: type');
    }
    if (!json.containsKey('id')) {
      throw ValidationError('Missing required field: id');
    }
    if (!_uuidRegex.hasMatch(json['id'] as String)) {
      throw ValidationError('Invalid UUID format: ${json['id']}');
    }
    if (!json.containsKey('timestamp')) {
      throw ValidationError('Missing required field: timestamp');
    }
    try {
      DateTime.parse(json['timestamp'] as String);
    } catch (e) {
      throw ValidationError('Invalid timestamp format: ${json['timestamp']}');
    }
  }
}

class ValidationError implements Exception {
  final String message;
  ValidationError(this.message);
  
  @override
  String toString() => 'ValidationError: $message';
}
```

---

## Version Compatibility

### Protocol Versioning

```typescript
// TypeScript
interface VersionInfo {
  protocol_version: string;    // "1.0.0"
  min_client_version: string;   // "1.0.0"
  max_client_version: string;   // "1.1.0"
}

function checkCompatibility(
  clientVersion: string,
  serverVersion: VersionInfo
): CompatibilityResult {
  if (compareVersions(clientVersion, serverVersion.min_client_version) < 0) {
    return { compatible: false, reason: 'CLIENT_TOO_OLD' };
  }
  if (compareVersions(clientVersion, serverVersion.max_client_version) > 0) {
    return { compatible: false, reason: 'CLIENT_TOO_NEW' };
  }
  return { compatible: true };
}
```

```dart
// Dart
class VersionCompatibility {
  static bool check(String clientVersion, VersionInfo serverInfo) {
    final client = _parseVersion(clientVersion);
    final min = _parseVersion(serverInfo.minClientVersion);
    final max = _parseVersion(serverInfo.maxClientVersion);
    
    return client >= min && client <= max;
  }
  
  static Version _parseVersion(String v) {
    final parts = v.split('.').map(int.parse).toList();
    return Version(parts[0], parts[1], parts[2]);
  }
}
```

---

## Code Generation

### TypeScript → Dart Workflow

1. Define types in TypeScript (source of truth)
2. Run code generator to produce Dart types
3. Commit both to repository
4. CI validates Dart types match TypeScript

### Generator Script (Conceptual)

```typescript
// scripts/generate-dart-types.ts
import { generateDartTypes } from './type-generator';
import * as fs from 'fs';

const typescriptTypes = fs.readFileSync('src/types/protocol.ts', 'utf-8');
const dartOutput = generateDartTypes(typescriptTypes, {
  useJsonSerializable: true,
  useFreezed: false,
});

fs.writeFileSync('../apps/mobile/lib/core/models/protocol.g.dart', dartOutput);
```

---

*Last updated: 2026-03-20*
