// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FileTreeNode _$FileTreeNodeFromJson(Map<String, dynamic> json) {
  return _FileTreeNode.fromJson(json);
}

/// @nodoc
mixin _$FileTreeNode {
  String get name => throw _privateConstructorUsedError;
  String get path => throw _privateConstructorUsedError;
  FileNodeType get type => throw _privateConstructorUsedError;
  List<FileTreeNode>? get children => throw _privateConstructorUsedError;
  int? get size => throw _privateConstructorUsedError;
  DateTime? get modifiedAt => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError;

  /// Serializes this FileTreeNode to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FileTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FileTreeNodeCopyWith<FileTreeNode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FileTreeNodeCopyWith<$Res> {
  factory $FileTreeNodeCopyWith(
          FileTreeNode value, $Res Function(FileTreeNode) then) =
      _$FileTreeNodeCopyWithImpl<$Res, FileTreeNode>;
  @useResult
  $Res call(
      {String name,
      String path,
      FileNodeType type,
      List<FileTreeNode>? children,
      int? size,
      DateTime? modifiedAt,
      String? content});
}

/// @nodoc
class _$FileTreeNodeCopyWithImpl<$Res, $Val extends FileTreeNode>
    implements $FileTreeNodeCopyWith<$Res> {
  _$FileTreeNodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FileTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? path = null,
    Object? type = null,
    Object? children = freezed,
    Object? size = freezed,
    Object? modifiedAt = freezed,
    Object? content = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as FileNodeType,
      children: freezed == children
          ? _value.children
          : children // ignore: cast_nullable_to_non_nullable
              as List<FileTreeNode>?,
      size: freezed == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int?,
      modifiedAt: freezed == modifiedAt
          ? _value.modifiedAt
          : modifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FileTreeNodeImplCopyWith<$Res>
    implements $FileTreeNodeCopyWith<$Res> {
  factory _$$FileTreeNodeImplCopyWith(
          _$FileTreeNodeImpl value, $Res Function(_$FileTreeNodeImpl) then) =
      __$$FileTreeNodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String path,
      FileNodeType type,
      List<FileTreeNode>? children,
      int? size,
      DateTime? modifiedAt,
      String? content});
}

/// @nodoc
class __$$FileTreeNodeImplCopyWithImpl<$Res>
    extends _$FileTreeNodeCopyWithImpl<$Res, _$FileTreeNodeImpl>
    implements _$$FileTreeNodeImplCopyWith<$Res> {
  __$$FileTreeNodeImplCopyWithImpl(
      _$FileTreeNodeImpl _value, $Res Function(_$FileTreeNodeImpl) _then)
      : super(_value, _then);

  /// Create a copy of FileTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? path = null,
    Object? type = null,
    Object? children = freezed,
    Object? size = freezed,
    Object? modifiedAt = freezed,
    Object? content = freezed,
  }) {
    return _then(_$FileTreeNodeImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as FileNodeType,
      children: freezed == children
          ? _value._children
          : children // ignore: cast_nullable_to_non_nullable
              as List<FileTreeNode>?,
      size: freezed == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int?,
      modifiedAt: freezed == modifiedAt
          ? _value.modifiedAt
          : modifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FileTreeNodeImpl implements _FileTreeNode {
  const _$FileTreeNodeImpl(
      {required this.name,
      required this.path,
      required this.type,
      final List<FileTreeNode>? children,
      this.size,
      this.modifiedAt,
      this.content})
      : _children = children;

  factory _$FileTreeNodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$FileTreeNodeImplFromJson(json);

  @override
  final String name;
  @override
  final String path;
  @override
  final FileNodeType type;
  final List<FileTreeNode>? _children;
  @override
  List<FileTreeNode>? get children {
    final value = _children;
    if (value == null) return null;
    if (_children is EqualUnmodifiableListView) return _children;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final int? size;
  @override
  final DateTime? modifiedAt;
  @override
  final String? content;

  @override
  String toString() {
    return 'FileTreeNode(name: $name, path: $path, type: $type, children: $children, size: $size, modifiedAt: $modifiedAt, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileTreeNodeImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._children, _children) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.modifiedAt, modifiedAt) ||
                other.modifiedAt == modifiedAt) &&
            (identical(other.content, content) || other.content == content));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      path,
      type,
      const DeepCollectionEquality().hash(_children),
      size,
      modifiedAt,
      content);

  /// Create a copy of FileTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FileTreeNodeImplCopyWith<_$FileTreeNodeImpl> get copyWith =>
      __$$FileTreeNodeImplCopyWithImpl<_$FileTreeNodeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FileTreeNodeImplToJson(
      this,
    );
  }
}

abstract class _FileTreeNode implements FileTreeNode {
  const factory _FileTreeNode(
      {required final String name,
      required final String path,
      required final FileNodeType type,
      final List<FileTreeNode>? children,
      final int? size,
      final DateTime? modifiedAt,
      final String? content}) = _$FileTreeNodeImpl;

  factory _FileTreeNode.fromJson(Map<String, dynamic> json) =
      _$FileTreeNodeImpl.fromJson;

  @override
  String get name;
  @override
  String get path;
  @override
  FileNodeType get type;
  @override
  List<FileTreeNode>? get children;
  @override
  int? get size;
  @override
  DateTime? get modifiedAt;
  @override
  String? get content;

  /// Create a copy of FileTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FileTreeNodeImplCopyWith<_$FileTreeNodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
