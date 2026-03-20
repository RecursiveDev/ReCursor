// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hook_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HookEvent _$HookEventFromJson(Map<String, dynamic> json) {
  return _HookEvent.fromJson(json);
}

/// @nodoc
mixin _$HookEvent {
  String get eventType => throw _privateConstructorUsedError;
  String get sessionId => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  Map<String, dynamic> get payload => throw _privateConstructorUsedError;

  /// Serializes this HookEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HookEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HookEventCopyWith<HookEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HookEventCopyWith<$Res> {
  factory $HookEventCopyWith(HookEvent value, $Res Function(HookEvent) then) =
      _$HookEventCopyWithImpl<$Res, HookEvent>;
  @useResult
  $Res call(
      {String eventType,
      String sessionId,
      DateTime timestamp,
      Map<String, dynamic> payload});
}

/// @nodoc
class _$HookEventCopyWithImpl<$Res, $Val extends HookEvent>
    implements $HookEventCopyWith<$Res> {
  _$HookEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HookEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventType = null,
    Object? sessionId = null,
    Object? timestamp = null,
    Object? payload = null,
  }) {
    return _then(_value.copyWith(
      eventType: null == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      payload: null == payload
          ? _value.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HookEventImplCopyWith<$Res>
    implements $HookEventCopyWith<$Res> {
  factory _$$HookEventImplCopyWith(
          _$HookEventImpl value, $Res Function(_$HookEventImpl) then) =
      __$$HookEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String eventType,
      String sessionId,
      DateTime timestamp,
      Map<String, dynamic> payload});
}

/// @nodoc
class __$$HookEventImplCopyWithImpl<$Res>
    extends _$HookEventCopyWithImpl<$Res, _$HookEventImpl>
    implements _$$HookEventImplCopyWith<$Res> {
  __$$HookEventImplCopyWithImpl(
      _$HookEventImpl _value, $Res Function(_$HookEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of HookEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventType = null,
    Object? sessionId = null,
    Object? timestamp = null,
    Object? payload = null,
  }) {
    return _then(_$HookEventImpl(
      eventType: null == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      payload: null == payload
          ? _value._payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HookEventImpl implements _HookEvent {
  const _$HookEventImpl(
      {required this.eventType,
      required this.sessionId,
      required this.timestamp,
      required final Map<String, dynamic> payload})
      : _payload = payload;

  factory _$HookEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$HookEventImplFromJson(json);

  @override
  final String eventType;
  @override
  final String sessionId;
  @override
  final DateTime timestamp;
  final Map<String, dynamic> _payload;
  @override
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  String toString() {
    return 'HookEvent(eventType: $eventType, sessionId: $sessionId, timestamp: $timestamp, payload: $payload)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HookEventImpl &&
            (identical(other.eventType, eventType) ||
                other.eventType == eventType) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            const DeepCollectionEquality().equals(other._payload, _payload));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, eventType, sessionId, timestamp,
      const DeepCollectionEquality().hash(_payload));

  /// Create a copy of HookEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HookEventImplCopyWith<_$HookEventImpl> get copyWith =>
      __$$HookEventImplCopyWithImpl<_$HookEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HookEventImplToJson(
      this,
    );
  }
}

abstract class _HookEvent implements HookEvent {
  const factory _HookEvent(
      {required final String eventType,
      required final String sessionId,
      required final DateTime timestamp,
      required final Map<String, dynamic> payload}) = _$HookEventImpl;

  factory _HookEvent.fromJson(Map<String, dynamic> json) =
      _$HookEventImpl.fromJson;

  @override
  String get eventType;
  @override
  String get sessionId;
  @override
  DateTime get timestamp;
  @override
  Map<String, dynamic> get payload;

  /// Create a copy of HookEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HookEventImplCopyWith<_$HookEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
