import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../chat/domain/providers/session_provider.dart';
import '../../domain/providers/git_provider.dart';
import '../widgets/file_change_tile.dart';
import '../widgets/git_status_card.dart';

/// Main Git screen showing repository status and a list of changed files.
///
/// Uses the explicit [sessionId] when provided, otherwise falls back to the
/// currently selected chat session.
class GitScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const GitScreen({super.key, this.sessionId = ''});

  @override
  ConsumerState<GitScreen> createState() => _GitScreenState();
}

class _GitScreenState extends ConsumerState<GitScreen> {
  ProviderSubscription<String?>? _sessionIdSubscription;

  @override
  void initState() {
    super.initState();
    _bindSessionContext();
  }

  @override
  void didUpdateWidget(covariant GitScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) {
      _bindSessionContext();
    }
  }

  @override
  void dispose() {
    _sessionIdSubscription?.close();
    super.dispose();
  }

  void _bindSessionContext() {
    _sessionIdSubscription?.close();
    _sessionIdSubscription = ref.listenManual<String?>(
      resolvedSessionIdProvider(widget.sessionId),
      (previous, next) {
        if (next == null || next.isEmpty || next == previous) {
          return;
        }

        Future<void>.microtask(
          () => ref.read(gitStatusProvider(next).notifier).fetchStatus(next),
        );
      },
      fireImmediately: true,
    );
  }

  String? _resolvedSessionId() {
    return ref.read(resolvedSessionIdProvider(widget.sessionId));
  }

  Future<void> _refresh() async {
    final sessionId = _resolvedSessionId();
    if (sessionId == null) {
      return;
    }

    await ref
        .read(gitStatusProvider(sessionId).notifier)
        .fetchStatus(sessionId);
  }

  void _onPull() {
    final sessionId = _resolvedSessionId();
    if (sessionId == null) {
      return;
    }

    ref.read(gitStatusProvider(sessionId).notifier).pull(sessionId);
  }

  void _onPush() {
    final sessionId = _resolvedSessionId();
    if (sessionId == null) {
      return;
    }

    ref.read(gitStatusProvider(sessionId).notifier).push(sessionId);
  }

  void _onCommit(List changes) {
    final sessionId = _resolvedSessionId();
    if (sessionId == null) {
      return;
    }

    context.push(
      '/git/commit',
      extra: {'sessionId': sessionId, 'changes': changes},
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedSessionId =
        ref.watch(resolvedSessionIdProvider(widget.sessionId));
    final statusAsync = resolvedSessionId != null
        ? ref.watch(gitStatusProvider(resolvedSessionId))
        : const AsyncValue<dynamic>.data(null);

    return Scaffold(
      appBar: AppBar(title: const Text('Git')),
      body: resolvedSessionId == null
          ? _sessionRequiredState()
          : RefreshIndicator(
              onRefresh: _refresh,
              child: statusAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (status) {
                  if (status == null) {
                    return _placeholderState(
                      icon: Icons.sync_outlined,
                      title: 'Awaiting git status',
                      subtitle:
                          'Pull to refresh if the repository summary does not appear.',
                    );
                  }

                  if (status.isClean) {
                    return Column(
                      children: [
                        GitStatusCard(status: status),
                        Expanded(
                          child: _placeholderState(
                            icon: Icons.check_circle_outline,
                            title: 'Repository is clean',
                            subtitle:
                                'No working tree changes were reported for this session.',
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      GitStatusCard(status: status),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          itemCount: status.changes.length,
                          itemBuilder: (context, index) {
                            final change = status.changes[index];
                            return FileChangeTile(
                              change: change,
                              onTap: () {},
                            );
                          },
                        ),
                      ),
                      _ActionRow(
                        onPull: _onPull,
                        onCommit: () => _onCommit(status.changes),
                        onPush: _onPush,
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _sessionRequiredState() {
    return _placeholderState(
      icon: Icons.source_outlined,
      title: 'Select a session first',
      subtitle:
          'Open a Claude session in Chat to inspect repository status for that workspace.',
    );
  }

  Widget _placeholderState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF9E9E9E)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFFD4D4D4)),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onPull;
  final VoidCallback onCommit;
  final VoidCallback onPush;

  const _ActionRow({
    required this.onPull,
    required this.onCommit,
    required this.onPush,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPull,
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('Pull'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onCommit,
              icon: const Icon(Icons.commit, size: 16),
              label: const Text('Commit'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPush,
              icon: const Icon(Icons.upload_outlined, size: 16),
              label: const Text('Push'),
            ),
          ),
        ],
      ),
    );
  }
}
