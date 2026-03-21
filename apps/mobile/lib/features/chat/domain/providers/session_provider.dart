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

final resolvedSessionIdProvider = Provider.family<String?, String>(
  (ref, routeSessionId) {
    final explicitSessionId = _normalizeNonEmptyString(routeSessionId);
    if (explicitSessionId != null) {
      return explicitSessionId;
    }

    return _normalizeNonEmptyString(ref.watch(currentSessionProvider));
  },
);

// ---------------------------------------------------------------------------
// Active sessions list
// ---------------------------------------------------------------------------

@riverpod
class ActiveSessions extends _$ActiveSessions {
  StreamSubscription<BridgeMessage>? _messageSubscription;
  StreamSubscription<List<db_lib.Session>>? _sessionSubscription;

  @override
  Future<List<ChatSession>> build() async {
    final db = ref.watch(databaseProvider);
    final service = ref.watch(webSocketServiceProvider);
    final initialRows = Completer<List<db_lib.Session>>();

    _sessionSubscription = db.sessionDao.watchAllSessions().listen((rows) {
      if (!initialRows.isCompleted) {
        initialRows.complete(rows);
      }
      state = AsyncData(rows.map(_rowToChatSession).toList());
    });

    final cachedAckPayload = service.lastConnectionAckPayload;
    if (cachedAckPayload != null) {
      await _syncRemoteSessions(cachedAckPayload);
    }

    _messageSubscription = service.messages.listen((message) {
      switch (message.type) {
        case BridgeMessageType.connectionAck:
          unawaited(_syncRemoteSessions(message.payload));
          break;
        case BridgeMessageType.sessionReady:
          unawaited(_persistSessionReady(message.payload));
          break;
        case BridgeMessageType.sessionEnd:
          unawaited(
              _markSessionClosed(_stringValue(message.payload['session_id'])));
          break;
        case BridgeMessageType.claudeEvent:
          unawaited(_handleClaudeEvent(message.payload));
          break;
        default:
          break;
      }
    });

    ref.onDispose(() {
      _messageSubscription?.cancel();
      _sessionSubscription?.cancel();
    });

    final rows = await initialRows.future;
    return rows.map(_rowToChatSession).toList();
  }

