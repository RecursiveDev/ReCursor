// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'git_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GitStatus _$GitStatusFromJson(Map<String, dynamic> json) {
  return _GitStatus.fromJson(json);
}

/// @nodoc
mixin _$GitStatus {
  String get branch => throw _privateConstructorUsedError;
  List<GitFileChange> get changes => throw _privateConstructorUsedError;
  int get ahead => throw _privateConstructorUsedError;
  int get behind => throw _privateConstructorUsedError;
  bool get isClean => throw _privateConstructorUsedError;

  /// Serializes this GitStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GitStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GitStatusCopyWith<GitStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GitStatusCopyWith<$Res> {
  factory $GitStatusCopyWith(GitStatus value, $Res Function(GitStatus) then) =
      _$GitStatusCopyWithImpl<$Res, GitStatus>;
  @useResult
  $Res call(
      {String branch,
      List<GitFileChange> changes,
      int ahead,
      int behind,
      bool isClean});
}

/// @nodoc
class _$GitStatusCopyWithImpl<$Res, $Val extends GitStatus>
    implements $GitStatusCopyWith<$Res> {
  _$GitStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GitStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? branch = null,
    Object? changes = null,
    Object? ahead = null,
    Object? behind = null,
    Object? isClean = null,
  }) {
    return _then(_value.copyWith(
      branch: null == branch
          ? _value.branch
          : branch // ignore: cast_nullable_to_non_nullable
              as String,
      changes: null == changes
          ? _value.changes
          : changes // ignore: cast_nullable_to_non_nullable
              as List<GitFileChange>,
      ahead: null == ahead
          ? _value.ahead
          : ahead // ignore: cast_nullable_to_non_nullable
              as int,
      behind: null == behind
          ? _value.behind
          : behind // ignore: cast_nullable_to_non_nullable
              as int,
      isClean: null == isClean
          ? _value.isClean
          : isClean // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GitStatusImplCopyWith<$Res>
    implements $GitStatusCopyWith<$Res> {
  factory _$$GitStatusImplCopyWith(
          _$GitStatusImpl value, $Res Function(_$GitStatusImpl) then) =
      __$$GitStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String branch,
      List<GitFileChange> changes,
      int ahead,
      int behind,
      bool isClean});
}

/// @nodoc
class __$$GitStatusImplCopyWithImpl<$Res>
    extends _$GitStatusCopyWithImpl<$Res, _$GitStatusImpl>
    implements _$$GitStatusImplCopyWith<$Res> {
  __$$GitStatusImplCopyWithImpl(
      _$GitStatusImpl _value, $Res Function(_$GitStatusImpl) _then)
      : super(_value, _then);

  /// Create a copy of GitStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? branch = null,
    Object? changes = null,
    Object? ahead = null,
    Object? behind = null,
    Object? isClean = null,
  }) {
    return _then(_$GitStatusImpl(
      branch: null == branch
          ? _value.branch
          : branch // ignore: cast_nullable_to_non_nullable
              as String,
      changes: null == changes
          ? _value._changes
          : changes // ignore: cast_nullable_to_non_nullable
              as List<GitFileChange>,
      ahead: null == ahead
          ? _value.ahead
          : ahead // ignore: cast_nullable_to_non_nullable
              as int,
      behind: null == behind
          ? _value.behind
          : behind // ignore: cast_nullable_to_non_nullable
              as int,
      isClean: null == isClean
          ? _value.isClean
          : isClean // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GitStatusImpl implements _GitStatus {
  const _$GitStatusImpl(
      {required this.branch,
      required final List<GitFileChange> changes,
      required this.ahead,
      required this.behind,
      required this.isClean})
      : _changes = changes;

  factory _$GitStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$GitStatusImplFromJson(json);

  @override
  final String branch;
  final List<GitFileChange> _changes;
  @override
  List<GitFileChange> get changes {
    if (_changes is EqualUnmodifiableListView) return _changes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_changes);
  }

  @override
  final int ahead;
  @override
  final int behind;
  @override
  final bool isClean;

  @override
  String toString() {
    return 'GitStatus(branch: $branch, changes: $changes, ahead: $ahead, behind: $behind, isClean: $isClean)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GitStatusImpl &&
            (identical(other.branch, branch) || other.branch == branch) &&
            const DeepCollectionEquality().equals(other._changes, _changes) &&
            (identical(other.ahead, ahead) || other.ahead == ahead) &&
            (identical(other.behind, behind) || other.behind == behind) &&
            (identical(other.isClean, isClean) || other.isClean == isClean));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, branch,
      const DeepCollectionEquality().hash(_changes), ahead, behind, isClean);

  /// Create a copy of GitStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GitStatusImplCopyWith<_$GitStatusImpl> get copyWith =>
      __$$GitStatusImplCopyWithImpl<_$GitStatusImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GitStatusImplToJson(
      this,
    );
  }
}

