import 'package:flutter/material.dart';

import '../../../../core/models/git_models.dart';
import '../../domain/providers/diff_provider.dart';
import 'diff_line_widget.dart';

class DiffHunkView extends StatelessWidget {
  final DiffHunk hunk;
  final DiffViewMode viewMode;

  const DiffHunkView({
    super.key,
    required this.hunk,
    required this.viewMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hunk header
        Container(
          width: double.infinity,
          color: const Color(0xFF1E1E1E),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            hunk.header,
            style: const TextStyle(
              color: Colors.grey,
              fontFamily: 'JetBrainsMono',
              fontSize: 12,
            ),
          ),
        ),
        // Lines
        ...hunk.lines.map((line) => DiffLineWidget(line: line)),
      ],
    );
  }
}
