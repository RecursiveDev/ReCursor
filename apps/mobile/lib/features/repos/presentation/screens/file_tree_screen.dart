import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/file_models.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../chat/domain/providers/session_provider.dart';
import '../../domain/providers/repo_provider.dart';
import '../widgets/breadcrumb_nav.dart';
import '../widgets/file_tree_node_widget.dart';

/// Full-screen file tree browser for a given [sessionId].
///
/// When [sessionId] is empty, the screen falls back to the currently selected
/// chat session.
class FileTreeScreen extends ConsumerWidget {
  final String sessionId;

  const FileTreeScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedSessionId = ref.watch(resolvedSessionIdProvider(sessionId));
    if (resolvedSessionId == null) {
      return Scaffold(
        appBar: _buildIdleAppBar('Files'),
        body: const EmptyState(
          icon: Icons.folder_off_outlined,
          title: 'Select a session first',
          subtitle:
              'Open a Claude session in Chat to browse files for that workspace.',
        ),
      );
    }

    final repoAsync = ref.watch(repoProvider(resolvedSessionId));
    final notifier = ref.read(repoProvider(resolvedSessionId).notifier);

    return repoAsync.when(
      loading: () => Scaffold(
        appBar: _buildIdleAppBar('Files'),
        body: const LoadingIndicator(message: 'Loading directory…'),
      ),
      error: (err, _) => Scaffold(
        appBar: _buildIdleAppBar('Files'),
        body: Center(
          child: ErrorCard(
            message: err.toString(),
            onRetry: () => notifier.fetchDirectory('.'),
          ),
        ),
      ),
      data: (state) {
        final nodes = state.visibleNodes;

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar:
              _buildSessionAppBar(state.currentPath, state.isAtRoot, notifier),
          floatingActionButton: FloatingActionButton.small(
            tooltip:
                state.showHidden ? 'Hide hidden files' : 'Show hidden files',
            onPressed: notifier.toggleHidden,
            child: Icon(
              state.showHidden
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
          body: Column(
            children: [
              Container(
                color: const Color(0xFF1E1E1E),
                child: BreadcrumbNav(
                  path: state.currentPath,
                  onSegmentTap: notifier.navigateTo,
                ),
              ),
              const Divider(height: 1, color: Color(0xFF3E3E3E)),
              if (state.isLoading) const LinearProgressIndicator(minHeight: 2),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ErrorCard(
                    message: state.error!,
                    onRetry: () => notifier.fetchDirectory(state.currentPath),
                  ),
                ),
              Expanded(
                child: nodes.isEmpty && !state.isLoading
                    ? EmptyState(
                        icon: Icons.folder_open,
                        title: 'Empty directory',
                        subtitle: state.showHidden
                            ? null
                            : 'Toggle visibility to show hidden files.',
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            notifier.fetchDirectory(state.currentPath),
                        child: ListView.builder(
                          itemCount: nodes.length,
                          itemBuilder: (context, index) {
                            final node = nodes[index];
                            return FileTreeNodeWidget(
                              node: node,
                              onTap: () => _onNodeTap(
                                context,
                                sessionId: resolvedSessionId,
                                node: node,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  AppBar _buildIdleAppBar(String title) {
    return AppBar(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(title),
    );
  }

  AppBar _buildSessionAppBar(
    String currentPath,
    bool isAtRoot,
    RepoNotifier notifier,
  ) {
    return AppBar(
      backgroundColor: const Color(0xFF1E1E1E),
      leading: isAtRoot
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: notifier.navigateUp,
            ),
      title: Text(
        currentPath,
        style: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 13,
          color: Color(0xFFD4D4D4),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _onNodeTap(
    BuildContext context, {
    required String sessionId,
    required FileTreeNode node,
  }) {
    final notifier = ProviderScope.containerOf(context).read(
      repoProvider(sessionId).notifier,
    );

    if (node.type == FileNodeType.directory) {
      notifier.navigateTo(node.path);
      return;
    }

    context.push(
      '/home/repos/view',
      extra: {'path': node.path, 'sessionId': sessionId},
    );
  }
}
