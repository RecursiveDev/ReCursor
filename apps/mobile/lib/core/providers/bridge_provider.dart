import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/connection_state.dart';
import '../network/websocket_service.dart';
import 'websocket_provider.dart';

/// Notifier that exposes connect/disconnect actions on the shared
/// [WebSocketService]. UI reads [bridgeProvider] for connection state and
/// calls `.notifier.connect(url, token)` to initiate a connection.
class BridgeNotifier extends Notifier<ConnectionStatus> {
  @override
  ConnectionStatus build() {
    final service = ref.watch(webSocketServiceProvider);
    // Sync initial status.
    final initial = service.currentStatus;

    // Keep state in sync with the service stream.
    final sub = service.connectionStatus.listen((s) {
      state = s;
    });
    ref.onDispose(sub.cancel);

    return initial;
  }

  /// Connect to the bridge at [url] using [token].
  Future<void> connect(String url, String token) {
    final service = ref.read(webSocketServiceProvider);
    return service.connect(url: url, token: token);
  }

  /// Disconnect from the bridge.
  void disconnect() {
    final service = ref.read(webSocketServiceProvider);
    service.disconnect();
  }
}

final bridgeProvider =
    NotifierProvider<BridgeNotifier, ConnectionStatus>(BridgeNotifier.new);
