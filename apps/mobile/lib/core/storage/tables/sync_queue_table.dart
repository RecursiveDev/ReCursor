import 'package:drift/drift.dart';

/// Offline mutation queue — persists operations until they can be flushed
/// to the bridge server after reconnection.
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// "send_message" | "approve_tool" | "git_command"
  TextColumn get operation => text()();

  /// JSON: full operation payload.
  TextColumn get payload => text()();

  TextColumn get sessionId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}