abstract class _GitStatus implements GitStatus {
  const factory _GitStatus(
      {required final String branch,
      required final List<GitFileChange> changes,
      required final int ahead,
      required final int behind,
      required final bool isClean}) = _$GitStatusImpl;

  factory _GitStatus.fromJson(Map<String, dynamic> json) =
      _$GitStatusImpl.fromJson;

  @override
  String get branch;
  @override
  List<GitFileChange> get changes;
  @override
  int get ahead;
  @override
  int get behind;
  @override
  bool get isClean;

  /// Create a copy of GitStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GitStatusImplCopyWith<_$GitStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GitFileChange _$GitFileChangeFromJson(Map<String, dynamic> json) {
  return _GitFileChange.fromJson(json);
}

/// @nodoc
mixin _$GitFileChange {
  String get path => throw _privateConstructorUsedError;
  FileChangeStatus get status => throw _privateConstructorUsedError;
  int? get additions => throw _privateConstructorUsedError;
  int? get deletions => throw _privateConstructorUsedError;
  String? get diff => throw _privateConstructorUsedError;

  /// Serializes this GitFileChange to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GitFileChange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GitFileChangeCopyWith<GitFileChange> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GitFileChangeCopyWith<$Res> {
  factory $GitFileChangeCopyWith(
          GitFileChange value, $Res Function(GitFileChange) then) =
      _$GitFileChangeCopyWithImpl<$Res, GitFileChange>;
  @useResult
  $Res call(
      {String path,
      FileChangeStatus status,
      int? additions,
      int? deletions,
      String? diff});
}

/// @nodoc
class _$GitFileChangeCopyWithImpl<$Res, $Val extends GitFileChange>
    implements $GitFileChangeCopyWith<$Res> {
  _$GitFileChangeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GitFileChange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? status = null,
    Object? additions = freezed,
    Object? deletions = freezed,
    Object? diff = freezed,
  }) {
    return _then(_value.copyWith(
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as FileChangeStatus,
      additions: freezed == additions
          ? _value.additions
          : additions // ignore: cast_nullable_to_non_nullable
              as int?,
      deletions: freezed == deletions
          ? _value.deletions
          : deletions // ignore: cast_nullable_to_non_nullable
              as int?,
      diff: freezed == diff
          ? _value.diff
          : diff // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GitFileChangeImplCopyWith<$Res>
    implements $GitFileChangeCopyWith<$Res> {
  factory _$$GitFileChangeImplCopyWith(
          _$GitFileChangeImpl value, $Res Function(_$GitFileChangeImpl) then) =
      __$$GitFileChangeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String path,
      FileChangeStatus status,
      int? additions,
      int? deletions,
      String? diff});
}

/// @nodoc
class __$$GitFileChangeImplCopyWithImpl<$Res>
    extends _$GitFileChangeCopyWithImpl<$Res, _$GitFileChangeImpl>
    implements _$$GitFileChangeImplCopyWith<$Res> {
  __$$GitFileChangeImplCopyWithImpl(
      _$GitFileChangeImpl _value, $Res Function(_$GitFileChangeImpl) _then)
      : super(_value, _then);

  /// Create a copy of GitFileChange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? status = null,
    Object? additions = freezed,
    Object? deletions = freezed,
    Object? diff = freezed,
  }) {
    return _then(_$GitFileChangeImpl(
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as FileChangeStatus,
      additions: freezed == additions
          ? _value.additions
          : additions // ignore: cast_nullable_to_non_nullable
              as int?,
      deletions: freezed == deletions
          ? _value.deletions
          : deletions // ignore: cast_nullable_to_non_nullable
              as int?,
      diff: freezed == diff
          ? _value.diff
          : diff // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GitFileChangeImpl implements _GitFileChange {
  const _$GitFileChangeImpl(
      {required this.path,
      required this.status,
      this.additions,
      this.deletions,
      this.diff});

  factory _$GitFileChangeImpl.fromJson(Map<String, dynamic> json) =>
      _$$GitFileChangeImplFromJson(json);

  @override
  final String path;
  @override
  final FileChangeStatus status;
  @override
  final int? additions;
  @override
  final int? deletions;
  @override
  final String? diff;

  @override
  String toString() {
    return 'GitFileChange(path: $path, status: $status, additions: $additions, deletions: $deletions, diff: $diff)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GitFileChangeImpl &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.additions, additions) ||
                other.additions == additions) &&
            (identical(other.deletions, deletions) ||
                other.deletions == deletions) &&
            (identical(other.diff, diff) || other.diff == diff));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, path, status, additions, deletions, diff);

  /// Create a copy of GitFileChange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GitFileChangeImplCopyWith<_$GitFileChangeImpl> get copyWith =>
      __$$GitFileChangeImplCopyWithImpl<_$GitFileChangeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GitFileChangeImplToJson(
      this,
    );
  }
}

