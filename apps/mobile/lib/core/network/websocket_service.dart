import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'bridge_connection_validator.dart';
import 'connection_state.dart';
import 'websocket_messages.dart';

typedef WebSocketChannelFactory = WebSocketChannel Function(Uri uri);

class WebSocketService {
  WebSocketService({WebSocketChannelFactory? channelFactory})
      : _channelFactory = channelFactory ?? WebSocketChannel.connect;

  static const int _heartbeatIntervalSeconds = 15;
  static const int _heartbeatTimeoutSeconds = 10;
  static const int _authTimeoutSeconds = 10;
  static const int _requestTimeoutSeconds = 10;
  static const int _maxReconnectDelaySeconds = 30;
  static const Uuid _uuid = Uuid();

  final WebSocketChannelFactory _channelFactory;

  WebSocketChannel? _channel;
  String? _url;
  String? _token;
  ConnectionPurpose? _connectionPurpose;
  Map<String, dynamic>? _lastConnectionAckPayload;
  Map<String, dynamic>? _lastHealthStatusPayload;

  final StreamController<BridgeMessage> _messageController =
      StreamController<BridgeMessage>.broadcast();
  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  int _reconnectAttempts = 0;
  bool _intentionalDisconnect = false;
  bool _authFailed = false;
  Completer<void>? _authCompleter;
  Completer<Map<String, dynamic>>? _healthCheckCompleter;
  Completer<Map<String, dynamic>>? _warningAckCompleter;

  Timer? _heartbeatTimer;
  Timer? _pongTimeoutTimer;
  Timer? _reconnectTimer;

  Stream<BridgeMessage> get messages => _messageController.stream;
  Stream<ConnectionStatus> get connectionStatus => _statusController.stream;
  ConnectionStatus get currentStatus => _status;
  ConnectionPurpose? get connectionPurpose => _connectionPurpose;
  Map<String, dynamic>? get lastConnectionAckPayload =>
      _lastConnectionAckPayload;
  Map<String, dynamic>? get lastHealthStatusPayload => _lastHealthStatusPayload;

  Future<void> connect({
    required String url,
    required String token,
    ConnectionPurpose purpose = ConnectionPurpose.primary,
  }) async {
    final validation = BridgeConnectionValidator.validate(
      url: url,
      token: token,
    );
    if (!validation.isValid) {
      throw BridgeConnectionException(validation.errorMessage!);
    }

    _url = url.trim();
    _token = token.trim();
    _connectionPurpose = purpose;
    _intentionalDisconnect = false;
    _authFailed = false;
    _reconnectAttempts = 0;
    _lastHealthStatusPayload = null;
    await _doConnect();
  }

  Future<Map<String, dynamic>> requestHealthCheck() async {
    _ensureConnected();
    _completePendingRequest(
      _healthCheckCompleter,
      const BridgeConnectionException('Bridge health check was superseded.'),
    );
    _healthCheckCompleter = Completer<Map<String, dynamic>>();

    final sent = _sendInternal(
      BridgeMessage.healthCheck(clientNonce: _uuid.v4()),
    );
    if (!sent) {
      _completePendingRequest(
        _healthCheckCompleter,
        const BridgeConnectionException('Unable to send bridge health check.'),
      );
      throw const BridgeConnectionException(
        'Unable to send bridge health check.',
      );
    }

    return _healthCheckCompleter!.future.timeout(
      const Duration(seconds: _requestTimeoutSeconds),
      onTimeout: () {
        throw const BridgeConnectionException(
          'Bridge health verification timed out.',
        );
      },
    );
  }

  Future<Map<String, dynamic>> acknowledgeWarning(String warningCode) async {
    _ensureConnected();
    _completePendingRequest(
      _warningAckCompleter,
      const BridgeConnectionException(
          'Bridge warning acknowledgment was superseded.'),
    );
    _warningAckCompleter = Completer<Map<String, dynamic>>();

    final sent = _sendInternal(
      BridgeMessage.acknowledgeWarning(warningCode: warningCode),
    );
    if (!sent) {
      _completePendingRequest(
        _warningAckCompleter,
        const BridgeConnectionException(
            'Unable to acknowledge bridge warning.'),
      );
      throw const BridgeConnectionException(
        'Unable to acknowledge bridge warning.',
      );
    }

    return _warningAckCompleter!.future.timeout(
      const Duration(seconds: _requestTimeoutSeconds),
      onTimeout: () {
        throw const BridgeConnectionException(
          'Bridge warning acknowledgment timed out.',
        );
      },
    );
  }

