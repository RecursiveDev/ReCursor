import 'dart:convert';

import 'package:drift/drift.dart';

import '../network/connection_state.dart';
import '../network/websocket_messages.dart';
import '../network/websocket_service.dart';
import '../storage/daos/sync_dao.dart';
import '../storage/database.dart';

/// Manages an offline-first mutation queue backed by [SyncDao].
/// Operations enqueued while disconnected are replayed on reconnect via [flush].
class SyncQueueService {
  SyncQueueService({required AppDatabase database})
      : _database = database,
        _dao = database.syncDao;

  final AppDatabase _database;
  final SyncDao _dao;

  Future<void> enqueue(
    String operation,
    Map<String, dynamic> payload, {
    String? sessionId,
  }) async {
    await _dao.enqueue(
      SyncQueueCompanion(
        operation: Value(operation),
        payload: Value(jsonEncode(payload)),
        sessionId: Value(sessionId),
        createdAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Dequeue all pending items and send them over [ws].
  /// Items that succeed are marked as synced; failures increment retry count.
  Future<void> flush(WebSocketService ws) async {
    final pending = await _dao.getPendingItems();
    for (final item in pending) {
      try {
        if (ws.currentStatus != ConnectionStatus.connected) {
          await _dao.incrementRetry(item.id, 'Bridge unavailable');
          continue;
        }

        final payloadMap = _decodePayload(item.payload);
        final message = _buildMessage(item.operation, payloadMap);
        final sent = ws.send(message);
        if (!sent) {
          await _dao.incrementRetry(item.id, 'Bridge unavailable');
          continue;
        }

        await _dao.markSynced(item.id);
        await _markLocalArtifactsSynced(item.operation, payloadMap);
      } catch (e) {
        await _dao.incrementRetry(item.id, e.toString());
      }
    }
  }

  Future<int> getPendingCount() async {
    final items = await _dao.getPendingItems();
    return items.length;
  }

  Map<String, dynamic> _decodePayload(String payload) {
    return jsonDecode(payload) as Map<String, dynamic>;
  }

  BridgeMessage _buildMessage(
    String operation,
    Map<String, dynamic> payload,
  ) {
    switch (operation) {
      case 'message':
        return BridgeMessage.message(
          sessionId: payload['session_id'] as String? ?? '',
          content: payload['content'] as String? ?? '',
          role: payload['role'] as String? ?? 'user',
        );
      case 'session_start':
        return BridgeMessage.sessionStart(
          agent: payload['agent'] as String? ?? 'claude-code',
          sessionId: payload['session_id'] as String?,
          workingDirectory: payload['working_directory'] as String? ?? '',
          resume: payload['resume'] as bool? ?? false,
        );
      case 'session_end':
        return BridgeMessage.sessionEnd(
          sessionId: payload['session_id'] as String? ?? '',
          reason: payload['reason'] as String? ?? 'user_request',
        );
      case 'approval_response':
        return BridgeMessage.approvalResponse(
          sessionId: payload['session_id'] as String? ?? '',
          toolCallId: payload['tool_call_id'] as String? ?? '',
          decision: payload['decision'] as String? ?? 'rejected',
          modifications: payload['modifications'] as Map<String, dynamic>?,
        );
      case 'notification_ack':
        return BridgeMessage.notificationAck(
          notificationIds: (payload['notification_ids'] as List<dynamic>? ?? [])
              .whereType<String>()
              .toList(),
        );
    }

    throw UnsupportedError('Unsupported sync queue operation: $operation');
  }

  Future<void> _markLocalArtifactsSynced(
    String operation,
    Map<String, dynamic> payload,
  ) async {
    if (operation == 'message') {
      final localMessageId = payload['local_message_id'] as String?;
      if (localMessageId == null || localMessageId.isEmpty) {
        return;
      }

      final existingMessage = await (_database.select(_database.messages)
            ..where((message) => message.id.equals(localMessageId)))
          .getSingleOrNull();
      if (existingMessage == null) {
        return;
      }

      await _database.messageDao.updateMessage(
        MessagesCompanion(
          id: Value(existingMessage.id),
          sessionId: Value(existingMessage.sessionId),
          role: Value(existingMessage.role),
          content: Value(existingMessage.content),
          messageType: Value(existingMessage.messageType),
          metadata: Value(existingMessage.metadata),
          createdAt: Value(existingMessage.createdAt),
          updatedAt: Value(DateTime.now().toUtc()),
          synced: const Value(true),
        ),
      );
      return;
    }

    if (operation == 'session_start') {
      final sessionId = payload['session_id'] as String?;
      if (sessionId == null || sessionId.isEmpty) {
        return;
      }

      final existingSession = await _database.sessionDao.getSession(sessionId);
      if (existingSession == null) {
        return;
      }

      await _database.sessionDao.upsertSession(
        SessionsCompanion(
          id: Value(existingSession.id),
          agentType: Value(existingSession.agentType),
          agentId: Value(existingSession.agentId),
          title: Value(existingSession.title),
          workingDirectory: Value(existingSession.workingDirectory),
          branch: Value(existingSession.branch),
          status: Value(existingSession.status),
          createdAt: Value(existingSession.createdAt),
          lastMessageAt: Value(existingSession.lastMessageAt),
          updatedAt: Value(DateTime.now().toUtc()),
          synced: const Value(true),
        ),
      );
    }
  }
}
