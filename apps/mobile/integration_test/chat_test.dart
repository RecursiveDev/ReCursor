import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:recursor_mobile/core/network/connection_state.dart';
import 'package:recursor_mobile/core/network/websocket_messages.dart';
import 'package:recursor_mobile/core/network/websocket_service.dart';
import 'package:recursor_mobile/core/providers/database_provider.dart';
import 'package:recursor_mobile/core/providers/websocket_provider.dart';
import 'package:recursor_mobile/core/storage/database.dart';
import 'package:recursor_mobile/features/chat/presentation/screens/session_list_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('starting a chat session sends a session_start request',
      (tester) async {
    final database = AppDatabase.inMemory();
    final webSocketService = FakeIntegrationWebSocketService(
      initialStatus: ConnectionStatus.connected,
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const SessionListScreen(),
        ),
        GoRoute(
          path: '/home/chat/:sessionId',
          builder: (_, state) => Scaffold(
            body: Center(
              child: Text('Chat ${state.pathParameters['sessionId']}'),
            ),
          ),
        ),
      ],
    );

    addTearDown(() async {
      router.dispose();
      await webSocketService.close();
      await database.close();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          webSocketServiceProvider.overrideWithValue(webSocketService),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New Session'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('newSessionWorkingDirectoryField')),
      '/workspace/integration-project',
    );
    await tester.tap(find.text('Start Session'));
    await tester.pumpAndSettle();

    expect(webSocketService.sentMessages, hasLength(1));
    expect(webSocketService.sentMessages.single.type,
        BridgeMessageType.sessionStart);
    expect(
      webSocketService.sentMessages.single.payload['working_directory'],
      '/workspace/integration-project',
    );
    expect(find.textContaining('Chat '), findsOneWidget);

    final sessions = await database.select(database.sessions).get();
    expect(sessions, hasLength(1));
    expect(sessions.single.workingDirectory, '/workspace/integration-project');
  });
}

class FakeIntegrationWebSocketService extends WebSocketService {
  FakeIntegrationWebSocketService({required ConnectionStatus initialStatus})
      : _currentStatus = initialStatus;

  final StreamController<BridgeMessage> _messageController =
      StreamController<BridgeMessage>.broadcast();
  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  final List<BridgeMessage> sentMessages = <BridgeMessage>[];
  final ConnectionStatus _currentStatus;

  @override
  Stream<BridgeMessage> get messages => _messageController.stream;

  @override
  Stream<ConnectionStatus> get connectionStatus => _statusController.stream;

  @override
  ConnectionStatus get currentStatus => _currentStatus;

  @override
  bool send(BridgeMessage message) {
    if (_currentStatus != ConnectionStatus.connected) {
      return false;
    }
    sentMessages.add(message);
    return true;
  }

  Future<void> close() async {
    await _messageController.close();
    await _statusController.close();
  }
}
