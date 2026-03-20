import '../../core/models/git_models.dart';

/// Parses unified diff strings into [DiffFile] objects.
class DiffParser {
  static final _fileHeaderOld = RegExp(r'^--- a/(.+)$');
  static final _fileHeaderNew = RegExp(r'^\+\+\+ b/(.+)$');
  static final _hunkHeader = RegExp(
    r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@(.*)$',
  );

  /// Parse a unified diff string into a list of [DiffFile] objects.
  static List<DiffFile> parse(String rawDiff) {
    final files = <DiffFile>[];
    final lines = rawDiff.split('\n');

    String? oldPath;
    String? newPath;
    final hunks = <DiffHunk>[];

    List<DiffLine>? currentHunkLines;
    DiffHunk? currentHunk;
    int oldLineNum = 0;
    int newLineNum = 0;

    void flushHunk() {
      if (currentHunk != null && currentHunkLines != null) {
        hunks.add(DiffHunk(
          header: currentHunk!.header,
          oldStart: currentHunk!.oldStart,
          oldLines: currentHunk!.oldLines,
          newStart: currentHunk!.newStart,
          newLines: currentHunk!.newLines,
          lines: List.unmodifiable(currentHunkLines!),
        ));
        currentHunk = null;
        currentHunkLines = null;
      }
    }

    void flushFile() {
      if (oldPath != null && newPath != null) {
        flushHunk();

        int additions = 0;
        int deletions = 0;
        for (final hunk in hunks) {
          for (final line in hunk.lines) {
            if (line.type == DiffLineType.added) additions++;
            if (line.type == DiffLineType.removed) deletions++;
          }
        }

        final path = newPath ?? oldPath ?? '';
        files.add(DiffFile(
          path: path,
          oldPath: oldPath!,
          newPath: newPath!,
          status: _inferStatus(oldPath!, newPath!),
          additions: additions,
          deletions: deletions,
          hunks: List.unmodifiable(hunks),
        ));

        oldPath = null;
        newPath = null;
        hunks.clear();
      }
    }

    for (final line in lines) {
      // New file header signals start of a new file diff
      if (line.startsWith('--- ')) {
        final match = _fileHeaderOld.firstMatch(line);
        if (match != null) {
          flushFile();
          oldPath = match.group(1);
          continue;
        }
        // Handle /dev/null for new files
        if (line == '--- /dev/null') {
          flushFile();
          oldPath = '/dev/null';
          continue;
        }
      }

      if (line.startsWith('+++ ')) {
        final match = _fileHeaderNew.firstMatch(line);
        if (match != null) {
          newPath = match.group(1);
          continue;
        }
        if (line == '+++ /dev/null') {
          newPath = '/dev/null';
          continue;
        }
      }

      // Hunk header
      final hunkMatch = _hunkHeader.firstMatch(line);
      if (hunkMatch != null) {
        flushHunk();
        final oldStart = int.parse(hunkMatch.group(1)!);
        final oldCount = int.tryParse(hunkMatch.group(2) ?? '1') ?? 1;
        final newStart = int.parse(hunkMatch.group(3)!);
        final newCount = int.tryParse(hunkMatch.group(4) ?? '1') ?? 1;
        final header = line;

        currentHunk = DiffHunk(
          header: header,
          oldStart: oldStart,
          oldLines: oldCount,
          newStart: newStart,
          newLines: newCount,
          lines: const [],
        );
        currentHunkLines = [];
        oldLineNum = oldStart;
        newLineNum = newStart;
        continue;
      }

      // Diff content lines
      if (currentHunkLines != null) {
        if (line.startsWith('+')) {
          currentHunkLines!.add(DiffLine(
            type: DiffLineType.added,
            content: line.substring(1),
            newLineNumber: newLineNum++,
          ));
        } else if (line.startsWith('-')) {
          currentHunkLines!.add(DiffLine(
            type: DiffLineType.removed,
            content: line.substring(1),
            oldLineNumber: oldLineNum++,
          ));
        } else if (line.startsWith(' ')) {
          currentHunkLines!.add(DiffLine(
            type: DiffLineType.context,
            content: line.substring(1),
            oldLineNumber: oldLineNum++,
            newLineNumber: newLineNum++,
          ));
        }
      }
    }

    flushFile();
    return files;
  }

  static FileChangeStatus _inferStatus(String oldPath, String newPath) {
    if (oldPath == '/dev/null') return FileChangeStatus.added;
    if (newPath == '/dev/null') return FileChangeStatus.deleted;
    if (oldPath != newPath) return FileChangeStatus.renamed;
    return FileChangeStatus.modified;
  }
}
