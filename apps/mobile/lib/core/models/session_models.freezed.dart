// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChatSession _$ChatSessionFromJson(Map<String, dynamic> json) {
  return _ChatSession.fromJson(json);
}

/// @nodoc
mixin _$ChatSession {
  String get id => throw _privateConstructorUsedError;
  String get agentType => throw _privateConstructorUsedError;
  String? get agentId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get workingDirectory => throw _privateConstructorUsedError;
  String? get branch => throw _privateConstructorUsedError;
  SessionStatus get status => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get lastMessageAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  bool get synced => throw _privateConstructorUsedError;

  /// Serializes this ChatSession to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatSessionCopyWith<ChatSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatSessionCopyWith<$Res> {
  factory $ChatSessionCopyWith(
          ChatSession value, $Res Function(ChatSession) then) =
      _$ChatSessionCopyWithImpl<$Res, ChatSession>;
  @useResult
  $Res call(
      {String id,
      String agentType,
      String? agentId,
      String title,
      String workingDirectory,
      String? branch,
      SessionStatus status,
      DateTime createdAt,
      DateTime? lastMessageAt,
      DateTime? updatedAt,
      bool synced});
}

/// @nodoc
class _$ChatSessionCopyWithImpl<$Res, $Val extends ChatSession>
    implements $ChatSessionCopyWith<$Res> {
  _$ChatSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? agentType = null,
    Object? agentId = freezed,
    Object? title = null,
    Object? workingDirectory = null,
    Object? branch = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? lastMessageAt = freezed,
    Object? updatedAt = freezed,
    Object? synced = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      agentType: null == agentType
          ? _value.agentType
          : agentType // ignore: cast_nullable_to_non_nullable
              as String,
      agentId: freezed == agentId
          ? _value.agentId
          : agentId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      workingDirectory: null == workingDirectory
          ? _value.workingDirectory
          : workingDirectory // ignore: cast_nullable_to_non_nullable
              as String,
      branch: freezed == branch
          ? _value.branch
          : branch // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SessionStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      synced: null == synced
          ? _value.synced
          : synced // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatSessionImplCopyWith<$Res>
    implements $ChatSessionCopyWith<$Res> {
  factory _$$ChatSessionImplCopyWith(
          _$ChatSessionImpl value, $Res Function(_$ChatSessionImpl) then) =
      __$$ChatSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String agentType,
      String? agentId,
      String title,
      String workingDirectory,
      String? branch,
      SessionStatus status,
      DateTime createdAt,
      DateTime? lastMessageAt,
      DateTime? updatedAt,
      bool synced});
}

/// @nodoc
class __$$ChatSessionImplCopyWithImpl<$Res>
    extends _$ChatSessionCopyWithImpl<$Res, _$ChatSessionImpl>
    implements _$$ChatSessionImplCopyWith<$Res> {
  __$$ChatSessionImplCopyWithImpl(
      _$ChatSessionImpl _value, $Res Function(_$ChatSessionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? agentType = null,
    Object? agentId = freezed,
    Object? title = null,
    Object? workingDirectory = null,
    Object? branch = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? lastMessageAt = freezed,
    Object? updatedAt = freezed,
    Object? synced = null,
  }) {
    return _then(_$ChatSessionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      agentType: null == agentType
          ? _value.agentType
          : agentType // ignore: cast_nullable_to_non_nullable
              as String,
      agentId: freezed == agentId
          ? _value.agentId
          : agentId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      workingDirectory: null == workingDirectory
          ? _value.workingDirectory
          : workingDirectory // ignore: cast_nullable_to_non_nullable
              as String,
      branch: freezed == branch
          ? _value.branch
          : branch // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SessionStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      synced: null == synced
          ? _value.synced
          : synced // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatSessionImpl implements _ChatSession {
  const _$ChatSessionImpl(
      {required this.id,
      required this.agentType,
      this.agentId,
      this.title = '',
      required this.workingDirectory,
      this.branch,
      this.status = SessionStatus.active,
      required this.createdAt,
      this.lastMessageAt,
      this.updatedAt,
      this.synced = true});

  factory _$ChatSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatSessionImplFromJson(json);

  @override
  final String id;
  @override
  final String agentType;
  @override
  final String? agentId;
  @override
  @JsonKey()
  final String title;
  @override
  final String workingDirectory;
  @override
  final String? branch;
  @override
  @JsonKey()
  final SessionStatus status;
  @override
  final DateTime createdAt;
  @override
  final DateTime? lastMessageAt;
  @override
  final DateTime? updatedAt;
  @override
  @JsonKey()
  final bool synced;

  @override
  String toString() {
    return 'ChatSession(id: $id, agentType: $agentType, agentId: $agentId, title: $title, workingDirectory: $workingDirectory, branch: $branch, status: $status, createdAt: $createdAt, lastMessageAt: $lastMessageAt, updatedAt: $updatedAt, synced: $synced)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.agentType, agentType) ||
                other.agentType == agentType) &&
            (identical(other.agentId, agentId) || other.agentId == agentId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.workingDirectory, workingDirectory) ||
                other.workingDirectory == workingDirectory) &&
            (identical(other.branch, branch) || other.branch == branch) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastMessageAt, lastMessageAt) ||
                other.lastMessageAt == lastMessageAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.synced, synced) || other.synced == synced));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      agentType,
      agentId,
      title,
      workingDirectory,
      branch,
      status,
      createdAt,
      lastMessageAt,
      updatedAt,
      synced);

  /// Create a copy of ChatSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatSessionImplCopyWith<_$ChatSessionImpl> get copyWith =>
      __$$ChatSessionImplCopyWithImpl<_$ChatSessionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatSessionImplToJson(
      this,
    );
  }
}

