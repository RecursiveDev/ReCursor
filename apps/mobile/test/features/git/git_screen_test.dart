import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recursor_mobile/core/network/connection_state.dart';
import 'package:recursor_mobile/core/network/websocket_messages.dart';
import 'package:recursor_mobile/core/network/websocket_service.dart';
import 'package:recursor_mobile/core/providers/websocket_provider.dart';
import 'package:recursor_mobile/features/chat/domain/providers/session_provider.dart';
import 'package:recursor_mobile/features/git/presentation/screens/git_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GitScreen falls back to the current chat session context',
      (tester) async {
    final webSocketService = FakeGitContextWebSocketService();
    final container = ProviderContainer(
      overrides: [
        webSocketServiceProvider.overrideWithValue(webSocketService),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(webSocketService.close);

    container.read(currentSessionProvider.notifier).state = 'sess-git-context';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: GitScreen(sessionId: ''),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(webSocketService.sentMessages, hasLength(1));
    expect(
      webSocketService.sentMessages.single.payload['session_id'],
      'sess-git-context',
    );
    expect(find.text('feature/context-sync'), findsOneWidget);
    expect(find.text('lib/main.dart'), findsOneWidget);
  });
}

class FakeGitContextWebSocketService extends WebSocketService {
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

    if (message.type == BridgeMessageType.gitStatusRequest) {
      Future<void>.microtask(() {
        _messageController.add(
          BridgeMessage(
            type: BridgeMessageType.gitStatusResponse,
            id: message.id,
            timestamp: DateTime.now().toUtc(),
            payload: {
              'branch': 'feature/context-sync',
              'ahead': 1,
              'behind': 0,
              'is_clean': false,
              'changes': [
                {
                  'path': 'lib/main.dart',
                  'status': 'modified',
                  'additions': 2,
                  'deletions': 1,
                },
              ],
            },
          ),
        );
      });
    }

    return true;
  }

  Future<void> close() async {
    await _messageController.close();
    await _statusController.close();
  }
}