  Future<void> _doConnect() async {
    if (_url == null || _token == null) {
      throw const BridgeConnectionException(
        'Bridge connection details are incomplete.',
      );
    }

    if (_status != ConnectionStatus.reconnecting) {
      _setStatus(ConnectionStatus.connecting);
    }

    _cleanUp(closeChannel: true, cancelReconnect: false);
    _authCompleter = Completer<void>();

    try {
      final Uri uri = Uri.parse(_url!);
      final WebSocketChannel channel = _channelFactory(uri);
      _channel = channel;

      channel.stream.listen(
        _onRawMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      await channel.ready;

      _sendInternal(
        BridgeMessage.auth(
          token: _token!,
          clientVersion: '0.1.0',
          platform: _platformString(),
          purpose: _connectionPurpose ?? ConnectionPurpose.primary,
        ),
      );

      await _authCompleter!.future.timeout(
        const Duration(seconds: _authTimeoutSeconds),
        onTimeout: () {
          throw const BridgeConnectionException(
            'Bridge authentication timed out.',
          );
        },
      );

      _startHeartbeat();
    } catch (error) {
      _completeAuthError(error);
      _setStatus(ConnectionStatus.error);
      _cleanUp(closeChannel: true, cancelReconnect: false);
      _scheduleReconnectIfNeeded();
      if (error is BridgeConnectionException) {
        rethrow;
      }
      throw BridgeConnectionException('Failed to connect to bridge: $error');
    }
  }

  void disconnect() {
    _intentionalDisconnect = true;
    _authFailed = false;
    _connectionPurpose = null;
    _completeAuthError(
      const BridgeConnectionException('Bridge connection closed.'),
    );
    _failPendingRequests(
      const BridgeConnectionException('Bridge connection closed.'),
    );
    _cleanUp();
    _setStatus(ConnectionStatus.disconnected);
  }

  bool send(BridgeMessage message) {
    if (_channel == null || _status != ConnectionStatus.connected) {
      return false;
    }
    return _sendInternal(message);
  }

  void sendRaw(String json) {
    _channel?.sink.add(json);
  }

  bool _sendInternal(BridgeMessage message) {
    final WebSocketChannel? channel = _channel;
    if (channel == null) {
      return false;
    }

    channel.sink.add(message.toJsonString());
    return true;
  }

  void _onRawMessage(dynamic data) {
    try {
      final Map<String, dynamic> json =
          jsonDecode(data as String) as Map<String, dynamic>;
      final BridgeMessage message = BridgeMessage.fromJson(json);

      if (message.type == BridgeMessageType.connectionAck) {
        _reconnectAttempts = 0;
        _authFailed = false;
        _lastConnectionAckPayload = Map<String, dynamic>.unmodifiable(
          Map<String, dynamic>.from(message.payload),
        );
        final ConnectionPurpose? acknowledgedPurpose =
            _parseConnectionPurpose(message.payload['purpose'] as String?);
        if (acknowledgedPurpose != null) {
          _connectionPurpose = acknowledgedPurpose;
        }
        _setStatus(ConnectionStatus.connected);
        _completeAuthSuccess();
        return;
      }

      if (message.type == BridgeMessageType.connectionError) {
        final String detail = message.payload['message'] as String? ??
            'Bridge rejected the connection.';
        final BridgeConnectionException exception =
            BridgeConnectionException(detail);

        if (_authCompleter != null && !_authCompleter!.isCompleted) {
          _authFailed = true;
          _completeAuthError(exception);
          _setStatus(ConnectionStatus.error);
          _cleanUp(closeChannel: true, cancelReconnect: false);
          return;
        }

        _failPendingRequests(exception);
        _setStatus(ConnectionStatus.error);
        _cleanUp(closeChannel: true, cancelReconnect: false);
        return;
      }

      if (message.type == BridgeMessageType.healthStatus) {
        final payload = Map<String, dynamic>.unmodifiable(
          Map<String, dynamic>.from(message.payload),
        );
        _lastHealthStatusPayload = payload;
        _completePendingMap(_healthCheckCompleter, payload);
      }

      if (message.type == BridgeMessageType.acknowledgmentAccepted) {
        final payload = Map<String, dynamic>.unmodifiable(
          Map<String, dynamic>.from(message.payload),
        );
        _lastHealthStatusPayload = <String, dynamic>{
          ...?_lastHealthStatusPayload,
          'ready': true,
          'requires_acknowledgment': false,
        };
        _completePendingMap(_warningAckCompleter, payload);
      }

      if (message.type == BridgeMessageType.heartbeatPong) {
        _pongTimeoutTimer?.cancel();
        _pongTimeoutTimer = null;
        return;
      }

      if (!_messageController.isClosed) {
        _messageController.add(message);
      }
    } catch (_) {
      // Ignore malformed frames from the bridge.
    }
  }

  void _onError(Object error) {
    final exception = BridgeConnectionException('Bridge socket error: $error');
    _completeAuthError(exception);
    _failPendingRequests(exception);
    _setStatus(ConnectionStatus.error);
    _cleanUp(closeChannel: false, cancelReconnect: false);
    _scheduleReconnectIfNeeded();
  }

  void _onDone() {
    const exception = BridgeConnectionException('Bridge connection closed.');
    _completeAuthError(exception);
    _failPendingRequests(exception);
    _setStatus(ConnectionStatus.disconnected);
    _cleanUp(closeChannel: false, cancelReconnect: false);
    _scheduleReconnectIfNeeded();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: _heartbeatIntervalSeconds),
      (_) => _sendPing(),
    );
  }

  void _sendPing() {
    if (_status != ConnectionStatus.connected) {
      return;
    }

    final bool sent = send(BridgeMessage.heartbeatPing());
    if (!sent) {
      return;
    }

    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = Timer(
      const Duration(seconds: _heartbeatTimeoutSeconds),
      _onPongTimeout,
    );
  }

  void _onPongTimeout() {
    const exception = BridgeConnectionException(
      'Bridge heartbeat timed out.',
    );
    _failPendingRequests(exception);
    _cleanUp(closeChannel: true, cancelReconnect: false);
    _setStatus(ConnectionStatus.reconnecting);
    _scheduleReconnectIfNeeded();
  }

  void _scheduleReconnectIfNeeded() {
    if (_intentionalDisconnect || _authFailed) {
      return;
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    final int delaySeconds = _exponentialDelay(_reconnectAttempts);
    _reconnectAttempts++;
    _setStatus(ConnectionStatus.reconnecting);

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (_intentionalDisconnect || _authFailed) {
        return;
      }

      try {
        await _doConnect();
      } catch (_) {
        // Reconnect failures are surfaced through connectionStatus.
      }
    });
  }

  int _exponentialDelay(int attempt) {
    final int delay = (1 << attempt).clamp(1, _maxReconnectDelaySeconds);
    return delay;
  }

  void _ensureConnected() {
    if (_channel == null || _status != ConnectionStatus.connected) {
      throw const BridgeConnectionException(
        'Bridge is not connected.',
      );
    }
  }

  void _completeAuthSuccess() {
    final Completer<void>? completer = _authCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void _completeAuthError(Object error) {
    final Completer<void>? completer = _authCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error);
    }
  }

  void _completePendingMap(
    Completer<Map<String, dynamic>>? completer,
    Map<String, dynamic> payload,
  ) {
    if (completer != null && !completer.isCompleted) {
      completer.complete(payload);
    }
  }

  void _completePendingRequest(
    Completer<Map<String, dynamic>>? completer,
    Object error,
  ) {
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error);
    }
  }

  void _failPendingRequests(BridgeConnectionException exception) {
    _completePendingRequest(_healthCheckCompleter, exception);
    _completePendingRequest(_warningAckCompleter, exception);
  }

  void _cleanUp({
    bool closeChannel = true,
    bool cancelReconnect = true,
  }) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = null;
    if (cancelReconnect) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
    }

    if (closeChannel) {
      _channel?.sink.close();
      _channel = null;
    }
  }

  void _setStatus(ConnectionStatus status) {
    _status = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  ConnectionPurpose? _parseConnectionPurpose(String? value) {
    return switch (value) {
      'primary' => ConnectionPurpose.primary,
      'probe' => ConnectionPurpose.probe,
      _ => null,
    };
  }

  String _platformString() {
    return 'flutter';
  }

  void dispose() {
    _intentionalDisconnect = true;
    _connectionPurpose = null;
    const exception = BridgeConnectionException('Bridge connection disposed.');
    _completeAuthError(exception);
    _failPendingRequests(exception);
    _cleanUp();
    _messageController.close();
    _statusController.close();
  }
}
