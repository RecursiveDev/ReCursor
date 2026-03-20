import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recursor_mobile/core/network/connection_state.dart';
import 'package:recursor_mobile/core/network/websocket_messages.dart';
import 'package:recursor_mobile/core/network/websocket_service.dart';
import 'package:recursor_mobile/core/providers/websocket_provider.dart';
import 'package:recursor_mobile/features/diff/domain/providers/diff_provider.dart';

void main() {
  group('DiffNotifier', () {
    late ProviderContainer container;
    late FakeDiffWebSocketService webSocketService;
    late ProviderSubscription<AsyncValue<void>> subscription;

    setUp(() async {
      webSocketService = FakeDiffWebSocketService();
      container = ProviderContainer(
        overrides: [
          webSocketServiceProvider.overrideWithValue(webSocketService),
        ],
      );
      subscription = container.listen<AsyncValue<void>>(
        diffNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      addTearDown(container.dispose);
      await container.read(diffNotifierProvider.future);
    });

    tearDown(() async {
      await webSocketService.close();
    });

    test('opens a unified diff handoff into the shared diff state', () {
      final opened =
          container.read(diffNotifierProvider.notifier).openUnifiedDiff(
                '--- a/lib/main.dart\n'
                '+++ b/lib/main.dart\n'
                '@@ -1 +1 @@\n'
                '-void oldMain() {}\n'
                '+void main() {}',
              );

      final files = container.read(currentDiffProvider);

      expect(opened, isTrue);
      expect(files, isNotNull);
      expect(files, hasLength(1));
      expect(files!.single.path, 'lib/main.dart');
      expect(files.single.additions, 1);
      expect(files.single.deletions, 1);
    });

    test('updates currentDiffProvider from git_diff responses', () async {
      webSocketService.emitMessage(
        BridgeMessage(
          type: BridgeMessageType.gitDiffResponse,
          timestamp: DateTime.now().toUtc(),
          payload: {
            'files': [
              {
                'path': 'lib/main.dart',
                'old_path': 'lib/main.dart',
                'new_path': 'lib/main.dart',
                'status': 'modified',
                'additions': 1,
                'deletions': 1,
                'hunks': [
                  {
                    'header': '@@ -1 +1 @@',
                    'old_start': 1,
                    'old_lines': 1,
                    'new_start': 1,
                    'new_lines': 1,
                    'lines': [
                      {
                        'type': 'removed',
                        'content': 'void oldMain() {}',
                        'old_line_number': 1,
                      },
                      {
                        'type': 'added',
                        'content': 'void main() {}',
                        'new_line_number': 1,
                      },
                    ],
                  },
                ],
              },
            ],
          },
        ),
      );

      await Future<void>.delayed(Duration.zero);

      final files = container.read(currentDiffProvider);
      expect(files, isNotNull);
      expect(files!.single.path, 'lib/main.dart');
      expect(files.single.hunks.single.lines, hasLength(2));
    });
  });
}

class FakeDiffWebSocketService extends WebSocketService {
  final StreamController<BridgeMessage> _messageController =
      StreamController<BridgeMessage>.broadcast();
  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();

  @override
  Stream<BridgeMessage> get messages => _messageController.stream;

  @override
  Stream<ConnectionStatus> get connectionStatus => _statusController.stream;

  @override
  ConnectionStatus get currentStatus => ConnectionStatus.connected;

  @override
  bool send(BridgeMessage message) => true;

  void emitMessage(BridgeMessage message) {
    _messageController.add(message);
  }

  Future<void> close() async {
    await _messageController.close();
    await _statusController.close();
  }
}
