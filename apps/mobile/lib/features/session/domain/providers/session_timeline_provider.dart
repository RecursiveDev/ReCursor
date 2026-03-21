import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/session_models.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/storage/database.dart' as db_lib;

/// Derives a merged [List<SessionEvent>] for [sessionId] from persisted
/// messages and hook-driven timeline events.
final sessionEventsProvider =
    Provider.family<List<SessionEvent>, String>((ref, sessionId) {
  final messagesAsync = ref.watch(_rawMessagesProvider(sessionId));
  final timelineEventsAsync = ref.watch(_rawSessionEventsProvider(sessionId));

  final events = <SessionEvent>[
    ...timelineEventsAsync.valueOrNull?.map(_rowToDomainSessionEvent) ??
        const <SessionEvent>[],
    ...messagesAsync.valueOrNull?.map(
          (message) => _messageRowToSessionEvent(sessionId, message),
        ) ??
        const <SessionEvent>[],
  ];

  final deduped = <String, SessionEvent>{};
  for (final event in events) {
    deduped[event.id] = event;
  }

  final mergedEvents = deduped.values.toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return mergedEvents;
});

final _rawMessagesProvider =
    StreamProvider.family<List<db_lib.Message>, String>((ref, sessionId) {
  return ref
      .watch(databaseProvider)
      .messageDao
      .watchMessagesForSession(sessionId);
});

final _rawSessionEventsProvider =
    StreamProvider.family<List<db_lib.SessionEvent>, String>((ref, sessionId) {
  return ref.watch(databaseProvider).sessionEventDao.watchEventsForSession(
        sessionId,
      );
});

SessionEvent _messageRowToSessionEvent(
    String sessionId, db_lib.Message message) {
  final eventType = _eventTypeFromMessageRow(message);
  final title = switch (eventType) {
    SessionEventType.userMessage => 'User',
    SessionEventType.agentMessage => 'Agent',
    SessionEventType.toolUse => 'Tool Use',
    SessionEventType.toolResult => 'Tool Result',
    SessionEventType.sessionStart => 'Session started',
    SessionEventType.sessionEnd => 'Session ended',
    SessionEventType.hookEvent => 'Event',
  };

  return SessionEvent(
    id: '${sessionId}_${message.id}',
    sessionId: sessionId,
    eventType: eventType,
    title: title,
    description: _truncate(message.content),
    timestamp: message.createdAt,
  );
}

SessionEvent _rowToDomainSessionEvent(db_lib.SessionEvent row) {
  return SessionEvent(
    id: row.id,
    sessionId: row.sessionId,
    eventType: SessionEventType.values.firstWhere(
      (value) => value.name == row.eventType,
      orElse: () => SessionEventType.hookEvent,
    ),
    title: row.title,
    description: row.description,
    timestamp: row.timestamp,
    metadata: _decodeMetadata(row.metadata),
  );
}

SessionEventType _eventTypeFromMessageRow(db_lib.Message message) {
  switch (message.messageType) {
    case 'toolCall':
    case 'tool_call':
      return SessionEventType.toolUse;
    case 'toolResult':
    case 'tool_result':
      return SessionEventType.toolResult;
    default:
      return message.role == 'user'
          ? SessionEventType.userMessage
          : SessionEventType.agentMessage;
  }
}

Map<String, dynamic>? _decodeMetadata(String? metadata) {
  if (metadata == null || metadata.isEmpty) {
    return null;
  }

  try {
    final decoded = jsonDecode(metadata);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
  } catch (_) {}

  return null;
}

String? _truncate(String value, {int maxLength = 120}) {
  if (value.isEmpty) {
    return null;
  }
  return value.length > maxLength ? '${value.substring(0, maxLength)}…' : value;
}
