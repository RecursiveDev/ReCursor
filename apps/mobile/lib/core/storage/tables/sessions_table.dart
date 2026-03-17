import 'package:drift/drift.dart';

/// Stores agent chat sessions.
class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get agentType => text()();
  TextColumn get agentId => text().nullable()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get workingDirectory => text()();
  TextColumn get branch => text().nullable()();

  /// "active" | "paused" | "closed"
  TextColumn get status => text()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastMessageAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
