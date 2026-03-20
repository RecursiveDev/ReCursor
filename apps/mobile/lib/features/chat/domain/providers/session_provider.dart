import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/models/session_models.dart';
import '../../../../core/network/websocket_messages.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/websocket_provider.dart';
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
  StreamSubscription<BridgeMessage>? _messageSubscription;

  @override
  Future<List<ChatSession>> build() async {
    final db = ref.watch(databaseProvider);
    final service = ref.watch(webSocketServiceProvider);

    final cachedAckPayload = service.lastConnectionAckPayload;
    if (cachedAckPayload != null) {
      await _syncRemoteSessions(cachedAckPayload);
    }

    _messageSubscription = service.messages.listen((message) {
      if (message.type == BridgeMessageType.connectionAck) {
        unawaited(_syncRemoteSessions(message.payload).then((_) {
          ref.invalidateSelf();
        }));
      }
      if (message.type == BridgeMessageType.sessionReady ||
          message.type == BridgeMessageType.sessionEnd) {
        ref.invalidateSelf();
      }
    });
    ref.onDispose(() => _messageSubscription?.cancel());

    final rows = await db.sessionDao.watchAllSessions().first;
    return rows.map(_rowToChatSession).toList();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<void> deleteSession(String sessionId) async {
    final db = ref.read(databaseProvider);
    await db.sessionDao.deleteSession(sessionId);
    ref.invalidateSelf();
  }

  Future<void> _syncRemoteSessions(Map<String, dynamic> payload) async {
    final db = ref.read(databaseProvider);
    final rawSessions = payload['active_sessions'] as List<dynamic>? ?? [];
    for (final rawSession in rawSessions.whereType<Map<String, dynamic>>()) {
      final sessionId = rawSession['session_id'] as String?;
      if (sessionId == null || sessionId.isEmpty) {
        continue;
      }

      final existing = await db.sessionDao.getSession(sessionId);
      final now = DateTime.now().toUtc();
      await db.sessionDao.upsertSession(
        db_lib.SessionsCompanion(
          id: Value(sessionId),
          agentType: Value(rawSession['agent'] as String? ?? 'claude-code'),
          agentId: Value(existing?.agentId),
          title: Value(_title(rawSession['title'] as String?)),
          workingDirectory:
              Value(rawSession['working_directory'] as String? ?? ''),
          branch: Value(existing?.branch),
          status: Value(
            (rawSession['status'] as String?) == 'closed'
                ? SessionStatus.closed.name
                : SessionStatus.active.name,
          ),
          createdAt: Value(existing?.createdAt ?? now),
          lastMessageAt: Value(existing?.lastMessageAt),
          updatedAt: Value(now),
          synced: const Value(true),
        ),
      );
    }
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

String _title(String? value) {
  if (value != null && value.isNotEmpty) {
    return value;
  }
  return 'Claude Code';
}
