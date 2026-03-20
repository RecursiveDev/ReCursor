import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recursor_mobile/core/network/connection_state.dart';
import 'package:recursor_mobile/core/network/websocket_messages.dart';
import 'package:recursor_mobile/core/network/websocket_service.dart';
import 'package:recursor_mobile/core/providers/database_provider.dart';
import 'package:recursor_mobile/core/providers/websocket_provider.dart';
import 'package:recursor_mobile/core/storage/database.dart';
import 'package:recursor_mobile/features/approvals/domain/approval_source.dart';
import 'package:recursor_mobile/features/approvals/domain/providers/approval_provider.dart';

void main() {
  group('PendingApprovalsNotifier', () {
    late AppDatabase database;
    late FakeApprovalWebSocketService webSocketService;
    late ProviderContainer container;

    setUp(() {
      database = AppDatabase.inMemory();
      webSocketService = FakeApprovalWebSocketService();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          webSocketServiceProvider.overrideWithValue(webSocketService),
        ],
      );
      addTearDown(container.dispose);
    });

    tearDown(() async {
      await webSocketService.close();
      await database.close();
    });

    test('marks hook-sourced approvals as observational and blocks responses',
        () async {
      container.read(pendingApprovalsProvider.notifier);
      webSocketService.emitMessage(
        BridgeMessage(
          type: BridgeMessageType.approvalRequired,
          timestamp: DateTime.now().toUtc(),
          payload: {
            'session_id': 'sess-hooks',
            'tool_call_id': 'tool-hooks',
            'tool': 'edit_file',
            'params': {'path': 'lib/main.dart'},
            'description': 'Observed edit request',
            'risk_level': 'high',
            'source': 'hooks',
          },
        ),
      );

      await Future<void>.delayed(Duration.zero);

      final pending = container.read(pendingApprovalsProvider);
      expect(pending, hasLength(1));
      expect(isObservedHookApproval(pending.single), isTrue);

      await container
          .read(pendingApprovalsProvider.notifier)
          .approve('sess-hooks', 'tool-hooks');

      expect(webSocketService.sentMessages, isEmpty);
      expect(container.read(pendingApprovalsProvider), hasLength(1));
    });

    test('sends approval responses for actionable Agent SDK approvals',
        () async {
      container.read(pendingApprovalsProvider.notifier);
      webSocketService.emitMessage(
        BridgeMessage(
          type: BridgeMessageType.approvalRequired,
          timestamp: DateTime.now().toUtc(),
          payload: {
            'session_id': 'sess-sdk',
            'tool_call_id': 'tool-sdk',
            'tool': 'run_command',
            'params': {'command': 'npm test'},
            'description': 'Run tests',
            'risk_level': 'medium',
            'source': 'agent_sdk',
          },
        ),
      );

      await Future<void>.delayed(Duration.zero);

      await container
          .read(pendingApprovalsProvider.notifier)
          .approve('sess-sdk', 'tool-sdk');

      expect(webSocketService.sentMessages, hasLength(1));
      expect(
        webSocketService.sentMessages.single.type,
        BridgeMessageType.approvalResponse,
      );
      expect(
        webSocketService.sentMessages.single.payload['tool_call_id'],
        'tool-sdk',
      );
      expect(container.read(pendingApprovalsProvider), isEmpty);
    });
  });
}

class FakeApprovalWebSocketService extends WebSocketService {
  final StreamController<BridgeMessage> _messageController =
      StreamController<BridgeMessage>.broadcast();
  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  final List<BridgeMessage> sentMessages = <BridgeMessage>[];

  @override
  Stream<BridgeMessage> get messages => _messageController.stream;

  @override
  Stream<ConnectionStatus> get connectionStatus => _statusController.stream;

  @override
  ConnectionStatus get currentStatus => ConnectionStatus.connected;

  @override
  bool send(BridgeMessage message) {
    sentMessages.add(message);
    return true;
  }

  void emitMessage(BridgeMessage message) {
    _messageController.add(message);
  }

  Future<void> close() async {
    await _messageController.close();
    await _statusController.close();
  }
}
