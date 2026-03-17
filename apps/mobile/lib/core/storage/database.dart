import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/message_dao.dart';
import 'daos/session_dao.dart';
import 'daos/sync_dao.dart';
import 'tables/agents_table.dart';
import 'tables/approvals_table.dart';
import 'tables/messages_table.dart';
import 'tables/sessions_table.dart';
import 'tables/sync_queue_table.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Sessions,
    Messages,
    Agents,
    Approvals,
    SyncQueue,
  ],
  daos: [
    SessionDao,
    MessageDao,
    SyncDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    return driftDatabase(name: 'recursor_app');
  });
}
