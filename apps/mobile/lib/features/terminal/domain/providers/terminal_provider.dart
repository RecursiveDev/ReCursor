import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/websocket_messages.dart';
import '../../../../core/providers/websocket_provider.dart';

// ---------------------------------------------------------------------------
// Terminal output per session
// ---------------------------------------------------------------------------

class TerminalNotifier extends StateNotifier<List<String>> {
  TerminalNotifier(this._ref, this._sessionId) : super([]) {
    _listen();
  }

  final Ref _ref;
  final String _sessionId;
  StreamSubscription<BridgeMessage>? _sub;

  void _listen() {
    final service = _ref.read(webSocketServiceProvider);
    _sub = service.messages.listen(_handleMessage);
  }

  void _handleMessage(BridgeMessage msg) {
    if (msg.type == BridgeMessageType.claudeEvent) {
      final msgType = msg.payload['type'] as String?;
      final sessionId = msg.payload['session_id'] as String?;

      if (msgType == 'terminal_output' && sessionId == _sessionId) {
        final line = msg.payload['data'] as String? ?? '';
        state = [...state, line];
      }
    }
  }

  /// Sends a `terminal_create` WS message.
  void createSession(String sessionId, String workingDir) {
    final service = _ref.read(webSocketServiceProvider);
    service.send(BridgeMessage(
      type: BridgeMessageType.claudeEvent,
      timestamp: DateTime.now().toUtc(),
      payload: {
        'type': 'terminal_create',
        'session_id': sessionId,
        'working_directory': workingDir,
      },
    ));
  }

  /// Sends a `terminal_input` WS message and echoes the command locally.
  void sendInput(String sessionId, String command) {
    final service = _ref.read(webSocketServiceProvider);
    service.send(BridgeMessage(
      type: BridgeMessageType.claudeEvent,
      timestamp: DateTime.now().toUtc(),
      payload: {
        'type': 'terminal_input',
        'session_id': sessionId,
        'data': '$command\n',
      },
    ));
    // Echo locally so the user sees their own input immediately.
    state = [...state, '\$ $command'];
  }

  /// Sends a `terminal_close` WS message.
  void closeSession(String sessionId) {
    final service = _ref.read(webSocketServiceProvider);
    service.send(BridgeMessage(
      type: BridgeMessageType.claudeEvent,
      timestamp: DateTime.now().toUtc(),
      payload: {
        'type': 'terminal_close',
        'session_id': sessionId,
      },
    ));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final terminalOutputProvider =
    StateNotifierProvider.family<TerminalNotifier, List<String>, String>(
  (ref, sessionId) => TerminalNotifier(ref, sessionId),
);