abstract class _GitFileChange implements GitFileChange {
  const factory _GitFileChange(
      {required final String path,
      required final FileChangeStatus status,
      final int? additions,
      final int? deletions,
      final String? diff}) = _$GitFileChangeImpl;

  factory _GitFileChange.fromJson(Map<String, dynamic> json) =
      _$GitFileChangeImpl.fromJson;

  @override
  String get path;
  @override
  FileChangeStatus get status;
  @override
  int? get additions;
  @override
  int? get deletions;
  @override
  String? get diff;

  /// Create a copy of GitFileChange
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GitFileChangeImplCopyWith<_$GitFileChangeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GitBranch _$GitBranchFromJson(Map<String, dynamic> json) {
  return _GitBranch.fromJson(json);
}

/// @nodoc
mixin _$GitBranch {
  String get name => throw _privateConstructorUsedError;
  bool get isCurrent => throw _privateConstructorUsedError;
  String? get upstream => throw _privateConstructorUsedError;
  int? get ahead => throw _privateConstructorUsedError;
  int? get behind => throw _privateConstructorUsedError;

  /// Serializes this GitBranch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GitBranch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GitBranchCopyWith<GitBranch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GitBranchCopyWith<$Res> {
  factory $GitBranchCopyWith(GitBranch value, $Res Function(GitBranch) then) =
      _$GitBranchCopyWithImpl<$Res, GitBranch>;
  @useResult
  $Res call(
      {String name, bool isCurrent, String? upstream, int? ahead, int? behind});
}

/// @nodoc
class _$GitBranchCopyWithImpl<$Res, $Val extends GitBranch>
    implements $GitBranchCopyWith<$Res> {
  _$GitBranchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GitBranch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? isCurrent = null,
    Object? upstream = freezed,
    Object? ahead = freezed,
    Object? behind = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      isCurrent: null == isCurrent
          ? _value.isCurrent
          : isCurrent // ignore: cast_nullable_to_non_nullable
              as bool,
      upstream: freezed == upstream
          ? _value.upstream
          : upstream // ignore: cast_nullable_to_non_nullable
              as String?,
      ahead: freezed == ahead
          ? _value.ahead
          : ahead // ignore: cast_nullable_to_non_nullable
              as int?,
      behind: freezed == behind
          ? _value.behind
          : behind // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GitBranchImplCopyWith<$Res>
    implements $GitBranchCopyWith<$Res> {
  factory _$$GitBranchImplCopyWith(
          _$GitBranchImpl value, $Res Function(_$GitBranchImpl) then) =
      __$$GitBranchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name, bool isCurrent, String? upstream, int? ahead, int? behind});
}

