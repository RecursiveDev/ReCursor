import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/agent_models.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/storage/database.dart';
import '../../../../core/storage/tables/agents_table.dart';

const _uuid = Uuid();

// ---------------------------------------------------------------------------
// Agents AsyncNotifier
// ---------------------------------------------------------------------------

class AgentNotifier extends AsyncNotifier<List<AgentConfig>> {
  @override
  Future<List<AgentConfig>> build() async {
    return _load();
  }

  Future<List<AgentConfig>> _load() async {
    final db = ref.read(databaseProvider);
    final rows = await db.select(db.agents).get();
    return rows.map(_rowToModel).toList();
  }

  AgentConfig _rowToModel(dynamic row) {
    return AgentConfig(
      id: row.id as String,
      displayName: row.displayName as String,
      type: AgentType.values.firstWhere(
        (e) => e.name == (row.agentType as String),
        orElse: () => AgentType.custom,
      ),
      bridgeUrl: row.bridgeUrl as String,
      authToken: row.authToken as String,
      workingDirectory: row.workingDirectory as String?,
      status: AgentConnectionStatus.values.firstWhere(
        (e) => e.name == (row.status as String),
        orElse: () => AgentConnectionStatus.disconnected,
      ),
      lastConnectedAt: row.lastConnectedAt as DateTime?,
      createdAt: row.createdAt as DateTime,
      updatedAt: row.updatedAt as DateTime,
    );
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> add(AgentConfig agent) async {
    final db = ref.read(databaseProvider);
    await db.into(db.agents).insert(AgentsCompanion(
          id: Value(agent.id),
          displayName: Value(agent.displayName),
          agentType: Value(agent.type.name),
          bridgeUrl: Value(agent.bridgeUrl),
          authToken: Value(agent.authToken),
          workingDirectory: Value(agent.workingDirectory),
          status: Value(agent.status.name),
          lastConnectedAt: Value(agent.lastConnectedAt),
          createdAt: Value(agent.createdAt),
          updatedAt: Value(agent.updatedAt),
        ));
    await load();
  }

  Future<void> updateAgent(AgentConfig agent) async {
    final db = ref.read(databaseProvider);
    await db.into(db.agents).insertOnConflictUpdate(AgentsCompanion(
          id: Value(agent.id),
          displayName: Value(agent.displayName),
          agentType: Value(agent.type.name),
          bridgeUrl: Value(agent.bridgeUrl),
          authToken: Value(agent.authToken),
          workingDirectory: Value(agent.workingDirectory),
          status: Value(agent.status.name),
          lastConnectedAt: Value(agent.lastConnectedAt),
          createdAt: Value(agent.createdAt),
          updatedAt: Value(DateTime.now()),
        ));
    await load();
  }

  Future<void> delete(String id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.agents)..where((a) => a.id.equals(id))).go();
    await load();
  }

  /// Attempts to connect to the given bridge and verifies a `connection_ack`
  /// response. Returns `true` on success, `false` on failure.
  Future<bool> testConnection(String bridgeUrl, String token) async {
    WebSocketChannel? channel;
    try {
      final uri = Uri.parse(bridgeUrl);
      channel = WebSocketChannel.connect(uri);
      await channel.ready;

      channel.sink.add(jsonEncode({
        'type': 'auth',
        'payload': {
          'token': token,
          'client_version': '0.1.0',
          'platform': 'flutter',
        },
        'timestamp': DateTime.now().toIso8601String(),
        'id': 'test-${_uuid.v4()}',
      }));

      // Wait up to 5 seconds for connection_ack.
      final completer = Completer<bool>();
      late StreamSubscription sub;
      final timeout = Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) completer.complete(false);
      });

      sub = channel.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            if (json['type'] == 'connection_ack') {
              if (!completer.isCompleted) completer.complete(true);
            }
          } catch (_) {}
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(false);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(false);
        },
      );

      final result = await completer.future;
      timeout.cancel();
      sub.cancel();
      await channel.sink.close();
      return result;
    } catch (_) {
      await channel?.sink.close();
      return false;
    }
  }
}

final agentsProvider =
    AsyncNotifierProvider<AgentNotifier, List<AgentConfig>>(AgentNotifier.new);
