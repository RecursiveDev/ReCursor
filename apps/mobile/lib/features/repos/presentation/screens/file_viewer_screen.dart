import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/error_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../domain/providers/repo_provider.dart';
import '../widgets/syntax_highlighted_file.dart';

/// Displays the content of a single file fetched via the bridge.
class FileViewerScreen extends ConsumerWidget {
  final String sessionId;
  final String path;

  const FileViewerScreen({
    super.key,
    required this.sessionId,
    required this.path,
  });

  String get _filename {
    final normalised = path.replaceAll('\\', '/');
    return normalised.split('/').last;
  }

  int? _fileSizeFromState(WidgetRef ref) {
    final state = ref.read(repoProvider(sessionId)).value;
    if (state == null) return null;
    try {
      return state.nodes
          .firstWhere((n) => n.path == path)
          .size;
    } catch (_) {
      return null;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
    }
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(
      fileContentProvider((sessionId: sessionId, path: path)),
    );
    final knownSize = _fileSizeFromState(ref);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: [
            Expanded(
              child: Text(
                _filename,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 13,
                  color: Color(0xFFD4D4D4),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (knownSize != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatSize(knownSize),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9E9E9E),
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          contentAsync.whenOrNull(
                data: (content) => IconButton(
                  tooltip: 'Copy file',
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: content));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: contentAsync.when(
        loading: () =>
            const LoadingIndicator(message: 'Fetching file content…'),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ErrorCard(
              message: err.toString(),
              onRetry: () => ref.invalidate(
                fileContentProvider((sessionId: sessionId, path: path)),
              ),
            ),
          ),
        ),
        data: (content) {
          final lineCount = '\n'.allMatches(content).length + 1;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (lineCount > 1000)
                Container(
                  color: const Color(0xFF2D2D2D),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: Color(0xFFFF9800),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Large file — $lineCount lines.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SyntaxHighlightedFile(
                  content: content,
                  filePath: path,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
