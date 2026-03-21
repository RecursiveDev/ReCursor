import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:recursor_mobile/core/network/websocket_messages.dart';
import 'package:recursor_mobile/core/network/websocket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Tests for connection purpose metadata handling (probe vs primary).
///
/// These tests define the expected behavior for mobile clients to declare
/// their connection purpose during auth handshake. Currently FAILING -
/// implementation code changes required.
///
/// Connection Purpose Semantics (per bridge-protocol.md):
/// - Probe: ~500ms-2s duration, health verification, capability check
/// - Primary: Session lifetime, active session for all communication
void main() {
  group('WebSocketService auth purpose field', () {
    test('sends purpose=probe in auth payload during health check flow',
        () async {
      final fakeChannel = FakeWebSocketChannel();
      final service = WebSocketService(channelFactory: (_) => fakeChannel);

      // Connect with purpose: probe for health verification
      final connectFuture = service.connect(
        url: 'wss://device.tailnet.ts.net:3000',
        token: 'bridge-token-123',
        purpose: ConnectionPurpose.probe, // NEW: Declare connection purpose
      );

      await Future<void>.delayed(Duration.zero);

      final authFrame =
          jsonDecode(fakeChannel.sentMessages.single) as Map<String, dynamic>;
      expect(authFrame['type'], 'auth');

      final payload = authFrame['payload'] as Map<String, dynamic>;
      expect(payload['token'], 'bridge-token-123');
      expect(payload['purpose'], 'probe'); // NEW: Purpose field in auth

      // Respond with connection_ack that echoes purpose
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
            'purpose': 'probe', // Echo accepted purpose
          },
        }),
      );

      await connectFuture;

      // Service should track its declared purpose
      expect(service.connectionPurpose, ConnectionPurpose.probe);

      service.dispose();
      await fakeChannel.close();
    });

    test('sends purpose=primary in auth payload for session connections',
        () async {
      final fakeChannel = FakeWebSocketChannel();
      final service = WebSocketService(channelFactory: (_) => fakeChannel);

      final connectFuture = service.connect(
        url: 'wss://device.tailnet.ts.net:3000',
        token: 'bridge-token-456',
        purpose: ConnectionPurpose.primary, // Primary session connection
      );

      await Future<void>.delayed(Duration.zero);

      final authFrame =
          jsonDecode(fakeChannel.sentMessages.single) as Map<String, dynamic>;
      expect(authFrame['type'], 'auth');

      final payload = authFrame['payload'] as Map<String, dynamic>;
      expect(payload['purpose'], 'primary'); // NEW: Purpose field in auth

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
            'purpose': 'primary',
          },
        }),
      );

      await connectFuture;

      expect(service.connectionPurpose, ConnectionPurpose.primary);

      service.dispose();
      await fakeChannel.close();
    });

    test('defaults to primary purpose when purpose argument omitted', () async {
      final fakeChannel = FakeWebSocketChannel();
      final service = WebSocketService(channelFactory: (_) => fakeChannel);

      // Legacy call without purpose argument - should default to primary
      final connectFuture = service.connect(
        url: 'wss://device.tailnet.ts.net:3000',
        token: 'bridge-token-789',
        // purpose argument omitted
      );

      await Future<void>.delayed(Duration.zero);

      final authFrame =
          jsonDecode(fakeChannel.sentMessages.single) as Map<String, dynamic>;
      final payload = authFrame['payload'] as Map<String, dynamic>;

      // Should default to 'primary' for backward compatibility
      expect(payload['purpose'], 'primary');

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
            'purpose': 'primary',
          },
        }),
      );

      await connectFuture;

      expect(service.connectionPurpose, ConnectionPurpose.primary);

      service.dispose();
      await fakeChannel.close();
    });
  });

  group('BridgeMessage.auth factory includes purpose field', () {
    test('creates auth message with purpose from enum value', () async {
      final authMessage = BridgeMessage.auth(
        token: 'test-token',
        clientVersion: '1.0.0',
        platform: 'ios',
        purpose: ConnectionPurpose.probe, // NEW: purpose parameter
      );

      expect(authMessage.type, BridgeMessageType.auth);
      expect(authMessage.payload['token'], 'test-token');
      expect(authMessage.payload['client_version'], '1.0.0');
      expect(authMessage.payload['platform'], 'ios');
      expect(authMessage.payload['purpose'], 'probe'); // NEW field
    });

    test('creates auth message with primary purpose as default', () async {
      // Legacy call without purpose - should default to primary
      final authMessage = BridgeMessage.auth(
        token: 'test-token',
        clientVersion: '1.0.0',
        platform: 'android',
      );

      expect(authMessage.payload['purpose'], 'primary');
    });
  });

  group('Connection purpose state management', () {
    test('tracks active purpose in connection state', () async {
      final fakeChannel = FakeWebSocketChannel();
      final service = WebSocketService(channelFactory: (_) => fakeChannel);

      // Initially purpose is null before connection
      expect(service.connectionPurpose, isNull);

      final connectFuture = service.connect(
        url: 'wss://device.tailnet.ts.net:3000',
        token: 'bridge-token',
        purpose: ConnectionPurpose.primary,
      );

      await Future<void>.delayed(Duration.zero);

      // During connecting phase, purpose should be set
      expect(service.connectionPurpose, ConnectionPurpose.primary);

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
      service.dispose();
      await fakeChannel.close();
    });

    test('clears purpose on disconnect', () async {
      final fakeChannel = FakeWebSocketChannel();
      final service = WebSocketService(channelFactory: (_) => fakeChannel);

      final connectFuture = service.connect(
        url: 'wss://device.tailnet.ts.net:3000',
        token: 'bridge-token',
        purpose: ConnectionPurpose.primary,
      );

      await Future<void>.delayed(Duration.zero);

      fakeChannel.addIncoming(
        jsonEncode({
          'type': 'connection_ack',
          'payload': {
            'server_version': '1.0.0',
            'supported_agents': <String>[],
            'connection_mode': 'secure_remote',
            'connection_mode_description': 'Secure tunnel',
            'bridge_url': 'wss://device.tailnet.ts.net:3000',
            'requires_health_verification': true,
            'active_sessions': [],
            'purpose': 'primary',
          },
        }),
      );

      await connectFuture;

      expect(service.connectionPurpose, ConnectionPurpose.primary);

      service.disconnect();

      // Purpose should be cleared after disconnect
      expect(service.connectionPurpose, isNull);

      service.dispose();
      await fakeChannel.close();
    });
  });
}

/// Fake WebSocket channel for testing purposes.
///
/// Mirrors the implementation from websocket_service_test.dart for isolated testing.
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

/// Fake WebSocket sink for testing purposes.
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
