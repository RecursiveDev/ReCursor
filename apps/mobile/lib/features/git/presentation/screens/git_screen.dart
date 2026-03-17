import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/providers/git_provider.dart';
import '../widgets/file_change_tile.dart';
import '../widgets/git_status_card.dart';

/// Main Git screen showing repository status and a list of changed files.
///
/// Requires a [sessionId] to scope WS requests. The session ID is taken from
/// the `extra` field of the route or falls back to an empty string for
/// demonstration purposes when navigated from the bottom nav.
class GitScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const GitScreen({super.key, this.sessionId = ''});

  @override
  ConsumerState<GitScreen> createState() => _GitScreenState();
}

class _GitScreenState extends ConsumerState<GitScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.sessionId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(gitStatusProvider(widget.sessionId).notifier)
            .fetchStatus(widget.sessionId);
      });
    }
  }

  Future<void> _refresh() async {
    if (widget.sessionId.isNotEmpty) {
      await ref
          .read(gitStatusProvider(widget.sessionId).notifier)
          .fetchStatus(widget.sessionId);
    }
  }

  void _onPull() {
    if (widget.sessionId.isNotEmpty) {
      ref
          .read(gitStatusProvider(widget.sessionId).notifier)
          .pull(widget.sessionId);
    }
  }

  void _onPush() {
    if (widget.sessionId.isNotEmpty) {
      ref
          .read(gitStatusProvider(widget.sessionId).notifier)
          .push(widget.sessionId);
    }
  }

  void _onCommit(List changes) {
    context.push(
      '/git/commit',
      extra: {'sessionId': widget.sessionId, 'changes': changes},
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = widget.sessionId.isNotEmpty
        ? ref.watch(gitStatusProvider(widget.sessionId))
        : const AsyncValue<dynamic>.data(null);

    return Scaffold(
      appBar: AppBar(title: const Text('Git')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: statusAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (status) {
            if (status == null) {
              return _emptyState();
            }

            if (status.isClean) {
              return Column(
                children: [
                  GitStatusCard(status: status),
                  Expanded(child: _emptyState()),
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

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle_outline,
              size: 48, color: Color(0xFF4CAF50)),
          SizedBox(height: 12),
          Text(
            'Repository is clean',
            style: TextStyle(fontSize: 15, color: Color(0xFF9E9E9E)),
          ),
        ],
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