/// @nodoc
class __$$GitBranchImplCopyWithImpl<$Res>
    extends _$GitBranchCopyWithImpl<$Res, _$GitBranchImpl>
    implements _$$GitBranchImplCopyWith<$Res> {
  __$$GitBranchImplCopyWithImpl(
      _$GitBranchImpl _value, $Res Function(_$GitBranchImpl) _then)
      : super(_value, _then);

  /// Create a copy of GitBranch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? isCurrent = null,
    Object? upstream = freezed,
    Object? ahead = freezed,
    Object? behind = freezed,
  }) {
    return _then(_$GitBranchImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      isCurrent: null == isCurrent
          ? _value.isCurrent
          : isCurrent // ignore: cast_nullable_to_non_nullable
              as bool,
      upstream: freezed == upstream
          ? _value.upstream
          : upstream // ignore: cast_nullable_to_non_nullable
              as String?,
      ahead: freezed == ahead
          ? _value.ahead
          : ahead // ignore: cast_nullable_to_non_nullable
              as int?,
      behind: freezed == behind
          ? _value.behind
          : behind // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GitBranchImpl implements _GitBranch {
  const _$GitBranchImpl(
      {required this.name,
      required this.isCurrent,
      this.upstream,
      this.ahead,
      this.behind});

  factory _$GitBranchImpl.fromJson(Map<String, dynamic> json) =>
      _$$GitBranchImplFromJson(json);

  @override
  final String name;
  @override
  final bool isCurrent;
  @override
  final String? upstream;
  @override
  final int? ahead;
  @override
  final int? behind;

  @override
  String toString() {
    return 'GitBranch(name: $name, isCurrent: $isCurrent, upstream: $upstream, ahead: $ahead, behind: $behind)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GitBranchImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isCurrent, isCurrent) ||
                other.isCurrent == isCurrent) &&
            (identical(other.upstream, upstream) ||
                other.upstream == upstream) &&
            (identical(other.ahead, ahead) || other.ahead == ahead) &&
            (identical(other.behind, behind) || other.behind == behind));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, isCurrent, upstream, ahead, behind);

  /// Create a copy of GitBranch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GitBranchImplCopyWith<_$GitBranchImpl> get copyWith =>
      __$$GitBranchImplCopyWithImpl<_$GitBranchImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GitBranchImplToJson(
      this,
    );
  }
}

abstract class _GitBranch implements GitBranch {
  const factory _GitBranch(
      {required final String name,
      required final bool isCurrent,
      final String? upstream,
      final int? ahead,
      final int? behind}) = _$GitBranchImpl;

  factory _GitBranch.fromJson(Map<String, dynamic> json) =
      _$GitBranchImpl.fromJson;

  @override
  String get name;
  @override
  bool get isCurrent;
  @override
  String? get upstream;
  @override
  int? get ahead;
  @override
  int? get behind;

  /// Create a copy of GitBranch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GitBranchImplCopyWith<_$GitBranchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DiffFile _$DiffFileFromJson(Map<String, dynamic> json) {
  return _DiffFile.fromJson(json);
}

/// @nodoc
mixin _$DiffFile {
  String get path => throw _privateConstructorUsedError;
  String get oldPath => throw _privateConstructorUsedError;
  String get newPath => throw _privateConstructorUsedError;
  FileChangeStatus get status => throw _privateConstructorUsedError;
  int get additions => throw _privateConstructorUsedError;
  int get deletions => throw _privateConstructorUsedError;
  List<DiffHunk> get hunks => throw _privateConstructorUsedError;
  String? get oldMode => throw _privateConstructorUsedError;
  String? get newMode => throw _privateConstructorUsedError;

  /// Serializes this DiffFile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DiffFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiffFileCopyWith<DiffFile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiffFileCopyWith<$Res> {
  factory $DiffFileCopyWith(DiffFile value, $Res Function(DiffFile) then) =
      _$DiffFileCopyWithImpl<$Res, DiffFile>;
  @useResult
  $Res call(
      {String path,
      String oldPath,
      String newPath,
      FileChangeStatus status,
      int additions,
      int deletions,
      List<DiffHunk> hunks,
      String? oldMode,
      String? newMode});
}

