import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/message_models.dart';
import '../../../../core/models/session_models.dart';
import '../../../../core/network/connection_state.dart';
import '../../../../core/network/websocket_messages.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/sync_queue_provider.dart';
import '../../../../core/providers/websocket_provider.dart';
import '../../../../core/storage/database.dart' as db_lib;
import 'session_provider.dart';

part 'chat_provider.g.dart';

const _uuid = Uuid();
const _messageOperation = 'message';
const _sessionStartOperation = 'session_start';
const _sessionEndOperation = 'session_end';

// ---------------------------------------------------------------------------
// Streaming message buffer: sessionId → current streaming text
// ---------------------------------------------------------------------------

final streamingMessageProvider =
    StateProvider<Map<String, String>>((ref) => {});

// ---------------------------------------------------------------------------
// Messages stream for a session
// ---------------------------------------------------------------------------

@riverpod
Stream<List<Message>> messages(Ref ref, String sessionId) {
  final db = ref.watch(databaseProvider);
  return db.messageDao.watchMessagesForSession(sessionId).map(
        (rows) => rows.map(_rowToDomainMessage).toList(),
      );
}

Message _rowToDomainMessage(db_lib.Message row) {
  List<MessagePart> parts = [];
  if (row.metadata != null) {
    try {
      final decoded = jsonDecode(row.metadata!) as Map<String, dynamic>;
      final partsJson = decoded['parts'] as List<dynamic>?;
      if (partsJson != null) {
        parts = partsJson
            .map((p) => MessagePart.fromJson(p as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
  }
  final role = MessageRole.values.firstWhere(
    (e) => e.name == row.role,
    orElse: () => MessageRole.agent,
  );
  final type = MessageType.values.firstWhere(
    (e) => e.name == row.messageType,
    orElse: () => MessageType.text,
  );
  return Message(
    id: row.id,
    sessionId: row.sessionId,
    role: role,
    content: row.content,
    type: type,
    parts: parts,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    synced: row.synced,
  );
}

// ---------------------------------------------------------------------------
// Chat notifier
// ---------------------------------------------------------------------------

@riverpod
class ChatNotifier extends _$ChatNotifier {
  StreamSubscription<BridgeMessage>? _messageSubscription;
  StreamSubscription<ConnectionStatus>? _statusSubscription;
  Future<void> _messagePipeline = Future<void>.value();

  @override
  Future<void> build() async {
    final service = ref.watch(webSocketServiceProvider);
    final syncQueue = ref.watch(syncQueueServiceProvider);

    final cachedAckPayload = service.lastConnectionAckPayload;
    if (cachedAckPayload != null) {
      await _syncActiveSessions(cachedAckPayload);
    }
    if (service.currentStatus == ConnectionStatus.connected) {
      await syncQueue.flush(service);
    }

    _messageSubscription = service.messages.listen((message) {
      _messagePipeline = _messagePipeline
          .catchError((Object _, StackTrace __) {})
          .then((_) => _handleBridgeMessage(message));
    });
    _statusSubscription = service.connectionStatus.listen((status) async {
      if (status == ConnectionStatus.connected) {
        await syncQueue.flush(service);
        final ackPayload = service.lastConnectionAckPayload;
        if (ackPayload != null) {
          await _syncActiveSessions(ackPayload);
        }
      }
    });

    ref.onDispose(() {
      _messageSubscription?.cancel();
      _statusSubscription?.cancel();
    });
  }

  Future<void> _handleBridgeMessage(BridgeMessage message) async {
    final payload = message.payload;

    switch (message.type) {
      case BridgeMessageType.connectionAck:
        await _syncActiveSessions(payload);
        break;
      case BridgeMessageType.sessionReady:
        await _persistSessionReady(payload);
        break;
      case BridgeMessageType.streamStart:
        _setStreaming(_stringValue(payload['session_id']), '');
        break;
      case BridgeMessageType.streamChunk:
        _appendStreaming(
          _stringValue(payload['session_id']),
          _stringValue(payload['content']),
        );
        break;
      case BridgeMessageType.streamEnd:
        await _finalizeStreaming(_stringValue(payload['session_id']));
        break;
      case BridgeMessageType.approvalRequired:
        await _persistApprovalRequired(message);
        break;
      case BridgeMessageType.toolResult:
        await _persistToolResult(message);
        break;
      case BridgeMessageType.claudeEvent:
        await _handleClaudeEvent(message);
        break;
      case BridgeMessageType.sessionEnd:
        await _markSessionClosed(_stringValue(payload['session_id']));
        break;
      default:
        break;
    }
  }

  Future<void> _syncActiveSessions(Map<String, dynamic> payload) async {
    final rawSessions = payload['active_sessions'] as List<dynamic>? ?? [];
    for (final rawSession in rawSessions.whereType<Map<String, dynamic>>()) {
      await _upsertSession(
        sessionId: _stringValue(rawSession['session_id']),
        agentType: _stringValue(rawSession['agent'], fallback: 'claude-code'),
        title: _stringValue(rawSession['title']),
        workingDirectory: _stringValue(rawSession['working_directory']),
        status: _sessionStatusFromRemote(rawSession['status'] as String?),
        synced: true,
      );
    }
    ref.invalidate(activeSessionsProvider);
  }

  void _setStreaming(String sessionId, String text) {
    if (sessionId.isEmpty) {
      return;
    }

    final current = Map<String, String>.from(
      ref.read(streamingMessageProvider),
    );
    current[sessionId] = text;
    ref.read(streamingMessageProvider.notifier).state = current;
  }

  void _appendStreaming(String sessionId, String chunk) {
    if (sessionId.isEmpty || chunk.isEmpty) {
      return;
    }

    final current = Map<String, String>.from(
      ref.read(streamingMessageProvider),
    );
    current[sessionId] = (current[sessionId] ?? '') + chunk;
    ref.read(streamingMessageProvider.notifier).state = current;
  }

  Future<void> _finalizeStreaming(String sessionId) async {
    if (sessionId.isEmpty) {
      return;
    }

    final current = Map<String, String>.from(
      ref.read(streamingMessageProvider),
    );
    final text = current.remove(sessionId) ?? '';
    ref.read(streamingMessageProvider.notifier).state = current;

    if (text.isEmpty) {
      return;
    }

    await _ensureSessionExists(sessionId);
    final now = DateTime.now().toUtc();
    await _insertMessage(
      Message(
        id: _uuid.v4(),
        sessionId: sessionId,
        role: MessageRole.agent,
        content: text,
        type: MessageType.text,
        parts: [MessagePart.text(content: text)],
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _persistSessionReady(Map<String, dynamic> payload) async {
    final sessionId = _stringValue(payload['session_id']);
    if (sessionId.isEmpty) {
      return;
    }

    await _upsertSession(
      sessionId: sessionId,
      agentType: _stringValue(payload['agent'], fallback: 'claude-code'),
      title: _titleFromWorkingDirectory(
        _stringValue(payload['working_directory']),
      ),
      workingDirectory: _stringValue(payload['working_directory']),
      branch: _nullableStringValue(payload['branch']),
      status: SessionStatus.active,
      synced: true,
    );
    ref.invalidate(activeSessionsProvider);
  }

  Future<void> _persistApprovalRequired(BridgeMessage message) async {
    final payload = message.payload;
    final sessionId = _stringValue(payload['session_id']);
    if (sessionId.isEmpty) {
      return;
    }

    await _ensureSessionExists(sessionId);
    final toolCallId = _stringValue(payload['tool_call_id']);
    final receivedAt = _messageTimestamp(message);
    await _insertMessage(
      Message(
        id: _remoteMessageId(
          message,
          fallback: 'approval:$sessionId:$toolCallId',
        ),
        sessionId: sessionId,
        role: MessageRole.agent,
        content: _stringValue(payload['description']),
        type: MessageType.toolCall,
        parts: [
          MessagePart.toolUse(
            tool: _stringValue(payload['tool'], fallback: 'unknown_tool'),
            params: _mapValue(payload['params']),
            id: toolCallId,
          ),
        ],
        metadata: {
          'description': _stringValue(payload['description']),
          'risk_level': _stringValue(payload['risk_level']),
          'source': _stringValue(payload['source']),
          'session_id': sessionId,
          'tool_call_id': toolCallId,
        },
        createdAt: receivedAt,
        updatedAt: receivedAt,
      ),
    );
  }

  Future<void> _persistToolResult(BridgeMessage message) async {
    final payload = message.payload;
    final sessionId = _stringValue(payload['session_id']);
    if (sessionId.isEmpty) {
      return;
    }

    await _ensureSessionExists(sessionId);
    final resultMap = _mapValue(payload['result']);
    final toolName = _stringValue(payload['tool'], fallback: 'unknown_tool');
    final toolCallId = _stringValue(payload['tool_call_id']);
    final metadata = <String, dynamic>{
      'tool': toolName,
      'session_id': sessionId,
      'tool_call_id': toolCallId,
      'source': _stringValue(payload['source']),
    };
    final diff = resultMap['diff'] as String?;
    if (diff != null && diff.isNotEmpty) {
      metadata['diff'] = diff;
    }

    final receivedAt = _messageTimestamp(message);
    await _insertMessage(
      Message(
        id: _remoteMessageId(
          message,
          fallback: 'tool_result:$sessionId:$toolCallId',
        ),
        sessionId: sessionId,
        role: MessageRole.agent,
        content: _stringValue(resultMap['content']),
        type: MessageType.toolResult,
        parts: [
          MessagePart.toolResult(
            toolCallId: toolCallId,
            result: ToolResult(
              success: resultMap['success'] as bool? ?? true,
              content: _stringValue(resultMap['content']),
              metadata: metadata,
              error: resultMap['error'] as String?,
              durationMs: resultMap['duration_ms'] as int?,
            ),
          ),
        ],
        createdAt: receivedAt,
        updatedAt: receivedAt,
      ),
    );
  }

  Future<void> _handleClaudeEvent(BridgeMessage message) async {
    final payload = message.payload;
    final eventType = _stringValue(payload['event_type']);
    final sessionId = _stringValue(payload['session_id']);
    final eventPayload = _mapValue(payload['payload']);

    if (sessionId.isEmpty || eventType.isEmpty) {
      return;
    }

    final receivedAt = _payloadTimestamp(
      payload['timestamp'],
      fallback: _messageTimestamp(message),
    );

    switch (eventType) {
      case 'SessionStart':
        await _ensureSessionExists(
          sessionId,
          workingDirectory: _stringValue(eventPayload['working_directory']),
          title: _stringValue(eventPayload['title']),
          branch: _nullableStringValue(eventPayload['branch']),
        );
        ref.invalidate(activeSessionsProvider);
        break;
      case 'UserPromptSubmit':
        final content = _stringValue(
          eventPayload['prompt'],
          fallback: _stringValue(
            eventPayload['message'],
            fallback: _stringValue(eventPayload['text']),
          ),
        );
        if (content.isEmpty) {
          break;
        }
        await _ensureSessionExists(sessionId);
        await _insertMessage(
          Message(
            id: _remoteMessageId(
              message,
              fallback:
                  'claude_event:$sessionId:$eventType:${receivedAt.toIso8601String()}',
            ),
            sessionId: sessionId,
            role: MessageRole.user,
            content: content,
            type: MessageType.text,
            parts: [MessagePart.text(content: content)],
            createdAt: receivedAt,
            updatedAt: receivedAt,
          ),
        );
        break;
      case 'SessionEnd':
      case 'Stop':
        await _ensureSessionExists(sessionId);
        await _markSessionClosed(sessionId);
        break;
      default:
        break;
    }

    final sessionEvent = _sessionEventFromHook(
      message: message,
      eventType: eventType,
      sessionId: sessionId,
      eventPayload: eventPayload,
      timestamp: receivedAt,
    );
    if (sessionEvent != null) {
      await _ensureSessionExists(sessionId);
      await _insertSessionEvent(sessionEvent);
    }
  }

  Future<void> _ensureSessionExists(
    String sessionId, {
    String? workingDirectory,
    String? title,
    String? branch,
  }) async {
    final db = ref.read(databaseProvider);
    final existing = await db.sessionDao.getSession(sessionId);
    if (existing != null) {
      final hasSessionMetadata =
          (workingDirectory != null && workingDirectory.isNotEmpty) ||
              (title != null && title.isNotEmpty) ||
              (branch != null && branch.isNotEmpty);
      if (!hasSessionMetadata) {
        return;
      }

      final resolvedWorkingDirectory =
          workingDirectory ?? existing.workingDirectory;
      await _upsertSession(
        sessionId: sessionId,
        agentType: existing.agentType,
        title: title ?? _titleFromWorkingDirectory(resolvedWorkingDirectory),
        workingDirectory: resolvedWorkingDirectory,
        branch: branch ?? existing.branch,
        status: _sessionStatusFromRemote(existing.status),
        synced: existing.synced,
      );
      return;
    }

    await _upsertSession(
      sessionId: sessionId,
      agentType: 'claude-code',
      title: title ?? _titleFromWorkingDirectory(workingDirectory ?? ''),
      workingDirectory: workingDirectory ?? '',
      branch: branch,
      status: SessionStatus.active,
      synced: true,
    );
  }

  Future<void> _upsertSession({
    required String sessionId,
    required String agentType,
    required String title,
    required String workingDirectory,
    String? branch,
    required SessionStatus status,
    required bool synced,
  }) async {
    if (sessionId.isEmpty) {
      return;
    }

    final db = ref.read(databaseProvider);
    final existing = await db.sessionDao.getSession(sessionId);
    final now = DateTime.now().toUtc();

    await db.sessionDao.upsertSession(
      db_lib.SessionsCompanion(
        id: Value(sessionId),
        agentType: Value(existing?.agentType ?? agentType),
        agentId: Value(existing?.agentId),
        title: Value(
          _resolveSessionTitle(
            existing?.title,
            title,
            workingDirectory,
          ),
        ),
        workingDirectory: Value(
          _coalesceNonEmpty(existing?.workingDirectory, workingDirectory),
        ),
        branch: Value(branch ?? existing?.branch),
        status: Value(status.name),
        createdAt: Value(existing?.createdAt ?? now),
        lastMessageAt: Value(existing?.lastMessageAt),
        updatedAt: Value(now),
        synced: Value((existing?.synced ?? false) || synced),
      ),
    );
  }

  Future<void> _touchSession(String sessionId) async {
    final db = ref.read(databaseProvider);
    final existing = await db.sessionDao.getSession(sessionId);
    if (existing == null) {
      return;
    }

    final now = DateTime.now().toUtc();
    await db.sessionDao.upsertSession(
      db_lib.SessionsCompanion(
        id: Value(existing.id),
        agentType: Value(existing.agentType),
        agentId: Value(existing.agentId),
        title: Value(existing.title),
        workingDirectory: Value(existing.workingDirectory),
        branch: Value(existing.branch),
        status: Value(existing.status),
        createdAt: Value(existing.createdAt),
        lastMessageAt: Value(now),
        updatedAt: Value(now),
        synced: Value(existing.synced),
      ),
    );
    ref.invalidate(activeSessionsProvider);
  }

  Future<void> _markSessionClosed(String sessionId) async {
    if (sessionId.isEmpty) {
      return;
    }

    final db = ref.read(databaseProvider);
    final existing = await db.sessionDao.getSession(sessionId);
    if (existing == null) {
      return;
    }

    final now = DateTime.now().toUtc();
    await db.sessionDao.upsertSession(
      db_lib.SessionsCompanion(
        id: Value(existing.id),
        agentType: Value(existing.agentType),
        agentId: Value(existing.agentId),
        title: Value(existing.title),
        workingDirectory: Value(existing.workingDirectory),
        branch: Value(existing.branch),
        status: Value(SessionStatus.closed.name),
        createdAt: Value(existing.createdAt),
        lastMessageAt: Value(existing.lastMessageAt),
        updatedAt: Value(now),
        synced: Value(existing.synced),
      ),
    );
    ref.invalidate(activeSessionsProvider);
  }

  Future<void> _insertMessage(Message message) async {
    final db = ref.read(databaseProvider);
    await db.messageDao.updateMessage(_toCompanion(message));
    await _touchSession(message.sessionId);
  }

  Future<void> _insertSessionEvent(SessionEvent event) async {
    final db = ref.read(databaseProvider);
    await db.sessionEventDao.upsertEvent(_toSessionEventCompanion(event));
    await _touchSession(event.sessionId);
  }

  // ---------- Public actions -----------------------------------------------

  Future<void> sendMessage(String sessionId, String content) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      return;
    }

    await _ensureSessionExists(sessionId);

    final service = ref.read(webSocketServiceProvider);
    final syncQueue = ref.read(syncQueueServiceProvider);
    final now = DateTime.now().toUtc();
    final localMessageId = _uuid.v4();
    final outgoingMessage = BridgeMessage.message(
      sessionId: sessionId,
      content: trimmedContent,
    );
    final sent = service.send(outgoingMessage);

    await _insertMessage(
      Message(
        id: localMessageId,
        sessionId: sessionId,
        role: MessageRole.user,
        content: trimmedContent,
        type: MessageType.text,
        parts: [MessagePart.text(content: trimmedContent)],
        createdAt: now,
        updatedAt: now,
        synced: sent,
      ),
    );

    if (!sent) {
      await syncQueue.enqueue(
        _messageOperation,
        {
          'session_id': sessionId,
          'content': trimmedContent,
          'role': 'user',
          'local_message_id': localMessageId,
        },
        sessionId: sessionId,
      );
    }
  }

  Future<String> startSession(String agent, String workingDir) async {
    final normalizedDirectory = workingDir.trim();
    if (normalizedDirectory.isEmpty) {
      throw ArgumentError('Working directory is required.');
    }

    final sessionId = _uuid.v4();
    final service = ref.read(webSocketServiceProvider);
    final syncQueue = ref.read(syncQueueServiceProvider);
    final sent = service.send(
      BridgeMessage.sessionStart(
        agent: agent,
        sessionId: sessionId,
        workingDirectory: normalizedDirectory,
      ),
    );

    await _upsertSession(
      sessionId: sessionId,
      agentType: agent,
      title: _titleFromWorkingDirectory(normalizedDirectory),
      workingDirectory: normalizedDirectory,
      status: SessionStatus.active,
      synced: sent,
    );

    if (!sent) {
      await syncQueue.enqueue(
        _sessionStartOperation,
        {
          'agent': agent,
          'session_id': sessionId,
          'working_directory': normalizedDirectory,
          'resume': false,
        },
        sessionId: sessionId,
      );
    }

    ref.invalidate(activeSessionsProvider);
    return sessionId;
  }

  Future<void> endSession(String sessionId) async {
    if (sessionId.isEmpty) {
      return;
    }

    final service = ref.read(webSocketServiceProvider);
    final syncQueue = ref.read(syncQueueServiceProvider);
    final sent = service.send(
      BridgeMessage.sessionEnd(sessionId: sessionId),
    );

    if (!sent) {
      await syncQueue.enqueue(
        _sessionEndOperation,
        {'session_id': sessionId, 'reason': 'user_request'},
        sessionId: sessionId,
      );
    }

    await _markSessionClosed(sessionId);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

db_lib.MessagesCompanion _toCompanion(Message msg) {
  final metadata = jsonEncode({
    'parts': msg.parts.map((p) => p.toJson()).toList(),
    if (msg.metadata != null) ...msg.metadata!,
  });
  return db_lib.MessagesCompanion(
    id: Value(msg.id),
    sessionId: Value(msg.sessionId),
    role: Value(msg.role.name),
    content: Value(msg.content),
    messageType: Value(msg.type.name),
    metadata: Value(metadata),
    createdAt: Value(msg.createdAt),
    updatedAt: Value(msg.updatedAt ?? msg.createdAt),
    synced: Value(msg.synced),
  );
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return fallback;
}

String? _nullableStringValue(Object? value) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return null;
}

Map<String, dynamic> _mapValue(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
  return <String, dynamic>{};
}

String _titleFromWorkingDirectory(String workingDirectory) {
  if (workingDirectory.isEmpty) {
    return 'Claude Code';
  }

  final normalized = workingDirectory.replaceAll('\\', '/');
  final segments = normalized.split('/').where((segment) => segment.isNotEmpty);
  return segments.isEmpty ? workingDirectory : segments.last;
}

String _coalesceNonEmpty(String? first, String? second,
    [String fallback = '']) {
  if (first != null && first.isNotEmpty) {
    return first;
  }
  if (second != null && second.isNotEmpty) {
    return second;
  }
  return fallback;
}

String _resolveSessionTitle(
  String? existingTitle,
  String? incomingTitle,
  String workingDirectory,
) {
  final derivedTitle = _titleFromWorkingDirectory(workingDirectory);

  if (incomingTitle != null && incomingTitle.isNotEmpty) {
    return incomingTitle;
  }

  if (existingTitle == null || existingTitle.isEmpty) {
    return derivedTitle;
  }

  if (existingTitle == 'Claude Code' && derivedTitle != 'Claude Code') {
    return derivedTitle;
  }

  return existingTitle;
}

String _remoteMessageId(BridgeMessage message, {required String fallback}) {
  return _stringValue(message.id, fallback: fallback);
}

DateTime _messageTimestamp(BridgeMessage message) {
  return message.timestamp.toUtc();
}

DateTime _payloadTimestamp(Object? value, {required DateTime fallback}) {
  if (value is String && value.isNotEmpty) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed.toUtc();
    }
  }
  return fallback.toUtc();
}

db_lib.SessionEventsCompanion _toSessionEventCompanion(SessionEvent event) {
  final metadata = event.metadata == null ? null : jsonEncode(event.metadata);
  return db_lib.SessionEventsCompanion(
    id: Value(event.id),
    sessionId: Value(event.sessionId),
    eventType: Value(event.eventType.name),
    title: Value(event.title),
    description: Value(event.description),
    metadata: Value(metadata),
    timestamp: Value(event.timestamp),
  );
}

SessionEvent? _sessionEventFromHook({
  required BridgeMessage message,
  required String eventType,
  required String sessionId,
  required Map<String, dynamic> eventPayload,
  required DateTime timestamp,
}) {
  final eventId = _remoteMessageId(
    message,
    fallback:
        'session_event:$sessionId:$eventType:${timestamp.toIso8601String()}',
  );

  switch (eventType) {
    case 'SessionStart':
      final workingDirectory = _stringValue(eventPayload['working_directory']);
      return SessionEvent(
        id: eventId,
        sessionId: sessionId,
        eventType: SessionEventType.sessionStart,
        title: 'Session started',
        description: _truncateForTimeline(
          _coalesceNonEmpty(
            _nullableStringValue(eventPayload['title']),
            workingDirectory,
          ),
        ),
        timestamp: timestamp,
        metadata: {
          'hook_event_type': eventType,
          'working_directory': workingDirectory,
          if (_nullableStringValue(eventPayload['branch']) case final branch?)
            'branch': branch,
        },
      );
    case 'SessionEnd':
    case 'Stop':
      return SessionEvent(
        id: eventId,
        sessionId: sessionId,
        eventType: SessionEventType.sessionEnd,
        title: 'Session ended',
        description: _truncateForTimeline(
          _coalesceNonEmpty(
            _nullableStringValue(eventPayload['reason']),
            _nullableStringValue(eventPayload['message']),
          ),
        ),
        timestamp: timestamp,
        metadata: {
          'hook_event_type': eventType,
          if (_nullableStringValue(eventPayload['reason']) case final reason?)
            'reason': reason,
        },
      );
    case 'PreToolUse':
      final tool = _hookToolName(eventPayload);
      final params = _hookToolParams(eventPayload);
      return SessionEvent(
        id: eventId,
        sessionId: sessionId,
        eventType: SessionEventType.toolUse,
        title: 'Tool: $tool',
        description: _truncateForTimeline(
          _coalesceNonEmpty(
            _nullableStringValue(eventPayload['description']),
            _nullableStringValue(eventPayload['message']),
            _toolTargetSummary(params) ?? '',
          ),
        ),
        timestamp: timestamp,
        metadata: {
          'hook_event_type': eventType,
          'tool': tool,
          'params': params,
          if (_nullableStringValue(eventPayload['tool_call_id'])
              case final toolCallId?)
            'tool_call_id': toolCallId,
          if (_nullableStringValue(eventPayload['risk_level'])
              case final riskLevel?)
            'risk_level': riskLevel,
        },
      );
    case 'PostToolUse':
      final tool = _hookToolName(eventPayload);
      final result = _mapValue(eventPayload['result']);
      final success = result['success'] as bool? ?? true;
      return SessionEvent(
        id: eventId,
        sessionId: sessionId,
        eventType: SessionEventType.toolResult,
        title: success ? 'Tool result: $tool' : 'Tool failed: $tool',
        description: _truncateForTimeline(
          _coalesceNonEmpty(
            _nullableStringValue(result['error']),
            _nullableStringValue(result['content']),
            _nullableStringValue(eventPayload['message']) ?? '',
          ),
        ),
        timestamp: timestamp,
        metadata: {
          'hook_event_type': eventType,
          'tool': tool,
          'result': result,
          if (_nullableStringValue(eventPayload['tool_call_id'])
              case final toolCallId?)
            'tool_call_id': toolCallId,
        },
      );
    case 'Notification':
      return SessionEvent(
        id: eventId,
        sessionId: sessionId,
        eventType: SessionEventType.hookEvent,
        title: _coalesceNonEmpty(
          _nullableStringValue(eventPayload['title']),
          _nullableStringValue(eventPayload['notification_type']),
          'Notification',
        ),
        description: _truncateForTimeline(
          _coalesceNonEmpty(
            _nullableStringValue(eventPayload['body']),
            _nullableStringValue(eventPayload['message']),
          ),
        ),
        timestamp: timestamp,
        metadata: {
          'hook_event_type': eventType,
          ...eventPayload,
        },
      );
    default:
      return null;
  }
}

String _hookToolName(Map<String, dynamic> payload) {
  return _coalesceNonEmpty(
    _nullableStringValue(payload['tool']),
    _nullableStringValue(payload['tool_name']),
    'unknown_tool',
  );
}

Map<String, dynamic> _hookToolParams(Map<String, dynamic> payload) {
  final params = _mapValue(payload['params']);
  if (params.isNotEmpty) {
    return params;
  }
  return _mapValue(payload['tool_input']);
}

String? _toolTargetSummary(Map<String, dynamic> params) {
  return _nullableStringValue(params['path']) ??
      _nullableStringValue(params['file_path']) ??
      _nullableStringValue(params['command']);
}

String? _truncateForTimeline(String value, {int maxLength = 120}) {
  if (value.isEmpty) {
    return null;
  }
  return value.length > maxLength ? '${value.substring(0, maxLength)}…' : value;
}

SessionStatus _sessionStatusFromRemote(String? status) {
  switch (status) {
    case 'closed':
      return SessionStatus.closed;
    case 'paused':
      return SessionStatus.paused;
    default:
      return SessionStatus.active;
  }
}
