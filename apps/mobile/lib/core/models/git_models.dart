import 'package:freezed_annotation/freezed_annotation.dart';

part 'git_models.freezed.dart';
part 'git_models.g.dart';

enum FileChangeStatus { modified, added, deleted, untracked, renamed }

enum DiffLineType { context, added, removed }

@freezed
class GitStatus with _$GitStatus {
  const factory GitStatus({
    required String branch,
    required List<GitFileChange> changes,
    required int ahead,
    required int behind,
    required bool isClean,
  }) = _GitStatus;

  factory GitStatus.fromJson(Map<String, dynamic> json) =>
      _$GitStatusFromJson(json);
}

@freezed
class GitFileChange with _$GitFileChange {
  const factory GitFileChange({
    required String path,
    required FileChangeStatus status,
    int? additions,
    int? deletions,
    String? diff,
  }) = _GitFileChange;

  factory GitFileChange.fromJson(Map<String, dynamic> json) =>
      _$GitFileChangeFromJson(json);
}

@freezed
class GitBranch with _$GitBranch {
  const factory GitBranch({
    required String name,
    required bool isCurrent,
    String? upstream,
    int? ahead,
    int? behind,
  }) = _GitBranch;

  factory GitBranch.fromJson(Map<String, dynamic> json) =>
      _$GitBranchFromJson(json);
}

@freezed
class DiffFile with _$DiffFile {
  const factory DiffFile({
    required String path,
    required String oldPath,
    required String newPath,
    required FileChangeStatus status,
    required int additions,
    required int deletions,
    required List<DiffHunk> hunks,
    String? oldMode,
    String? newMode,
  }) = _DiffFile;

  factory DiffFile.fromJson(Map<String, dynamic> json) =>
      _$DiffFileFromJson(json);
}

@freezed
class DiffHunk with _$DiffHunk {
  const factory DiffHunk({
    required String header,
    required int oldStart,
    required int oldLines,
    required int newStart,
    required int newLines,
    required List<DiffLine> lines,
  }) = _DiffHunk;

  factory DiffHunk.fromJson(Map<String, dynamic> json) =>
      _$DiffHunkFromJson(json);
}

@freezed
class DiffLine with _$DiffLine {
  const factory DiffLine({
    required DiffLineType type,
    required String content,
    int? oldLineNumber,
    int? newLineNumber,
  }) = _DiffLine;

  factory DiffLine.fromJson(Map<String, dynamic> json) =>
      _$DiffLineFromJson(json);
}
