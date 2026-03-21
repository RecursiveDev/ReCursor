import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recursor_mobile/core/models/session_models.dart';
import 'package:recursor_mobile/core/providers/database_provider.dart';
import 'package:recursor_mobile/core/storage/database.dart' as db_lib;
import 'package:recursor_mobile/features/session/domain/providers/session_timeline_provider.dart';

void main() {
  group('sessionEventsProvider', () {
    late db_lib.AppDatabase database;
    late ProviderContainer container;
    late ProviderSubscription<List<SessionEvent>> subscription;

    setUp(() async {
      database = db_lib.AppDatabase.inMemory();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
      );
      subscription = container.listen<List<SessionEvent>>(
        sessionEventsProvider('sess-timeline-provider'),
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      addTearDown(container.dispose);

      final createdAt = DateTime.utc(2026, 3, 21, 14, 0, 0);
      await database.sessionDao.upsertSession(
        db_lib.SessionsCompanion(
          id: const Value('sess-timeline-provider'),
          agentType: const Value('claude-code'),
          title: const Value('Timeline Provider Session'),
          workingDirectory: const Value('/workspace/timeline-provider'),
          status: const Value('active'),
          createdAt: Value(createdAt),
          updatedAt: Value(createdAt),
          synced: const Value(true),
        ),
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('merges persisted hook events with message-derived events in order',
        () async {
      final sessionStartAt = DateTime.utc(2026, 3, 21, 14, 0, 0);
      final messageAt = DateTime.utc(2026, 3, 21, 14, 0, 1);
      final toolResultAt = DateTime.utc(2026, 3, 21, 14, 0, 2);

      await database.sessionEventDao.upsertEvent(
        db_lib.SessionEventsCompanion(
          id: const Value('evt-session-start'),
          sessionId: const Value('sess-timeline-provider'),
          eventType: const Value('sessionStart'),
          title: const Value('Session started'),
          description: const Value('/workspace/timeline-provider'),
          metadata: const Value('{"hook_event_type":"SessionStart"}'),
          timestamp: Value(sessionStartAt),
        ),
      );
      await database.messageDao.insertMessage(
        db_lib.MessagesCompanion(
          id: const Value('msg-user-1'),
          sessionId: const Value('sess-timeline-provider'),
          role: const Value('user'),
          content: const Value('Inspect lib/main.dart'),
          messageType: const Value('text'),
          metadata: const Value('{"parts":[]}'),
          createdAt: Value(messageAt),
          updatedAt: Value(messageAt),
          synced: const Value(true),
        ),
      );
      await database.sessionEventDao.upsertEvent(
        db_lib.SessionEventsCompanion(
          id: const Value('evt-tool-result'),
          sessionId: const Value('sess-timeline-provider'),
          eventType: const Value('toolResult'),
          title: const Value('Tool result: read_file'),
          description: const Value('Read lib/main.dart'),
          metadata: const Value('{"tool":"read_file"}'),
          timestamp: Value(toolResultAt),
        ),
      );

      await _drainQueue();

      final events =
          container.read(sessionEventsProvider('sess-timeline-provider'));

      expect(events.map((event) => event.id), <String>[
        'evt-session-start',
        'sess-timeline-provider_msg-user-1',
        'evt-tool-result',
      ]);
      expect(events.map((event) => event.eventType), <SessionEventType>[
        SessionEventType.sessionStart,
        SessionEventType.userMessage,
        SessionEventType.toolResult,
      ]);
      expect(events[0].metadata?['hook_event_type'], 'SessionStart');
      expect(events[1].description, 'Inspect lib/main.dart');
      expect(events[2].title, 'Tool result: read_file');
    });
  });
}

Future<void> _drainQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(const Duration(milliseconds: 20));
}
