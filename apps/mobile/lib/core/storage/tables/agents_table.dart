import 'package:drift/drift.dart';

/// Stores configured agent connections.
class Agents extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();

  /// "claude-code" | "opencode" | "aider" | "goose" | "custom"
  TextColumn get agentType => text()();

  /// WebSocket bridge URL, e.g. "wss://100.78.42.15:3000"
  TextColumn get bridgeUrl => text()();

  /// Encrypted bridge auth token.
  TextColumn get authToken => text()();

  TextColumn get workingDirectory => text().nullable()();

  /// "connected" | "disconnected" | "inactive"
  TextColumn get status =>
      text().withDefault(const Constant('disconnected'))();

  DateTimeColumn get lastConnectedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
