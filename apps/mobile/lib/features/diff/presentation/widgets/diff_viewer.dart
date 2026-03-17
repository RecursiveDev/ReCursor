import 'package:flutter/material.dart';

import '../../../../core/models/git_models.dart';
import '../../domain/providers/diff_provider.dart';
import 'diff_file_card.dart';

class DiffViewer extends StatelessWidget {
  final List<DiffFile> files;
  final DiffViewMode viewMode;

  const DiffViewer({
    super.key,
    required this.files,
    required this.viewMode,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: files.length,
      itemBuilder: (context, i) => DiffFileCard(
        file: files[i],
        viewMode: viewMode,
      ),
    );
  }
}
