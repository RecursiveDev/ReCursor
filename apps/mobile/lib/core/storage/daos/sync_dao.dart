import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/sync_queue_table.dart';

part 'sync_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  /// Return all items that have not yet been successfully synced.
  Future<List<SyncQueueData>> getPendingItems() {
    return (select(syncQueue)
          ..where((q) => q.synced.equals(false))
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  /// Add a new item to the sync queue.
  Future<void> enqueue(SyncQueueCompanion item) async {
    await into(syncQueue).insert(item);
  }

  /// Mark an item as successfully synced.
  Future<void> markSynced(int id) async {
    await (update(syncQueue)..where((q) => q.id.equals(id))).write(
      const SyncQueueCompanion(synced: Value(true)),
    );
  }

  /// Increment retry count and record the last error for an item.
  Future<void> incrementRetry(int id, String error) async {
    final item = await (select(syncQueue)..where((q) => q.id.equals(id)))
        .getSingleOrNull();
    if (item == null) return;

    await (update(syncQueue)..where((q) => q.id.equals(id))).write(
      SyncQueueCompanion(
        retryCount: Value(item.retryCount + 1),
        lastError: Value(error),
      ),
    );
  }

  /// Remove all items that have been successfully synced.
  Future<void> clearSynced() async {
    await (delete(syncQueue)..where((q) => q.synced.equals(true))).go();
  }
}
