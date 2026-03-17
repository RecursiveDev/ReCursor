// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'agent_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AgentConfig _$AgentConfigFromJson(Map<String, dynamic> json) {
  return _AgentConfig.fromJson(json);
}

/// @nodoc
mixin _$AgentConfig {
  String get id => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  AgentType get type => throw _privateConstructorUsedError;
  String get bridgeUrl => throw _privateConstructorUsedError;
  String get authToken => throw _privateConstructorUsedError;
  String? get workingDirectory => throw _privateConstructorUsedError;
  AgentConnectionStatus get status => throw _privateConstructorUsedError;
  DateTime? get lastConnectedAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this AgentConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AgentConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AgentConfigCopyWith<AgentConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AgentConfigCopyWith<$Res> {
  factory $AgentConfigCopyWith(
          AgentConfig value, $Res Function(AgentConfig) then) =
      _$AgentConfigCopyWithImpl<$Res, AgentConfig>;
  @useResult
  $Res call(
      {String id,
      String displayName,
      AgentType type,
      String bridgeUrl,
      String authToken,
      String? workingDirectory,
      AgentConnectionStatus status,
      DateTime? lastConnectedAt,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$AgentConfigCopyWithImpl<$Res, $Val extends AgentConfig>
    implements $AgentConfigCopyWith<$Res> {
  _$AgentConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AgentConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? type = null,
    Object? bridgeUrl = null,
    Object? authToken = null,
    Object? workingDirectory = freezed,
    Object? status = null,
    Object? lastConnectedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as AgentType,
      bridgeUrl: null == bridgeUrl
          ? _value.bridgeUrl
          : bridgeUrl // ignore: cast_nullable_to_non_nullable
              as String,
      authToken: null == authToken
          ? _value.authToken
          : authToken // ignore: cast_nullable_to_non_nullable
              as String,
      workingDirectory: freezed == workingDirectory
          ? _value.workingDirectory
          : workingDirectory // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as AgentConnectionStatus,
      lastConnectedAt: freezed == lastConnectedAt
          ? _value.lastConnectedAt
          : lastConnectedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AgentConfigImplCopyWith<$Res>
    implements $AgentConfigCopyWith<$Res> {
  factory _$$AgentConfigImplCopyWith(
          _$AgentConfigImpl value, $Res Function(_$AgentConfigImpl) then) =
      __$$AgentConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String displayName,
      AgentType type,
      String bridgeUrl,
      String authToken,
      String? workingDirectory,
      AgentConnectionStatus status,
      DateTime? lastConnectedAt,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$AgentConfigImplCopyWithImpl<$Res>
    extends _$AgentConfigCopyWithImpl<$Res, _$AgentConfigImpl>
    implements _$$AgentConfigImplCopyWith<$Res> {
  __$$AgentConfigImplCopyWithImpl(
      _$AgentConfigImpl _value, $Res Function(_$AgentConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of AgentConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? type = null,
    Object? bridgeUrl = null,
    Object? authToken = null,
    Object? workingDirectory = freezed,
    Object? status = null,
    Object? lastConnectedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$AgentConfigImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as AgentType,
      bridgeUrl: null == bridgeUrl
          ? _value.bridgeUrl
          : bridgeUrl // ignore: cast_nullable_to_non_nullable
              as String,
      authToken: null == authToken
          ? _value.authToken
          : authToken // ignore: cast_nullable_to_non_nullable
              as String,
      workingDirectory: freezed == workingDirectory
          ? _value.workingDirectory
          : workingDirectory // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as AgentConnectionStatus,
      lastConnectedAt: freezed == lastConnectedAt
          ? _value.lastConnectedAt
          : lastConnectedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AgentConfigImpl implements _AgentConfig {
  const _$AgentConfigImpl(
      {required this.id,
      required this.displayName,
      required this.type,
      required this.bridgeUrl,
      required this.authToken,
      this.workingDirectory,
      this.status = AgentConnectionStatus.disconnected,
      this.lastConnectedAt,
      required this.createdAt,
      required this.updatedAt});

  factory _$AgentConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$AgentConfigImplFromJson(json);

  @override
  final String id;
  @override
  final String displayName;
  @override
  final AgentType type;
  @override
  final String bridgeUrl;
  @override
  final String authToken;
  @override
  final String? workingDirectory;
  @override
  @JsonKey()
  final AgentConnectionStatus status;
  @override
  final DateTime? lastConnectedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'AgentConfig(id: $id, displayName: $displayName, type: $type, bridgeUrl: $bridgeUrl, authToken: $authToken, workingDirectory: $workingDirectory, status: $status, lastConnectedAt: $lastConnectedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AgentConfigImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.bridgeUrl, bridgeUrl) ||
                other.bridgeUrl == bridgeUrl) &&
            (identical(other.authToken, authToken) ||
                other.authToken == authToken) &&
            (identical(other.workingDirectory, workingDirectory) ||
                other.workingDirectory == workingDirectory) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.lastConnectedAt, lastConnectedAt) ||
                other.lastConnectedAt == lastConnectedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      displayName,
      type,
      bridgeUrl,
      authToken,
      workingDirectory,
      status,
      lastConnectedAt,
      createdAt,
      updatedAt);

  /// Create a copy of AgentConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AgentConfigImplCopyWith<_$AgentConfigImpl> get copyWith =>
      __$$AgentConfigImplCopyWithImpl<_$AgentConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AgentConfigImplToJson(
      this,
    );
  }
}

abstract class _AgentConfig implements AgentConfig {
  const factory _AgentConfig(
      {required final String id,
      required final String displayName,
      required final AgentType type,
      required final String bridgeUrl,
      required final String authToken,
      final String? workingDirectory,
      final AgentConnectionStatus status,
      final DateTime? lastConnectedAt,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$AgentConfigImpl;

  factory _AgentConfig.fromJson(Map<String, dynamic> json) =
      _$AgentConfigImpl.fromJson;

  @override
  String get id;
  @override
  String get displayName;
  @override
  AgentType get type;
  @override
  String get bridgeUrl;
  @override
  String get authToken;
  @override
  String? get workingDirectory;
  @override
  AgentConnectionStatus get status;
  @override
  DateTime? get lastConnectedAt;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of AgentConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AgentConfigImplCopyWith<_$AgentConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
