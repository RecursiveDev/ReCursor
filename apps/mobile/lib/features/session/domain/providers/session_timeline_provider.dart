import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/session_models.dart';
import '../../../../core/providers/database_provider.dart';

/// Derives a [List<SessionEvent>] from the messages stored for [sessionId].
///
/// - User messages → [SessionEventType.userMessage]
/// - Agent text messages → [SessionEventType.agentMessage]
/// - Tool-call messages → [SessionEventType.toolUse]
///
/// Results are sorted by [SessionEvent.timestamp] ascending.
final sessionEventsProvider =
    Provider.family<List<SessionEvent>, String>((ref, sessionId) {
  final messagesAsync = ref.watch(_rawMessagesProvider(sessionId));
  final messages = messagesAsync.valueOrNull ?? [];

  final events = <SessionEvent>[];

  for (final msg in messages) {
    final eventType = switch (msg.messageType) {
      'tool_call' => SessionEventType.toolUse,
      _ => msg.role == 'user'
          ? SessionEventType.userMessage
          : SessionEventType.agentMessage,
    };

    final title = switch (eventType) {
      SessionEventType.userMessage => 'User',
      SessionEventType.agentMessage => 'Agent',
      SessionEventType.toolUse => 'Tool Use',
      _ => 'Event',
    };

    final description = msg.content.isNotEmpty
        ? (msg.content.length > 120
            ? '${msg.content.substring(0, 120)}…'
            : msg.content)
        : null;

    events.add(SessionEvent(
      id: '${sessionId}_${msg.id}',
      sessionId: sessionId,
      eventType: eventType,
      title: title,
      description: description,
      timestamp: msg.createdAt,
    ));
  }

  events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return events;
});

// Internal stream-backed provider for raw DB messages.
final _rawMessagesProvider = StreamProvider.family((ref, String sessionId) {
  return ref.watch(databaseProvider).messageDao
      .watchMessagesForSession(sessionId);
});
