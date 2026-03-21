import 'dart:async';
import 'dart:convert';

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

    test('deduplicates replayed hook events and preserves hook timestamps',
        () async {
      final sessionStartAt = DateTime.utc(2026, 3, 21, 12, 0, 0);
      final promptAt = DateTime.utc(2026, 3, 21, 12, 0, 1);
      final toolUseAt = DateTime.utc(2026, 3, 21, 12, 0, 2);
      final toolResultAt = DateTime.utc(2026, 3, 21, 12, 0, 3);

      webSocketService.emitMessage(
        BridgeMessage(
          id: 'claude-session-start-1',
          type: BridgeMessageType.claudeEvent,
          timestamp: sessionStartAt,
          payload: {
            'event_type': 'SessionStart',
            'session_id': 'sess-hooks',
            'timestamp': sessionStartAt.toIso8601String(),
            'payload': {
              'working_directory': '/workspace/project-hooks',
            },
          },
        ),
      );
      webSocketService.emitMessage(
        BridgeMessage(
          id: 'claude-user-prompt-1',
          type: BridgeMessageType.claudeEvent,
          timestamp: promptAt,
          payload: {
            'event_type': 'UserPromptSubmit',
            'session_id': 'sess-hooks',
            'timestamp': promptAt.toIso8601String(),
            'payload': {
              'prompt': 'Inspect lib/main.dart',
            },
          },
        ),
      );
      webSocketService.emitMessage(
        BridgeMessage(
          id: 'hook-approval-1',
          type: BridgeMessageType.approvalRequired,
          timestamp: toolUseAt,
          payload: {
            'session_id': 'sess-hooks',
            'tool_call_id': 'tool-hook-1',
            'tool': 'read_file',
            'params': {'path': 'lib/main.dart'},
            'description': 'Observed via Claude hooks',
            'risk_level': 'low',
            'source': 'hooks',
          },
        ),
      );
      webSocketService.emitMessage(
        BridgeMessage(
          id: 'hook-approval-1',
          type: BridgeMessageType.approvalRequired,
          timestamp: toolUseAt,
          payload: {
            'session_id': 'sess-hooks',
            'tool_call_id': 'tool-hook-1',
            'tool': 'read_file',
            'params': {'path': 'lib/main.dart'},
            'description': 'Observed via Claude hooks',
            'risk_level': 'low',
            'source': 'hooks',
          },
        ),
      );
      webSocketService.emitMessage(
        BridgeMessage(
          id: 'hook-tool-result-1',
          type: BridgeMessageType.toolResult,
          timestamp: toolResultAt,
          payload: {
            'session_id': 'sess-hooks',
            'tool_call_id': 'tool-hook-1',
            'tool': 'read_file',
            'result': {
              'success': true,
              'content': 'File contents here',
              'duration_ms': 12,
            },
          },
        ),
      );
      webSocketService.emitMessage(
        BridgeMessage(
          id: 'hook-tool-result-1',
          type: BridgeMessageType.toolResult,
          timestamp: toolResultAt,
          payload: {
            'session_id': 'sess-hooks',
            'tool_call_id': 'tool-hook-1',
            'tool': 'read_file',
            'result': {
              'success': true,
              'content': 'File contents here',
              'duration_ms': 12,
            },
          },
        ),
      );
      webSocketService.emitMessage(
        BridgeMessage(
          id: 'claude-user-prompt-1',
          type: BridgeMessageType.claudeEvent,
          timestamp: promptAt,
          payload: {
            'event_type': 'UserPromptSubmit',
            'session_id': 'sess-hooks',
            'timestamp': promptAt.toIso8601String(),
            'payload': {
              'prompt': 'Inspect lib/main.dart',
            },
          },
        ),
      );
      webSocketService.emitMessage(
        BridgeMessage(
          id: 'claude-session-end-1',
          type: BridgeMessageType.claudeEvent,
          timestamp: DateTime.utc(2026, 3, 21, 12, 0, 4),
          payload: {
            'event_type': 'SessionEnd',
            'session_id': 'sess-hooks',
            'timestamp': DateTime.utc(2026, 3, 21, 12, 0, 4).toIso8601String(),
            'payload': const <String, dynamic>{},
          },
        ),
      );

      await _drainQueue();

      final session = await database.sessionDao.getSession('sess-hooks');
      final messages =
          await database.messageDao.getMessagesForSession('sess-hooks');

      expect(session, isNotNull);
      expect(session!.title, 'project-hooks');
      expect(session.status, 'closed');
      expect(messages, hasLength(3));
      expect(messages.map((message) => message.id), <String>[
        'claude-user-prompt-1',
        'hook-approval-1',
        'hook-tool-result-1',
      ]);
      expect(
        messages.map((message) => message.createdAt.millisecondsSinceEpoch),
        <int>[
          promptAt.millisecondsSinceEpoch,
          toolUseAt.millisecondsSinceEpoch,
          toolResultAt.millisecondsSinceEpoch,
        ],
      );

      final toolCallMetadata =
          jsonDecode(messages[1].metadata!) as Map<String, dynamic>;
      expect(toolCallMetadata['source'], 'hooks');
      expect(toolCallMetadata['tool_call_id'], 'tool-hook-1');
    });

    test('persists hook timeline events for tool lifecycle and notifications',
        () async {
      final sessionStartAt = DateTime.utc(2026, 3, 21, 13, 0, 0);
      final toolUseAt = DateTime.utc(2026, 3, 21, 13, 0, 2);
      final toolResultAt = DateTime.utc(2026, 3, 21, 13, 0, 4);
      final notificationAt = DateTime.utc(2026, 3, 21, 13, 0, 5);

      webSocketService.emitMessage(
        BridgeMessage(
          id: 'claude-session-start-timeline',
          type: BridgeMessageType.claudeEvent,
          timestamp: sessionStartAt,
          payload: {
            'event_type': 'SessionStart',
            'session_id': 'sess-timeline',
            'timestamp': sessionStartAt.toIso8601String(),
            'payload': {
              'working_directory': '/workspace/project-timeline',
              'branch': 'feature/live-timeline',
            },
          },
        ),
      );
      webSocketService.emitMessage(
        BridgeMessage(
          id: 'claude-pre-tool-1',
          type: BridgeMessageType.claudeEvent,
          timestamp: toolUseAt,
          payload: {
            'event_type': 'PreToolUse',
            'session_id': 'sess-timeline',
            'timestamp': toolUseAt.toIso8601String(),
            'payload': {
              'tool': 'edit_file',
              'tool_call_id': 'tool-timeline-1',
              'description': 'Preparing to update lib/main.dart',
              'params': {'path': 'lib/main.dart'},
              'risk_level': 'medium',
            },
          },
        ),
      );
      webSocketService.emitMessage(
        BridgeMessage(
          id: 'claude-pre-tool-1',
          type: BridgeMessageType.claudeEvent,
          timestamp: toolUseAt,
          payload: {
            'event_type': 'PreToolUse',
            'session_id': 'sess-timeline',
            'timestamp': toolUseAt.toIso8601String(),
            'payload': {
              'tool': 'edit_file',
              'tool_call_id': 'tool-timeline-1',
              'description': 'Preparing to update lib/main.dart',
              'params': {'path': 'lib/main.dart'},
              'risk_level': 'medium',
            },
          },
        ),
      );
      webSocketService.emitMessage(
        BridgeMessage(
          id: 'claude-post-tool-1',
          type: BridgeMessageType.claudeEvent,
          timestamp: toolResultAt,
          payload: {
            'event_type': 'PostToolUse',
            'session_id': 'sess-timeline',
            'timestamp': toolResultAt.toIso8601String(),
            'payload': {
              'tool': 'edit_file',
              'tool_call_id': 'tool-timeline-1',
              'result': {
                'success': true,
                'content': 'Updated lib/main.dart',
              },
            },
          },
        ),
      );
      webSocketService.emitMessage(
        BridgeMessage(
          id: 'claude-notification-1',
          type: BridgeMessageType.claudeEvent,
          timestamp: notificationAt,
          payload: {
            'event_type': 'Notification',
            'session_id': 'sess-timeline',
            'timestamp': notificationAt.toIso8601String(),
            'payload': {
              'title': 'Claude is waiting',
              'body': 'Review the latest diff when ready.',
              'notification_type': 'agent_idle',
            },
          },
        ),
      );

      await _drainQueue();

      final session = await database.sessionDao.getSession('sess-timeline');
      final sessionEvents =
          await database.sessionEventDao.getEventsForSession('sess-timeline');

      expect(session, isNotNull);
      expect(session!.branch, 'feature/live-timeline');
      expect(sessionEvents.map((event) => event.id), <String>[
        'claude-session-start-timeline',
        'claude-pre-tool-1',
        'claude-post-tool-1',
        'claude-notification-1',
      ]);
      expect(sessionEvents.map((event) => event.eventType), <String>[
        'sessionStart',
        'toolUse',
        'toolResult',
        'hookEvent',
      ]);
      expect(
          sessionEvents.map((event) => event.timestamp.millisecondsSinceEpoch),
          <int>[
            sessionStartAt.millisecondsSinceEpoch,
            toolUseAt.millisecondsSinceEpoch,
            toolResultAt.millisecondsSinceEpoch,
            notificationAt.millisecondsSinceEpoch,
          ]);
      expect(sessionEvents[1].description, 'Preparing to update lib/main.dart');
      expect(sessionEvents[2].title, 'Tool result: edit_file');
      expect(sessionEvents[3].title, 'Claude is waiting');
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
