import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/models/git_models.dart';
import '../../../../core/network/bridge_socket.dart';

part 'diff_provider.g.dart';

enum DiffViewMode { unified, splitView }

final currentDiffProvider = StateProvider<List<DiffFile>?>((ref) => null);

final diffViewModeProvider =
    StateProvider<DiffViewMode>((ref) => DiffViewMode.unified);

@riverpod
class DiffNotifier extends _$DiffNotifier {
  @override
  Future<void> build() async {
    final socket = ref.watch(bridgeSocketProvider);
    socket.messageStream.listen((msg) {
      if (msg['type'] == 'diff_result') {
        final rawFiles = msg['files'] as List<dynamic>? ?? [];
        final files = rawFiles
            .whereType<Map<String, dynamic>>()
            .map((f) => DiffFile.fromJson(f))
            .toList();
        ref.read(currentDiffProvider.notifier).state = files;
      }
    });
  }

  Future<void> requestDiff(String sessionId, {List<String>? files}) async {
    final socket = ref.read(bridgeSocketProvider);
    socket.send({
      'type': 'request_diff',
      'session_id': sessionId,
      if (files != null) 'files': files,
    });
  }

  void clearDiff() {
    ref.read(currentDiffProvider.notifier).state = null;
  }
}
