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

    _messageSubscription = service.messages.listen(_handleBridgeMessage);
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

  void _handleBridgeMessage(BridgeMessage message) {
    final payload = message.payload;

    switch (message.type) {
      case BridgeMessageType.connectionAck:
        unawaited(_syncActiveSessions(payload));
        break;
      case BridgeMessageType.sessionReady:
        unawaited(_persistSessionReady(payload));
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
        unawaited(_finalizeStreaming(_stringValue(payload['session_id'])));
        break;
      case BridgeMessageType.approvalRequired:
        unawaited(_persistApprovalRequired(payload));
        break;
      case BridgeMessageType.toolResult:
        unawaited(_persistToolResult(payload));
        break;
      case BridgeMessageType.claudeEvent:
        unawaited(_handleClaudeEvent(payload));
        break;
      case BridgeMessageType.sessionEnd:
        unawaited(_markSessionClosed(_stringValue(payload['session_id'])));
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
      branch: payload['branch'] as String?,
      status: SessionStatus.active,
      synced: true,
    );
    ref.invalidate(activeSessionsProvider);
  }

  Future<void> _persistApprovalRequired(Map<String, dynamic> payload) async {
    final sessionId = _stringValue(payload['session_id']);
    if (sessionId.isEmpty) {
      return;
    }

    await _ensureSessionExists(sessionId);
    final now = DateTime.now().toUtc();
    await _insertMessage(
      Message(
        id: _uuid.v4(),
        sessionId: sessionId,
        role: MessageRole.agent,
        content: _stringValue(payload['description']),
        type: MessageType.toolCall,
        parts: [
          MessagePart.toolUse(
            tool: _stringValue(payload['tool'], fallback: 'unknown_tool'),
            params: _mapValue(payload['params']),
            id: _stringValue(payload['tool_call_id']),
          ),
        ],
        metadata: {
          'description': _stringValue(payload['description']),
          'risk_level': _stringValue(payload['risk_level']),
          'source': _stringValue(payload['source']),
        },
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _persistToolResult(Map<String, dynamic> payload) async {
    final sessionId = _stringValue(payload['session_id']);
    if (sessionId.isEmpty) {
      return;
    }

    await _ensureSessionExists(sessionId);
    final resultMap = _mapValue(payload['result']);
    final toolName = _stringValue(payload['tool'], fallback: 'unknown_tool');
    final metadata = <String, dynamic>{'tool': toolName};
    final diff = resultMap['diff'] as String?;
    if (diff != null && diff.isNotEmpty) {
      metadata['diff'] = diff;
    }

    final now = DateTime.now().toUtc();
    await _insertMessage(
      Message(
        id: _uuid.v4(),
        sessionId: sessionId,
        role: MessageRole.agent,
        content: _stringValue(resultMap['content']),
        type: MessageType.toolResult,
        parts: [
          MessagePart.toolResult(
            toolCallId: _stringValue(payload['tool_call_id']),
            result: ToolResult(
              success: resultMap['success'] as bool? ?? true,
              content: _stringValue(resultMap['content']),
              metadata: metadata,
              error: resultMap['error'] as String?,
              durationMs: resultMap['duration_ms'] as int?,
            ),
          ),
        ],
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _handleClaudeEvent(Map<String, dynamic> payload) async {
    final eventType = _stringValue(payload['event_type']);
    final sessionId = _stringValue(payload['session_id']);
    final eventPayload = _mapValue(payload['payload']);

    if (sessionId.isEmpty || eventType.isEmpty) {
      return;
    }

    switch (eventType) {
      case 'SessionStart':
        await _ensureSessionExists(
          sessionId,
          workingDirectory: _stringValue(eventPayload['working_directory']),
          title: _stringValue(eventPayload['title']),
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
        final now = DateTime.now().toUtc();
        await _insertMessage(
          Message(
            id: _uuid.v4(),
            sessionId: sessionId,
            role: MessageRole.user,
            content: content,
            type: MessageType.text,
            parts: [MessagePart.text(content: content)],
            createdAt: now,
            updatedAt: now,
          ),
        );
        break;
      case 'SessionEnd':
      case 'Stop':
        await _markSessionClosed(sessionId);
        break;
      default:
        break;
    }
  }

  Future<void> _ensureSessionExists(
    String sessionId, {
    String? workingDirectory,
    String? title,
  }) async {
    final db = ref.read(databaseProvider);
    final existing = await db.sessionDao.getSession(sessionId);
    if (existing != null) {
      return;
    }

    await _upsertSession(
      sessionId: sessionId,
      agentType: 'claude-code',
      title: title ?? _titleFromWorkingDirectory(workingDirectory ?? ''),
      workingDirectory: workingDirectory ?? '',
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
          _coalesceNonEmpty(
            existing?.title,
            title,
            _titleFromWorkingDirectory(workingDirectory),
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
    await db.messageDao.insertMessage(_toCompanion(message));
    await _touchSession(message.sessionId);
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
