import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:recursor_mobile/core/network/bridge_connection_validator.dart';
import 'package:recursor_mobile/core/network/connection_state.dart';
import 'package:recursor_mobile/core/network/websocket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  group('WebSocketService', () {
    test('sends auth and waits for connection_ack before becoming connected',
        () async {
      final fakeChannel = FakeWebSocketChannel();
      final service = WebSocketService(channelFactory: (_) => fakeChannel);
      final statuses = <ConnectionStatus>[];

      final statusSub = service.connectionStatus.listen(statuses.add);
      final Future<void> connectFuture = service.connect(
        url: 'wss://device.tailnet.ts.net:3000',
        token: 'bridge-token-123',
      );

      await Future<void>.delayed(Duration.zero);

      expect(statuses.first, ConnectionStatus.connecting);
      expect(fakeChannel.sentMessages, hasLength(1));

      final authFrame =
          jsonDecode(fakeChannel.sentMessages.single) as Map<String, dynamic>;
      expect(authFrame['type'], 'auth');
      expect(
        (authFrame['payload'] as Map<String, dynamic>)['token'],
        'bridge-token-123',
      );

      fakeChannel.addIncoming(
        jsonEncode({
          'type': 'connection_ack',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'payload': {
            'server_version': '1.0.0',
            'supported_agents': <String>[],
            'active_sessions': <Map<String, dynamic>>[],
          },
        }),
      );

      await connectFuture;

      expect(service.currentStatus, ConnectionStatus.connected);
      expect(statuses, contains(ConnectionStatus.connected));

      await statusSub.cancel();
      service.dispose();
      await fakeChannel.close();
    });

    test('surfaces connection_error without scheduling reconnects', () async {
      final fakeChannel = FakeWebSocketChannel();
      var connectionAttempts = 0;
      final service = WebSocketService(channelFactory: (_) {
        connectionAttempts++;
        return fakeChannel;
      });

      final Future<void> connectFuture = service.connect(
        url: 'wss://device.tailnet.ts.net:3000',
        token: 'bridge-token-123',
      );

      await Future<void>.delayed(Duration.zero);

      fakeChannel.addIncoming(
        jsonEncode({
          'type': 'connection_error',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'payload': {
            'code': 'AUTH_FAILED',
            'message': 'Invalid or expired token',
          },
        }),
      );

      await expectLater(
        connectFuture,
        throwsA(
          isA<BridgeConnectionException>().having(
            (error) => error.message,
            'message',
            'Invalid or expired token',
          ),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(service.currentStatus, ConnectionStatus.error);
      expect(connectionAttempts, 1);

      service.dispose();
      await fakeChannel.close();
    });
  });
}

class FakeWebSocketChannel implements WebSocketChannel {
  FakeWebSocketChannel({Future<void>? ready})
      : ready = ready ?? Future<void>.value(),
        _incomingController = StreamController<dynamic>.broadcast(),
        _sink = FakeWebSocketSink(<String>[]);

  final StreamController<dynamic> _incomingController;
  final FakeWebSocketSink _sink;

  @override
  final Future<void> ready;

  List<String> get sentMessages => _sink.messages;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  @override
  Stream<dynamic> get stream => _incomingController.stream;

  @override
  WebSocketSink get sink => _sink;

  void addIncoming(String message) {
    _incomingController.add(message);
  }

  Future<void> close() async {
    await _sink.close();
    await _incomingController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class FakeWebSocketSink implements WebSocketSink {
  FakeWebSocketSink(this.messages);

  final List<String> messages;
  final Completer<void> _doneCompleter = Completer<void>();

  @override
  Future<void> get done => _doneCompleter.future;

  @override
  void add(Object? data) {
    messages.add(data as String);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {
    await for (final data in stream) {
      add(data);
    }
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete();
    }
  }
}
