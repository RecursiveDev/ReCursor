import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/git_models.dart';
import '../../../../core/network/websocket_messages.dart';
import '../../../../core/providers/websocket_provider.dart';
import '../../../diff/domain/providers/diff_provider.dart';

// ---------------------------------------------------------------------------
// GitStatus provider (AsyncNotifierProvider.family)
// ---------------------------------------------------------------------------

final gitStatusProvider = AsyncNotifierProvider.family<GitNotifier, GitStatus?, String>(
  GitNotifier.new,
);

class GitNotifier extends FamilyAsyncNotifier<GitStatus?, String> {
  StreamSubscription<BridgeMessage>? _sub;

  @override
  Future<GitStatus?> build(String arg) async {
    final service = ref.watch(webSocketServiceProvider);

    _sub?.cancel();
    _sub = service.messages.listen(_handleMessage);
    ref.onDispose(() => _sub?.cancel());

    return null;
  }

  void _handleMessage(BridgeMessage msg) {
    if (msg.type == BridgeMessageType.gitStatusResponse) {
      final payload = msg.payload;
      try {
        final status = GitStatus.fromJson(payload);
        state = AsyncValue.data(status);
      } catch (_) {
        // Malformed payload — ignore.
      }
    }

    if (msg.type == BridgeMessageType.gitDiffResponse) {
      final rawFiles = msg.payload['files'] as List<dynamic>? ?? [];
      final files = rawFiles
          .whereType<Map<String, dynamic>>()
          .map(DiffFile.fromJson)
          .toList();
      ref.read(currentDiffProvider.notifier).state = files;
    }
  }

  /// Sends a `git_status_request` and awaits a `git_status_response`.
  Future<void> fetchStatus(String sessionId) async {
    state = const AsyncValue.loading();
    final service = ref.read(webSocketServiceProvider);
    service.send(BridgeMessage.gitStatusRequest(sessionId: sessionId));
    // State will be updated by _handleMessage on response.
  }

  /// Sends a `git_commit` message.
  Future<void> commit(
    String sessionId,
    String message, [
    List<String>? files,
  ]) async {
    final service = ref.read(webSocketServiceProvider);
    service.send(BridgeMessage.gitCommit(
      sessionId: sessionId,
      commitMessage: message,
      files: files,
    ));
  }

  /// Sends a `git_diff` request; response populates [currentDiffProvider].
  Future<void> fetchDiff(String sessionId) async {
    final service = ref.read(webSocketServiceProvider);
    service.send(BridgeMessage.gitDiff(sessionId: sessionId));
  }

  /// Sends a `git_pull` message.
  Future<void> pull(String sessionId) async {
    final service = ref.read(webSocketServiceProvider);
    // git_pull is not a first-class BridgeMessageType; tunnel via claudeEvent.
    service.send(BridgeMessage(
      type: BridgeMessageType.claudeEvent,
      timestamp: DateTime.now().toUtc(),
      payload: {'type': 'git_pull', 'session_id': sessionId},
    ));
  }

  /// Sends a `git_push` message.
  Future<void> push(String sessionId) async {
    final service = ref.read(webSocketServiceProvider);
    service.send(BridgeMessage(
      type: BridgeMessageType.claudeEvent,
      timestamp: DateTime.now().toUtc(),
      payload: {'type': 'git_push', 'session_id': sessionId},
    ));
  }
}
