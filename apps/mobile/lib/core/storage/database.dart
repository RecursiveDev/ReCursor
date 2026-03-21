import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/message_dao.dart';
import 'daos/session_dao.dart';
import 'daos/session_event_dao.dart';
import 'daos/sync_dao.dart';
import 'tables/agents_table.dart';
import 'tables/approvals_table.dart';
import 'tables/messages_table.dart';
import 'tables/session_events_table.dart';
import 'tables/sessions_table.dart';
import 'tables/sync_queue_table.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Sessions,
    Messages,
    SessionEvents,
    Agents,
    Approvals,
    SyncQueue,
  ],
  daos: [
    SessionDao,
    MessageDao,
    SessionEventDao,
    SyncDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  factory AppDatabase.inMemory() {
    return AppDatabase.forTesting(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
        },
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.createTable(sessionEvents);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    return driftDatabase(name: 'recursor_app');
  });
}
