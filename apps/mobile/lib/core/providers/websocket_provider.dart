import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/connection_state.dart';
import '../network/websocket_messages.dart';
import '../network/websocket_service.dart';

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(service.dispose);
  return service;
});

final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.connectionStatus;
});

final bridgeMessagesProvider = StreamProvider<BridgeMessage>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.messages;
});
