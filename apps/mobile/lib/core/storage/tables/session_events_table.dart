import 'package:drift/drift.dart';

import 'sessions_table.dart';

/// Stores timeline events observed during a session.
class SessionEvents extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get eventType => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get metadata => text().nullable()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