/// @nodoc
class _$DiffFileCopyWithImpl<$Res, $Val extends DiffFile>
    implements $DiffFileCopyWith<$Res> {
  _$DiffFileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiffFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? oldPath = null,
    Object? newPath = null,
    Object? status = null,
    Object? additions = null,
    Object? deletions = null,
    Object? hunks = null,
    Object? oldMode = freezed,
    Object? newMode = freezed,
  }) {
    return _then(_value.copyWith(
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      oldPath: null == oldPath
          ? _value.oldPath
          : oldPath // ignore: cast_nullable_to_non_nullable
              as String,
      newPath: null == newPath
          ? _value.newPath
          : newPath // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as FileChangeStatus,
      additions: null == additions
          ? _value.additions
          : additions // ignore: cast_nullable_to_non_nullable
              as int,
      deletions: null == deletions
          ? _value.deletions
          : deletions // ignore: cast_nullable_to_non_nullable
              as int,
      hunks: null == hunks
          ? _value.hunks
          : hunks // ignore: cast_nullable_to_non_nullable
              as List<DiffHunk>,
      oldMode: freezed == oldMode
          ? _value.oldMode
          : oldMode // ignore: cast_nullable_to_non_nullable
              as String?,
      newMode: freezed == newMode
          ? _value.newMode
          : newMode // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiffFileImplCopyWith<$Res>
    implements $DiffFileCopyWith<$Res> {
  factory _$$DiffFileImplCopyWith(
          _$DiffFileImpl value, $Res Function(_$DiffFileImpl) then) =
      __$$DiffFileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String path,
      String oldPath,
      String newPath,
      FileChangeStatus status,
      int additions,
      int deletions,
      List<DiffHunk> hunks,
      String? oldMode,
      String? newMode});
}

/// @nodoc
class __$$DiffFileImplCopyWithImpl<$Res>
    extends _$DiffFileCopyWithImpl<$Res, _$DiffFileImpl>
    implements _$$DiffFileImplCopyWith<$Res> {
  __$$DiffFileImplCopyWithImpl(
      _$DiffFileImpl _value, $Res Function(_$DiffFileImpl) _then)
      : super(_value, _then);

  /// Create a copy of DiffFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? oldPath = null,
    Object? newPath = null,
    Object? status = null,
    Object? additions = null,
    Object? deletions = null,
    Object? hunks = null,
    Object? oldMode = freezed,
    Object? newMode = freezed,
  }) {
    return _then(_$DiffFileImpl(
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      oldPath: null == oldPath
          ? _value.oldPath
          : oldPath // ignore: cast_nullable_to_non_nullable
              as String,
      newPath: null == newPath
          ? _value.newPath
          : newPath // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as FileChangeStatus,
      additions: null == additions
          ? _value.additions
          : additions // ignore: cast_nullable_to_non_nullable
              as int,
      deletions: null == deletions
          ? _value.deletions
          : deletions // ignore: cast_nullable_to_non_nullable
              as int,
      hunks: null == hunks
          ? _value._hunks
          : hunks // ignore: cast_nullable_to_non_nullable
              as List<DiffHunk>,
      oldMode: freezed == oldMode
          ? _value.oldMode
          : oldMode // ignore: cast_nullable_to_non_nullable
              as String?,
      newMode: freezed == newMode
          ? _value.newMode
          : newMode // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DiffFileImpl implements _DiffFile {
  const _$DiffFileImpl(
      {required this.path,
      required this.oldPath,
      required this.newPath,
      required this.status,
      required this.additions,
      required this.deletions,
      required final List<DiffHunk> hunks,
      this.oldMode,
      this.newMode})
      : _hunks = hunks;

  factory _$DiffFileImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiffFileImplFromJson(json);

  @override
  final String path;
  @override
  final String oldPath;
  @override
  final String newPath;
  @override
  final FileChangeStatus status;
  @override
  final int additions;
  @override
  final int deletions;
  final List<DiffHunk> _hunks;
  @override
  List<DiffHunk> get hunks {
    if (_hunks is EqualUnmodifiableListView) return _hunks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hunks);
  }

  @override
  final String? oldMode;
  @override
  final String? newMode;

  @override
  String toString() {
    return 'DiffFile(path: $path, oldPath: $oldPath, newPath: $newPath, status: $status, additions: $additions, deletions: $deletions, hunks: $hunks, oldMode: $oldMode, newMode: $newMode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiffFileImpl &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.oldPath, oldPath) || other.oldPath == oldPath) &&
            (identical(other.newPath, newPath) || other.newPath == newPath) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.additions, additions) ||
                other.additions == additions) &&
            (identical(other.deletions, deletions) ||
                other.deletions == deletions) &&
            const DeepCollectionEquality().equals(other._hunks, _hunks) &&
            (identical(other.oldMode, oldMode) || other.oldMode == oldMode) &&
            (identical(other.newMode, newMode) || other.newMode == newMode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      path,
      oldPath,
      newPath,
      status,
      additions,
      deletions,
      const DeepCollectionEquality().hash(_hunks),
      oldMode,
      newMode);

  /// Create a copy of DiffFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiffFileImplCopyWith<_$DiffFileImpl> get copyWith =>
      __$$DiffFileImplCopyWithImpl<_$DiffFileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiffFileImplToJson(
      this,
    );
  }
}

