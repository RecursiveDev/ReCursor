// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FileTreeNodeImpl _$$FileTreeNodeImplFromJson(Map<String, dynamic> json) =>
    _$FileTreeNodeImpl(
      name: json['name'] as String,
      path: json['path'] as String,
      type: $enumDecode(_$FileNodeTypeEnumMap, json['type']),
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => FileTreeNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      size: (json['size'] as num?)?.toInt(),
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
      content: json['content'] as String?,
    );

Map<String, dynamic> _$$FileTreeNodeImplToJson(_$FileTreeNodeImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
      'type': _$FileNodeTypeEnumMap[instance.type]!,
      'children': instance.children,
      'size': instance.size,
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'content': instance.content,
    };

const _$FileNodeTypeEnumMap = {
  FileNodeType.file: 'file',
  FileNodeType.directory: 'directory',
};
