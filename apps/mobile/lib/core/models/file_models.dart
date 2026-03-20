import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_models.freezed.dart';
part 'file_models.g.dart';

enum FileNodeType { file, directory }

@freezed
class FileTreeNode with _$FileTreeNode {
  const factory FileTreeNode({
    required String name,
    required String path,
    required FileNodeType type,
    List<FileTreeNode>? children,
    int? size,
    DateTime? modifiedAt,
    String? content,
  }) = _FileTreeNode;

  factory FileTreeNode.fromJson(Map<String, dynamic> json) =>
      _$FileTreeNodeFromJson(json);
}
