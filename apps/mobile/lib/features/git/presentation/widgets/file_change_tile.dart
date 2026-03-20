import 'package:flutter/material.dart';

import '../../../../core/models/git_models.dart';

/// A list tile for a single [GitFileChange].
class FileChangeTile extends StatelessWidget {
  final GitFileChange change;
  final VoidCallback? onTap;

  const FileChangeTile({
    super.key,
    required this.change,
    this.onTap,
  });

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
      FileChangeStatus.modified => const Color(0xFF569CD6),
      FileChangeStatus.added => const Color(0xFF4EC9B0),
      FileChangeStatus.deleted => const Color(0xFFF44747),
      FileChangeStatus.renamed => const Color(0xFFFF9800),
      FileChangeStatus.untracked => const Color(0xFF9E9E9E),
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(change.status);
    final label = _statusLabel(change.status);

    final hasStats =
        change.additions != null || change.deletions != null;

    return ListTile(
      onTap: onTap,
      dense: true,
      leading: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
      title: Text(
        change.path,
        style: const TextStyle(
          fontSize: 13,
          fontFamily: 'JetBrainsMono',
          color: Color(0xFFD4D4D4),
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: hasStats
          ? Text(
              [
                if (change.additions != null) '+${change.additions}',
                if (change.deletions != null) '-${change.deletions}',
              ].join('  '),
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'JetBrainsMono',
                color: Color(0xFF9E9E9E),
              ),
            )
          : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right,
              size: 18, color: Color(0xFF9E9E9E))
          : null,
    );
  }
}
