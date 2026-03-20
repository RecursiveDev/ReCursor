import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recursor_mobile/core/network/connection_state.dart';
import 'package:recursor_mobile/core/network/websocket_messages.dart';
import 'package:recursor_mobile/core/network/websocket_service.dart';
import 'package:recursor_mobile/core/providers/websocket_provider.dart';
import 'package:recursor_mobile/features/chat/presentation/widgets/chat_input_bar.dart';

void main() {
  testWidgets('offline chat input queues locally instead of blocking send',
      (tester) async {
    final webSocketService = FakeWidgetWebSocketService(
      initialStatus: ConnectionStatus.disconnected,
    );
    String? submittedText;

    addTearDown(webSocketService.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          webSocketServiceProvider.overrideWithValue(webSocketService),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ChatInputBar(
              sessionId: 'sess-widget',
              onSend: (text) => submittedText = text,
              onVoice: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('Offline — messages will send when reconnected'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.schedule_send), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Queue me');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.schedule_send));
    await tester.pump();

    expect(submittedText, 'Queue me');
  });
}

class FakeWidgetWebSocketService extends WebSocketService {
  FakeWidgetWebSocketService({required ConnectionStatus initialStatus})
      : _currentStatus = initialStatus;

  final StreamController<BridgeMessage> _messageController =
      StreamController<BridgeMessage>.broadcast();
  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  final ConnectionStatus _currentStatus;

  @override
  Stream<BridgeMessage> get messages => _messageController.stream;

  @override
  Stream<ConnectionStatus> get connectionStatus => _statusController.stream;

  @override
  ConnectionStatus get currentStatus => _currentStatus;

  @override
  bool send(BridgeMessage message) {
    return _currentStatus == ConnectionStatus.connected;
  }

  Future<void> close() async {
    await _messageController.close();
    await _statusController.close();
  }
}
