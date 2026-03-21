import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recursor_mobile/core/models/session_models.dart';
import 'package:recursor_mobile/core/network/connection_state.dart';
import 'package:recursor_mobile/core/network/websocket_messages.dart';
import 'package:recursor_mobile/core/network/websocket_service.dart';
import 'package:recursor_mobile/core/providers/database_provider.dart';
import 'package:recursor_mobile/core/providers/websocket_provider.dart';
import 'package:recursor_mobile/core/storage/database.dart';
import 'package:recursor_mobile/features/chat/domain/providers/session_provider.dart';

void main() {
  group('ActiveSessions', () {
    late AppDatabase database;
    late FakeSessionWebSocketService webSocketService;
    late ProviderContainer container;
    late ProviderSubscription<AsyncValue<List<ChatSession>>> subscription;

    setUp(() async {
      database = AppDatabase.inMemory();
      webSocketService = FakeSessionWebSocketService(
        initialStatus: ConnectionStatus.connected,
      );
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          webSocketServiceProvider.overrideWithValue(webSocketService),
        ],
      );
      subscription = container.listen<AsyncValue<List<ChatSession>>>(
        activeSessionsProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      addTearDown(container.dispose);
      await container.read(activeSessionsProvider.future);
    });

    tearDown(() async {
      await webSocketService.close();
      await database.close();
    });

    test('creates and closes Claude hook sessions without chat notifier',
        () async {
      final startedAt = DateTime.utc(2026, 3, 21, 12, 30, 0);
      final endedAt = DateTime.utc(2026, 3, 21, 12, 31, 0);

      webSocketService.emitMessage(
        BridgeMessage(
          id: 'claude-session-start-session-provider',
          type: BridgeMessageType.claudeEvent,
          timestamp: startedAt,
          payload: {
            'event_type': 'SessionStart',
            'session_id': 'sess-live-hooks',
            'timestamp': startedAt.toIso8601String(),
            'payload': {
              'working_directory': '/workspace/project-live-hooks',
            },
          },
        ),
      );

      await _drainQueue();

      final startedSessions =
          container.read(activeSessionsProvider).valueOrNull ?? <ChatSession>[];
      expect(startedSessions, hasLength(1));
      expect(startedSessions.single.id, 'sess-live-hooks');
      expect(startedSessions.single.title, 'project-live-hooks');
      expect(startedSessions.single.status, SessionStatus.active);

      webSocketService.emitMessage(
        BridgeMessage(
          id: 'claude-session-end-session-provider',
          type: BridgeMessageType.claudeEvent,
          timestamp: endedAt,
          payload: {
            'event_type': 'SessionEnd',
            'session_id': 'sess-live-hooks',
            'timestamp': endedAt.toIso8601String(),
            'payload': const <String, dynamic>{},
          },
        ),
      );

      await _drainQueue();

      final endedSessions =
          container.read(activeSessionsProvider).valueOrNull ?? <ChatSession>[];
      expect(endedSessions, hasLength(1));
      expect(endedSessions.single.status, SessionStatus.closed);

      final storedSession =
          await database.sessionDao.getSession('sess-live-hooks');
      expect(storedSession, isNotNull);
      expect(storedSession!.status, 'closed');
    });

    test('captures branch metadata from Claude SessionStart hooks', () async {
      final startedAt = DateTime.utc(2026, 3, 21, 12, 30, 30);

      webSocketService.emitMessage(
        BridgeMessage(
          id: 'claude-session-start-branch-session-provider',
          type: BridgeMessageType.claudeEvent,
          timestamp: startedAt,
          payload: {
            'event_type': 'SessionStart',
            'session_id': 'sess-branch-hooks',
            'timestamp': startedAt.toIso8601String(),
            'payload': {
              'working_directory': '/workspace/project-branch-hooks',
              'branch': 'feature/timeline-enrichment',
            },
          },
        ),
      );

      await _drainQueue();

      final sessions =
          container.read(activeSessionsProvider).valueOrNull ?? <ChatSession>[];
      expect(sessions, hasLength(1));
      expect(sessions.single.branch, 'feature/timeline-enrichment');

      final storedSession =
          await database.sessionDao.getSession('sess-branch-hooks');
      expect(storedSession, isNotNull);
      expect(storedSession!.branch, 'feature/timeline-enrichment');
    });

    test('prefers explicit session ids and falls back to current session', () {
      container.read(currentSessionProvider.notifier).state = 'sess-current';

      expect(container.read(resolvedSessionIdProvider('')), 'sess-current');
      expect(
        container.read(resolvedSessionIdProvider('sess-explicit')),
        'sess-explicit',
      );
    });

    test('reacts to database changes after the initial load', () async {
      await database.sessionDao.upsertSession(
        SessionsCompanion(
          id: const Value('sess-db-watch'),
          agentType: const Value('claude-code'),
          title: const Value('Watched Session'),
          workingDirectory: const Value('/workspace/db-watch'),
          status: const Value('active'),
          createdAt: Value(DateTime.now().toUtc()),
          updatedAt: Value(DateTime.now().toUtc()),
          synced: const Value(true),
        ),
      );

      await _drainQueue();

      var sessions =
          container.read(activeSessionsProvider).valueOrNull ?? <ChatSession>[];
      expect(sessions.map((session) => session.id), contains('sess-db-watch'));

      await container
          .read(activeSessionsProvider.notifier)
          .deleteSession('sess-db-watch');
      await _drainQueue();

      sessions =
          container.read(activeSessionsProvider).valueOrNull ?? <ChatSession>[];
      expect(sessions, isEmpty);
    });
  });
}

Future<void> _drainQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(const Duration(milliseconds: 20));
}

class FakeSessionWebSocketService extends WebSocketService {
  FakeSessionWebSocketService({required ConnectionStatus initialStatus})
      : _currentStatus = initialStatus;

  final StreamController<BridgeMessage> _messageController =
      StreamController<BridgeMessage>.broadcast();
  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();

  final ConnectionStatus _currentStatus;
  Map<String, dynamic>? _lastConnectionAckPayload;

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
  bool send(BridgeMessage message) =>
      _currentStatus == ConnectionStatus.connected;

  void emitMessage(BridgeMessage message) {
    if (message.type == BridgeMessageType.connectionAck) {
      _lastConnectionAckPayload = message.payload;
    }
    _messageController.add(message);
  }

  Future<void> close() async {
    await _messageController.close();
    await _statusController.close();
  }
}
