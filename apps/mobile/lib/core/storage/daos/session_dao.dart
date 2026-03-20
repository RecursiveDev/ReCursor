import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/sessions_table.dart';

part 'session_dao.g.dart';

@DriftAccessor(tables: [Sessions])
class SessionDao extends DatabaseAccessor<AppDatabase>
    with _$SessionDaoMixin {
  SessionDao(super.db);

  /// Watch all sessions ordered by most recently updated.
  Stream<List<Session>> watchAllSessions() {
    return (select(sessions)
          ..orderBy([(s) => OrderingTerm.desc(s.updatedAt)]))
        .watch();
  }

  /// Fetch a single session by ID.
  Future<Session?> getSession(String id) {
    return (select(sessions)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert or update a session row.
  Future<void> upsertSession(SessionsCompanion session) async {
    await into(sessions).insertOnConflictUpdate(session);
  }

  /// Delete a session by ID.
  Future<void> deleteSession(String id) async {
    await (delete(sessions)..where((s) => s.id.equals(id))).go();
  }

  /// Return the count of active sessions.
  Future<int> getActiveSessionCount() async {
    final query = select(sessions)
      ..where((s) => s.status.equals('active'));
    final rows = await query.get();
    return rows.length;
  }
}
