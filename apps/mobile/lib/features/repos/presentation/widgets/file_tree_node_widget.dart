import 'package:flutter/material.dart';

import '../../../../core/models/file_models.dart';
import '../../../../shared/constants/colors.dart';
import '../../../../shared/constants/typography.dart';

/// A single row in the file tree list.
///
/// Shows an appropriate icon and colour for the node type/extension, the
/// node name in monospace, and — for files — a human-readable size badge.
class FileTreeNodeWidget extends StatelessWidget {
  final FileTreeNode node;
  final VoidCallback onTap;

  const FileTreeNodeWidget({
    super.key,
    required this.node,
    required this.onTap,
  });

  // ---------------------------------------------------------------------------
  // Icon helpers
  // ---------------------------------------------------------------------------

  static IconData _iconForNode(FileTreeNode node) {
    if (node.type == FileNodeType.directory) return Icons.folder;
    final ext = _extension(node.name);
    return switch (ext) {
      'dart' => Icons.code,
      'ts' || 'tsx' || 'js' || 'jsx' => Icons.javascript,
      'md' || 'mdx' => Icons.description,
      'json' => Icons.data_object,
      'yaml' || 'yml' => Icons.settings,
      'png' || 'jpg' || 'jpeg' || 'gif' || 'svg' || 'webp' => Icons.image,
      _ => Icons.insert_drive_file,
    };
  }

  static Color _colorForNode(FileTreeNode node) {
    if (node.type == FileNodeType.directory) {
      return const Color(0xFFE8C17A); // warm yellow for folders
    }
    final ext = _extension(node.name);
    return switch (ext) {
      'dart' => kPrimary, // blue
      'ts' || 'tsx' || 'js' || 'jsx' => const Color(0xFFE8C17A), // yellow
      'md' || 'mdx' => const Color(0xFF4EC9B0), // teal
      'json' || 'yaml' || 'yml' || 'toml' || 'ini' => kTextSecondary, // grey
      _ => kTextSecondary,
    };
  }

  static String _extension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  // ---------------------------------------------------------------------------
  // Size formatting
  // ---------------------------------------------------------------------------

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
    }
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDir = node.type == FileNodeType.directory;
    final iconColor = _colorForNode(node);
    final icon = _iconForNode(node);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          dense: true,
          leading: Icon(icon, color: iconColor, size: 20),
          title: Text(
            node.name,
            style: AppTypography.code.copyWith(
              fontSize: 13,
              color: const Color(0xFFD4D4D4),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isDir && node.size != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatSize(node.size!),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9E9E9E),
                      fontFamily: 'JetBrainsMono',
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: Color(0xFF9E9E9E),
              ),
            ],
          ),
          onTap: onTap,
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFF2A2A2A)),
      ],
    );
  }
}
