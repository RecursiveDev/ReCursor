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
            'connection_mode': 'secure_remote',
            'connection_mode_description': 'Secure tunnel',
            'bridge_url': 'wss://device.tailnet.ts.net:3000',
            'requires_health_verification': true,
            'active_sessions': <Map<String, dynamic>>[],
          },
        }),
      );

      await connectFuture;

      expect(service.currentStatus, ConnectionStatus.connected);
      expect(statuses, contains(ConnectionStatus.connected));
      expect(
        service.lastConnectionAckPayload?['requires_health_verification'],
        isTrue,
      );

      await statusSub.cancel();
      service.dispose();
      await fakeChannel.close();
    });

    test('can request bridge health status after auth', () async {
      final fakeChannel = FakeWebSocketChannel();
      final service = WebSocketService(channelFactory: (_) => fakeChannel);

      final connectFuture = service.connect(
        url: 'wss://device.tailnet.ts.net:3000',
        token: 'bridge-token-123',
      );
      await Future<void>.delayed(Duration.zero);

      fakeChannel.addIncoming(
        jsonEncode({
          'type': 'connection_ack',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'payload': {
            'server_version': '1.0.0',
            'supported_agents': <String>[],
            'connection_mode': 'secure_remote',
            'connection_mode_description': 'Secure tunnel',
            'bridge_url': 'wss://device.tailnet.ts.net:3000',
            'requires_health_verification': true,
            'active_sessions': <Map<String, dynamic>>[],
          },
        }),
      );
      await connectFuture;

      final healthFuture = service.requestHealthCheck();
      await Future<void>.delayed(Duration.zero);

      final healthFrame =
          jsonDecode(fakeChannel.sentMessages.last) as Map<String, dynamic>;
      expect(healthFrame['type'], 'health_check');

      fakeChannel.addIncoming(
        jsonEncode({
          'type': 'health_status',
          'id': healthFrame['id'],
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'payload': {
            'status': 'healthy',
            'connection_mode': 'secure_remote',
            'warnings': <String>[],
            'checks': {
              'tls_valid': true,
              'clock_sync': true,
              'version_compatible': true,
              'token_permissions': true,
            },
            'server_timestamp': DateTime.now().toUtc().toIso8601String(),
            'latency_ms': 24,
            'ready': true,
          },
        }),
      );

      final payload = await healthFuture;
      expect(payload['status'], 'healthy');
      expect(service.lastHealthStatusPayload?['ready'], isTrue);

      service.dispose();
      await fakeChannel.close();
    });

    test('can acknowledge warning for direct public bridge mode', () async {
      final fakeChannel = FakeWebSocketChannel();
      final service = WebSocketService(channelFactory: (_) => fakeChannel);

      final connectFuture = service.connect(
        url: 'wss://203.0.113.42:3000',
        token: 'bridge-token-123',
      );
      await Future<void>.delayed(Duration.zero);

      fakeChannel.addIncoming(
        jsonEncode({
          'type': 'connection_ack',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'payload': {
            'server_version': '1.0.0',
            'supported_agents': <String>[],
            'connection_mode': 'direct_public',
            'connection_mode_description': 'Direct public connection',
            'bridge_url': 'wss://203.0.113.42:3000',
            'requires_health_verification': true,
            'active_sessions': <Map<String, dynamic>>[],
          },
        }),
      );
      await connectFuture;

      final healthFuture = service.requestHealthCheck();
      await Future<void>.delayed(Duration.zero);
      fakeChannel.addIncoming(
        jsonEncode({
          'type': 'health_status',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'payload': {
            'status': 'warning',
            'connection_mode': 'direct_public',
            'warnings': ['DIRECT_PUBLIC_CONNECTION'],
            'checks': {
              'tls_valid': true,
              'clock_sync': true,
              'version_compatible': true,
              'token_permissions': true,
            },
            'server_timestamp': DateTime.now().toUtc().toIso8601String(),
            'latency_ms': 45,
            'ready': false,
            'requires_acknowledgment': true,
          },
        }),
      );
      await healthFuture;

      final ackFuture = service.acknowledgeWarning('DIRECT_PUBLIC_CONNECTION');
      await Future<void>.delayed(Duration.zero);

      final ackFrame =
          jsonDecode(fakeChannel.sentMessages.last) as Map<String, dynamic>;
      expect(ackFrame['type'], 'acknowledge_warning');

      fakeChannel.addIncoming(
        jsonEncode({
          'type': 'acknowledgment_accepted',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'payload': {
            'warning_code': 'DIRECT_PUBLIC_CONNECTION',
            'ready': true,
            'session_timeout': '8h',
          },
        }),
      );

      final payload = await ackFuture;
      expect(payload['ready'], isTrue);
      expect(service.lastHealthStatusPayload?['ready'], isTrue);

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