abstract class _ChatSession implements ChatSession {
  const factory _ChatSession(
      {required final String id,
      required final String agentType,
      final String? agentId,
      final String title,
      required final String workingDirectory,
      final String? branch,
      final SessionStatus status,
      required final DateTime createdAt,
      final DateTime? lastMessageAt,
      final DateTime? updatedAt,
      final bool synced}) = _$ChatSessionImpl;

  factory _ChatSession.fromJson(Map<String, dynamic> json) =
      _$ChatSessionImpl.fromJson;

  @override
  String get id;
  @override
  String get agentType;
  @override
  String? get agentId;
  @override
  String get title;
  @override
  String get workingDirectory;
  @override
  String? get branch;
  @override
  SessionStatus get status;
  @override
  DateTime get createdAt;
  @override
  DateTime? get lastMessageAt;
  @override
  DateTime? get updatedAt;
  @override
  bool get synced;

  /// Create a copy of ChatSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatSessionImplCopyWith<_$ChatSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SessionEvent _$SessionEventFromJson(Map<String, dynamic> json) {
  return _SessionEvent.fromJson(json);
}

/// @nodoc
mixin _$SessionEvent {
  String get id => throw _privateConstructorUsedError;
  String get sessionId => throw _privateConstructorUsedError;
  SessionEventType get eventType => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Serializes this SessionEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SessionEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SessionEventCopyWith<SessionEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionEventCopyWith<$Res> {
  factory $SessionEventCopyWith(
          SessionEvent value, $Res Function(SessionEvent) then) =
      _$SessionEventCopyWithImpl<$Res, SessionEvent>;
  @useResult
  $Res call(
      {String id,
      String sessionId,
      SessionEventType eventType,
      String title,
      String? description,
      DateTime timestamp,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class _$SessionEventCopyWithImpl<$Res, $Val extends SessionEvent>
    implements $SessionEventCopyWith<$Res> {
  _$SessionEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SessionEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? eventType = null,
    Object? title = null,
    Object? description = freezed,
    Object? timestamp = null,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      eventType: null == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as SessionEventType,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SessionEventImplCopyWith<$Res>
    implements $SessionEventCopyWith<$Res> {
  factory _$$SessionEventImplCopyWith(
          _$SessionEventImpl value, $Res Function(_$SessionEventImpl) then) =
      __$$SessionEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String sessionId,
      SessionEventType eventType,
      String title,
      String? description,
      DateTime timestamp,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class __$$SessionEventImplCopyWithImpl<$Res>
    extends _$SessionEventCopyWithImpl<$Res, _$SessionEventImpl>
    implements _$$SessionEventImplCopyWith<$Res> {
  __$$SessionEventImplCopyWithImpl(
      _$SessionEventImpl _value, $Res Function(_$SessionEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of SessionEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? eventType = null,
    Object? title = null,
    Object? description = freezed,
    Object? timestamp = null,
    Object? metadata = freezed,
  }) {
    return _then(_$SessionEventImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      eventType: null == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as SessionEventType,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SessionEventImpl implements _SessionEvent {
  const _$SessionEventImpl(
      {required this.id,
      required this.sessionId,
      required this.eventType,
      required this.title,
      this.description,
      required this.timestamp,
      final Map<String, dynamic>? metadata})
      : _metadata = metadata;

  factory _$SessionEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$SessionEventImplFromJson(json);

  @override
  final String id;
  @override
  final String sessionId;
  @override
  final SessionEventType eventType;
  @override
  final String title;
  @override
  final String? description;
  @override
  final DateTime timestamp;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'SessionEvent(id: $id, sessionId: $sessionId, eventType: $eventType, title: $title, description: $description, timestamp: $timestamp, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.eventType, eventType) ||
                other.eventType == eventType) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, sessionId, eventType, title,
      description, timestamp, const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of SessionEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionEventImplCopyWith<_$SessionEventImpl> get copyWith =>
      __$$SessionEventImplCopyWithImpl<_$SessionEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SessionEventImplToJson(
      this,
    );
  }
}

abstract class _SessionEvent implements SessionEvent {
  const factory _SessionEvent(
      {required final String id,
      required final String sessionId,
      required final SessionEventType eventType,
      required final String title,
      final String? description,
      required final DateTime timestamp,
      final Map<String, dynamic>? metadata}) = _$SessionEventImpl;

  factory _SessionEvent.fromJson(Map<String, dynamic> json) =
      _$SessionEventImpl.fromJson;

  @override
  String get id;
  @override
  String get sessionId;
  @override
  SessionEventType get eventType;
  @override
  String get title;
  @override
  String? get description;
  @override
  DateTime get timestamp;
  @override
  Map<String, dynamic>? get metadata;

  /// Create a copy of SessionEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SessionEventImplCopyWith<_$SessionEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
