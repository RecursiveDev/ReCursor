import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:recursor_mobile/core/network/connection_state.dart';
import 'package:recursor_mobile/core/network/websocket_messages.dart';
import 'package:recursor_mobile/core/network/websocket_service.dart';
import 'package:recursor_mobile/core/storage/database.dart';
import 'package:recursor_mobile/core/sync/sync_queue.dart';

void main() {
  group('SyncQueueService', () {
    late AppDatabase database;
    late SyncQueueService service;

    setUp(() {
      database = AppDatabase.inMemory();
      service = SyncQueueService(database: database);
    });

    tearDown(() async {
      await database.close();
    });

    test('keeps queued items pending when the bridge is unavailable', () async {
      await service.enqueue(
        'message',
        <String, dynamic>{
          'session_id': 'sess-1',
          'content': 'hello',
          'role': 'user',
        },
        sessionId: 'sess-1',
      );

      final webSocket = FakeSyncWebSocketService(
        status: ConnectionStatus.disconnected,
        sendResult: false,
      );

      await service.flush(webSocket);

      final queuedItems = await database.select(database.syncQueue).get();
      final item = queuedItems.single;

      expect(item.synced, isFalse);
      expect(item.retryCount, 1);
      expect(item.lastError, 'Bridge unavailable');
      expect(webSocket.sentMessages, isEmpty);
    });

    test('replays queued message payloads using the bridge protocol', () async {
      await service.enqueue(
        'message',
        <String, dynamic>{
          'session_id': 'sess-1',
          'content': 'hello',
          'role': 'user',
        },
        sessionId: 'sess-1',
      );

      final webSocket = FakeSyncWebSocketService(
        status: ConnectionStatus.connected,
        sendResult: true,
      );

      await service.flush(webSocket);

      final queuedItems = await database.select(database.syncQueue).get();
      final item = queuedItems.single;

      expect(item.synced, isTrue);
      expect(item.retryCount, 0);
      expect(webSocket.sentMessages, hasLength(1));
      expect(webSocket.sentMessages.single.type, BridgeMessageType.message);
      expect(webSocket.sentMessages.single.payload['session_id'], 'sess-1');
      expect(webSocket.sentMessages.single.payload['content'], 'hello');
      expect(webSocket.sentMessages.single.payload['role'], 'user');
    });

    test('marks local messages as synced after a successful flush', () async {
      await database.sessionDao.upsertSession(
        SessionsCompanion(
          id: const Value('sess-1'),
          agentType: const Value('claude-code'),
          title: const Value('Queued Session'),
          workingDirectory: const Value('/workspace/queued'),
          status: const Value('active'),
          createdAt: Value(DateTime.now().toUtc()),
          updatedAt: Value(DateTime.now().toUtc()),
          synced: const Value(true),
        ),
      );
      await database.messageDao.insertMessage(
        MessagesCompanion(
          id: const Value('msg-1'),
          sessionId: const Value('sess-1'),
          role: const Value('user'),
          content: const Value('hello'),
          messageType: const Value('text'),
          createdAt: Value(DateTime.now().toUtc()),
          updatedAt: Value(DateTime.now().toUtc()),
          synced: const Value(false),
        ),
      );
      await service.enqueue(
        'message',
        <String, dynamic>{
          'session_id': 'sess-1',
          'content': 'hello',
          'role': 'user',
          'local_message_id': 'msg-1',
        },
        sessionId: 'sess-1',
      );

      final webSocket = FakeSyncWebSocketService(
        status: ConnectionStatus.connected,
        sendResult: true,
      );

      await service.flush(webSocket);

      final storedMessages =
          await database.messageDao.getMessagesForSession('sess-1');
      expect(storedMessages.single.synced, isTrue);
    });

    test('replays queued session starts with the provided client session id',
        () async {
      await service.enqueue(
        'session_start',
        <String, dynamic>{
          'agent': 'claude-code',
          'session_id': 'sess-queued',
          'working_directory': '/workspace/app',
          'resume': false,
        },
        sessionId: 'sess-queued',
      );

      final webSocket = FakeSyncWebSocketService(
        status: ConnectionStatus.connected,
        sendResult: true,
      );

      await service.flush(webSocket);

      expect(webSocket.sentMessages, hasLength(1));
      expect(
          webSocket.sentMessages.single.type, BridgeMessageType.sessionStart);
      expect(
          webSocket.sentMessages.single.payload['session_id'], 'sess-queued');
      expect(
        webSocket.sentMessages.single.payload['working_directory'],
        '/workspace/app',
      );
    });
  });
}

class FakeSyncWebSocketService extends WebSocketService {
  FakeSyncWebSocketService({
    required ConnectionStatus status,
    required this.sendResult,
  }) : _status = status;

  final ConnectionStatus _status;
  final bool sendResult;
  final List<BridgeMessage> sentMessages = <BridgeMessage>[];

  @override
  ConnectionStatus get currentStatus => _status;

  @override
  bool send(BridgeMessage message) {
    sentMessages.add(message);
    return sendResult;
  }
}
