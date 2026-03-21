import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/file_models.dart';
import '../../../../core/network/websocket_messages.dart';
import '../../../../core/providers/websocket_provider.dart';
import '../../../../shared/utils/bridge_payload_normalizer.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class RepoState {
  final String currentPath;
  final List<FileTreeNode> nodes;
  final bool isLoading;
  final String? error;
  final bool showHidden;

  const RepoState({
    this.currentPath = '.',
    this.nodes = const [],
    this.isLoading = false,
    this.error,
    this.showHidden = false,
  });

  RepoState copyWith({
    String? currentPath,
    List<FileTreeNode>? nodes,
    bool? isLoading,
    String? error,
    bool? showHidden,
    bool clearError = false,
  }) {
    return RepoState(
      currentPath: currentPath ?? this.currentPath,
      nodes: nodes ?? this.nodes,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      showHidden: showHidden ?? this.showHidden,
    );
  }

  /// Path segments for breadcrumb display.
  List<String> get breadcrumbs {
    if (currentPath == '.' || currentPath == '/') return ['/'];
    final normalised = currentPath.replaceAll('\\', '/');
    final parts = normalised.split('/').where((s) => s.isNotEmpty).toList();
    return ['/', ...parts];
  }

  /// Visible nodes, filtered by [showHidden].
  List<FileTreeNode> get visibleNodes {
    if (showHidden) return nodes;
    return nodes.where((n) => !n.name.startsWith('.')).toList();
  }

  bool get isAtRoot {
    return currentPath == '.' || currentPath == '/' || currentPath.isEmpty;
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class RepoNotifier extends FamilyAsyncNotifier<RepoState, String> {
  /// The sessionId passed as the family argument.
  String get _sessionId => arg;

  @override
  Future<RepoState> build(String arg) async {
    // Listen to inbound bridge messages and surface file_list / file_read
    // responses to waiting completers.
    ref.listen<AsyncValue<BridgeMessage>>(bridgeMessagesProvider, (_, next) {
      next.whenData(_handleMessage);
    });

    // Start at root of session working directory.
    const initial = RepoState();
    await _fetchDirectory(initial.currentPath);
    return state.value ?? initial;
  }

  // ---------------------------------------------------------------------------
  // Response correlators
  // ---------------------------------------------------------------------------

  final Map<String, Completer<BridgeMessage>> _pending = {};

  void _handleMessage(BridgeMessage msg) {
    if (msg.id != null && _pending.containsKey(msg.id)) {
      _pending[msg.id]!.complete(msg);
      _pending.remove(msg.id);
      return;
    }
    // Unsolicited file_list_response — ignore (another session may have sent).
  }

  Future<BridgeMessage> _sendAndAwait(BridgeMessage outgoing) {
    final completer = Completer<BridgeMessage>();
    Timer? timeoutTimer;

    if (outgoing.id != null) {
      _pending[outgoing.id!] = completer;
    }

    final service = ref.read(webSocketServiceProvider);
    service.send(outgoing);

    timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!completer.isCompleted) {
        _pending.remove(outgoing.id);
        completer.completeError(TimeoutException('Bridge response timed out'));
      }
    });

    completer.future.whenComplete(() {
      timeoutTimer?.cancel();
    });

    return completer.future;
  }

  // ---------------------------------------------------------------------------
  // Public actions
  // ---------------------------------------------------------------------------

  /// Fetch [path] and update state with the returned nodes.
  Future<void> fetchDirectory(String path) async {
    final current = state.value ?? const RepoState();
    state = AsyncData(current.copyWith(isLoading: true, clearError: true));
    await _fetchDirectory(path);
  }

  Future<void> _fetchDirectory(String path) async {
    final current = state.value ?? const RepoState();
    try {
      final outgoing = BridgeMessage.fileList(
        sessionId: _sessionId,
        path: path,
      );
      final response = await _sendAndAwait(outgoing);

      if (response.type == BridgeMessageType.error) {
        final msg = response.payload['message'] as String? ?? 'Unknown error';
        state = AsyncData(
          current.copyWith(
            isLoading: false,
            error: msg,
            currentPath: path,
          ),
        );
        return;
      }

      final normalizedPayload = normalizeFileListPayload(response.payload);
      final rawNodes = normalizedPayload['nodes'] as List<dynamic>? ?? [];
      final nodes = rawNodes
          .whereType<Map<String, dynamic>>()
          .map(FileTreeNode.fromJson)
          .toList();

      // Sort: directories first, then files, each group alphabetically.
      nodes.sort((a, b) {
        if (a.type != b.type) {
          return a.type == FileNodeType.directory ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      final resolvedPath = normalizedPayload['path'] as String?;
      state = AsyncData(
        current.copyWith(
          currentPath: resolvedPath ?? path,
          nodes: nodes,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      state = AsyncData(
        current.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  /// Fetch the content of a file at [path].
  Future<String> readFile(String path) async {
    final outgoing = BridgeMessage.fileRead(
      sessionId: _sessionId,
      path: path,
    );
    final response = await _sendAndAwait(outgoing);
    if (response.type == BridgeMessageType.error) {
      final msg = response.payload['message'] as String? ?? 'Unknown error';
      throw Exception(msg);
    }
    return response.payload['content'] as String? ?? '';
  }

  /// Navigate to [path], updating the current directory.
  Future<void> navigateTo(String path) => fetchDirectory(path);

  /// Navigate to the parent directory.
  Future<void> navigateUp() {
    final current = state.value?.currentPath ?? '.';
    if (current == '.' || current == '/' || current.isEmpty) {
      return Future.value();
    }

    final normalised = current.replaceAll('\\', '/');
    final segments = normalised.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return Future.value();
    segments.removeLast();
    final parent = segments.isEmpty ? '/' : segments.join('/');
    return fetchDirectory(parent);
  }

  /// Toggle display of hidden (dot-prefixed) files.
  void toggleHidden() {
    final current = state.value ?? const RepoState();
    state = AsyncData(current.copyWith(showHidden: !current.showHidden));
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Family notifier provider keyed by sessionId.
final repoProvider =
    AsyncNotifierProviderFamily<RepoNotifier, RepoState, String>(
  RepoNotifier.new,
);

/// Provides the content string of a file at [path] for a given [sessionId].
final fileContentProvider =
    FutureProviderFamily<String, ({String sessionId, String path})>(
  (ref, args) async {
    final notifier = ref.read(repoProvider(args.sessionId).notifier);
    return notifier.readFile(args.path);
  },
);