abstract class _DiffFile implements DiffFile {
  const factory _DiffFile(
      {required final String path,
      required final String oldPath,
      required final String newPath,
      required final FileChangeStatus status,
      required final int additions,
      required final int deletions,
      required final List<DiffHunk> hunks,
      final String? oldMode,
      final String? newMode}) = _$DiffFileImpl;

  factory _DiffFile.fromJson(Map<String, dynamic> json) =
      _$DiffFileImpl.fromJson;

  @override
  String get path;
  @override
  String get oldPath;
  @override
  String get newPath;
  @override
  FileChangeStatus get status;
  @override
  int get additions;
  @override
  int get deletions;
  @override
  List<DiffHunk> get hunks;
  @override
  String? get oldMode;
  @override
  String? get newMode;

  /// Create a copy of DiffFile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiffFileImplCopyWith<_$DiffFileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DiffHunk _$DiffHunkFromJson(Map<String, dynamic> json) {
  return _DiffHunk.fromJson(json);
}

/// @nodoc
mixin _$DiffHunk {
  String get header => throw _privateConstructorUsedError;
  int get oldStart => throw _privateConstructorUsedError;
  int get oldLines => throw _privateConstructorUsedError;
  int get newStart => throw _privateConstructorUsedError;
  int get newLines => throw _privateConstructorUsedError;
  List<DiffLine> get lines => throw _privateConstructorUsedError;

  /// Serializes this DiffHunk to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DiffHunk
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiffHunkCopyWith<DiffHunk> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiffHunkCopyWith<$Res> {
  factory $DiffHunkCopyWith(DiffHunk value, $Res Function(DiffHunk) then) =
      _$DiffHunkCopyWithImpl<$Res, DiffHunk>;
  @useResult
  $Res call(
      {String header,
      int oldStart,
      int oldLines,
      int newStart,
      int newLines,
      List<DiffLine> lines});
}

/// @nodoc
class _$DiffHunkCopyWithImpl<$Res, $Val extends DiffHunk>
    implements $DiffHunkCopyWith<$Res> {
  _$DiffHunkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiffHunk
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? header = null,
    Object? oldStart = null,
    Object? oldLines = null,
    Object? newStart = null,
    Object? newLines = null,
    Object? lines = null,
  }) {
    return _then(_value.copyWith(
      header: null == header
          ? _value.header
          : header // ignore: cast_nullable_to_non_nullable
              as String,
      oldStart: null == oldStart
          ? _value.oldStart
          : oldStart // ignore: cast_nullable_to_non_nullable
              as int,
      oldLines: null == oldLines
          ? _value.oldLines
          : oldLines // ignore: cast_nullable_to_non_nullable
              as int,
      newStart: null == newStart
          ? _value.newStart
          : newStart // ignore: cast_nullable_to_non_nullable
              as int,
      newLines: null == newLines
          ? _value.newLines
          : newLines // ignore: cast_nullable_to_non_nullable
              as int,
      lines: null == lines
          ? _value.lines
          : lines // ignore: cast_nullable_to_non_nullable
              as List<DiffLine>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiffHunkImplCopyWith<$Res>
    implements $DiffHunkCopyWith<$Res> {
  factory _$$DiffHunkImplCopyWith(
          _$DiffHunkImpl value, $Res Function(_$DiffHunkImpl) then) =
      __$$DiffHunkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String header,
      int oldStart,
      int oldLines,
      int newStart,
      int newLines,
      List<DiffLine> lines});
}

/// @nodoc
class __$$DiffHunkImplCopyWithImpl<$Res>
    extends _$DiffHunkCopyWithImpl<$Res, _$DiffHunkImpl>
    implements _$$DiffHunkImplCopyWith<$Res> {
  __$$DiffHunkImplCopyWithImpl(
      _$DiffHunkImpl _value, $Res Function(_$DiffHunkImpl) _then)
      : super(_value, _then);

  /// Create a copy of DiffHunk
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? header = null,
    Object? oldStart = null,
    Object? oldLines = null,
    Object? newStart = null,
    Object? newLines = null,
    Object? lines = null,
  }) {
    return _then(_$DiffHunkImpl(
      header: null == header
          ? _value.header
          : header // ignore: cast_nullable_to_non_nullable
              as String,
      oldStart: null == oldStart
          ? _value.oldStart
          : oldStart // ignore: cast_nullable_to_non_nullable
              as int,
      oldLines: null == oldLines
          ? _value.oldLines
          : oldLines // ignore: cast_nullable_to_non_nullable
              as int,
      newStart: null == newStart
          ? _value.newStart
          : newStart // ignore: cast_nullable_to_non_nullable
              as int,
      newLines: null == newLines
          ? _value.newLines
          : newLines // ignore: cast_nullable_to_non_nullable
              as int,
      lines: null == lines
          ? _value._lines
          : lines // ignore: cast_nullable_to_non_nullable
              as List<DiffLine>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DiffHunkImpl implements _DiffHunk {
  const _$DiffHunkImpl(
      {required this.header,
      required this.oldStart,
      required this.oldLines,
      required this.newStart,
      required this.newLines,
      required final List<DiffLine> lines})
      : _lines = lines;

  factory _$DiffHunkImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiffHunkImplFromJson(json);

  @override
  final String header;
  @override
  final int oldStart;
  @override
  final int oldLines;
  @override
  final int newStart;
  @override
  final int newLines;
  final List<DiffLine> _lines;
  @override
  List<DiffLine> get lines {
    if (_lines is EqualUnmodifiableListView) return _lines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lines);
  }

  @override
  String toString() {
    return 'DiffHunk(header: $header, oldStart: $oldStart, oldLines: $oldLines, newStart: $newStart, newLines: $newLines, lines: $lines)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiffHunkImpl &&
            (identical(other.header, header) || other.header == header) &&
            (identical(other.oldStart, oldStart) ||
                other.oldStart == oldStart) &&
            (identical(other.oldLines, oldLines) ||
                other.oldLines == oldLines) &&
            (identical(other.newStart, newStart) ||
                other.newStart == newStart) &&
            (identical(other.newLines, newLines) ||
                other.newLines == newLines) &&
            const DeepCollectionEquality().equals(other._lines, _lines));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, header, oldStart, oldLines,
      newStart, newLines, const DeepCollectionEquality().hash(_lines));

  /// Create a copy of DiffHunk
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiffHunkImplCopyWith<_$DiffHunkImpl> get copyWith =>
      __$$DiffHunkImplCopyWithImpl<_$DiffHunkImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiffHunkImplToJson(
      this,
    );
  }
}

