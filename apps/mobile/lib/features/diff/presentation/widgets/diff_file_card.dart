import 'package:flutter/material.dart';

import '../../../../core/models/git_models.dart';
import '../../domain/providers/diff_provider.dart';
import 'diff_hunk_view.dart';

class DiffFileCard extends StatelessWidget {
  final DiffFile file;
  final DiffViewMode viewMode;

  const DiffFileCard({
    super.key,
    required this.file,
    required this.viewMode,
  });

  String get _statusLabel {
    return switch (file.status) {
      FileChangeStatus.modified => 'M',
      FileChangeStatus.added => 'A',
      FileChangeStatus.deleted => 'D',
      FileChangeStatus.renamed => 'R',
      FileChangeStatus.untracked => '?',
    };
  }

  Color get _statusColor {
    return switch (file.status) {
      FileChangeStatus.modified => Colors.orange,
      FileChangeStatus.added => const Color(0xFF4EC9B0),
      FileChangeStatus.deleted => Colors.redAccent,
      FileChangeStatus.renamed => const Color(0xFF569CD6),
      FileChangeStatus.untracked => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF252526),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        collapsedBackgroundColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            _statusLabel,
            style: TextStyle(
              color: _statusColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'JetBrainsMono',
            ),
          ),
        ),
        title: Text(
          file.path,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: 'JetBrainsMono',
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+${file.additions}',
              style: const TextStyle(
                  color: Color(0xFF4EC9B0),
                  fontSize: 12,
                  fontFamily: 'JetBrainsMono'),
            ),
            const SizedBox(width: 6),
            Text(
              '-${file.deletions}',
              style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontFamily: 'JetBrainsMono'),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, color: Colors.grey, size: 16),
          ],
        ),
        children: file.hunks
            .map((h) => DiffHunkView(hunk: h, viewMode: viewMode))
            .toList(),
      ),
    );
  }
}
