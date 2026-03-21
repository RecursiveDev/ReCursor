import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recursor_mobile/core/network/connection_state.dart';
import 'package:recursor_mobile/core/network/websocket_messages.dart';
import 'package:recursor_mobile/core/network/websocket_service.dart';
import 'package:recursor_mobile/core/providers/websocket_provider.dart';
import 'package:recursor_mobile/features/chat/domain/providers/session_provider.dart';
import 'package:recursor_mobile/features/repos/presentation/screens/file_tree_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FileTreeScreen falls back to the current chat session context',
      (tester) async {
    final webSocketService = FakeRepoContextWebSocketService();
    final container = ProviderContainer(
      overrides: [
        webSocketServiceProvider.overrideWithValue(webSocketService),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(webSocketService.close);

    container.read(currentSessionProvider.notifier).state = 'sess-file-context';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: FileTreeScreen(sessionId: ''),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(webSocketService.sentMessages, hasLength(1));
    expect(
      webSocketService.sentMessages.single.payload['session_id'],
      'sess-file-context',
    );
    expect(find.text('/workspace/repo'), findsOneWidget);
    expect(find.text('README.md'), findsOneWidget);
    expect(find.text('lib'), findsOneWidget);
  });
}

class FakeRepoContextWebSocketService extends WebSocketService {
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

    if (message.type == BridgeMessageType.fileList) {
      Future<void>.microtask(() {
        _messageController.add(
          BridgeMessage(
            type: BridgeMessageType.fileListResponse,
            id: message.id,
            timestamp: DateTime.now().toUtc(),
            payload: {
              'path': '/workspace/repo',
              'entries': [
                {
                  'name': 'lib',
                  'path': '/workspace/repo/lib',
                  'type': 'directory',
                  'modified': '2026-03-21T12:00:00.000Z',
                },
                {
                  'name': 'README.md',
                  'path': '/workspace/repo/README.md',
                  'type': 'file',
                  'size': 128,
                  'modified': '2026-03-21T12:00:00.000Z',
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
