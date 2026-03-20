enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class ConnectionState {
  final ConnectionStatus status;
  final String? bridgeUrl;
  final DateTime? lastConnectedAt;
  final int reconnectAttempts;
  final String? errorMessage;

  const ConnectionState({
    required this.status,
    this.bridgeUrl,
    this.lastConnectedAt,
    this.reconnectAttempts = 0,
    this.errorMessage,
  });

  const ConnectionState.initial()
      : status = ConnectionStatus.disconnected,
        bridgeUrl = null,
        lastConnectedAt = null,
        reconnectAttempts = 0,
        errorMessage = null;

  ConnectionState copyWith({
    ConnectionStatus? status,
    String? bridgeUrl,
    DateTime? lastConnectedAt,
    int? reconnectAttempts,
    String? errorMessage,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      bridgeUrl: bridgeUrl ?? this.bridgeUrl,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'ConnectionState(status: $status, url: $bridgeUrl, attempts: $reconnectAttempts)';
}
