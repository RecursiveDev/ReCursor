import 'dart:convert';

import 'package:drift/drift.dart';

import '../network/websocket_messages.dart';
import '../network/websocket_service.dart';
import '../storage/daos/sync_dao.dart';
import '../storage/database.dart';
import '../storage/tables/sync_queue_table.dart';

/// Manages an offline-first mutation queue backed by [SyncDao].
/// Operations enqueued while disconnected are replayed on reconnect via [flush].
class SyncQueueService {
  SyncQueueService({required AppDatabase database})
      : _dao = database.syncDao;

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
        final payloadMap =
            jsonDecode(item.payload) as Map<String, dynamic>;
        final message = BridgeMessage(
          type: BridgeMessageType.message,
          timestamp: DateTime.now().toUtc(),
          payload: {
            'operation': item.operation,
            'data': payloadMap,
            if (item.sessionId != null) 'session_id': item.sessionId,
          },
        );
        ws.send(message);
        await _dao.markSynced(item.id);
      } catch (e) {
        await _dao.incrementRetry(item.id, e.toString());
      }
    }
  }

  Future<int> getPendingCount() async {
    final items = await _dao.getPendingItems();
    return items.length;
  }
}
