---
title: "Offline-First Architecture"
description: "How the ReCursor app works without connectivity and syncs when reconnected."
sidebar:
  order: 20
  label: "Offline architecture"
---
> How the ReCursor app works without connectivity and syncs when reconnected.

---

## Storage Strategy

| Data Type | Storage | Rationale |
|-----------|---------|-----------|
| Conversations, tasks, agent configs | **Drift** (SQLite) | Type-safe queries, migrations, reactive streams, relational integrity |
| UI preferences, cached tokens, session state | **Hive** | Fast key-value for ephemeral data |
| File content cache | **File system** | Large blobs don't belong in SQLite |

---

## Repository Pattern

```
UI Layer (Riverpod providers)
    |
Repository Layer (abstracts local vs. remote)
    |
    +-- Local Data Source (Drift / Hive)
    +-- Remote Data Source (Bridge WebSocket)
```

- Repository reads from local DB first (instant UI response).
- Fetches from bridge in background and updates local state.
- Drift's reactive queries (`watch()`) automatically update the UI when local data changes.

---

## Sync Queue

When offline, mutations go into a local queue:

```dart
// SyncQueue table (Drift)
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operation => text()(); // "send_message", "approve_tool", "git_command"
  TextColumn get payload => text()(); // JSON: full operation
  TextColumn get sessionId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}
```

### Queue Operations

```dart
class SyncService {
  final SyncQueueDao _queueDao;
  final WebSocketService _ws;

  // Enqueue mutation when offline
  Future<void> enqueue(String operation, Map<String, dynamic> payload) async {
    await _queueDao.insert(SyncQueueCompanion(
      operation: Value(operation),
      payload: Value(jsonEncode(payload)),
      createdAt: Value(DateTime.now()),
    ));
  }

  // Flush queue on reconnect
  Future<void> flushQueue() async {
    final pending = await _queueDao.getPending();
    
    for (final item in pending) {
      try {
        await _sendToBridge(item);
        await _queueDao.markSynced(item.id);
      } catch (e) {
        await _queueDao.incrementRetry(item.id, e.toString());
      }
    }
  }
}
```

---

## Conflict Resolution

### Default: Last-Write-Wins

```dart
class ConflictResolver {
  T resolve(T local, T remote) {
    // Compare updated_at timestamps
    if (local.updatedAt.isAfter(remote.updatedAt)) {
      return local; // Local wins
    }
    return remote; // Remote wins
  }
}
```

### Critical Operations

For destructive operations (git push, file overwrite), prompt user:

```dart
Future<ConflictResolution> resolveCriticalConflict({
  required SyncConflict conflict,
}) async {
  // Show dialog to user
  return showDialog<ConflictResolution>(
    context: context,
    builder: (_) => ConflictDialog(conflict: conflict),
  );
}

enum ConflictResolution {
  useLocal,
  useRemote,
  merge,
  cancel,
}
```

---

## Network Detection

```dart
class NetworkService {
  final Connectivity _connectivity;
  final WebSocketService _ws;

  Stream<ConnectionStatus> get status {
    return _connectivity.onConnectivityChanged
      .asyncMap((result) => _mapToStatus(result));
  }

  Future<ConnectionStatus> _mapToStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      return ConnectionStatus.offline;
    }
    
    // Ping bridge to confirm reachability
    final reachable = await _pingBridge();
    return reachable 
      ? ConnectionStatus.online 
      : ConnectionStatus.bridg






















































Unreachable;
  }
}
```

### Connection States

| State | Description | Behavior |
|-------|-------------|----------|
| `online` | Connected to bridge | Sync queue, real-time updates |
| `offline` | No connectivity | Queue mutations locally |
| `bridge_unreachable` | Network but no bridge | Retry with backoff, queue mutations |

---

## Sync Strategies

### Push-First (Outbound)

1. User action (send message, approve tool)
2. Save to local DB
3. Try to send via WebSocket
4. If failed, add to SyncQueue
5. Show "pending" state in UI

### Pull-First (Inbound)

1. On reconnect, request all events since last sync
2. Merge with local state
3. Resolve conflicts
4. Update UI

### Event Replay

```dart
class EventReplay {
  Future<void> replaySince(DateTime lastSync) async {
    final events = await _bridge.getEventsSince(lastSync);
    
    for (final event in events) {
      await _applyEvent(event);
    }
  }
}
```

---

## Retry Strategy

```dart
class RetryPolicy {
  final int maxRetries = 5;
  final List<Duration> backoffDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 30),
  ];

  Future<T> withRetry<T>(Future<T> Function() operation, int attempt) async {
    try {
      return await operation();
    } catch (e) {
      if (attempt >= maxRetries) rethrow;
      
      await Future.delayed(backoffDelays[attempt]);
      return withRetry(operation, attempt + 1);
    }
  }
}
```

---

## Storage Limits

| Data Type | Max Size | Cleanup Strategy |
|-----------|----------|------------------|
| SyncQueue | 1000 items | FIFO eviction |
| Messages | 30 days | Archive to file |
| Sessions | 90 days | Soft delete |
| File cache | 100 MB | LRU eviction |

---

## Future Scaling

If sync complexity grows, consider:

- **PowerSync** — integrates with Drift, handles bidirectional sync automatically
- **Couchbase Lite** — built-in conflict resolution
- Both have commercial licensing but eliminate custom sync engine maintenance.

---

## Related Documentation

- [Data Models](../../architecture/data-models/) — Drift schemas
- [Architecture Overview](../../architecture/system-overview/) — System architecture
- [Bridge Protocol](../../architecture/bridge-protocol/) — WebSocket specification

---

*Last updated: 2026-03-17*