abstract class _DiffHunk implements DiffHunk {
  const factory _DiffHunk(
      {required final String header,
      required final int oldStart,
      required final int oldLines,
      required final int newStart,
      required final int newLines,
      required final List<DiffLine> lines}) = _$DiffHunkImpl;

  factory _DiffHunk.fromJson(Map<String, dynamic> json) =
      _$DiffHunkImpl.fromJson;

  @override
  String get header;
  @override
  int get oldStart;
  @override
  int get oldLines;
  @override
  int get newStart;
  @override
  int get newLines;
  @override
  List<DiffLine> get lines;

  /// Create a copy of DiffHunk
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiffHunkImplCopyWith<_$DiffHunkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DiffLine _$DiffLineFromJson(Map<String, dynamic> json) {
  return _DiffLine.fromJson(json);
}

/// @nodoc
mixin _$DiffLine {
  DiffLineType get type => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  int? get oldLineNumber => throw _privateConstructorUsedError;
  int? get newLineNumber => throw _privateConstructorUsedError;

  /// Serializes this DiffLine to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DiffLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiffLineCopyWith<DiffLine> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiffLineCopyWith<$Res> {
  factory $DiffLineCopyWith(DiffLine value, $Res Function(DiffLine) then) =
      _$DiffLineCopyWithImpl<$Res, DiffLine>;
  @useResult
  $Res call(
      {DiffLineType type,
      String content,
      int? oldLineNumber,
      int? newLineNumber});
}

/// @nodoc
class _$DiffLineCopyWithImpl<$Res, $Val extends DiffLine>
    implements $DiffLineCopyWith<$Res> {
  _$DiffLineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiffLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? content = null,
    Object? oldLineNumber = freezed,
    Object? newLineNumber = freezed,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as DiffLineType,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      oldLineNumber: freezed == oldLineNumber
          ? _value.oldLineNumber
          : oldLineNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      newLineNumber: freezed == newLineNumber
          ? _value.newLineNumber
          : newLineNumber // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiffLineImplCopyWith<$Res>
    implements $DiffLineCopyWith<$Res> {
  factory _$$DiffLineImplCopyWith(
          _$DiffLineImpl value, $Res Function(_$DiffLineImpl) then) =
      __$$DiffLineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DiffLineType type,
      String content,
      int? oldLineNumber,
      int? newLineNumber});
}

