import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/message_models.dart';
import '../../../../core/models/session_models.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/network/bridge_socket.dart';
import '../../../../core/storage/database.dart' as db_lib;

part 'chat_provider.g.dart';

const _uuid = Uuid();

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
  @override
  Future<void> build() async {
    final socket = ref.watch(bridgeSocketProvider);
    socket.messageStream.listen(_handleBridgeMessage);
  }

  void _handleBridgeMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    final sessionId = msg['session_id'] as String? ?? '';

    switch (type) {
      case 'stream_start':
        _setStreaming(sessionId, '');
      case 'stream_chunk':
        final chunk = msg['chunk'] as String? ?? '';
        _appendStreaming(sessionId, chunk);
      case 'stream_end':
        _finalizeStreaming(sessionId);
      case 'tool_call':
        _persistToolCall(sessionId, msg);
      case 'tool_result':
        _persistToolResult(sessionId, msg);
      case 'session_ready':
        _onSessionReady(sessionId, msg);
      default:
        break;
    }
  }

  void _setStreaming(String sessionId, String text) {
    final current = Map<String, String>.from(
      ref.read(streamingMessageProvider),
    );
    current[sessionId] = text;
    ref.read(streamingMessageProvider.notifier).state = current;
  }

  void _appendStreaming(String sessionId, String chunk) {
    final current = Map<String, String>.from(
      ref.read(streamingMessageProvider),
    );
    current[sessionId] = (current[sessionId] ?? '') + chunk;
    ref.read(streamingMessageProvider.notifier).state = current;
  }

  Future<void> _finalizeStreaming(String sessionId) async {
    final current = Map<String, String>.from(
      ref.read(streamingMessageProvider),
    );
    final text = current.remove(sessionId) ?? '';
    ref.read(streamingMessageProvider.notifier).state = current;

    if (text.isNotEmpty) {
      final db = ref.read(databaseProvider);
      final now = DateTime.now();
      await db.messageDao.insertMessage(_toCompanion(Message(
        id: _uuid.v4(),
        sessionId: sessionId,
        role: MessageRole.agent,
        content: text,
        type: MessageType.text,
        parts: [MessagePart.text(content: text)],
        createdAt: now,
        updatedAt: now,
      )));
    }
  }

  Future<void> _persistToolCall(
      String sessionId, Map<String, dynamic> msg) async {
    final db = ref.read(databaseProvider);
    final toolName = msg['tool'] as String? ?? 'unknown';
    final params =
        (msg['params'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final id = msg['id'] as String? ?? _uuid.v4();
    final now = DateTime.now();

    await db.messageDao.insertMessage(_toCompanion(Message(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: MessageRole.agent,
      content: '',
      type: MessageType.toolCall,
      parts: [MessagePart.toolUse(tool: toolName, params: params, id: id)],
      createdAt: now,
      updatedAt: now,
    )));
  }

  Future<void> _persistToolResult(
      String sessionId, Map<String, dynamic> msg) async {
    final db = ref.read(databaseProvider);
    final toolCallId = msg['tool_call_id'] as String? ?? '';
    final success = msg['success'] as bool? ?? true;
    final content = msg['content'] as String? ?? '';
    final now = DateTime.now();

    await db.messageDao.insertMessage(_toCompanion(Message(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: MessageRole.agent,
      content: '',
      type: MessageType.toolResult,
      parts: [
        MessagePart.toolResult(
          toolCallId: toolCallId,
          result: ToolResult(success: success, content: content),
        )
      ],
      createdAt: now,
      updatedAt: now,
    )));
  }

  void _onSessionReady(String sessionId, Map<String, dynamic> msg) {
    // Session is live; any UI waiting can react via activeSessionsProvider
  }

  // ---------- Public actions -----------------------------------------------

  Future<void> sendMessage(String sessionId, String content) async {
    if (content.trim().isEmpty) return;
    final db = ref.read(databaseProvider);

    // Optimistic insert
    final now = DateTime.now();
    final msg = Message(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: MessageRole.user,
      content: content,
      type: MessageType.text,
      parts: [MessagePart.text(content: content)],
      createdAt: now,
      updatedAt: now,
      synced: false,
    );
    await db.messageDao.insertMessage(_toCompanion(msg));

    // Send over socket
    final socket = ref.read(bridgeSocketProvider);
    socket.send({
      'type': 'user_message',
      'session_id': sessionId,
      'content': content,
    });
  }

  Future<void> startSession(String agentId, String workingDir) async {
    final socket = ref.read(bridgeSocketProvider);
    final sessionId = _uuid.v4();
    socket.send({
      'type': 'session_start',
      'session_id': sessionId,
      'agent_id': agentId,
      'working_directory': workingDir,
    });
  }

  Future<void> endSession(String sessionId) async {
    final socket = ref.read(bridgeSocketProvider);
    socket.send({'type': 'session_end', 'session_id': sessionId});
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
