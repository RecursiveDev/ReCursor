import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/models/git_models.dart';
import '../../../../core/network/websocket_messages.dart';
import '../../../../core/providers/websocket_provider.dart';
import '../../../../shared/utils/bridge_payload_normalizer.dart';
import '../../../../shared/utils/diff_parser.dart';

part 'diff_provider.g.dart';

enum DiffViewMode { unified, splitView }

final currentDiffProvider = StateProvider<List<DiffFile>?>((ref) => null);

final diffViewModeProvider =
    StateProvider<DiffViewMode>((ref) => DiffViewMode.unified);

@riverpod
class DiffNotifier extends _$DiffNotifier {
  StreamSubscription<BridgeMessage>? _messageSubscription;

  @override
  Future<void> build() async {
    final service = ref.watch(webSocketServiceProvider);

    final previousSubscription = _messageSubscription;
    if (previousSubscription != null) {
      unawaited(previousSubscription.cancel());
    }
    _messageSubscription = service.messages.listen(_handleBridgeMessage);

    ref.onDispose(() {
      _messageSubscription?.cancel();
      _messageSubscription = null;
    });
  }

  void _handleBridgeMessage(BridgeMessage message) {
    if (message.type != BridgeMessageType.gitDiffResponse) {
      return;
    }

    final rawFiles = message.payload['files'] as List<dynamic>? ?? [];
    final files = rawFiles
        .whereType<Map<String, dynamic>>()
        .map(normalizeDiffFile)
        .map(DiffFile.fromJson)
        .toList();
    ref.read(currentDiffProvider.notifier).state = files;
  }

  Future<void> requestDiff(String sessionId, {List<String>? files}) async {
    final service = ref.read(webSocketServiceProvider);
    service.send(
      BridgeMessage.gitDiff(
        sessionId: sessionId,
        files: files,
      ),
    );
  }

  bool openUnifiedDiff(String rawDiff) {
    final trimmedDiff = rawDiff.trim();
    if (trimmedDiff.isEmpty) {
      return false;
    }

    final files = DiffParser.parse(trimmedDiff);
    if (files.isEmpty) {
      return false;
    }

    ref.read(currentDiffProvider.notifier).state = files;
    return true;
  }

  void clearDiff() {
    ref.read(currentDiffProvider.notifier).state = null;
  }
}
