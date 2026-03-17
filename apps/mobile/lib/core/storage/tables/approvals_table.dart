import 'package:drift/drift.dart';

import 'sessions_table.dart';

/// Stores tool call approval history.
class Approvals extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get tool => text()();
  TextColumn get description => text()();

  /// JSON: tool parameters.
  TextColumn get params => text()();

  /// Agent's explanation.
  TextColumn get reasoning => text().nullable()();

  /// "low" | "medium" | "high" | "critical"
  TextColumn get riskLevel => text()();

  /// "approved" | "rejected" | "modified" | "pending"
  TextColumn get decision => text()();

  /// User's modification instructions.
  TextColumn get modifications => text().nullable()();

  /// JSON: tool execution result.
  TextColumn get result => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get decidedAt => dateTime().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
