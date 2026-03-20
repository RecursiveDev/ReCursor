import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/file_models.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../domain/providers/repo_provider.dart';
import '../widgets/breadcrumb_nav.dart';
import '../widgets/file_tree_node_widget.dart';

/// Full-screen file tree browser for a given [sessionId].
class FileTreeScreen extends ConsumerWidget {
  final String sessionId;

  const FileTreeScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoAsync = ref.watch(repoProvider(sessionId));
    final notifier = ref.read(repoProvider(sessionId).notifier);

    return repoAsync.when(
      loading: () => Scaffold(
        appBar: _buildAppBar(context, ref, '…', notifier),
        body: const LoadingIndicator(message: 'Loading directory…'),
      ),
      error: (err, _) => Scaffold(
        appBar: _buildAppBar(context, ref, 'Error', notifier),
        body: Center(
          child: ErrorCard(
            message: err.toString(),
            onRetry: () => notifier.fetchDirectory(
              repoAsync.value?.currentPath ?? '.',
            ),
          ),
        ),
      ),
      data: (state) {
        final nodes = state.visibleNodes;

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: _buildAppBar(context, ref, state.currentPath, notifier),
          floatingActionButton: FloatingActionButton.small(
            tooltip: state.showHidden ? 'Hide hidden files' : 'Show hidden files',
            onPressed: notifier.toggleHidden,
            child: Icon(
              state.showHidden
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
          body: Column(
            children: [
              // Breadcrumb
              Container(
                color: const Color(0xFF1E1E1E),
                child: BreadcrumbNav(
                  path: state.currentPath,
                  onSegmentTap: notifier.navigateTo,
                ),
              ),
              const Divider(height: 1, color: Color(0xFF3E3E3E)),
              // Loading overlay when fetching a sub-directory
              if (state.isLoading)
                const LinearProgressIndicator(minHeight: 2),
              // Error banner
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ErrorCard(
                    message: state.error!,
                    onRetry: () => notifier.fetchDirectory(state.currentPath),
                  ),
                ),
              // File list
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
                              onTap: () => _onNodeTap(context, node),
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

  AppBar _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    String currentPath,
    RepoNotifier notifier,
  ) {
    final state = ref.read(repoProvider(sessionId)).value;
    final atRoot = state?.isAtRoot ?? true;

    return AppBar(
      backgroundColor: const Color(0xFF1E1E1E),
      leading: atRoot
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

  void _onNodeTap(BuildContext context, FileTreeNode node) {
    final notifier =
        // ignore: invalid_use_of_protected_member
        ProviderScope.containerOf(context).read(repoProvider(sessionId).notifier);
    if (node.type == FileNodeType.directory) {
      notifier.navigateTo(node.path);
    } else {
      context.push(
        '/home/repos/view',
        extra: {'path': node.path, 'sessionId': sessionId},
      );
    }
  }
}
