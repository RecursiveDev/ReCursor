import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/git_models.dart';
import '../../domain/providers/diff_provider.dart';
import '../widgets/diff_hunk_view.dart';
import '../widgets/diff_viewer.dart';

class DiffViewerScreen extends ConsumerStatefulWidget {
  const DiffViewerScreen({super.key});

  @override
  ConsumerState<DiffViewerScreen> createState() => _DiffViewerScreenState();
}

class _DiffViewerScreenState extends ConsumerState<DiffViewerScreen> {
  int _selectedFileIndex = 0;

  String _statusLabel(FileChangeStatus status) {
    return switch (status) {
      FileChangeStatus.modified => 'M',
      FileChangeStatus.added => 'A',
      FileChangeStatus.deleted => 'D',
      FileChangeStatus.renamed => 'R',
      FileChangeStatus.untracked => '?',
    };
  }

  Color _statusColor(FileChangeStatus status) {
    return switch (status) {
      FileChangeStatus.modified => Colors.orange,
      FileChangeStatus.added => const Color(0xFF4EC9B0),
      FileChangeStatus.deleted => Colors.redAccent,
      FileChangeStatus.renamed => const Color(0xFF569CD6),
      FileChangeStatus.untracked => Colors.grey,
    };
  }

  Widget _buildFileSidebar(List<DiffFile> files, DiffViewMode viewMode) {
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final isSelected = index == _selectedFileIndex;
        final color = _statusColor(file.status);
        return InkWell(
          onTap: () => setState(() => _selectedFileIndex = index),
          child: Container(
            color: isSelected ? const Color(0xFF2A2D2E) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _statusLabel(file.status),
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'JetBrainsMono',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.path.split('/').last,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'JetBrainsMono',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(
                            '+${file.additions}',
                            style: const TextStyle(
                              color: Color(0xFF4EC9B0),
                              fontSize: 10,
                              fontFamily: 'JetBrainsMono',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '-${file.deletions}',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 10,
                              fontFamily: 'JetBrainsMono',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiffDetail(DiffFile file, DiffViewMode viewMode) {
    if (file.hunks.isEmpty) {
      return const Center(
        child: Text(
          'No hunks to display',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: file.hunks.length,
      itemBuilder: (context, i) =>
          DiffHunkView(hunk: file.hunks[i], viewMode: viewMode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diff = ref.watch(currentDiffProvider);
    final viewMode = ref.watch(diffViewModeProvider);

    final fileCount = diff?.length ?? 0;
    final additions = diff?.fold<int>(0, (sum, f) => sum + f.additions) ?? 0;
    final deletions = diff?.fold<int>(0, (sum, f) => sum + f.deletions) ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252526),
        title: Row(
          children: [
            Text(
              '$fileCount ${fileCount == 1 ? 'file' : 'files'}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              '+$additions',
              style: const TextStyle(color: Color(0xFF4EC9B0), fontSize: 13),
            ),
            const SizedBox(width: 6),
            Text(
              '-$deletions',
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: viewMode == DiffViewMode.unified
                ? 'Switch to split view'
                : 'Switch to unified view',
            icon: Icon(
              viewMode == DiffViewMode.unified
                  ? Icons.vertical_split
                  : Icons.view_stream,
              color: const Color(0xFF9CDCFE),
            ),
            onPressed: () {
              ref.read(diffViewModeProvider.notifier).state =
                  viewMode == DiffViewMode.unified
                      ? DiffViewMode.splitView
                      : DiffViewMode.unified;
            },
          ),
        ],
      ),
      body: diff == null || diff.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.difference_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No diff to display',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final isTabletLandscape = constraints.maxWidth >= 600;

                if (isTabletLandscape) {
                  // Clamp selected index in case diff changed
                  final safeIndex =
                      _selectedFileIndex.clamp(0, diff.length - 1);

                  return Row(
                    children: [
                      // Left 35%: file list sidebar
                      SizedBox(
                        width: constraints.maxWidth * 0.35,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF252526),
                            border: Border(
                              right: BorderSide(color: Color(0xFF3C3C3C)),
                            ),
                          ),
                          child: _buildFileSidebar(diff, viewMode),
                        ),
                      ),
                      // Right 65%: selected file diff hunks
                      Expanded(
                        child: _buildDiffDetail(diff[safeIndex], viewMode),
                      ),
                    ],
                  );
                }

                // Portrait: original single-panel ListView
                return DiffViewer(files: diff, viewMode: viewMode);
              },
            ),
    );
  }
}
