import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/session_events_table.dart';

part 'session_event_dao.g.dart';

@DriftAccessor(tables: [SessionEvents])
class SessionEventDao extends DatabaseAccessor<AppDatabase>
    with _$SessionEventDaoMixin {
  SessionEventDao(super.db);

  /// Watch all timeline events for a session ordered by occurrence time.
  Stream<List<SessionEvent>> watchEventsForSession(String sessionId) {
    return (select(sessionEvents)
          ..where((event) => event.sessionId.equals(sessionId))
          ..orderBy([(event) => OrderingTerm.asc(event.timestamp)]))
        .watch();
  }

  /// Fetch all timeline events for a session ordered by occurrence time.
  Future<List<SessionEvent>> getEventsForSession(String sessionId) {
    return (select(sessionEvents)
          ..where((event) => event.sessionId.equals(sessionId))
          ..orderBy([(event) => OrderingTerm.asc(event.timestamp)]))
        .get();
  }

  /// Insert or update a timeline event row.
  Future<void> upsertEvent(SessionEventsCompanion event) async {
    await into(sessionEvents).insertOnConflictUpdate(event);
  }

  /// Delete all timeline events belonging to [sessionId].
  Future<void> deleteEventsForSession(String sessionId) async {
    await (delete(sessionEvents)
          ..where((event) => event.sessionId.equals(sessionId)))
        .go();
  }
}
