import 'package:drift/drift.dart';

import 'sessions_table.dart';

/// Stores chat messages within sessions.
class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(Sessions, #id)();

  /// "user" | "agent" | "system"
  TextColumn get role => text()();

  /// Full message text (markdown).
  TextColumn get content => text()();

  /// "text" | "tool_call" | "tool_result" | "system"
  TextColumn get messageType =>
      text().withDefault(const Constant('text'))();

  /// JSON: token count, tool info, etc.
  TextColumn get metadata => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
