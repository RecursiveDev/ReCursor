import 'dart:async';

import '../network/connection_state.dart';
import '../network/websocket_service.dart';
import '../notifications/notification_center.dart';
import 'sync_queue.dart';

/// Orchestrates sync on reconnection.
/// Listens to [WebSocketService.connectionStatus] and triggers queue flush
/// when the connection is (re-)established.
class SyncService {
  SyncService({
    required WebSocketService webSocketService,
    required SyncQueueService syncQueue,
    required NotificationCenter notificationCenter,
  })  : _ws = webSocketService,
        _syncQueue = syncQueue,
        _notificationCenter = notificationCenter;

  final WebSocketService _ws;
  final SyncQueueService _syncQueue;
  final NotificationCenter _notificationCenter;

  StreamSubscription<ConnectionStatus>? _statusSubscription;
  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;

    _statusSubscription = _ws.connectionStatus.listen((status) async {
      if (status == ConnectionStatus.connected) {
        await _onReconnected();
      }
    });
  }

  Future<void> _onReconnected() async {
    // Flush queued messages.
    await _syncQueue.flush(_ws);
  }

  void stop() {
    _running = false;
    _statusSubscription?.cancel();
    _statusSubscription = null;
  }
}
