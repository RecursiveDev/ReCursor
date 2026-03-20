import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/messages_table.dart';

part 'message_dao.g.dart';

@DriftAccessor(tables: [Messages])
class MessageDao extends DatabaseAccessor<AppDatabase>
    with _$MessageDaoMixin {
  MessageDao(super.db);

  /// Watch all messages for a session, ordered by creation time ascending.
  Stream<List<Message>> watchMessagesForSession(String sessionId) {
    return (select(messages)
          ..where((m) => m.sessionId.equals(sessionId))
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .watch();
  }

  /// Fetch all messages for a session (one-shot).
  Future<List<Message>> getMessagesForSession(String sessionId) {
    return (select(messages)
          ..where((m) => m.sessionId.equals(sessionId))
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .get();
  }

  /// Insert a new message row.
  Future<void> insertMessage(MessagesCompanion message) async {
    await into(messages).insert(message);
  }

  /// Update an existing message row.
  Future<void> updateMessage(MessagesCompanion message) async {
    await into(messages).insertOnConflictUpdate(message);
  }

  /// Delete all messages belonging to [sessionId].
  Future<void> deleteMessagesForSession(String sessionId) async {
    await (delete(messages)
          ..where((m) => m.sessionId.equals(sessionId)))
        .go();
  }
}
