Map<String, dynamic> normalizeGitStatusPayload(Map<String, dynamic> payload) {
  return {
    ...payload,
    'isClean': payload['isClean'] ?? payload['is_clean'] ?? false,
    'changes': (payload['changes'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(normalizeGitFileChange)
        .toList(),
  };
}

Map<String, dynamic> normalizeGitFileChange(Map<String, dynamic> change) {
  return {
    ...change,
    'additions': change['additions'],
    'deletions': change['deletions'],
  };
}

Map<String, dynamic> normalizeFileListPayload(Map<String, dynamic> payload) {
  final rawEntries = payload['entries'] ?? payload['nodes'];

  return {
    ...payload,
    'path': payload['path'] ?? payload['currentPath'] ?? '.',
    'nodes': (rawEntries as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(normalizeFileEntry)
        .toList(),
  };
}

Map<String, dynamic> normalizeFileEntry(Map<String, dynamic> entry) {
  return {
    ...entry,
    'modifiedAt': entry['modifiedAt'] ?? entry['modified'],
  };
}

Map<String, dynamic> normalizeDiffFile(Map<String, dynamic> file) {
  return {
    ...file,
    'oldPath': file['oldPath'] ?? file['old_path'] ?? file['path'] ?? '',
    'newPath': file['newPath'] ?? file['new_path'] ?? file['path'] ?? '',
    'oldMode': file['oldMode'] ?? file['old_mode'],
    'newMode': file['newMode'] ?? file['new_mode'],
    'hunks': (file['hunks'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(normalizeDiffHunk)
        .toList(),
  };
}

Map<String, dynamic> normalizeDiffHunk(Map<String, dynamic> hunk) {
  return {
    ...hunk,
    'oldStart': hunk['oldStart'] ?? hunk['old_start'] ?? 0,
    'oldLines': hunk['oldLines'] ?? hunk['old_lines'] ?? 0,
    'newStart': hunk['newStart'] ?? hunk['new_start'] ?? 0,
    'newLines': hunk['newLines'] ?? hunk['new_lines'] ?? 0,
    'lines': (hunk['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(normalizeDiffLine)
        .toList(),
  };
}

Map<String, dynamic> normalizeDiffLine(Map<String, dynamic> line) {
  return {
    ...line,
    'oldLineNumber': line['oldLineNumber'] ?? line['old_line_number'],
    'newLineNumber': line['newLineNumber'] ?? line['new_line_number'],
  };
}
