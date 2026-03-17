/// Application-wide constants.
class AppConfig {
  const AppConfig._();

  static const String appName = 'ReCursor';
  static const String version = '0.1.0';

  /// Heartbeat ping interval in seconds.
  static const int heartbeatInterval = 15;

  /// Seconds to wait for a heartbeat pong before triggering reconnect.
  static const int heartbeatTimeout = 10;

  /// Maximum number of reconnect attempts before giving up.
  static const int maxReconnectAttempts = 10;

  /// Maximum number of items stored in the offline sync queue.
  static const int maxSyncQueueSize = 500;
}