  Future<void> refresh() async {
    final cachedAckPayload =
        ref.read(webSocketServiceProvider).lastConnectionAckPayload;
    if (cachedAckPayload != null) {
      await _syncRemoteSessions(cachedAckPayload);
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final db = ref.read(databaseProvider);
    await db.sessionDao.deleteSession(sessionId);
  }

  Future<void> _syncRemoteSessions(Map<String, dynamic> payload) async {
    final rawSessions = payload['active_sessions'] as List<dynamic>? ?? [];
    for (final rawSession in rawSessions.whereType<Map<String, dynamic>>()) {
      final sessionId = _stringValue(rawSession['session_id']);
      if (sessionId.isEmpty) {
        continue;
      }

      await _upsertSession(
        sessionId: sessionId,
        agentType: _stringValue(rawSession['agent'], fallback: 'claude-code'),
        title: _stringValue(rawSession['title']),
        workingDirectory: _stringValue(rawSession['working_directory']),
        status: (rawSession['status'] as String?) == 'closed'
            ? SessionStatus.closed
            : SessionStatus.active,
      );
    }
  }

  Future<void> _persistSessionReady(Map<String, dynamic> payload) async {
    final sessionId = _stringValue(payload['session_id']);
    if (sessionId.isEmpty) {
      return;
    }

    await _upsertSession(
      sessionId: sessionId,
      agentType: _stringValue(payload['agent'], fallback: 'claude-code'),
      title: _stringValue(payload['title']),
      workingDirectory: _stringValue(payload['working_directory']),
      branch: _nullableStringValue(payload['branch']),
      status: SessionStatus.active,
    );
  }

  Future<void> _handleClaudeEvent(Map<String, dynamic> payload) async {
    final eventType = _stringValue(payload['event_type']);
    final sessionId = _stringValue(payload['session_id']);
    final eventPayload = _mapValue(payload['payload']);

    if (sessionId.isEmpty || eventType.isEmpty) {
      return;
    }

    switch (eventType) {
      case 'SessionStart':
        await _upsertSession(
          sessionId: sessionId,
          agentType: 'claude-code',
          title: _stringValue(eventPayload['title']),
          workingDirectory: _stringValue(eventPayload['working_directory']),
          branch: _nullableStringValue(eventPayload['branch']),
          status: SessionStatus.active,
        );
        break;
      case 'SessionEnd':
      case 'Stop':
        await _markSessionClosed(sessionId);
        break;
      default:
        break;
    }
  }

  Future<void> _markSessionClosed(String sessionId) async {
    if (sessionId.isEmpty) {
      return;
    }

    final db = ref.read(databaseProvider);
    final existing = await db.sessionDao.getSession(sessionId);
    if (existing == null) {
      return;
    }

    final now = DateTime.now().toUtc();
    await db.sessionDao.upsertSession(
      db_lib.SessionsCompanion(
        id: Value(existing.id),
        agentType: Value(existing.agentType),
        agentId: Value(existing.agentId),
        title: Value(existing.title),
        workingDirectory: Value(existing.workingDirectory),
        branch: Value(existing.branch),
        status: Value(SessionStatus.closed.name),
        createdAt: Value(existing.createdAt),
        lastMessageAt: Value(existing.lastMessageAt),
        updatedAt: Value(now),
        synced: Value(existing.synced),
      ),
    );
  }

  Future<void> _upsertSession({
    required String sessionId,
    required String agentType,
    required String title,
    required String workingDirectory,
    String? branch,
    required SessionStatus status,
  }) async {
    if (sessionId.isEmpty) {
      return;
    }

    final db = ref.read(databaseProvider);
    final existing = await db.sessionDao.getSession(sessionId);
    final now = DateTime.now().toUtc();
    final resolvedWorkingDirectory =
        _coalesceNonEmpty(existing?.workingDirectory, workingDirectory);

    await db.sessionDao.upsertSession(
      db_lib.SessionsCompanion(
        id: Value(sessionId),
        agentType: Value(existing?.agentType ?? agentType),
        agentId: Value(existing?.agentId),
        title: Value(
          _resolveTitle(
            existing?.title,
            title,
            resolvedWorkingDirectory,
          ),
        ),
        workingDirectory: Value(resolvedWorkingDirectory),
        branch: Value(branch ?? existing?.branch),
        status: Value(status.name),
        createdAt: Value(existing?.createdAt ?? now),
        lastMessageAt: Value(existing?.lastMessageAt),
        updatedAt: Value(now),
        synced: const Value(true),
      ),
    );
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

String _stringValue(Object? value, {String fallback = ''}) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return fallback;
}

String? _nullableStringValue(Object? value) {
  return _normalizeNonEmptyString(value);
}

String? _normalizeNonEmptyString(Object? value) {
  if (value is! String) {
    return null;
  }

  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  return trimmed;
}

Map<String, dynamic> _mapValue(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

String _titleFromWorkingDirectory(String workingDirectory) {
  if (workingDirectory.isEmpty) {
    return 'Claude Code';
  }

  final normalized = workingDirectory.replaceAll('\\', '/');
  final segments = normalized.split('/').where((segment) => segment.isNotEmpty);
  return segments.isEmpty ? workingDirectory : segments.last;
}

String _coalesceNonEmpty(String? first, String? second,
    [String fallback = '']) {
  if (first != null && first.isNotEmpty) {
    return first;
  }
  if (second != null && second.isNotEmpty) {
    return second;
  }
  return fallback;
}

String _resolveTitle(
  String? existingTitle,
  String? incomingTitle,
  String workingDirectory,
) {
  final preferredTitle = _coalesceNonEmpty(incomingTitle, existingTitle);
  if (preferredTitle.isNotEmpty) {
    return preferredTitle;
  }
  return _titleFromWorkingDirectory(workingDirectory);
}
