import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'connection_state.dart';
import 'websocket_messages.dart';

/// WebSocket client service for communication with the ReCursor bridge server.
///
/// Responsibilities:
/// - Connect / disconnect lifecycle
/// - Authentication handshake
/// - Heartbeat (ping every 15 s, expect pong within 10 s)
/// - Automatic reconnect with exponential back-off (1 → 2 → 4 → 8 … max 30 s)
/// - Serialize outgoing [BridgeMessage] to JSON
/// - Parse incoming JSON into [BridgeMessage]
class WebSocketService {
  static const int _heartbeatIntervalSeconds = 15;
  static const int _heartbeatTimeoutSeconds = 10;
  static const int _maxReconnectDelaySeconds = 30;

  WebSocketChannel? _channel;
  String? _url;
  String? _token;

  final _messageController = StreamController<BridgeMessage>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  int _reconnectAttempts = 0;
  bool _intentionalDisconnect = false;

  Timer? _heartbeatTimer;
  Timer? _pongTimeoutTimer;
  Timer? _reconnectTimer;

  // ---------------------------------------------------------------------------
  // Public streams
  // ---------------------------------------------------------------------------

  Stream<BridgeMessage> get messages => _messageController.stream;
  Stream<ConnectionStatus> get connectionStatus => _statusController.stream;
  ConnectionStatus get currentStatus => _status;

  // ---------------------------------------------------------------------------
  // Connect / Disconnect
  // ---------------------------------------------------------------------------

  Future<void> connect({required String url, required String token}) async {
    _url = url;
    _token = token;
    _intentionalDisconnect = false;
    _reconnectAttempts = 0;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    _setStatus(ConnectionStatus.connecting);

    try {
      final uri = Uri.parse(_url!);
      _channel = WebSocketChannel.connect(uri);

      // Wait for the channel to be ready (throws on auth/network failure).
      await _channel!.ready;

      _setStatus(ConnectionStatus.connected);
      _reconnectAttempts = 0;

      // Send auth immediately.
      send(BridgeMessage.auth(
        token: _token!,
        clientVersion: '0.1.0',
        platform: _platformString(),
      ));

      // Start listening to incoming frames.
      _channel!.stream.listen(
        _onRawMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _startHeartbeat();
    } catch (e) {
      _setStatus(ConnectionStatus.error);
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _intentionalDisconnect = true;
    _cleanUp();
    _setStatus(ConnectionStatus.disconnected);
  }

  // ---------------------------------------------------------------------------
  // Send
  // ---------------------------------------------------------------------------

  void send(BridgeMessage message) {
    if (_channel == null || _status != ConnectionStatus.connected) return;
    _channel!.sink.add(message.toJsonString());
  }

  /// Send raw JSON string — primarily for testing.
  void sendRaw(String json) {
    _channel?.sink.add(json);
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _onRawMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final msg = BridgeMessage.fromJson(json);

      // Heartbeat pong — cancel timeout timer.
      if (msg.type == BridgeMessageType.heartbeatPong) {
        _pongTimeoutTimer?.cancel();
        _pongTimeoutTimer = null;
        return;
      }

      _messageController.add(msg);
    } catch (_) {
      // Malformed message — ignore.
    }
  }

  void _onError(Object error) {
    _setStatus(ConnectionStatus.error);
    _cleanUp(closeChannel: false);
    if (!_intentionalDisconnect) _scheduleReconnect();
  }

  void _onDone() {
    _setStatus(ConnectionStatus.disconnected);
    _cleanUp(closeChannel: false);
    if (!_intentionalDisconnect) _scheduleReconnect();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      Duration(seconds: _heartbeatIntervalSeconds),
      (_) => _sendPing(),
    );
  }

  void _sendPing() {
    if (_status != ConnectionStatus.connected) return;
    send(BridgeMessage.heartbeatPing());

    // Expect pong within timeout window.
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = Timer(
      Duration(seconds: _heartbeatTimeoutSeconds),
      _onPongTimeout,
    );
  }

  void _onPongTimeout() {
    // No pong received — trigger reconnect.
    _cleanUp(closeChannel: true);
    _setStatus(ConnectionStatus.reconnecting);
    if (!_intentionalDisconnect) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_intentionalDisconnect) return;
    _reconnectTimer?.cancel();

    final delaySeconds = _exponentialDelay(_reconnectAttempts);
    _reconnectAttempts++;
    _setStatus(ConnectionStatus.reconnecting);

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (!_intentionalDisconnect) await _doConnect();
    });
  }

  int _exponentialDelay(int attempt) {
    final delay = (1 << attempt).clamp(1, _maxReconnectDelaySeconds);
    return delay;
  }

  void _cleanUp({bool closeChannel = true}) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (closeChannel) {
      _channel?.sink.close();
      _channel = null;
    }
  }

  void _setStatus(ConnectionStatus status) {
    _status = status;
    _statusController.add(status);
  }

  String _platformString() {
    // In a full implementation, use Platform.isIOS / Platform.isAndroid.
    return 'flutter';
  }

  void dispose() {
    _intentionalDisconnect = true;
    _cleanUp();
    _messageController.close();
    _statusController.close();
  }
}
