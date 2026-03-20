import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recursor_mobile/core/network/connection_state.dart';
import 'package:recursor_mobile/core/network/websocket_messages.dart';
import 'package:recursor_mobile/core/network/websocket_service.dart';
import 'package:recursor_mobile/core/providers/database_provider.dart';
import 'package:recursor_mobile/core/providers/websocket_provider.dart';
import 'package:recursor_mobile/core/storage/database.dart';
import 'package:recursor_mobile/features/chat/domain/providers/chat_provider.dart';

void main() {
  group('ChatNotifier', () {
    late AppDatabase database;
    late FakeChatWebSocketService webSocketService;
    late ProviderContainer container;
    late ProviderSubscription<AsyncValue<void>> chatNotifierSubscription;

    setUp(() async {
      database = AppDatabase.inMemory();
      webSocketService = FakeChatWebSocketService(
        initialStatus: ConnectionStatus.connected,
      );
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          webSocketServiceProvider.overrideWithValue(webSocketService),
        ],
      );
      chatNotifierSubscription = container.listen<AsyncValue<void>>(
        chatNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(chatNotifierSubscription.close);
      addTearDown(container.dispose);
      await container.read(chatNotifierProvider.future);
    });

    tearDown(() async {
      await webSocketService.close();
      await database.close();
    });

    test('persists session readiness, tool events, and streamed responses',
        () async {
      webSocketService.emitMessage(
        BridgeMessage(
          type: BridgeMessageType.sessionReady,
          timestamp: DateTime.now().toUtc(),
          payload: {
            'session_id': 'sess-stream',
            'agent': 'claude-code',
            'working_directory': '/workspace/project-alpha',
            'status': 'ready',
            'model': 'claude-sonnet',
          },
        ),
      );
      webSocketService.emitMessage(
        BridgeMessage(
          type: BridgeMessageType.approvalRequired,
          timestamp: DateTime.now().toUtc(),
          payload: {
            'session_id': 'sess-stream',
            'tool_call_id': 'tool-1',
            'tool': 'edit_file',
            'params': {'path': 'lib/main.dart'},
            'description': 'Approval required for edit_file',
            'risk_level': 'medium',
            'source': 'agent_sdk',
          },
        ),
      );
      webSocketService.emitMessage(
        BridgeMessage(
          type: BridgeMessageType.toolResult,
          timestamp: DateTime.now().toUtc(),
          payload: {
            'session_id': 'sess-stream',
            'tool_call_id': 'tool-1',
            'tool': 'edit_file',
            'result': {
              'success': true,
              'content': 'Updated lib/main.dart',
              'duration_ms': 18,
            },
          },
        ),
      );
      webSocketService.emitMessage(
        BridgeMessage(
          type: BridgeMessageType.streamStart,
          timestamp: DateTime.now().toUtc(),
          payload: {
            'session_id': 'sess-stream',
            'message_id': 'msg-1',
          },
        ),
      );
      webSocketService.emitMessage(
        BridgeMessage(
          type: BridgeMessageType.streamChunk,
          timestamp: DateTime.now().toUtc(),
          payload: {
            'session_id': 'sess-stream',
            'message_id': 'msg-1',
            'content': 'Hello',
          },
        ),
      );
      webSocketService.emitMessage(
        BridgeMessage(
          type: BridgeMessageType.streamChunk,
          timestamp: DateTime.now().toUtc(),
          payload: {
            'session_id': 'sess-stream',
            'message_id': 'msg-1',
            'content': ' world',
          },
        ),
      );
      webSocketService.emitMessage(
        BridgeMessage(
          type: BridgeMessageType.streamEnd,
          timestamp: DateTime.now().toUtc(),
          payload: {
            'session_id': 'sess-stream',
            'message_id': 'msg-1',
            'finish_reason': 'stop',
          },
        ),
      );

      await _drainQueue();

      final session = await database.sessionDao.getSession('sess-stream');
      final messages =
          await database.messageDao.getMessagesForSession('sess-stream');

      expect(session, isNotNull);
      expect(session!.title, 'project-alpha');
      expect(messages, hasLength(3));
      expect(
        messages.map((message) => message.messageType),
        containsAll(<String>['toolCall', 'toolResult', 'text']),
      );
      expect(
        messages.any((message) => message.content == 'Hello world'),
        isTrue,
      );
    });

    test('queues outgoing messages offline and flushes them on reconnect',
        () async {
      await database.sessionDao.upsertSession(
        SessionsCompanion(
          id: const Value('sess-offline'),
          agentType: const Value('claude-code'),
          title: const Value('Offline Session'),
          workingDirectory: const Value('/workspace/offline'),
          status: const Value('active'),
          createdAt: Value(DateTime.now().toUtc()),
          updatedAt: Value(DateTime.now().toUtc()),
          synced: const Value(true),
        ),
      );

      webSocketService.currentStatusValue = ConnectionStatus.disconnected;

      await container
          .read(chatNotifierProvider.notifier)
          .sendMessage('sess-offline', 'Queued hello');
      await _drainQueue();

      var queuedItems = await database.select(database.syncQueue).get();
      var storedMessages =
          await database.messageDao.getMessagesForSession('sess-offline');

      expect(queuedItems, hasLength(1));
      expect(queuedItems.single.operation, 'message');
      expect(queuedItems.single.synced, isFalse);
      expect(storedMessages.single.synced, isFalse);
      expect(webSocketService.sentMessages, isEmpty);

      webSocketService.currentStatusValue = ConnectionStatus.connected;
      webSocketService.emitStatus(ConnectionStatus.connected);
      await _drainQueue();

      queuedItems = await database.select(database.syncQueue).get();
      storedMessages =
          await database.messageDao.getMessagesForSession('sess-offline');

      expect(queuedItems.single.synced, isTrue);
      expect(storedMessages.single.synced, isTrue);
      expect(webSocketService.sentMessages, hasLength(1));
      expect(
          webSocketService.sentMessages.single.type, BridgeMessageType.message);
      expect(
        webSocketService.sentMessages.single.payload['content'],
        'Queued hello',
      );
    });
  });
}

Future<void> _drainQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(const Duration(milliseconds: 20));
}

class FakeChatWebSocketService extends WebSocketService {
  FakeChatWebSocketService({required ConnectionStatus initialStatus})
      : _currentStatus = initialStatus;

  final StreamController<BridgeMessage> _messageController =
      StreamController<BridgeMessage>.broadcast();
  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  final List<BridgeMessage> sentMessages = <BridgeMessage>[];

  ConnectionStatus _currentStatus;
  Map<String, dynamic>? _lastConnectionAckPayload;
  bool sendResult = true;

  set currentStatusValue(ConnectionStatus value) {
    _currentStatus = value;
  }

  @override
  Stream<BridgeMessage> get messages => _messageController.stream;

  @override
  Stream<ConnectionStatus> get connectionStatus => _statusController.stream;

  @override
  ConnectionStatus get currentStatus => _currentStatus;

  @override
  Map<String, dynamic>? get lastConnectionAckPayload =>
      _lastConnectionAckPayload;

  @override
  bool send(BridgeMessage message) {
    if (_currentStatus != ConnectionStatus.connected) {
      return false;
    }
    sentMessages.add(message);
    return sendResult;
  }

  void emitMessage(BridgeMessage message) {
    if (message.type == BridgeMessageType.connectionAck) {
      _lastConnectionAckPayload = message.payload;
    }
    _messageController.add(message);
  }

  void emitStatus(ConnectionStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  Future<void> close() async {
    await _messageController.close();
    await _statusController.close();
  }
}
