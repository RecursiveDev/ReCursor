import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/models/session_models.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/network/bridge_socket.dart';
import '../../../../core/storage/database.dart' as db_lib;

part 'session_provider.g.dart';

// ---------------------------------------------------------------------------
// Current session ID
// ---------------------------------------------------------------------------

final currentSessionProvider = StateProvider<String?>((ref) => null);

// ---------------------------------------------------------------------------
// Active sessions list
// ---------------------------------------------------------------------------

@riverpod
class ActiveSessions extends _$ActiveSessions {
  @override
  Future<List<ChatSession>> build() async {
    final db = ref.watch(databaseProvider);
    final rows = await db.sessionDao.watchAllSessions().first;
    final sessions = rows.map(_rowToChatSession).toList();

    // Keep up-to-date when bridge sends session events
    final socket = ref.watch(bridgeSocketProvider);
    socket.messageStream.listen((msg) {
      if (msg['type'] == 'session_ready' || msg['type'] == 'session_closed') {
        ref.invalidateSelf();
      }
    });

    return sessions;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<void> deleteSession(String sessionId) async {
    final db = ref.read(databaseProvider);
    await db.sessionDao.deleteSession(sessionId);
    ref.invalidateSelf();
  }
}

// ---------------------------------------------------------------------------
// Single session selector
// ---------------------------------------------------------------------------

final activeSessionProvider =
    Provider.family<ChatSession?, String>((ref, sessionId) {
  final sessions = ref.watch(activeSessionsProvider).valueOrNull ?? [];
  try {
    return sessions.firstWhere((s) => s.id == sessionId);
  } catch (_) {
    return null;
  }
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ChatSession _rowToChatSession(db_lib.Session row) {
  return ChatSession(
    id: row.id,
    agentType: row.agentType,
    agentId: row.agentId,
    title: row.title,
    workingDirectory: row.workingDirectory,
    branch: row.branch,
    status: SessionStatus.values.firstWhere(
      (e) => e.name == row.status,
      orElse: () => SessionStatus.active,
    ),
    createdAt: row.createdAt,
    lastMessageAt: row.lastMessageAt,
    updatedAt: row.updatedAt,
    synced: row.synced,
  );
}