/// @nodoc
class __$$DiffLineImplCopyWithImpl<$Res>
    extends _$DiffLineCopyWithImpl<$Res, _$DiffLineImpl>
    implements _$$DiffLineImplCopyWith<$Res> {
  __$$DiffLineImplCopyWithImpl(
      _$DiffLineImpl _value, $Res Function(_$DiffLineImpl) _then)
      : super(_value, _then);

  /// Create a copy of DiffLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? content = null,
    Object? oldLineNumber = freezed,
    Object? newLineNumber = freezed,
  }) {
    return _then(_$DiffLineImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as DiffLineType,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      oldLineNumber: freezed == oldLineNumber
          ? _value.oldLineNumber
          : oldLineNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      newLineNumber: freezed == newLineNumber
          ? _value.newLineNumber
          : newLineNumber // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DiffLineImpl implements _DiffLine {
  const _$DiffLineImpl(
      {required this.type,
      required this.content,
      this.oldLineNumber,
      this.newLineNumber});

  factory _$DiffLineImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiffLineImplFromJson(json);

  @override
  final DiffLineType type;
  @override
  final String content;
  @override
  final int? oldLineNumber;
  @override
  final int? newLineNumber;

  @override
  String toString() {
    return 'DiffLine(type: $type, content: $content, oldLineNumber: $oldLineNumber, newLineNumber: $newLineNumber)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiffLineImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.oldLineNumber, oldLineNumber) ||
                other.oldLineNumber == oldLineNumber) &&
            (identical(other.newLineNumber, newLineNumber) ||
                other.newLineNumber == newLineNumber));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, type, content, oldLineNumber, newLineNumber);

  /// Create a copy of DiffLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiffLineImplCopyWith<_$DiffLineImpl> get copyWith =>
      __$$DiffLineImplCopyWithImpl<_$DiffLineImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiffLineImplToJson(
      this,
    );
  }
}

abstract class _DiffLine implements DiffLine {
  const factory _DiffLine(
      {required final DiffLineType type,
      required final String content,
      final int? oldLineNumber,
      final int? newLineNumber}) = _$DiffLineImpl;

  factory _DiffLine.fromJson(Map<String, dynamic> json) =
      _$DiffLineImpl.fromJson;

  @override
  DiffLineType get type;
  @override
  String get content;
  @override
  int? get oldLineNumber;
  @override
  int? get newLineNumber;

  /// Create a copy of DiffLine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiffLineImplCopyWith<_$DiffLineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
