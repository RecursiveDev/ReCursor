# Offline-First Architecture

> How the app works without connectivity and syncs when reconnected.

---

## Storage Strategy

| Data Type | Storage | Rationale |
|-----------|---------|-----------|
| Conversations, tasks, agent configs | **Drift** (SQLite) | Type-safe queries, migrations, reactive streams, relational integrity |
| UI preferences, cached tokens, session state | **Hive** | Fast key-value for ephemeral data |
| File content cache | **File system** | Large blobs don't belong in SQLite |

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

## Sync Queue

When offline, mutations go into a local queue:

```
| id | operation | payload | created_at | synced |
|----|-----------|---------|------------|--------|
| 1  | send_message | {...} | 2026-03-16T10:00:00Z | false |
| 2  | approve_tool | {...} | 2026-03-16T10:01:00Z | false |
```

On reconnect:
1. Push queued changes to bridge server (oldest first).
2. Pull remote changes (new messages, task updates).
3. Apply **last-write-wins** by comparing `updated_at` timestamps.
4. Mark queue items as synced.

## Conflict Resolution

- **Default:** Last-write-wins based on `updated_at` timestamp.
- **Critical operations** (git push, file overwrite): prompt user to confirm.
- Every synced record carries `updated_at` and `synced` boolean.

## Network Detection

- Use `connectivity_plus` to listen for network state changes.
- **Do NOT rely solely on connectivity status.** Phone may have internet but bridge may be down.
- On connectivity change: ping bridge endpoint to confirm reachability.
- On bridge reachable: trigger sync queue flush.

## Future Scaling

If sync complexity grows, consider:
- **PowerSync** — integrates with Drift, handles bidirectional sync automatically.
- **Couchbase Lite** — built-in conflict resolution.
- Both have commercial licensing but eliminate custom sync engine maintenance.
