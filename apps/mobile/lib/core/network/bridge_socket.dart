// Re-exports for backwards compatibility with generated code
export '../providers/websocket_provider.dart'
    show webSocketServiceProvider, connectionStatusProvider, bridgeMessagesProvider;
export 'connection_state.dart' show ConnectionStatus;

// Aliases
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'websocket_messages.dart';
import 'websocket_service.dart';
import '../providers/websocket_provider.dart';
import 'connection_state.dart';

/// Thin facade over [WebSocketService] that exposes a map-based API used by
/// feature providers generated before the typed-message redesign.
class BridgeSocket {
  BridgeSocket(this._service);

  final WebSocketService _service;

  /// Stream of decoded JSON payloads from the bridge.
  Stream<Map<String, dynamic>> get messageStream =>
      _service.messages.map((msg) => msg.toJson());

  /// Send a raw map as a JSON frame.
  void send(Map<String, dynamic> data) {
    _service.sendRaw(jsonEncode(data));
  }

  ConnectionStatus get currentStatus => _service.currentStatus;
}

final _bridgeSocketProvider = Provider<BridgeSocket>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return BridgeSocket(service);
});

/// Alias: bridgeSocketProvider exposes the [BridgeSocket] facade.
final bridgeSocketProvider = _bridgeSocketProvider;

/// Alias: bridgeSocketStateProvider = connectionStatusProvider
final bridgeSocketStateProvider = connectionStatusProvider;

/// Alias type: BridgeSocketState = ConnectionStatus
typedef BridgeSocketState = ConnectionStatus;
