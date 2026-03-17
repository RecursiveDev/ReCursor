// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'git_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GitStatusImpl _$$GitStatusImplFromJson(Map<String, dynamic> json) =>
    _$GitStatusImpl(
      branch: json['branch'] as String,
      changes: (json['changes'] as List<dynamic>)
          .map((e) => GitFileChange.fromJson(e as Map<String, dynamic>))
          .toList(),
      ahead: (json['ahead'] as num).toInt(),
      behind: (json['behind'] as num).toInt(),
      isClean: json['isClean'] as bool,
    );

Map<String, dynamic> _$$GitStatusImplToJson(_$GitStatusImpl instance) =>
    <String, dynamic>{
      'branch': instance.branch,
      'changes': instance.changes,
      'ahead': instance.ahead,
      'behind': instance.behind,
      'isClean': instance.isClean,
    };

_$GitFileChangeImpl _$$GitFileChangeImplFromJson(Map<String, dynamic> json) =>
    _$GitFileChangeImpl(
      path: json['path'] as String,
      status: $enumDecode(_$FileChangeStatusEnumMap, json['status']),
      additions: (json['additions'] as num?)?.toInt(),
      deletions: (json['deletions'] as num?)?.toInt(),
      diff: json['diff'] as String?,
    );

Map<String, dynamic> _$$GitFileChangeImplToJson(_$GitFileChangeImpl instance) =>
    <String, dynamic>{
      'path': instance.path,
      'status': _$FileChangeStatusEnumMap[instance.status]!,
      'additions': instance.additions,
      'deletions': instance.deletions,
      'diff': instance.diff,
    };

const _$FileChangeStatusEnumMap = {
  FileChangeStatus.modified: 'modified',
  FileChangeStatus.added: 'added',
  FileChangeStatus.deleted: 'deleted',
  FileChangeStatus.untracked: 'untracked',
  FileChangeStatus.renamed: 'renamed',
};

_$GitBranchImpl _$$GitBranchImplFromJson(Map<String, dynamic> json) =>
    _$GitBranchImpl(
      name: json['name'] as String,
      isCurrent: json['isCurrent'] as bool,
      upstream: json['upstream'] as String?,
      ahead: (json['ahead'] as num?)?.toInt(),
      behind: (json['behind'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$GitBranchImplToJson(_$GitBranchImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'isCurrent': instance.isCurrent,
      'upstream': instance.upstream,
      'ahead': instance.ahead,
      'behind': instance.behind,
    };

_$DiffFileImpl _$$DiffFileImplFromJson(Map<String, dynamic> json) =>
    _$DiffFileImpl(
      path: json['path'] as String,
      oldPath: json['oldPath'] as String,
      newPath: json['newPath'] as String,
      status: $enumDecode(_$FileChangeStatusEnumMap, json['status']),
      additions: (json['additions'] as num).toInt(),
      deletions: (json['deletions'] as num).toInt(),
      hunks: (json['hunks'] as List<dynamic>)
          .map((e) => DiffHunk.fromJson(e as Map<String, dynamic>))
          .toList(),
      oldMode: json['oldMode'] as String?,
      newMode: json['newMode'] as String?,
    );

Map<String, dynamic> _$$DiffFileImplToJson(_$DiffFileImpl instance) =>
    <String, dynamic>{
      'path': instance.path,
      'oldPath': instance.oldPath,
      'newPath': instance.newPath,
      'status': _$FileChangeStatusEnumMap[instance.status]!,
      'additions': instance.additions,
      'deletions': instance.deletions,
      'hunks': instance.hunks,
      'oldMode': instance.oldMode,
      'newMode': instance.newMode,
    };

_$DiffHunkImpl _$$DiffHunkImplFromJson(Map<String, dynamic> json) =>
    _$DiffHunkImpl(
      header: json['header'] as String,
      oldStart: (json['oldStart'] as num).toInt(),
      oldLines: (json['oldLines'] as num).toInt(),
      newStart: (json['newStart'] as num).toInt(),
      newLines: (json['newLines'] as num).toInt(),
      lines: (json['lines'] as List<dynamic>)
          .map((e) => DiffLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$DiffHunkImplToJson(_$DiffHunkImpl instance) =>
    <String, dynamic>{
      'header': instance.header,
      'oldStart': instance.oldStart,
      'oldLines': instance.oldLines,
      'newStart': instance.newStart,
      'newLines': instance.newLines,
      'lines': instance.lines,
    };

_$DiffLineImpl _$$DiffLineImplFromJson(Map<String, dynamic> json) =>
    _$DiffLineImpl(
      type: $enumDecode(_$DiffLineTypeEnumMap, json['type']),
      content: json['content'] as String,
      oldLineNumber: (json['oldLineNumber'] as num?)?.toInt(),
      newLineNumber: (json['newLineNumber'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$DiffLineImplToJson(_$DiffLineImpl instance) =>
    <String, dynamic>{
      'type': _$DiffLineTypeEnumMap[instance.type]!,
      'content': instance.content,
      'oldLineNumber': instance.oldLineNumber,
      'newLineNumber': instance.newLineNumber,
    };

const _$DiffLineTypeEnumMap = {
  DiffLineType.context: 'context',
  DiffLineType.added: 'added',
  DiffLineType.removed: 'removed',
};
