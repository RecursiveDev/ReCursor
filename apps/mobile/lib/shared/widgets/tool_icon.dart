import 'package:flutter/material.dart';

class ToolIcon extends StatelessWidget {
  final String tool;
  final double size;
  final Color? color;

  const ToolIcon({
    super.key,
    required this.tool,
    this.size = 24,
    this.color,
  });

  IconData get _icon => switch (tool.toLowerCase()) {
        'edit_file' || 'write' || 'edit' => Icons.edit,
        'read_file' || 'read' => Icons.file_open,
        'bash' || 'run_command' || 'bash_command' => Icons.terminal,
        'glob' => Icons.folder_open,
        'grep' => Icons.search,
        'list_files' || 'ls' => Icons.list,
        'git_commit' => Icons.commit,
        'git_diff' => Icons.difference,
        _ => Icons.build,
      };

  @override
  Widget build(BuildContext context) {
    return Icon(
      _icon,
      size: size,
      color: color ?? Theme.of(context).iconTheme.color,
    );
  }
}
